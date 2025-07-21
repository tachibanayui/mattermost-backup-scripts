#!/bin/bash
SNAPSHOT="$1"
set -euo pipefail
source env.sh
if ! dpkg -s "restic" &>/dev/null; then
    echo "Restic not installed" | tee -a "$LOG_FILE"
    sudo apt install -y restic
fi

if [ ! -r "$RESTIC_PW_FILE" ]; then
    echo "Password is not set!"
    read -s -p "Please enter encryption password for backup: " PASSWORD
    echo "$PASSWORD" > "$RESTIC_PW_FILE"
    chmod 600 "$RESTIC_PW_FILE"  
    echo "Password saved to $RESTIC_PW_FILE!"
fi

if [ -z "$SNAPSHOT" ]; then
    echo "[*] Available snapshots:"
    restic -r "$RESTIC_REPO" --password-file "$RESTIC_PW_FILE" snapshots
    echo
    read -rp "Enter snapshot ID to restore: " SNAPSHOT
fi

echo "[*] Starting Mattermost restore from snapshot: $SNAPSHOT"
if [ ! -d "$RESTIC_REPO" ]; then
    echo "ERROR: Restic repository not found at $RESTIC_REPO"
    exit 1
fi

rm -rf "$RESTORE_DIR"
mkdir -p "$RESTORE_DIR"

echo "[*] Restoring snapshot files to $RESTORE_DIR..."
restic -r "$RESTIC_REPO" --password-file "$RESTIC_PW_FILE" restore "$SNAPSHOT" --target "$RESTORE_DIR"

LATEST_SQL=$(find "$RESTORE_DIR" -name 'db-*.sql.gz' | sort | tail -n 1)
if [ -z "$LATEST_SQL" ]; then
    echo "ERROR: No SQL dump found in snapshot"
    exit 1
fi

echo "[*] Stopping Mattermost service..."
systemctl stop mattermost

echo "[*] Dropping and recreating database..."
sudo -u postgres psql <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME;
EOF

echo "[*] Restoring PostgreSQL from $LATEST_SQL..."
gunzip -c "$LATEST_SQL" | sudo -u postgres psql "$DB_NAME"
sudo -u postgres psql "$DB_NAME" <<EOF
ALTER SCHEMA public OWNER TO $DB_USER;
GRANT ALL ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $DB_USER;
EOF

echo "[*] Restoring file data to $DATA_DIR..."
rm -rf "$DATA_DIR"/*
cp -a "$RESTORE_DIR$DATA_DIR/." "$DATA_DIR/"

echo "[*] Starting Mattermost service..."
systemctl restart mattermost

echo "[*] Restore complete!"