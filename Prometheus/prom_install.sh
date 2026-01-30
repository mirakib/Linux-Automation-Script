#!/bin/bash

set -e

INSTALL_BIN="/usr/local/bin"
CONFIG_DIR="/etc/prometheus"
DATA_DIR="/var/lib/prometheus"
TMP_DIR="/tmp/prom_stack"
USER="prometheus"
ARCH="linux-amd64"

declare -A URLS
declare -A SHA
declare -A VERSIONS
declare -A SIZES
declare -A DATES

URLS[prometheus]="https://github.com/prometheus/prometheus/releases/download/v3.9.1/prometheus-3.9.1.${ARCH}.tar.gz"
SHA[prometheus]="86a6999dd6aacbd994acde93c77cfa314d4be1c8e7b7c58f444355c77b32c584"
VERSIONS[prometheus]="3.9.1"
SIZES[prometheus]="125.84 MiB"
DATES[prometheus]="2026-01-07"

URLS[alertmanager]="https://github.com/prometheus/alertmanager/releases/download/v0.30.1/alertmanager-0.30.1.${ARCH}.tar.gz"
SHA[alertmanager]="79bc54258ba9b039e2c3a23b3bc3d74b699f29070f5d67c41d68d5323e309a26"
VERSIONS[alertmanager]="0.30.1"
SIZES[alertmanager]="35.47 MiB"
DATES[alertmanager]="2026-01-12"

URLS[nodeexporter]="https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.${ARCH}.tar.gz"
SHA[nodeexporter]="c46e5b6f53948477ff3a19d97c58307394a29fe64a01905646f026ddc32cb65b"
VERSIONS[nodeexporter]="1.10.2"
SIZES[nodeexporter]="11.15 MiB"
DATES[nodeexporter]="2025-10-25"

URLS[blackbox_exporter]="https://github.com/prometheus/blackbox_exporter/releases/download/v0.28.0/blackbox_exporter-0.28.0.${ARCH}.tar.gz"
SHA[blackbox_exporter]="caf5d242fb1cf6d5cb678f3f799f22703d4fafea26b03dcbbd7e1f1825e06329"
VERSIONS[blackbox_exporter]="0.28.0"
SIZES[blackbox_exporter]="15.40 MiB"
DATES[blackbox_exporter]="2025-12-04"

about() {
    printf "%-20s %-10s %-12s %-12s\n" "Binary" "Version" "Size" "ReleaseDate"
    for key in "${!URLS[@]}"; do
        printf "%-20s %-10s %-12s %-12s\n" "$key" "${VERSIONS[$key]}" "${SIZES[$key]}" "${DATES[$key]}"
    done | sort
}

help_menu() {
    echo "./script.sh                 -> Install Prometheus only"
    echo "./script.sh nodeexporter    -> Install Prometheus + Node Exporter"
    echo "./script.sh help            -> Show help"
    echo "./script.sh about           -> Show binaries"
    echo "./script.sh check           -> Check installed services"
}

check_installed() {
    for key in "${!URLS[@]}"; do
        if systemctl list-unit-files | grep -q "$key.service"; then
            echo "$key service installed"
        fi
    done
}

create_user() {
    if ! id "$USER" &>/dev/null; then
        useradd --no-create-home --shell /bin/false $USER
    fi
}

verify_sha() {
    file=$1
    expected=$2
    actual=$(sha256sum "$file" | awk '{print $1}')
    if [ "$actual" != "$expected" ]; then
        echo "Checksum verification failed"
        exit 1
    fi
}

create_prometheus_service() {
cat <<EOF >/etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
After=network.target

[Service]
User=$USER
ExecStart=$INSTALL_BIN/prometheus \
  --config.file=$CONFIG_DIR/prometheus.yml \
  --storage.tsdb.path=$DATA_DIR \
  --storage.tsdb.retention.time=15d

Restart=always

[Install]
WantedBy=multi-user.target
EOF
}

create_generic_service() {
name=$1
cat <<EOF >/etc/systemd/system/${name}.service
[Unit]
Description=$name
After=network.target

[Service]
User=$USER
ExecStart=$INSTALL_BIN/$name
Restart=always

[Install]
WantedBy=multi-user.target
EOF
}

install_binary() {
name=$1
if systemctl list-unit-files | grep -q "$name.service"; then
    echo "$name already installed"
    return
fi
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"
file=$(basename "${URLS[$name]}")
curl -LO "${URLS[$name]}"
verify_sha "$file" "${SHA[$name]}"
tar -xzf "$file"
dir=$(find . -maxdepth 1 -type d -name "*${VERSIONS[$name]}*")
cp "$dir/$name" "$INSTALL_BIN/"
chmod +x "$INSTALL_BIN/$name"
if [ "$name" == "prometheus" ]; then
    mkdir -p "$CONFIG_DIR" "$DATA_DIR"
    chown -R $USER:$USER "$CONFIG_DIR" "$DATA_DIR"
    create_prometheus_service
else
    create_generic_service "$name"
fi
systemctl daemon-reload
systemctl enable "$name"
systemctl start "$name"
rm -rf "$TMP_DIR"
echo "$name installed and started"
}

if [ "$1" == "help" ]; then
    help_menu
    exit 0
fi

if [ "$1" == "about" ]; then
    about
    exit 0
fi

if [ "$1" == "check" ]; then
    check_installed
    exit 0
fi

create_user

if ! systemctl list-unit-files | grep -q "prometheus.service"; then
    install_binary prometheus
fi

if [ $# -eq 0 ]; then
    exit 0
fi

for arg in "$@"; do
    if [[ -n "${URLS[$arg]}" ]]; then
        install_binary "$arg"
    fi
done
