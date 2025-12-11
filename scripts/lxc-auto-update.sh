#!/bin/bash

LOGFILE="/var/log/lxc-auto-update.log"
export DEBIAN_FRONTEND=noninteractive

# APT optimization options
APT_OPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Acquire::Languages=none -o Acquire::GzipIndexes=true -o Acquire::CompressionTypes::Order::=gz"

{
  echo "=============================="
  echo "$(date): Starting LXC-Auto-Update run (cron/manual)"

  echo "$(date): Running APT update..."
  if ! /usr/bin/apt-get update -q $APT_OPTS; then
    echo "$(date): ERROR running apt-get update. Watchtower will NOT run."
    exit 1
  fi

  echo "$(date): Running APT dist-upgrade..."
  if ! /usr/bin/apt-get -y -q dist-upgrade $APT_OPTS; then
    echo "$(date): ERROR running dist-upgrade. Watchtower will NOT run."
    exit 1
  fi

  echo "$(date): Cleaning up packages..."
  /usr/bin/apt-get -y -q autoremove --purge $APT_OPTS || true
  /usr/bin/apt-get -y -q autoclean || true

  echo "$(date): System update completed successfully."
  
  echo ""
  echo "$(date): === Docker Container Overview ==="
  echo "Running containers:"
  docker ps --format "  - {{.Names}} ({{.Image}})" 2>/dev/null || echo "  No running containers found."
  echo ""
  echo "All containers:"
  docker ps -a --format "  - {{.Names}} ({{.Image}}) - Status: {{.Status}}" 2>/dev/null || echo "  No containers found."
  echo ""
  
  echo "$(date): Starting Watchtower (one-time run)..."
  echo "$(date): Checking for Docker image updates..."

  /usr/bin/systemctl start watchtower-oneshot.service
  WT_RC=$?

  # Capture Watchtower logs
  echo ""
  echo "$(date): === Watchtower Log Output ==="
  journalctl -u watchtower-oneshot.service --no-pager -n 50 --since "1 minute ago" 2>/dev/null | grep -v "^--" || true
  echo "$(date): === End Watchtower Log ==="
  echo ""

  if [ $WT_RC -ne 0 ]; then
    echo "$(date): ERROR: Watchtower exit code $WT_RC."
    exit $WT_RC
  else
    echo "$(date): Watchtower completed successfully."
  fi

  echo "$(date): LXC-Auto-Update run finished."
  echo "=============================="

} >> "$LOGFILE" 2>&1
