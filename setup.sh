#!/bin/bash

# ============================================
# setup.sh - Install system update automation
# Default time: 05:00
# Usage:
#   bash setup.sh           → installs with 05:00 daily
#   bash setup.sh HH:MM     → installs with custom time
# ============================================

# Get the directory where setup.sh is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
  echo "ERROR: Please run setup.sh as root."
  exit 1
fi

# Verify required files exist
if [ ! -d "$SCRIPT_DIR/scripts" ] || [ ! -d "$SCRIPT_DIR/systemd" ]; then
  echo "ERROR: Required directories 'scripts/' and 'systemd/' not found."
  echo "Please run setup.sh from the repository root directory."
  exit 1
fi

DEFAULT_TIME="05:00"
INPUT_TIME="${1:-$DEFAULT_TIME}"

if [[ ! "$INPUT_TIME" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
  echo "ERROR: Invalid time format. Use HH:MM (e.g. 22:52)"
  exit 1
fi

CRON_HOUR=$(echo "$INPUT_TIME" | cut -d':' -f1)
CRON_MIN=$(echo "$INPUT_TIME"  | cut -d':' -f2)

echo "Using daily update time: $CRON_HOUR:$CRON_MIN"

echo "[0/6] Installing required dependencies..."
bash "$SCRIPT_DIR/scripts/install-dependencies.sh"

echo "[1/6] Installing systemd Watchtower service..."
cp "$SCRIPT_DIR/systemd/watchtower-oneshot.service" /etc/systemd/system/
systemctl daemon-reload

echo "[2/6] Installing update script..."
cp "$SCRIPT_DIR/scripts/system-and-docker-update.sh" /usr/local/sbin/
chmod +x /usr/local/sbin/system-and-docker-update.sh

echo "[3/6] Installing update-on-boot service and enabling it..."
cp "$SCRIPT_DIR/systemd/update-on-boot.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable update-on-boot.service

echo "[4/6] Installing auto-update toggle script..."
cp "$SCRIPT_DIR/scripts/auto-update-toggle.sh" /usr/local/sbin/
chmod +x /usr/local/sbin/auto-update-toggle.sh

echo "[5/6] Creating short command symlinks..."
bash "$SCRIPT_DIR/scripts/create-symlinks.sh"

# Create log file if it doesn't exist
LOGFILE="/var/log/system-and-docker-update.log"
if [ ! -f "$LOGFILE" ]; then
    touch "$LOGFILE"
    echo "$(date): Log file created by setup.sh" >> "$LOGFILE"
fi

echo "[6/6] Creating cronjob at $CRON_HOUR:$CRON_MIN..."

crontab -l 2>/dev/null | grep -v "/usr/local/sbin/system-and-docker-update.sh" > /tmp/cron.$$ || true
echo "$CRON_MIN $CRON_HOUR * * * /usr/local/sbin/system-and-docker-update.sh" >> /tmp/cron.$$
crontab /tmp/cron.$$
rm -f /tmp/cron.$$

echo "======================================"
echo " Setup completed successfully!"
echo " Daily update time: $CRON_HOUR:$CRON_MIN"
echo " Auto update on boot is ENABLED by default."
echo ""
echo " Short commands available:"
echo "   update-system              # run updates manually"
echo "   update-toggle status       # show current status"
echo "   update-toggle on/off       # enable/disable daily updates"
echo "   update-toggle boot-on/off  # enable/disable boot updates"
echo "   update-log                 # view full log"
echo "   update-log-live            # view real-time log"
echo ""
echo " Logfile: /var/log/system-and-docker-update.log"
echo "======================================"
