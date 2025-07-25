#!/bin/bash
#
# Configuration for Mattermost backup and restore scripts
# The defaults assume you have follow the installation guide described
# [here](https://docs.mattermost.com/deploy/server/deploy-linux.html)
# then you can leave this file as is

# PostgreSQL database name used by Mattermost
DB_NAME="mattermost"

# PostgreSQL user with privileges to dump and restore the database
# Leave this as default if you follow the installation guide
DB_USER="mmuser"

# Path to the Mattermost data directory (e.g. file uploads, configs)
# Leave this as default if you follow the installation guide
DATA_DIR="/opt/mattermost/data"

# Temporary path to restore Mattermost data before moving it into place
RESTORE_DIR="/tmp/mattermost-restore"

# Temporary path to store pg_dump output and logs during backup
TMP_DIR="/tmp/mattermost-backup"

# Restic repository path (can be a local directory or remote like s3:s3bucket-name)
# This is where your backups are stored
RESTIC_REPO="root@localhost:/mm-backup/restic-mattermost"

# File containing the password for the restic repository
RESTIC_PW_FILE="/root/.restic-password"

# Number of daily backups to keep
KEEP_DAILY=7

# Number of weekly backups to keep
KEEP_WEEKLY=5

# Number of monthly backups to keep
KEEP_MONTHLY=6

# Optional: Mattermost webhook URL for notifications
# Leave empty if not using notifications
MATTERMOST_WEBHOOK=""

# Current date and time for log entries
DATE=$(date +%F-%H%M)

# Log file path for backup and restore operations
# Ensure the specified path is writable
LOG_FILE="/var/log/mattermost-backup.log"