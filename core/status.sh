#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/config/runtime.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo
    echo "No environment configured."
    echo
    echo "Run:"
    echo "  ./platform init"
    exit 1
fi

source "$CONFIG_FILE"

echo
echo "Infrastructure Platform Engine"
echo "=============================="
echo
echo "Environment"
echo "-----------"
echo "Name                : ${ENVIRONMENT_NAME}"
echo "Infrastructure type : ${INFRASTRUCTURE_TYPE}"
echo

if [[ -f "${PROJECT_ROOT}/state/infrastructure.json" ]]; then
    if python3 -m json.tool "${PROJECT_ROOT}/state/infrastructure.json" >/dev/null 2>&1; then
        echo "Discovery status    : available"
    else
        echo "Discovery status    : invalid"
    fi
else
    echo "Discovery status    : not executed"
fi

if [[ -f "${PROJECT_ROOT}/state/audit.json" ]]; then
    echo "Audit status        : available"
else
    echo "Audit status        : not executed"
fi

echo
