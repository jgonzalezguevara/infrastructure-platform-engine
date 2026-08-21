#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/config/runtime.env"
STATE_FILE="${PROJECT_ROOT}/state/infrastructure.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Environment is not configured."
    echo "Run: ./platform init"
    exit 1
fi

source "$CONFIG_FILE"

echo
echo "Infrastructure Discovery"
echo "========================"
echo
echo "Environment : ${ENVIRONMENT_NAME}"
echo "Type        : ${INFRASTRUCTURE_TYPE}"
echo

case "$INFRASTRUCTURE_TYPE" in

    linux)
        echo "Running Linux infrastructure discovery..."

        TMP_STATE=$(mktemp)
        trap 'rm -f "$TMP_STATE"' EXIT

        "${PROJECT_ROOT}/collectors/linux/discover.sh" > "$TMP_STATE"

        if ! python3 -m json.tool "$TMP_STATE" >/dev/null 2>&1; then
            echo
            echo "ERROR: Discovery generated an invalid infrastructure inventory."
            exit 1
        fi

        mv "$TMP_STATE" "$STATE_FILE"
        trap - EXIT
        ;;

    *)
        echo "Discovery for '${INFRASTRUCTURE_TYPE}' is not implemented yet."
        exit 1
        ;;
esac

chmod 600 "$STATE_FILE"

if ! python3 -m json.tool "$STATE_FILE" >/dev/null 2>&1; then
    echo
    echo "ERROR: Discovery generated an invalid infrastructure inventory."
    rm -f "$STATE_FILE"
    exit 1
fi

echo
echo "Discovery completed."
echo "Inventory validation: OK"
echo
echo "Inventory:"
echo "  $STATE_FILE"
echo
