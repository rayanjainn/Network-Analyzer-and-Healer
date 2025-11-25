#!/bin/bash

# ==========================================================
#  FINAL DEVICE MONITORING SETUP SCRIPT
#  - Removes snap docker (incompatible with monitoring)
#  - Installs real Docker CE
#  - Installs rsyslog remote logging
#  - Starts node-exporter + cAdvisor correctly
# ==========================================================

if [ -z "$1" ]; then
    echo "Usage: $0 --<RSYSLOG_SERVER_IP>"
    exit 1
fi

RSYSLOG_IP="${1#--}"

# Colors
GREEN='\033[0;32m'
RESET='\033[0m'
BOLD='\033[1m'
YELLOW='\033[1;33m'
BLUE="\033[0;34m"

echo -e "${YELLOW}${BOLD}[UPDATING APT]${RESET}"
sudo apt update -y

# ==========================================================
#  REMOVE SNAP DOCKER (MOST IMPORTANT FIX)
# ==========================================================
echo -e "${YELLOW}${BOLD}[CHECKING FOR SNAP DOCKER]${RESET}"

if snap list | grep -q docker; then
    echo -e "${BLUE}Snap Docker detected → removing (this fixes mount errors)...${RESET}"
    sudo snap remove docker
fi

if dpkg -l | grep -q docker.io; then
    echo -e "${BLUE}Removing conflicting docker.io package...${RESET}"
    sudo apt purge -y docker.io docker-doc docker-compose docker-compose-v2 containerd runc || true
fi

sudo rm -rf /var/snap/docker || true

# ==========================================================
#  INSTALL REAL DOCKER CE
# ==========================================================
echo -e "${YELLOW}${BOLD}[INSTALLING REAL DOCKER CE]${RESET}"

if ! command -v docker &>/dev/null; then
    sudo apt update -y
    sudo apt install -y ca-certificates curl gnupg lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    sudo systemctl enable docker
    sudo systemctl start docker

    echo -e "${GREEN}${BOLD}[Docker CE Installed Successfully]${RESET}"

else
    echo -e "${BLUE}${BOLD}[Docker Already Installed]${RESET}"
fi

# ==========================================================
#  SETUP RSYSLOG
# ==========================================================
echo -e "${YELLOW}${BOLD}[SETTING UP RSYSLOG]${RESET}"

sudo apt install -y rsyslog

sudo bash -c "cat << EOF > /etc/rsyslog.d/50-remote.conf
*.* @@${RSYSLOG_IP}
EOF"

sudo systemctl enable rsyslog
sudo systemctl restart rsyslog

echo -e "${GREEN}${BOLD}[RSYSLOG CONFIGURED]${RESET}"

# ==========================================================
#  REMOVE OLD CONTAINERS IF THEY EXIST
# ==========================================================
docker rm -f node-exporter &>/dev/null || true
docker rm -f cadvisor &>/dev/null || true

# ==========================================================
#  START NODE EXPORTER (CORRECT HOST MOUNTS)
# ==========================================================
echo -e "${YELLOW}${BOLD}[STARTING NODE EXPORTER]${RESET}"

docker run -d \
  --name=node-exporter \
  --net=host \
  --pid=host \
  -v "/proc:/host/proc:ro" \
  -v "/sys:/host/sys:ro" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter:latest \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys \
  --path.rootfs=/host

echo -e "${GREEN}${BOLD}[NODE EXPORTER RUNNING]${RESET}"

# ==========================================================
#  START CADVISOR (REAL WORKING VERSION)
# ==========================================================
echo -e "${YELLOW}${BOLD}[STARTING CADVISOR]${RESET}"

docker run -d \
  --name=cadvisor \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --restart=always \
  gcr.io/cadvisor/cadvisor:v0.49.1 \
  --disable_metrics=accelerator

echo -e "${GREEN}${BOLD}[CADVISOR RUNNING]${RESET}"

# ==========================================================
#  SSH ENABLE
# ==========================================================
echo -e "${YELLOW}${BOLD}[INSTALLING SSH SERVER]${RESET}"

sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl restart ssh

# ==========================================================
#  OUTPUT
# ==========================================================
PC_NAME=$(hostname)
IP_ADDR=$(hostname -I | awk '{print $1}')

echo "======================================================================"
echo -e "${BOLD}ADD TO PROMETHEUS CONFIG:${RESET}\n"
echo -e "${PC_NAME}_NodeExporter ==> ${IP_ADDR}:9100"
echo -e "${PC_NAME}_cAdvisor     ==> ${IP_ADDR}:8080"
echo "======================================================================"
echo -e "${GREEN}${BOLD}[SETUP COMPLETE – Monitoring Containers Running]${RESET}"
