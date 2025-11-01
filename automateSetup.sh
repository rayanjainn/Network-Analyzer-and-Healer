# AUTOMATED LOG STACK SETUP
# (Rsyslog + Loki + Promtail + Grafana)
# File: automateSetup.sh
# Make executable: chmod +x automateSetup.sh

echo "[Checking OS]"
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        echo "NOT UBUNTU FILE STRUCTURE - NICE TRY D..."
        exit 1
    fi
else
    echo "NOT UBUNTU FILE STRUCTURE - NICE TRY D..."
    exit 1
fi

echo "[SUCCESSFUL] - UBUNTU DETECTED"

set -euo pipefail

# Update system & install rsyslog + prerequisites
echo "Updating apt and installing packages..."
sudo apt update -y
sudo apt install -y rsyslog curl apt-transport-https ca-certificates gnupg lsb-release software-properties-common

# this was some optional shi-if this makes it work, then it is DEFINITELY NOT OPTINAL!
sudo chmod o+r /var/log/syslog
sudo chmod o+r /var/log/auth.log
# THIS FCKIN SHI WAS THE MAIN THING!


# Enable and start rsyslog
echo "Enabling and restarting rsyslog..."

sudo systemctl enable rsyslog
sudo systemctl restart rsyslog
sleep 2
sudo systemctl status rsyslog --no-pager || true

# Setup remote log directory
echo "[SETTING UP REMOTE LOG DIRECTORY] - Creating /var/log/remote and setting permissions..."
sudo mkdir -p /var/log/remote
sudo chown -R root:root /var/log/remote
sudo chmod -R 777 /var/log/remote

# Update /etc/rsyslog.conf to enable UDP/TCP reception (uncomment matching lines if present)
echo "[EDITING THE syslog.conf FILE] - @ /etc/rsyslog.conf"
sudo cp /etc/rsyslog.conf /etc/rsyslog.conf.bak || true
sudo sed -i 's/^#\s*module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf || true
sudo sed -i 's/^#\s*input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf || true
sudo sed -i 's/^#\s*module(load="imtcp")/module(load="imtcp")/' /etc/rsyslog.conf || true
sudo sed -i 's/^#\s*input(type="imtcp" port="514")/input(type="imtcp" port="514")/' /etc/rsyslog.conf || true

# Create forwarding rule for remote logs
echo "[WRITING FORWARDING SCRIPT] - Writing to /etc/rsyslog.d/remote.conf"
sudo bash -c 'cat > /etc/rsyslog.d/remote.conf <<EOF
template(name="RemoteLogsByHost" type="string" string="/var/log/remote/%HOSTNAME%.log")

if \$fromhost-ip != "127.0.0.1" then {
    action(type="omfile" dynaFile="RemoteLogsByHost")
    stop
}
EOF'

# Ensure rsyslog dir perms and restart
sudo mkdir -p /var/log/remote
sudo chown syslog:adm /var/log/remote
sudo chmod 775 /var/log/remote
sudo systemctl restart rsyslog
echo "[RSYSLOG SETUP COMPLETE]"

# Install Docker (official repo) and docker compose plugin
echo "[INSTALLING DOCKER] - along with Docker Compose Plugin..."
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

echo "[SUCCESS] - Docker Installed"

# Create stack directories
echo "[CREATING STACK DIRECTORIES] - under ~/log-stack..."
mkdir -p ~/log-stack/grafana-data ~/log-stack/loki-data && sudo chown -R root:root ~/log-stack && sudo chmod -R 777 ~/log-stack
sudo mkdir -p /etc/promtail

# some more changes-HOPEFULLY THEY WORK
mkdir -p ~/log-stack/grafana-data ~/log-stack/loki-data
# Set Loki directory permissions to allow UID 10001 to write (Loki's default user)
sudo chown -R 10001:10001 ~/log-stack/loki-data
sudo chmod -R 775 ~/log-stack/loki-data
# Keep Grafana writable as root
sudo chown -R root:root ~/log-stack/grafana-data
sudo chmod -R 777 ~/log-stack/grafana-data

# Create config files (from your markdown)
echo "[CREATING LOKI & PROMTAIL] - config files"
cat > ~/log-stack/loki-config.yaml <<'LOKI_CFG'
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
  chunk_idle_period: 5m
  max_chunk_age: 1h
  chunk_target_size: 1048576

schema_config:
  configs:
    - from: 2020-10-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h

storage_config:
  boltdb:
    directory: /loki/index
  filesystem:
    directory: /loki/chunks

limits_config:
  enforce_metric_name: false
LOKI_CFG

