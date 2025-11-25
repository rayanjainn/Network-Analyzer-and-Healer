#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${YELLOW}${BOLD}Stopping Monitoring Stack and Undoing Configuration...${RESET}"
sleep 1

# ========================================================
# STOP & REMOVE MONITORING CONTAINERS
# ========================================================
echo -e "${YELLOW}${BOLD}[STOPPING NODE EXPORTER & CADVISOR]${RESET}"

if command -v docker &>/dev/null; then

    # Stop node-exporter
    if docker ps -a --format '{{.Names}}' | grep -q "^node-exporter$"; then
        sudo docker stop node-exporter 2>/dev/null || true
        sudo docker rm node-exporter 2>/dev/null || true
        echo -e "${GREEN}[node-exporter STOPPED & REMOVED]${RESET}"
    else
        echo -e "${BLUE}[node-exporter NOT FOUND]${RESET}"
    fi

    # Stop cadvisor
    if docker ps -a --format '{{.Names}}' | grep -q "^cadvisor$"; then
        sudo docker stop cadvisor 2>/dev/null || true
        sudo docker rm cadvisor 2>/dev/null || true
        echo -e "${GREEN}[cAdvisor STOPPED & REMOVED]${RESET}"
    else
        echo -e "${BLUE}[cAdvisor NOT FOUND]${RESET}"
    fi

else
    echo -e "${BLUE}[SKIPPED] Docker is not installed${RESET}"
fi

# ========================================================
# REMOVE RSYSLOG REMOTE CONFIG
# ========================================================
echo -e "${YELLOW}${BOLD}[REMOVING RSYSLOG REMOTE CONFIGURATION]${RESET}"

if [ -f /etc/rsyslog.d/50-remote.conf ]; then
    sudo rm /etc/rsyslog.d/50-remote.conf
    sudo systemctl restart rsyslog
    echo -e "${GREEN}[REMOVED] /etc/rsyslog.d/50-remote.conf${RESET}"
else
    echo -e "${BLUE}[SKIPPED] Remote rsyslog config not found${RESET}"
fi

# ========================================================
# STOP SSH
# ========================================================
echo -e "${YELLOW}${BOLD}[STOPPING SSH SERVICE]${RESET}"
sudo systemctl stop ssh 2>/dev/null || sudo systemctl stop sshd 2>/dev/null || true
echo -e "${GREEN}[SSH STOPPED]${RESET}"

# ========================================================
# OPTIONAL: REMOVE DOCKER COMPLETELY
# ========================================================
REMOVE_DOCKER=false   # Change to true to uninstall Docker

if [ "$REMOVE_DOCKER" = true ]; then
    echo -e "${YELLOW}${BOLD}[REMOVING DOCKER & COMPONENTS]${RESET}"
    sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo apt autoremove -y
    sudo rm -rf /var/lib/docker /var/lib/containerd
    echo -e "${GREEN}[DOCKER COMPLETELY REMOVED]${RESET}"
else
    echo -e "${BLUE}[SKIPPED] Docker uninstall disabled${RESET}"
fi

echo "=============================================================="
echo -e "${GREEN}${BOLD}MONITORING SHUTDOWN COMPLETE${RESET}"
echo "=============================================================="
echo -e "${BOLD}• Node Exporter — STOPPED & REMOVED"
echo -e "• cAdvisor — STOPPED & REMOVED"
echo -e "• Remote Rsyslog — CONFIG REMOVED"
echo -e "• SSH — STOPPED (restart with: sudo systemctl start ssh)"
echo "=============================================================="
