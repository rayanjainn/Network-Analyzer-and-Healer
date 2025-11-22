#!/bin/bash

if [ -z "$1" ];then
    echo "Usage: $0 --<RSYSLOG_SERVER_IP>"
    exit 1
fi

RSYSLOG_IP="${1#--}"

# this will start the node-exporter on your DEVICE along with sending the rsyslog to the rsyslog server

GREEN='\033[0;32m'
RESET='\033[0m'
BOLD='\033[1m'
YELLOW='\033[1;33m'
BLUE="\033[0;34m"

echo -e "${YELLOW}${BOLD}[UPDATING APT REPOSITORIES]${RESET}"
sudo apt update -y

# setup rsyslog download first
echo -e "${YELLOW}[SETTING UP RSYSLOG FOR REMOTE LOGGING]${RESET}"
sudo apt install -y rsyslog

# Enable and start rsyslog
echo -e "${BOLD}Enabling and restarting rsyslog...${RESET}"
sudo systemctl enable rsyslog
sudo systemctl restart rsyslog
sleep 2
sudo systemctl status rsyslog --no-pager||true

# now, we wish to add the 50-remote.conf in /etc/rsyslog.d/
echo -e "${YELLOW}[ADDING REMOTE RSYSLOG CONFIGURATION]${RESET}"

# ===== MODIFIED: Insert actual IP instead of placeholder =====
sudo bash -c "cat << EOF > /etc/rsyslog.d/50-remote.conf
*.* @@${RSYSLOG_IP}
EOF"

sudo systemctl restart rsyslog
echo -e "${GREEN}${BOLD}[RSYSLOG CONFIGURATION ADDED]${RESET}"

echo -e "${YELLOW}[CHECKING DOCKER INSTALLATION]${RESET}"

# Proceed only if Docker is not installed
if ! command -v docker&>/dev/null;then

    # Install Docker (official repo) and docker compose plugin
    echo -e "${YELLOW}[INSTALLING DOCKER]${RESET} - along with Docker Compose Plugin..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg|sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"|sudo tee /etc/apt/sources.list.d/docker.list>/dev/null
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Add current user to docker group (non-blocking)
    if ! groups $USER|grep -q '\bdocker\b';then
        echo "Adding $USER to docker group (you may need to re-login for group changes)..."
        sudo usermod -aG docker $USER||true
    fi

    echo -e "${GREEN}[SUCCESS] - Docker Installed${RESET}"

else
    echo -e "${BLUE}${BOLD}[SKIPPED] - Docker already installed on this system.${RESET}"
fi

echo -e "${BOLD}INITIATING DOWNLOAD FOR NODE-EXPORTER...${RESET}"
sudo docker run -d \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter:latest \
  --path.rootfs=/host

echo -e "${GREEN}${BOLD}[NODE-EXPORTER SETUP COMPLETE]${RESET}"

# NOW, WE DOWNLOAD FOR cAdvisor (in case there are containers running on the Device)
echo -e "${BOLD}INITIATING DOWNLOAD FOR CADVISOR...${RESET}"

# Pull and run cAdvisor container
sudo docker run -d \
  --name=cadvisor \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --publish=8080:8080 \
  --detach=true \
  --restart=always \
  google/cadvisor:latest

echo -e "${GREEN}${BOLD}[CADVISOR SETUP COMPLETE]${RESET}"


echo -e "${BOLD}SETTING UP SSH FOR REMOTE ACCESS...${RESET}"

sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl restart ssh
sudo systemctl status ssh --no-pager || true

PC_NAME=$(hostname)
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "======================================================================"
echo -e "${BOLD}ADD THE FOLLOWING TO THE TOML FILE WHICH WILL THEN BE USED TO CONFIGURE PROMETHEUS:${RESET}\n"
echo -e "\n${PC_NAME}_cAdvisor =====> ${IP_ADDR}:8080"
echo -e "${PC_NAME}_NodeExport ===> ${IP_ADDR}:9100"
echo "======================================================================"
echo -e "${BLUE}Update this @ "container-monitoring/deviceDetails.toml"${RESET}"
echo -e "${BOLD}JUST MAKE NOTE OF THE IP in a Book for now, and later, manually, add to the Device Details${r}"
echo "======================================================================="
echo -e "${BOLD}[MAKE NOTE OF:- DEVICE NAME, IP, PASS]${RESET}"
echo -e "${GREEN}${BOLD}[REMOTE CONFIGURATION COMPLETE]${RESET}"