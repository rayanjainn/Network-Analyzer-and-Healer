#!/bin/bash

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
BOLD="\033[1m"
r="\033[0m"

DEVICE_LIST="./deviceDetails.toml"
PROMETHEUS_TEMPLATE="./prometheus_template.yml"
TARGET_FILE="./prometheus.yml"

echo -e "${BOLD}${YELLOW}[SETTING UP PROMETHEUS CONFIGURATION]${r}: Result will be @ ${TARGET_FILE}"

# Start fresh from template
cp "$PROMETHEUS_TEMPLATE" "$TARGET_FILE"

echo "" >> "$TARGET_FILE"
echo "# --- Auto-generated scrape configs below ---" >> "$TARGET_FILE"

current_name=""
current_ip=""

while IFS= read -r line; do
    line="$(echo "$line" | xargs)"

    if [[ "$line" == name* ]]; then
        current_name=$(echo "$line" | cut -d'=' -f2 | tr -d '" ')
    fi

    if [[ "$line" == ip* ]]; then
        current_ip=$(echo "$line" | cut -d'=' -f2 | tr -d '" ')
    fi

    if [[ -n "$current_name" && -n "$current_ip" ]]; then

        cat <<EOF >> "$TARGET_FILE"

  - job_name: ${current_name}_NodeExport
    static_configs:
      - targets: ["${current_ip}:9100"]

EOF

        cat <<EOF >> "$TARGET_FILE"

  - job_name: ${current_name}_cAdvisor
    static_configs:
      - targets: ["${current_ip}:8080"]

EOF

        current_name=""
        current_ip=""
    fi

done < "$DEVICE_LIST"

echo -e "${GREEN}[SUCCESSFULLY GENERATED THE prometheus.yml] => ${TARGET_FILE}${r}"
echo -e "${BLUE}You can now use this file in your Prometheus setup to monitor the listed devices.${r}"
echo -e "${BLUE}Remember to restart Prometheus after updating the configuration.${r}"
echo -e "${BOLD}${GREEN}[SETUP COMPLETE]${r}"