sudo tee /etc/promtail/promtail.yaml > /dev/null <<'PROMTAIL_CFG'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: remote-logs
    static_configs:
      - targets: [localhost]
        labels:
          job: varlogs
          host: ${HOSTNAME}
          __path__: /var/log/remote/*.log
PROMTAIL_CFG
sudo chmod 644 /etc/promtail/promtail.yaml

# Pull necessary Docker images
echo "[PULLING DOCKER IMAGES] - of loki, grafana and promtail"
sudo systemctl restart docker
sudo docker pull grafana/loki:2.9.0
sudo docker pull grafana/grafana:10.0.0
sudo docker pull grafana/promtail:2.9.0

# Create docker network if not exists
NET_NAME="log-network"
if ! sudo docker network ls --format '{{.Name}}' | grep -q "^${NET_NAME}$"; then
  echo "Creating docker network ${NET_NAME}..."
  sudo docker network create ${NET_NAME}
else
  echo "[ALREADY EXISTS] - Docker network ${NET_NAME} already exists."
fi

# Run Loki container
echo "[STATUS] - Running Loki container..."

# checks for Loki ownership and perms stuff
# Ensure Loki data directory exists and is accessible to UID 10001
sudo mkdir -p ~/log-stack/loki-data
sudo chown -R 10001:10001 ~/log-stack/loki-data
sudo chmod -R 775 ~/log-stack/loki-data

sudo docker rm -f loki 2>/dev/null || true

# newly ADDED to remove existing loki container if any
sudo docker rm -f loki


# adding the WAL directory thing
# Create Loki data directories
mkdir -p ~/loki-data/chunks ~/loki-data/index ~/loki-data/wal

# Set proper permissions
sudo chown -R 10001:10001 ~/loki-data
sudo chmod -R 777 ~/loki-data

# making a small change in running loki container
# sudo docker run -d --name loki \
#   --network ${NET_NAME} \
#   -v ~/log-stack/loki-data:/loki \
#   -v ~/log-stack/loki-config.yaml:/etc/loki/local-config.yaml:ro \
#   grafana/loki:2.9.0 \
#   -config.file=/etc/loki/local-config.yaml

# added the below three things- chunks, index and the wal. If pipeline breaks, remove the last three -v and well, redo the things
# sudo docker run -d --name loki \
#   --network ${NET_NAME} \
#   -u 10001 \
#   -v ~/log-stack/loki-data:/loki \
#   -v ~/log-stack/loki-config.yaml:/etc/loki/local-config.yaml:ro \
#   -v ~/loki-data/chunks:/loki/chunks \
#   -v ~/loki-data/index:/loki/index \
#   -v ~/loki-data/wal:/wal \
#   grafana/loki:2.9.0 \
#   -config.file=/etc/loki/local-config.yaml

sudo docker run -d \
  --name loki \
  --network log-network \
  -u 10001 \
  -p 3100:3100 \
  -v ~/loki-data/chunks:/loki/chunks \
  -v ~/loki-data/index:/loki/index \
  -v ~/loki-data/wal:/wal \
  -v ~/log-stack/loki-config.yaml:/etc/loki/local-config.yaml:ro \
  grafana/loki:2.9.0 \
  -config.file=/etc/loki/local-config.yaml


# Run Grafana container
echo "[STATUS] - Running Grafana container..."
sudo docker rm -f grafana 2>/dev/null || true
sudo docker run -d --name grafana \
  --network ${NET_NAME} \
  -p 3000:3000 \
  -v ~/log-stack/grafana-data:/var/lib/grafana \
  grafana/grafana:10.0.0

# Run Promtail container
echo "[STATUS] - Running Promtail container..."
sudo docker rm -f promtail 2>/dev/null || true
sudo docker run -d --name promtail \
  --network ${NET_NAME} \
  -v /etc/promtail/promtail.yaml:/etc/promtail/promtail.yaml:ro \
  -v /var/log/remote:/var/log/remote:ro \
  grafana/promtail:2.9.0 \
  -config.file=/etc/promtail/promtail.yaml \
  -config.expand-env=true

echo "All containers are up and running!"
echo "-----------------------------------------"
echo "Access Grafana at: http://localhost:3000"
echo "Default Login -> admin / admin"
echo "Add Loki datasource -> URL: http://loki:3100"
echo "-----------------------------------------"
echo "To check live logs: sudo tail -f /var/log/remote/*.log"
echo "\nAlso, check whether or no that all the data you get can be sent to Loki"
echo "For the same, run:- curl http://localhost:3100/ready"
echo "If you get a response 'ready', you're good to go!"
echo "[SETUP COMPLETE] - Les Go!"

# End