# Auto System and Docker Update
A fully automated system and Docker update solution for Debian 13 LXC containers.  
Includes one-shot Watchtower updates, daily scheduled updates, boot-time updates,  
and a complete toggle system to enable or disable automatic updates at any time.

---

##  Features

- Automatic system updates (APT)
- Automatic Docker container updates using Watchtower (one-shot mode)
- Automatic updates on container startup (optional)
- Daily scheduled updates via Cron
- Full enable/disable toggle system for daily updates & boot updates
- Manual update execution
- Full log output
- Automatic installation of all required dependencies (Docker, Cron, etc.)

---

##  Components Included

### Systemd Services
- `watchtower-oneshot.service` – runs Watchtower once per update cycle
- `update-on-boot.service` – optional automatic update on container startup

### Shell Scripts
- `setup.sh` – installs and configures the entire update system
- `install-dependencies.sh` – installs Docker, Cron, and required tools
- `system-and-docker-update.sh` – performs the actual update tasks
- `auto-update-toggle.sh` – enables/disables automatic updates and boot updates

---

##  Installation

### 1. Clone the repository
- `git clone https://github.com/TimProg29/system-and-docker-update.git`

### 2. Master Install Command (Default Update Time 05:00)
- `cd watchtower-lxc-update && chmod +x setup.sh scripts/*.sh && systemctl daemon-reload && bash setup.sh`

### 2. Master Install Command (Custom Update Time HH:MM)
- `cd watchtower-lxc-update && chmod +x setup.sh scripts/*.sh && systemctl daemon-reload && bash setup.sh <HH:MM>`

---

## Commands
- `bash setup.sh` - Installs/updates the update system with default daily update time at 05:00.
- `bash setup.sh <HH:MM>` - Installs/updates the update system with daily update time at specified HH:MM.
- `bash update-toggle.sh on` - Enables automatic daily updates.
- `bash update-toggle.sh off` - Disables automatic daily updates.
- `bash update-toggle.sh boot-on` - Enables automatic updates on container startup.
- `bash update-toggle.sh boot-off` - Disables automatic updates on container startup.
- `bash update-toggle.sh status` - Displays the current status of automatic updates.
- `bash /usr/local/sbin/system-and-docker-update.sh` - Manually runs the update process immediately.

---

## Logs
- Update logs are stored at `/var/log/system-and-docker-update.log`.
- View logs with `cat /var/log/system-and-docker-update.log` or `tail -f /var/log/system-and-docker-update.log` for real-time updates.

---

## Deinstallation
- `auto-update-toggle.sh off`
- `auto-update-toggle.sh boot-off`

- `rm /usr/local/sbin/system-and-docker-update.sh`
- `rm /usr/local/sbin/auto-update-toggle.sh`
- `rm /etc/systemd/system/watchtower-oneshot.service`
- `rm /etc/systemd/system/update-on-boot.service`

- `systemctl daemon-reload`

---
