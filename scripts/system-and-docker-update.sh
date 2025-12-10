#!/bin/bash

LOGFILE="/var/log/system-and-docker-update.log"
export DEBIAN_FRONTEND=noninteractive

# APT optimization options
APT_OPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Acquire::Languages=none -o Acquire::GzipIndexes=true -o Acquire::CompressionTypes::Order::=gz"

{
  echo "=============================="
  echo "$(date): Starting full update run (cron/manual)"

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
  echo "$(date): Starting Watchtower (one-time run)..."

  /usr/bin/systemctl start watchtower-oneshot.service
  WT_RC=$?

  if [ $WT_RC -ne 0 ]; then
    echo "$(date): ERROR: Watchtower exit code $WT_RC."
    exit $WT_RC
  else
    echo "$(date): Watchtower completed successfully."
  fi

  echo "$(date): Update run finished."
  echo "=============================="

} >> "$LOGFILE" 2>&1
