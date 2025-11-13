#!/bin/bash
# Helper: configure rsyslog on Ubuntu (idempotent helper)
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
  echo "Run this script as root or with sudo"
  exit 2
fi

apt update -y
apt install -y rsyslog

mkdir -p /var/log/remote
chown syslog:syslog /var/log/remote || true
chmod 755 /var/log/remote

# Ensure imudp/imtcp enabled
sed -i 's/^#\s*module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf || true
sed -i 's/^#\s*input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf || true
sed -i 's/^#\s*module(load="imtcp")/module(load="imtcp")/' /etc/rsyslog.conf || true
sed -i 's/^#\s*input(type="imtcp" port="514")/input(type="imtcp" port="514")/' /etc/rsyslog.conf || true

cat > /etc/rsyslog.d/50-remote.conf <<'EOF'
template(name="RemoteLogsByHost" type="string" string="/var/log/remote/%HOSTNAME%.log")

if $fromhost-ip != '127.0.0.1' then {
    action(type="omfile" dynaFile="RemoteLogsByHost")
    stop
}
EOF

systemctl restart rsyslog
ufw allow 514/tcp
ufw allow 514/udp

echo "rsyslog configured. Remote logs will land in /var/log/remote/"
