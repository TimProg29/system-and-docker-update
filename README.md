# LXC-Auto-Update

A fully automated system and Docker update solution for Debian-based LXC containers (Debian 12/13).

LXC-Auto-Update keeps your containers always up-to-date with minimal effort. It combines APT system updates with Docker container updates via Watchtower in a single, automated solution. The tool supports daily scheduled updates, boot-time updates, automatic service restarts, and custom update commands for third-party applications like Pi-hole or Home Assistant.

### Key Highlights
- 🔄 **Fully Automated** – Set it and forget it
- 🐳 **Docker Support** – Updates all containers via Watchtower
- ⏰ **Flexible Scheduling** – Daily cron jobs + optional boot updates
- 🔧 **Service Management** – Auto-restart services after updates
- 📝 **Custom Commands** – Add your own update scripts
- 📊 **Detailed Logging** – Full visibility into update processes

---

## Features

### System Updates
- Automatic system updates (APT dist-upgrade)
- Optimized APT commands for faster updates
- Automatic cleanup (autoremove, autoclean)

### Docker Updates
- Automatic Docker container updates using Watchtower (one-shot mode)
- Automatic Docker API version detection
- Container overview in logs (running & stopped)
- Image cleanup after updates

### Scheduling
- Daily scheduled updates via Cron (customizable time)
- Automatic updates on container startup (optional)
- Full enable/disable toggle system

### Service Management
- Automatic detection of services needing restart (via needrestart)
- Optional auto-restart of affected services after updates
- Kernel update detection with reboot notification

### Custom Commands
- Add custom update commands for any application
- Support for Pi-hole, AMP, Home Assistant, Snap, and more
- Easy management (add, remove, list)

### Logging & Monitoring
- Full log output to `/var/log/lxc-auto-update.log`
- Real-time log viewing
- Pre-update package overview
- Post-update service status

### Installation & Configuration
- Automatic installation of all dependencies (Docker, Cron, needrestart)
- Simple setup with single command
- Short command aliases for easy management
- Configuration file for persistent settings

---

## Components Included

### Systemd Services
- `watchtower-oneshot.service` – runs Watchtower once per update cycle
- `update-on-boot.service` – optional automatic update on container startup

### Shell Scripts
- `setup.sh` – installs and configures the entire update system
- `install-dependencies.sh` – installs Docker, Cron, and required tools
- `lxc-auto-update.sh` – performs the actual update tasks
- `auto-update-toggle.sh` – enables/disables automatic updates and boot updates
- `create-symlinks.sh` – creates short command aliases
- `run-watchtower.sh` – runs Watchtower with correct Docker API version

---

## Installation

### Clone the repository
```bash
git clone https://github.com/TimProg29/LXC-Auto-Update.git
cd LXC-Auto-Update
```

### Install with default update time (05:00)
```bash
chmod +x setup.sh scripts/*.sh && bash setup.sh
```

### Install with custom update time (HH:MM)
```bash
chmod +x setup.sh scripts/*.sh && bash setup.sh 22:30
```

---

## Commands

### Short Commands (after installation)
| Command | Description |
|---------|-------------|
| `update-system` | Manually runs the update process immediately |
| `update-toggle on` | Enables automatic daily updates |
| `update-toggle off` | Disables automatic daily updates |
| `update-toggle boot-on` | Enables automatic updates on container startup |
| `update-toggle boot-off` | Disables automatic updates on container startup |
| `update-toggle restart-on` | Enables auto-restart of services after update |
| `update-toggle restart-off` | Disables auto-restart of services after update |
| `update-toggle status` | Displays the current status of all settings |
| `update-custom add "<cmd>" "<desc>"` | Add a custom update command |
| `update-custom remove <number>` | Remove a custom command by number |
| `update-custom list` | List all custom update commands |
| `update-log` | View full update log |
| `update-log-live` | View real-time update log |

---

### Setup Commands
| Command | Description |
|---------|-------------|
| `bash setup.sh` | Installs with default daily update time at 05:00 |
| `bash setup.sh <HH:MM>` | Installs with specified daily update time |

---

## Logs

Update logs are stored at `/var/log/lxc-auto-update.log`

| Command | Description |
|---------|-------------|
| `update-log` | View full log |
| `update-log-live` | View real-time updates |

---

## Deinstallation
```bash
# Disable services
update-toggle off
update-toggle boot-off

# Remove symlinks
rm /usr/local/bin/update-system
rm /usr/local/bin/update-toggle
rm /usr/local/bin/update-log
rm /usr/local/bin/update-log-live

# Remove scripts
rm /usr/local/sbin/lxc-auto-update.sh
rm /usr/local/sbin/auto-update-toggle.sh
rm /usr/local/sbin/run-watchtower.sh

# Remove config
rm /etc/lxc-auto-update.conf

# Remove services
rm /etc/systemd/system/watchtower-oneshot.service
rm /etc/systemd/system/update-on-boot.service

# Remove log file (optional)
rm /var/log/lxc-auto-update.log

# Reload systemd
systemctl daemon-reload
```

---

## Links

### Core Components
- [Watchtower GitHub](https://github.com/containrrr/watchtower)
- [Docker Documentation](https://docs.docker.com/)
- [Debian LXC](https://wiki.debian.org/LXC)

### Tools Used
- [Cron Documentation](https://man7.org/linux/man-pages/man5/crontab.5.html)
- [Systemd Documentation](https://www.freedesktop.org/software/systemd/man/)
- [needrestart](https://github.com/liske/needrestart)
- [APT Documentation](https://wiki.debian.org/Apt)

---

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.
