# this will start the node-exporter on your DEVICE along with sending the rsyslog to the rsyslog server

GREEN='\033[0;32m'
RESET='\033[0m'
BOLD='\033[1m'
YELLOW='\033[1;33m'

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
sudo systemctl status rsyslog --no-pager || true

# now, we wish to add the 50-remote.conf in /etc/rsyslog.d/
echo -e "${YELLOW}[ADDING REMOTE RSYSLOG CONFIGURATION]${RESET}"
sudo bash -c 'cat << EOF > /etc/rsyslog.d/50-remote.conf
*.* @@<RSYSLOG_SERVER_IP>:514    # Use @ for UDP
EOF'
# Replace <RSYSLOG_SERVER_IP> with the actual IP address of your rsyslog server
sudo systemctl restart rsyslog
echo -e "${GREEN}${BOLD}[RSYSLOG CONFIGURATION ADDED]${RESET



echo -e "${YELLOW}[CHECKING DOCKER INSTALLATION]${RESET}"

# Proceed only if Docker is not installed
if ! command -v docker &> /dev/null; then

    # Install Docker (official repo) and docker compose plugin
    echo -e "${YELLOW}[INSTALLING DOCKER]${r} - along with Docker Compose Plugin..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Add current user to docker group (non-blocking)
    if ! groups $USER | grep -q '\bdocker\b'; then
        echo "Adding $USER to docker group (you may need to re-login for group changes)..."
        sudo usermod -aG docker $USER || true
    fi

    echo -e "${GREEN}[SUCCESS] - Docker Installed${r}"

else
    echo -e "${BLUE}[SKIPPED] - Docker already installed on this system.${r}"
fi

echo -e "${BOLD}INITIATING DOWNLOAD FOR NODE-EXPORTER...${RESET}"
sudo docker run -d \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter:latest \
  --path.rootfs=/host

echo -e "${GREEN}${BOLD}[NODE-EXPORTER SETUP COMPLETE]${r}"