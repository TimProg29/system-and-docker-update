#!/bin/bash

LOGFILE="/var/log/lxc-auto-update.log"
CONFIG_FILE="/etc/lxc-auto-update.conf"
export DEBIAN_FRONTEND=noninteractive

# Load config
AUTO_RESTART="off"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# APT optimization options
APT_OPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -o Acquire::Languages=none -o Acquire::GzipIndexes=true -o Acquire::CompressionTypes::Order::=gz"

{
  echo "=============================="
  echo "$(date): Starting LXC-Auto-Update run (cron/manual)"
  echo "$(date): Auto-restart services: $AUTO_RESTART"

  # ================================
  # Show all update sources
  # ================================
  echo ""
  echo "$(date): === System Update Sources ==="
  
  # APT upgradeable packages
  echo "$(date): APT packages with available updates:"
  apt list --upgradeable 2>/dev/null | grep -v "Listing..." | head -20 || echo "  None"
  APT_COUNT=$(apt list --upgradeable 2>/dev/null | grep -v "Listing..." | wc -l)
  echo "  Total: $APT_COUNT packages"
  
  # Snap packages
  if command -v snap &> /dev/null; then
    echo ""
    echo "$(date): Snap packages with available updates:"
    snap refresh --list 2>/dev/null || echo "  None or snap not configured"
  fi
  
  # Flatpak packages
  if command -v flatpak &> /dev/null; then
    echo ""
    echo "$(date): Flatpak packages with available updates:"
    flatpak remote-ls --updates 2>/dev/null || echo "  None"
  fi
  
  # Systemd services (running)
  echo ""
  echo "$(date): Active systemd services:"
  systemctl list-units --type=service --state=running --no-pager --no-legend | wc -l | xargs -I {} echo "  {} services running"
  
  # Needrestart - shows services needing restart after updates
  if command -v needrestart &> /dev/null; then
    echo ""
    echo "$(date): Services needing restart (pre-update):"
    needrestart -b 2>/dev/null | grep -E "NEEDRESTART-SVC" | sed 's/NEEDRESTART-SVC: /  - /' || echo "  None"
  fi

  echo "$(date): === End Update Sources ==="

  echo ""
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

  # Check for services needing restart after update
  if command -v needrestart &> /dev/null; then
    echo ""
    echo "$(date): === Services Needing Restart (post-update) ==="
    
    # Get list of services that need restart
    SERVICES_TO_RESTART=$(needrestart -b 2>/dev/null | grep "NEEDRESTART-SVC:" | sed 's/NEEDRESTART-SVC: //')
    
    if [ -n "$SERVICES_TO_RESTART" ]; then
      SERVICE_COUNT=$(echo "$SERVICES_TO_RESTART" | wc -l)
      echo "$(date): Found $SERVICE_COUNT service(s) needing restart:"
      echo "$SERVICES_TO_RESTART" | while read service; do
        echo "  - $service"
      done
      
      if [ "$AUTO_RESTART" = "on" ]; then
        echo ""
        echo "$(date): Auto-restart is ENABLED. Restarting affected services..."
        echo "$SERVICES_TO_RESTART" | while read service; do
          if [ -n "$service" ]; then
            echo "$(date): Restarting $service..."
            if systemctl restart "$service" 2>&1; then
              echo "$(date): ✓ $service restarted successfully"
            else
              echo "$(date): ✗ WARNING: Failed to restart $service"
            fi
          fi
        done
        echo "$(date): Service restarts completed."
      else
        echo ""
        echo "$(date): Auto-restart is DISABLED. Manual restart required for above services."
        echo "$(date): Enable with: update-toggle restart-on"
      fi
    else
      echo "$(date): No services need restart."
    fi
    
    # Check if kernel update requires reboot
    KERNEL_STATUS=$(needrestart -b 2>/dev/null | grep "NEEDRESTART-KSTA:" | awk '{print $2}')
    if [ "$KERNEL_STATUS" = "3" ]; then
      echo ""
      echo "$(date): ⚠ KERNEL UPDATE DETECTED - System reboot recommended!"
      echo "$(date): Run 'reboot' to apply kernel updates."
    fi
    
    echo "$(date): === End Restart Check ==="
  else
    echo ""
    echo "$(date): Note: Install 'needrestart' for service restart detection."
  fi
  
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
