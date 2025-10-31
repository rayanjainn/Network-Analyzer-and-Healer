#!/bin/bash
# CLEANUP SCRIPT for Network Analyzer Stack
# Use when automateSetup.sh fails midway or you want a full reset

echo "-----------------------------------------"
echo "[RESTARTING THE SYSTEM] - NETWORK ANALYZER CLEANUP"
echo "-----------------------------------------"

set -e

# Stop and remove containers
echo "[DOCKER] - Removing running containers..."
sudo docker rm -f loki grafana promtail 2>/dev/null || true

# Remove docker network
NET_NAME="log-network"
if sudo docker network ls --format '{{.Name}}' | grep -q "^${NET_NAME}$"; then
  echo "[DOCKER] - Removing network ${NET_NAME}..."
  sudo docker network rm ${NET_NAME}
fi

# Remove configuration and log directories
echo "[FILESYSTEM] - Removing log-stack and Promtail directories..."
sudo rm -rf ~/log-stack
sudo rm -rf /etc/promtail
sudo rm -rf /var/log/remote

# Restore rsyslog backup if exists
if [ -f /etc/rsyslog.conf.bak ]; then
  echo "[RSYSLOG] - Restoring backup config..."
  sudo mv /etc/rsyslog.conf.bak /etc/rsyslog.conf
fi

# Restart rsyslog service
echo "[RSYSLOG] - Restarting service..."
sudo systemctl restart rsyslog || true

echo "-----------------------------------------"
echo "[SUCCESS] - Cleanup completed! System reset to initial state."
echo "-----------------------------------------"
