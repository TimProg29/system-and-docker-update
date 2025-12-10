#!/bin/bash

# ============================================
# setup.sh - Install system update automation
# Default time: 05:00
# Usage:
#   bash setup.sh           → installs with 05:00 daily
#   bash setup.sh HH:MM     → installs with custom time
# ============================================

if [ "$EUID" -ne 0 ]; then
  echo "ERROR: Please run setup.sh as root."
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

echo "[0/5] Installing required dependencies..."
bash scripts/install-dependencies.sh

echo "[1/5] Installing systemd Watchtower service..."
cp systemd/watchtower-oneshot.service /etc/systemd/system/
systemctl daemon-reload

echo "[2/5] Installing update script..."
cp scripts/system-and-docker-update.sh /usr/local/sbin/
chmod +x /usr/local/sbin/system-and-docker-update.sh

echo "[3/5] Installing update-on-boot service and enabling it..."
cp systemd/update-on-boot.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable update-on-boot.service

echo "[4/5] Installing auto-update toggle script..."
cp scripts/auto-update-toggle.sh /usr/local/sbin/
chmod +x /usr/local/sbin/auto-update-toggle.sh

echo "[5/5] Creating cronjob at $CRON_HOUR:$CRON_MIN..."

crontab -l 2>/dev/null | grep -v "/usr/local/sbin/system-and-docker-update.sh" > /tmp/cron.$$ || true
echo "$CRON_MIN $CRON_HOUR * * * /usr/local/sbin/system-and-docker-update.sh" >> /tmp/cron.$$
crontab /tmp/cron.$$
rm -f /tmp/cron.$$

echo "======================================"
echo " Setup completed successfully!"
echo " Daily update time: $CRON_HOUR:$CRON_MIN"
echo " Auto update on boot is ENABLED by default."
echo " You can control it with:"
echo "   auto-update-toggle.sh boot-off   # disable on boot"
echo "   auto-update-toggle.sh boot-on    # re-enable on boot"
echo " Daily updates via:"
echo "   auto-update-toggle.sh on/off [HH:MM]"
echo " Logfile:"
echo "   /var/log/system-and-docker-update.log"
echo "======================================"
