#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${YELLOW}${BOLD}Stopping Monitoring Stack and Undoing Configuration...${RESET}"
sleep 1

# STOP DOCKER CONTAINERS
echo -e "${YELLOW}${BOLD}[STOPPING NODE EXPORTER & CADVISOR]${RESET}"

if command -v docker &>/dev/null; then
    sudo docker stop $(sudo docker ps -q --filter "ancestor=quay.io/prometheus/node-exporter") 2>/dev/null || true
    sudo docker rm $(sudo docker ps -aq --filter "ancestor=quay.io/prometheus/node-exporter") 2>/dev/null || true

    sudo docker stop cadvisor 2>/dev/null || true
    sudo docker rm cadvisor 2>/dev/null || true

    echo -e "${GREEN}[DONE] Docker monitoring containers stopped${RESET}"
else
    echo -e "${BLUE}[SKIPPED] Docker not installed${RESET}"
fi


# REMOVE RSYSLOG REMOTE CONFIG
echo -e "${YELLOW}${BOLD}[REMOVING RSYSLOG REMOTE CONFIGURATION]${RESET}"

if [ -f /etc/rsyslog.d/50-remote.conf ]; then
    sudo rm /etc/rsyslog.d/50-remote.conf
    sudo systemctl restart rsyslog
    echo -e "${GREEN}[REMOVED] /etc/rsyslog.d/50-remote.conf${RESET}"
else
    echo -e "${BLUE}[SKIPPED] Remote rsyslog config not found${RESET}"
fi

echo -e "${YELLOW}${BOLD}[STOPPING SSH SERVICE]${RESET}"
sudo systemctl stop ssh 2>/dev/null || sudo systemctl stop sshd 2>/dev/null || true
echo -e "${GREEN}[SSH STOPPED]${RESET}"


# OPTIONAL: UNINSTALL DOCKER (comment out if not desired)
REMOVE_DOCKER=false   # set to true if you want docker removed

if [ "$REMOVE_DOCKER" = true ]; then
    echo -e "${YELLOW}${BOLD}[REMOVING DOCKER AND RELATED COMPONENTS]${RESET}"
    sudo apt remove docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo apt autoremove
    echo -e "${GREEN}[DOCKER REMOVED]${RESET}"
else
    echo -e "${BLUE}[SKIPPED] Docker uninstall disabled${RESET}"
fi


echo "=============================================================="
echo -e "${GREEN}${BOLD}MONITORING SHUTDOWN COMPLETE${RESET}"
echo "=============================================================="
echo -e "${BOLD}• Node Exporter — STOPPED & REMOVED"
echo -e "• cAdvisor — STOPPED & REMOVED"
echo -e "• Remote Rsyslog — CONFIG REMOVED"
echo -e "• SSH — STOPPED (can restart manually: sudo systemctl start ssh)"
echo "=============================================================="
