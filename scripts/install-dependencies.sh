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
# optional interactive config, safe to skip in automation

echo "[5/5] Checking Docker installation..."
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found. Installing Docker CE..."

  mkdir -p /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg \
      -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  . /etc/os-release
  DOCKER_CODENAME="${VERSION_CODENAME:-bookworm}"

  echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
${DOCKER_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl enable --now docker
else
  echo "Docker is already installed."
fi

echo "All required dependencies are installed and running."
