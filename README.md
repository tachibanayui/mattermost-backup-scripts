# Mattermost Backup Script (Restic + PostgreSQL)

This repository contains a set of Bash scripts for backing up a self-hosted Mattermost instance installed natively on Linux. It uses `restic` for secure and efficient backups

## Features

-   Backs up:
    -   PostgreSQL database (`pg_dump`)
    -   Mattermost data directory (e.g., `/opt/mattermost/data`)
-   Encrypted and deduplicated backups using [`restic`](https://restic.net)
-   Retention policy:
    -   7 daily
    -   5 weekly
    -   6 monthly snapshots
-   Cron-ready and includes logging
-   Includes restore script

## Files

-   `backup.sh` – Main backup script
-   `restore.sh` – Database and data restore script
-   `env.sh` – Environment variable configuration (paths, credentials, etc.)
-   `README.md` – This file

## Usage

1. **Edit config file**:
   Open `env.sh` and edit the config to your deployment
2. **Run backup.sh**:
   Run `backup.sh`, the first run will initialize the restic repository, you will be asked to
   create a password for your backups
3. **Set up cron job**:
   Add to crontab using cron.txt as a template:
    ```bash
    crontab -e
    ```

## Restore

To restore from a backup run:

```bash
./restore.sh snapshot-id
```

If you omit `snapshot-id`, the script will show a list of available snapshots for you to select from.
