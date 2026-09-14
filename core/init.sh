#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CONFIG_DIR="${PROJECT_ROOT}/config"
SECRETS_DIR="${PROJECT_ROOT}/secrets"

CONFIG_FILE="${CONFIG_DIR}/runtime.env"
SECRETS_FILE="${SECRETS_DIR}/runtime.env"

mkdir -p "$CONFIG_DIR" "$SECRETS_DIR"

echo
echo "Infrastructure Platform Engine"
echo "=============================="
echo
echo "Create infrastructure environment"
echo

read -rp "Environment name (example: customer-platform): " ENVIRONMENT_NAME

while [[ -z "$ENVIRONMENT_NAME" ]]; do
    echo "Environment name cannot be empty."
    read -rp "Environment name (example: customer-platform): " ENVIRONMENT_NAME
done

echo
echo "Infrastructure type"
echo "-------------------"
echo "1) Linux servers"
echo "2) Kubernetes"
echo "3) VMware"
echo "4) Rancher"
echo "5) Harvester"
echo "6) Proxmox"
echo "7) Bare metal"
echo "8) Mixed infrastructure"
echo

read -rp "Select infrastructure type (example: 1): " TYPE

case "$TYPE" in
    1) INFRASTRUCTURE_TYPE="linux" ;;
    2) INFRASTRUCTURE_TYPE="kubernetes" ;;
    3) INFRASTRUCTURE_TYPE="vmware" ;;
    4) INFRASTRUCTURE_TYPE="rancher" ;;
    5) INFRASTRUCTURE_TYPE="harvester" ;;
    6) INFRASTRUCTURE_TYPE="proxmox" ;;
    7) INFRASTRUCTURE_TYPE="baremetal" ;;
    8) INFRASTRUCTURE_TYPE="mixed" ;;
    *)
        echo "Invalid infrastructure type."
        exit 1
        ;;
esac

cat > "$CONFIG_FILE" <<EOF_CONFIG
ENVIRONMENT_NAME=${ENVIRONMENT_NAME}
INFRASTRUCTURE_TYPE=${INFRASTRUCTURE_TYPE}
EOF_CONFIG

touch "$SECRETS_FILE"

chmod 600 "$CONFIG_FILE"
chmod 600 "$SECRETS_FILE"

echo
echo "Environment created."
echo
echo "Name : ${ENVIRONMENT_NAME}"
echo "Type : ${INFRASTRUCTURE_TYPE}"
echo
echo "Next step:"
echo "  ./platform discover"
echo
