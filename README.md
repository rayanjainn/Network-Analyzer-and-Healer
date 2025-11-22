![Script Test](https://img.shields.io/github/actions/workflow/status/Th3C0d3Mast3r/Network-Analyzer-and-Healer/server_setup_test.yaml?branch=main&label=SCRIPT%20STATUS&logo=github)
![License](https://img.shields.io/github/license/Th3C0d3Mast3r/Network-Analyzer-and-Healer)
![Last Commit](https://img.shields.io/github/last-commit/Th3C0d3Mast3r/Network-Analyzer-and-Healer)
![Version](https://img.shields.io/github/v/tag/Th3C0d3Mast3r/Network-Analyzer-and-Healer?label=VERSION&color=brightgreen&logo=git)

# Network Analyzer & Healer  
### Rsyslog → Promtail → Loki → Grafana Stack

This repository automates an **on-premise observability and log aggregation pipeline** using:

- **Rsyslog** — system log collector (host)
- **Promtail** — log shipper that reads logs from files and forwards to Loki
- **Loki** — log aggregation backend
- **Grafana** — visualization and analysis dashboard

> The above is the analyzer part-healer stack will be added soon

---

## Architecture Overview

```
+-------------------+       +-------------------+       +------------------+       +-----------------+
|  System Logs      |       |   Promtail Agent  |       |      Loki        |       |    Grafana      |
|  (via Rsyslog)    +------>+   (Dockerized)    +------>+  (Dockerized)    +------>+  (Dockerized)   |
+-------------------+       +-------------------+       +------------------+       +-----------------+
        |                           |                         |                         |
        |------ Ubuntu Host --------|-------------------------|-------------------------|
```

The pipeline flow is:
**System Logs → Rsyslog → Promtail → Loki → Grafana**

---

## Repository Structure
<!--REPO_TREE_START-->
<!--REPO_TREE_END-->

## Setup Instructions

Run the following commands on **Ubuntu**:

```bash
# Clone the repository
git clone <repo-url>
cd Network-Analyzer-and-Healer

# Make automation scripts executable
chmod +x scripts/*.sh
chmod +x ./automateSetup.sh
chmod +x ./restart.sh

# Run the automated setup
./automateSetup.sh

# In case there is some problem in the intermediate steps, then, run the following command
./restart.sh
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

Expected:
- Rsyslog service active  
- Loki and Promtail running (`docker ps`)  
- Grafana accessible at: **http://localhost:3000**

Default Grafana credentials:
- **Username:** admin  
- **Password:** admin

---

## Viewing Logs

1. Open **Grafana** at `http://localhost:3000`
2. Add **Loki** as a data source:
   - URL: `http://loki:3100`
3. Explore logs via:
   - *Explore → Log labels → host, process, severity*

---

## Troubleshooting

| Issue | Possible Cause | Fix |
|-------|----------------|-----|
| Grafana not loading | Container not up | `docker-compose up -d` |
| Logs missing | Promtail config path issue | Check `/var/log/syslog` and `promtail-config.yaml` |
| Rsyslog not sending | UDP/TCP port blocked | `sudo ufw allow 514/tcp` |

---

## Version History
| Version | Date | Description | Status |
|---------|------|-------------|--------|
| v1.0.0  | 1st November, 2025  | Automated Setup of the whole Project, with Log aggregation | `COMPLETED` |
| v1.0.1  | TBA  | Adding Basic Log interpretation, and base recovery queries | `IN-PROGRESS` |
| v2.0.0  | TBA  | Fulling running Repository | `TO-DO` |

## License

Licensed under the MIT License — feel free to modify and extend.

---

> *Part of the “Network Healer” suite — building self-healing, intelligent monitoring systems.*