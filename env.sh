#!/bin/bash
#
# Configuration for Mattermost backup and restore scripts

# PostgreSQL database name used by Mattermost
DB_NAME="mattermost"

# PostgreSQL user with privileges to dump and restore the database
DB_USER="mmuser"

# Path to the Mattermost data directory (e.g. file uploads, configs)
DATA_DIR="/opt/mattermost/data"

# Temporary path to restore Mattermost data before moving it into place
RESTORE_DIR="/tmp/mattermost-restore"

# Temporary path to store pg_dump output and logs during backup
TMP_DIR="/tmp/mattermost-backup"

# Restic repository path (can be a local directory or remote like s3:s3bucket-name)
RESTIC_REPO="/mm-backup/restic-mattermost"

# File containing the password for the restic repository
RESTIC_PW_FILE="/root/.restic-password"

# Number of daily backups to keep
KEEP_DAILY=7

# Number of weekly backups to keep
KEEP_WEEKLY=5

# Number of monthly backups to keep
KEEP_MONTHLY=6
