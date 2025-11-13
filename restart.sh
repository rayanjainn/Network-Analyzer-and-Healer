#!/bin/bash
# CLEANUP SCRIPT for Network Analyzer Stack
# Use when automateSetup.sh fails midway or you want a full reset

# ====== COLORS ======
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
BOLD="\033[1m"
r="\033[0m"


echo "-----------------------------------------"
echo -e "${BOLD}[RESTARTING THE SYSTEM] - NETWORK ANALYZER CLEANUP${r}"
echo "-----------------------------------------"

set -e

# Stop and remove containers
echo -e "${RED}[DOCKER] - Removing running containers...${e}"
sudo docker rm -f loki grafana promtail 2>/dev/null || true

# Remove docker network
NET_NAME="log-network"
if sudo docker network ls --format '{{.Name}}' | grep -q "^${NET_NAME}$"; then
  echo "[DOCKER] - Removing network ${NET_NAME}..."
  sudo docker network rm ${NET_NAME}
fi

# Remove configuration and log directories
echo -e "${RED}[FILESYSTEM] - Removing log-stack and Promtail directories...${r}"
sudo rm -rf ~/log-stack
sudo rm -rf /etc/promtail
sudo rm -rf /var/log/remote

# Restore rsyslog backup if exists
if [ -f /etc/rsyslog.conf.bak ]; then
  echo -e "${RED}[RSYSLOG] - Restoring backup config...${r}"
  sudo mv /etc/rsyslog.conf.bak /etc/rsyslog.conf
fi

# Restart rsyslog service
echo -e "${YELLOW}${BOLD}[RSYSLOG] - Restarting service...${r}${r}"
sudo systemctl restart rsyslog || true

echo "-----------------------------------------"
echo -e "${GREEN}[${BOLD}SUCCESS] - Cleanup completed! System reset to initial state.${r}"
echo "-----------------------------------------"
