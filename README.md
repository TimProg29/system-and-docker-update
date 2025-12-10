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
- `create-symlinks.sh` – creates short command aliases (update-system, update-toggle)

---

##  Installation

### 1. Clone the repository
```bash
git clone https://github.com/TimProg29/system-and-docker-update.git
cd system-and-docker-update
```

### 2. Master Install Command (Default Update Time 05:00)
```bash
chmod +x setup.sh scripts/*.sh && bash setup.sh
```

### 2. Master Install Command (Custom Update Time HH:MM)
```bash
chmod +x setup.sh scripts/*.sh && bash setup.sh <HH:MM>
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
| `update-toggle status` | Displays the current status of automatic updates |
| `update-log` | View full update log |
| `update-log-live` | View real-time update log |

### Setup Commands
| Command | Description |
|---------|-------------|
| `bash setup.sh` | Installs/updates with default daily update time at 05:00 |
| `bash setup.sh <HH:MM>` | Installs/updates with specified daily update time |

---

## Logs
- Update logs are stored at `/var/log/system-and-docker-update.log`

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
rm /usr/local/sbin/system-and-docker-update.sh
rm /usr/local/sbin/auto-update-toggle.sh

# Remove services
rm /etc/systemd/system/watchtower-oneshot.service
rm /etc/systemd/system/update-on-boot.service

# Remove log file (optional)
rm /var/log/system-and-docker-update.log

# Reload systemd
systemctl daemon-reload
```

---

## Links
- Watchtower GitHub: https://github.com/containrrr/watchtower
- Docker Documentation: https://github.com/moby/moby
- Debian LXC: https://github.com/lxc/lxc
- Cron Documentation: https://github.com/vixie/cron

---

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.
