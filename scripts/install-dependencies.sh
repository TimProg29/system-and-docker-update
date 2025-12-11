#!/bin/bash
set -e

echo "=== install-dependencies.sh: checking required components ==="

if [ "$EUID" -ne 0 ]; then
  echo "ERROR: Please run this script as root."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/5] Updating APT package index..."
apt-get update -y

echo "[2/5] Installing base tools (curl, ca-certificates, gnupg)..."
apt-get install -y curl ca-certificates gnupg

echo "[3/5] Ensuring cron is installed and running..."
apt-get install -y cron
systemctl enable --now cron

echo "[4/5] Ensuring unattended-upgrades is installed..."
apt-get install -y unattended-upgrades

echo "[4.5/5] Installing needrestart for service restart detection..."
apt-get install -y needrestart
# Configure needrestart for automatic mode (no prompts)
sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'l';/" /etc/needrestart/needrestart.conf 2>/dev/null || true

echo "[5/5] Checking Docker installation..."

# Determine correct Debian codename for Docker repo
. /etc/os-release
DOCKER_CODENAME="${VERSION_CODENAME}"

# Docker may not have repos for testing/unstable versions - fallback to bookworm
case "$DOCKER_CODENAME" in
  trixie|sid|testing|unstable)
    echo "Notice: Debian $DOCKER_CODENAME detected. Using 'bookworm' for Docker repository."
    DOCKER_CODENAME="bookworm"
    ;;
esac

fix_docker_gpg_key() {
  echo "Setting up Docker GPG key..."
  rm -f /etc/apt/keyrings/docker.gpg
  rm -f /etc/apt/keyrings/docker.asc
  install -m 0755 -d /etc/apt/keyrings
  
  # Download and dearmor in one step
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
${DOCKER_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list
  
  apt-get update -y
}

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found. Installing Docker CE..."
  rm -f /etc/apt/sources.list.d/docker.list
  fix_docker_gpg_key
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
else
  echo "Docker is already installed."
  
  # Always verify and fix GPG key if needed
  if apt-get update 2>&1 | grep -q "NO_PUBKEY\|not signed"; then
    echo "Docker repository has GPG issues. Fixing..."
    fix_docker_gpg_key
    echo "Docker GPG key fixed."
  else
    echo "Docker repository OK."
  fi
fi

echo "All required dependencies are installed and running."
