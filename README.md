# Mattermost Backup Script (Restic + PostgreSQL)

This repository contains a set of Bash scripts for backing up a self-hosted Mattermost instance installed natively on Linux. It uses `restic` for secure and efficient backups. This script is designed to be run directly from the server hosting your Mattermost instance. It assumes that the Mattermost application and its data are accessible locally on the server.

## Features

-   Backs up:
    -   PostgreSQL database (`pg_dump`)
    -   Mattermost data directory (e.g., `/opt/mattermost/data`)
    -   Backups are stored at `/mm`, you can customize this by editing `RESTIC_REPO` variable in the `env.sh` file
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
-   `env.sh` – Environment variable configuration. It contains all the necessary variables required for the backup and restore process. Open `env.sh` and follow the inline comments to fill in the required information specific to your deployment.
-   `README.md` – This file

## Usage

1. **Edit config file**:
   Open `env.sh` and edit the config to your deployment
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

1. Create a systemd service file:
    ```bash
    sudo nano /etc/systemd/system/mattermost-backup.service
    ```
2. Add the following content to the file:

    ```ini
    [Unit]
    Description=Mattermost Backup Service

    [Service]
    Type=oneshot
    ExecStart=/path/to/backup.sh
    ```

3. Create a systemd timer file:
    ```bash
    sudo nano /etc/systemd/system/mattermost-backup.timer
    ```
4. Add the following content to the file:

    ```ini
    [Unit]
    Description=Run Mattermost Backup Daily

    [Timer]
    OnCalendar=*-*-* 02:00:00

    [Install]
    WantedBy=timers.target
    ```

5. Enable and start the timer:
    ```bash
    sudo systemctl enable mattermost-backup.timer
    sudo systemctl start mattermost-backup.timer
    ```
6. Verify the timer is active:
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
