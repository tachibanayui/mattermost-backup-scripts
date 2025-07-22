#!/bin/bash
set -euo pipefail
source env.sh
trap 'on_failure' ERR

on_failure() {
    send_mattermost_notification failed "Backup failed on $(hostname). Check logs at $LOG_FILE"
    exit 1
}

send_mattermost_notification() {
    local status="$1"
    local message="$2"
    local color="#00FF00"
    [ "$status" = "failed" ] && color="#FF0000"
    [ -z "${MATTERMOST_WEBHOOK:-}" ] && return

    curl -X POST -H 'Content-Type: application/json' \
        -d "{
            \"attachments\": [{
                \"fallback\": \"Backup $status\",
                \"color\": \"$color\",
                \"title\": \"Mattermost Backup $status\",
                \"text\": \"$message\",
                \"footer\": \"Backup Script\",
                \"username\": \"Mattermost backup script\",
                \"ts\": $(date +%s)
            }]
        }" "$MATTERMOST_WEBHOOK"
}

if ! dpkg -s "restic" &>/dev/null; then
    echo "Restic not installed" | tee -a "$LOG_FILE"
    sudo apt install -y restic
fi

if [ ! -r "$RESTIC_PW_FILE" ]; then
    echo "Password is not set!"
    read -s -p "Please enter encryption password for backup: " PASSWORD
    echo "$PASSWORD" > "$RESTIC_PW_FILE"
    chmod 600 "$RESTIC_PW_FILE"  # Restrict file access
    echo "Password saved to $RESTIC_PW_FILE!"
fi

echo "[$DATE] Starting Mattermost backup" | tee -a "$LOG_FILE"
mkdir -p "$TMP_DIR"
echo "[$DATE] Dumping PostgreSQL..." | tee -a "$LOG_FILE"
sudo -u postgres pg_dump "$DB_NAME" | gzip > "$TMP_DIR/db-$DATE.sql.gz"
if [ ! -f "$RESTIC_REPO/config" ]; then
    echo "[$DATE] Initializing Restic repo..." | tee -a "$LOG_FILE"
    restic -r "$RESTIC_REPO" --password-file "$RESTIC_PW_FILE" init
fi

echo "[$DATE] Running backup..." | tee -a "$LOG_FILE"
restic -r "$RESTIC_REPO" --password-file "$RESTIC_PW_FILE" backup \
    "$TMP_DIR/db-$DATE.sql.gz" \
    "$DATA_DIR"

echo "[$DATE] Pruning old backups..." | tee -a "$LOG_FILE"
restic -r "$RESTIC_REPO" \
    --password-file "$RESTIC_PW_FILE" forget \
    --keep-daily $KEEP_DAILY \
    --keep-weekly $KEEP_WEEKLY \
    --keep-monthly $KEEP_MONTHLY \
    --prune

echo "[$DATE] Cleaning up temp files..." | tee -a "$LOG_FILE"
rm -rf "$TMP_DIR"

echo "[$DATE] Local backup complete!" | tee -a "$LOG_FILE"
send_mattermost_notification success "Backup completed on $(hostname)."