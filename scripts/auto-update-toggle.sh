#!/bin/bash

TARGET_CMD="/usr/local/sbin/lxc-auto-update.sh"
BOOT_SERVICE="update-on-boot.service"

if [ "$EUID" -ne 0 ]; then
  echo "ERROR: Please run this script as root."
  exit 1
fi

ACTION="$1"
TIME_ARG="$2"

get_current_cron_line() {
  crontab -l 2>/dev/null | grep "$TARGET_CMD" || true
}

case "$ACTION" in
  on)
    DEFAULT_TIME="05:00"
    TIME_TO_USE="${TIME_ARG:-$DEFAULT_TIME}"

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

  status)
    CRON_LINE=$(get_current_cron_line)
    if [ -z "$CRON_LINE" ]; then
      CRON_STATUS="OFF"
    else
      CRON_MIN=$(echo "$CRON_LINE" | awk '{print $1}')
      CRON_HOUR=$(echo "$CRON_LINE" | awk '{print $2}')
      CRON_STATUS="ON (scheduled at ${CRON_HOUR}:${CRON_MIN})"
    fi

    BOOT_ENABLED=$(systemctl is-enabled $BOOT_SERVICE 2>/dev/null || echo "disabled")

    echo "Auto update (daily cron): $CRON_STATUS"
    echo "Auto update on boot:      $BOOT_ENABLED"
    ;;

  *)
    echo "Usage:"
    echo "  $0 on [HH:MM]       # enable daily auto update"
    echo "  $0 off              # disable daily auto update"
    echo "  $0 boot-on          # enable auto update at container startup"
    echo "  $0 boot-off         # disable auto update at startup"
    echo "  $0 status           # show current auto-update status"
    exit 1
    ;;
esac
