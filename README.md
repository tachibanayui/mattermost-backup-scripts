# Mattermost Backup Script (Restic + PostgreSQL)

This repository contains a set of Bash scripts for backing up a self-hosted Mattermost instance installed natively on Linux. It uses `restic` for secure and efficient backups. This script is designed to be run directly from the server hosting your Mattermost instance. It assumes that the Mattermost application and its data are accessible locally on the server.

## Features

-   Backs up:
    -   PostgreSQL database (`pg_dump`)
    -   Mattermost data directory (e.g., `/opt/mattermost/data`)
    -   By default, backups are stored at `/mm-backup/restic-mattermost`, you can customize this by editing `RESTIC_REPO` variable in the `env.sh` file
-   Encrypted and deduplicated backups using [`restic`](https://restic.net)
-   It supports a wide range of backends: local disks, SFTP, AWS S3, Backblaze B2, GCP,... using `restic`
-   Retention policy:
    -   7 daily
    -   5 weekly
    -   6 monthly snapshots
-   Cron-ready and includes logging
-   Includes restore script

## Files

-   `backup.sh` – Main backup script
-   `restore.sh` – Database and data restore script
-   `env.sh` – Environment variable configuration. It contains all the necessary variables required for the backup and restore process. Open `env.sh` and follow the inline comments to fill in the required information specific to your deployment.
-   `README.md` – This file

## Usage

1. **Edit config file**:
   Open `env.sh` and edit the config to your deployment
    > **Note:** If you want to use SFTP as your backup destination, set the `RESTIC_REPO` variable in `env.sh` to the SFTP URL, e.g. `sftp:user@host:/path/to/repo`. Make sure the server is accessible and SSH keys or credentials are configured for authentication.
2. **Run backup.sh**:
   Run `backup.sh`, the first run will initialize the restic repository, you will be asked to
   create a password for your backups

## Automating Backups

You can automate the backup process using either a cron job or a systemd timer.

### Using Cron

1. Open the crontab editor:
    ```bash
    crontab -e
    ```
2. Add the following line to schedule the backup script (e.g., daily at 2 AM):
    ```bash
    0 2 * * * /path/to/backup.sh >> /var/log/mattermost-backup.log 2>&1
    ```
3. Save and exit the editor. The cron job will now run the backup script at the specified time.

### Using a Systemd Timer

1. Copy the provided service and timer files to the appropriate locations:

    ```bash
    sudo cp ./systemd-timers/mattermost-backup.service /etc/systemd/system/
    sudo cp ./systemd-timers/mattermost-backup.timer /etc/systemd/system/
    ```

    **Note:** Before copying, ensure that the `ExecStart` path in `mattermost-backup.service` points to the correct location of your `backup.sh` script.

2. Enable and start the timer:

    ```bash
    sudo systemctl enable mattermost-backup.timer --now
    ```

3. Verify the timer is active:
    ```bash
    systemctl list-timers --all
    ```

## Mattermost Backup Status Notifications

This project supports sending backup success/failure messages to a Mattermost channel using an [Incoming Webhook](https://docs.mattermost.com/integrations/incoming-webhooks.html).

### Enable Notifications

1. **Create a Webhook in Mattermost:**

    - Go to **Main Menu -> Integrations -> Incoming Webhooks**
    - Click **"Add Incoming Webhook"**
    - Set:
        - **Channel**: the channel you want to receive messages
        - Set other fields to your need
    - Click **Save** and copy the **Webhook URL**

2. **Edit `env.sh`:**

    Add the following line:

    ```bash
    MATTERMOST_WEBHOOK="https://your-mattermost-url/hooks/xxxxxxxxxx"
    ```

### Disable Notifications

To disable, simply comment out or remove the MATTERMOST_WEBHOOK line in env.sh:

```bash
# MATTERMOST_WEBHOOK="..."
```

## Restore

To restore from a backup run:

```bash
./restore.sh snapshot-id
```

If you omit `snapshot-id`, the script will show a list of available snapshots for you to select from.

## License

This project is licensed under the [MIT License](LICENSE).
