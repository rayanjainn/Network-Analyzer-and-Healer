![Script Test](https://img.shields.io/github/actions/workflow/status/Th3C0d3Mast3r/Network-Analyzer-and-Healer/server_setup_test.yaml?branch=main&label=SCRIPT%20STATUS&logo=github)
![License](https://img.shields.io/github/license/Th3C0d3Mast3r/Network-Analyzer-and-Healer)
![Last Commit](https://img.shields.io/github/last-commit/Th3C0d3Mast3r/Network-Analyzer-and-Healer)
![Version](https://img.shields.io/github/v/tag/Th3C0d3Mast3r/Network-Analyzer-and-Healer?label=VERSION&color=brightgreen&logo=git)

# Network Analyzer & Healer  
- **Centralized log aggregation** :- Rsyslog → Promtail → Loki
    
- **Host and container metrics** :- Node Exporter & cAdvisor → Prometheus

- **Unified dashboards** :- Grafana for visualizing logs and metrics together

- **Automated healing**
  - Shell scripts triggered based on alert conditions
  - Execution over SSH to remote systems
  - Helps auto-correct failures such as high CPU usage, service crashes, insufficient memory, and more

---

## Architecture Overview
![base flow diagram](./images/image.png)

## Remote Device
- Backed by rsyslog, node-exporter, and cAdvisor
- Collects system logs and performance data
- Sends everything to the monitoring server

## Central Monitoring Server
- Promtail receives logs and writes them to Loki
- Prometheus scrapes performance and container metrics
- Grafana visualizes all collected data
- Alert triggers can remotely execute healing scripts to fix system issues on the remote machines

This forms a complete end-to-end automated loop:

1. **Monitor**
2. **Detect**
3. **Alert**
4. **Auto-Heal**

All executed entirely on-premise, without internet or cloud services.

---

## Repository Structure
<!--REPO_TREE_START-->
```
.
├── LICENSE
├── README.md
├── automateSetup.sh
├── config
│   ├── loki-config.yaml
│   ├── promtail-config.yaml
│   └── rsyslog.conf
├── container-monitoring
│   ├── README.md
│   ├── deviceDetails.toml
│   ├── docker-compose.yml
│   ├── makePrometheus.sh
│   ├── prometheus.yml
│   ├── prometheus_template.yml
│   └── queries.promql
├── dashboard.json
├── docker
│   └── docker-compose.yml
├── images
│   └── image.png
├── remote_container_setup
│   ├── README.md
│   ├── remoteConfig.sh
│   └── remoteShutdown.sh
├── restart.sh
└── scripts
    ├── ubuntu-rsyslog-setup.sh
    └── validate-install.sh
```
<!--REPO_TREE_END-->

## Setup Instructions
> image goes here
Run the following commands on **Ubuntu**:

```bash
# Clone the repository
git clone <repo-url>
cd Network-Analyzer-and-Healer

# FOR CLIENT SIDE (REMOTE DEVICES)
./remoteConfig.sh

# FOR SERVER SIDE (CENTRAL MONITORING SYSTEM)
./automateSetup.sh

# in case some problem happens, and exits without proper setup, run this, and then resolve
./restart.sh

cd container-monitoring

# Update your monitoring list:
# Edit deviceDetails.toml and add:
# IP = ""
# NAME = ""
# PASS = ""
./makePrometheus.sh

# Start monitoring stack
sudo docker compose up -d

# Validate Prometheus scraping targets
# Navigate to http://prometheus:9090 and check under "Targets"
# Remote systems should be visible as healthy

# Then open Grafana (http://localhost:3000)
# and add data sources for both Loki and Prometheus
```

The script will:
- Install Docker & Docker Compose (if missing)
- Configure Rsyslog to forward logs
- Start Promtail, Loki, and Grafana containers
- Verify setup via `validate-install.sh`

---

## Validation

After installation:

```bash
./scripts/validate-install.sh
```

## Expected Result
- Rsyslog service active and forwarding logs
- Promtail and Loki running (docker ps)
- Prometheus scraping remote node-exporter and cAdvisor targets
- Grafana accessible at: `http://localhost:3000`

## Default Grafana credentials
- `Username`: admin
- `Password`: admin

## Viewing Logs
- Open Grafana: `http://localhost:3000`
- Add Loki as a Data Source:
    - URL: `http://loki:3100`
- Add Prometheus as a Data Source:
    - URL: `http://prometheus:9090`

> Once done, then import the pre-made dashboard template that you can find in the repository, that is, under the name of `dashboard.json`. Import that, and you will be mostly good to go.

---

## Version History
| Version | Date | Description | Status |
|---------|------|-------------|--------|
| v1.0.0  | 1st November, 2025  | Automated Setup of the whole Project, with Log aggregation | `COMPLETED` |
| v1.0.1  | TBA  | Adding Basic Log interpretation, and base recovery queries | `IN-PROGRESS` |
| v2.0.0  | TBA  | Fulling running Repository | `TO-DO` |

---

## Troubleshooting
> will be added here soon
---

## License

Licensed under the MIT License — feel free to modify and extend.

---

> *Part of the “Network Healer” suite — building self-healing, intelligent monitoring systems.*
