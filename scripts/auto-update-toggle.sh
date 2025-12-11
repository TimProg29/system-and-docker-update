#!/bin/bash

TARGET_CMD="/usr/local/sbin/lxc-auto-update.sh"
BOOT_SERVICE="update-on-boot.service"
CONFIG_FILE="/etc/lxc-auto-update.conf"

# Create config file if not exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "AUTO_RESTART=off" > "$CONFIG_FILE"
fi

# Load config
source "$CONFIG_FILE"

get_current_cron_line() {
  crontab -l 2>/dev/null | grep "$TARGET_CMD" || true
}

show_status() {
  echo "=== LXC-Auto-Update Status ==="
  
  # Daily cron status
  if crontab -l 2>/dev/null | grep -q "lxc-auto-update.sh"; then
    CRON_TIME=$(crontab -l 2>/dev/null | grep "lxc-auto-update.sh" | awk '{print $2":"$1}')
    echo "Daily updates:    ENABLED (at $CRON_TIME)"
  else
    echo "Daily updates:    DISABLED"
  fi
  
  # Boot update status
  if systemctl is-enabled update-on-boot.service &>/dev/null; then
    echo "Boot updates:     ENABLED"
  else
    echo "Boot updates:     DISABLED"
  fi
  
  # Auto-restart status
  source "$CONFIG_FILE" 2>/dev/null
  if [ "$AUTO_RESTART" = "on" ]; then
    echo "Auto-restart:     ENABLED"
  else
    echo "Auto-restart:     DISABLED"
  fi
  
  echo "==============================="
}

case "$1" in
  on)
    DEFAULT_TIME="05:00"
    TIME_TO_USE="${2:-$DEFAULT_TIME}"

    if [[ ! "$TIME_TO_USE" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
      echo "ERROR: Invalid time format. Use HH:MM"
      exit 1
    fi

    HOUR=$(echo "$TIME_TO_USE" | cut -d':' -f1)
    MIN=$(echo "$TIME_TO_USE"  | cut -d':' -f2)

    echo "Enabling daily auto update at $HOUR:$MIN ..."

    crontab -l 2>/dev/null | grep -v "$TARGET_CMD" > /tmp/cron.$$ || true
    echo "$MIN $HOUR * * * $TARGET_CMD" >> /tmp/cron.$$
    crontab /tmp/cron.$$
    rm -f /tmp/cron.$$

    echo "Daily auto update enabled."
    ;;

  off)
    echo "Disabling daily auto update..."
    crontab -l 2>/dev/null | grep -v "$TARGET_CMD" > /tmp/cron.$$ || true
    crontab /tmp/cron.$$
    rm -f /tmp/cron.$$

    echo "Daily auto update disabled."
    ;;

  boot-on)
    echo "Enabling update-on-boot..."
    systemctl enable $BOOT_SERVICE
    echo "Update will run automatically at container startup."
    ;;

  boot-off)
    echo "Disabling update-on-boot..."
    systemctl disable $BOOT_SERVICE
    echo "Startup update disabled."
    ;;

  restart-on)
    sed -i 's/AUTO_RESTART=.*/AUTO_RESTART=on/' "$CONFIG_FILE"
    echo "Auto-restart after updates ENABLED"
    ;;

  restart-off)
    sed -i 's/AUTO_RESTART=.*/AUTO_RESTART=off/' "$CONFIG_FILE"
    echo "Auto-restart after updates DISABLED"
    ;;

  status)
    show_status
    ;;

  *)
    echo "Usage:"
    echo "  $0 on [HH:MM]       # enable daily auto update"
    echo "  $0 off              # disable daily auto update"
    echo "  $0 boot-on          # enable auto update at container startup"
    echo "  $0 boot-off         # disable auto update at startup"
    echo "  $0 restart-on       # enable auto-restart of services after update"
    echo "  $0 restart-off      # disable auto-restart of services after update"
    echo "  $0 status           # show current auto-update status"
    exit 1
    ;;
esac
