#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

"${PROJECT_ROOT}/collectors/linux/local.sh" \
    > "${TMP_DIR}/base.json"

"${PROJECT_ROOT}/collectors/linux/modules/updates.sh" \
    > "${TMP_DIR}/updates.json"

"${PROJECT_ROOT}/collectors/linux/modules/security.sh" \
    > "${TMP_DIR}/security.json"

"${PROJECT_ROOT}/collectors/linux/modules/network-exposure.sh" \
    > "${TMP_DIR}/network-exposure.json"

"${PROJECT_ROOT}/collectors/linux/modules/containers.sh" \
    > "${TMP_DIR}/containers.json"

"${PROJECT_ROOT}/collectors/linux/modules/software.sh" \
    > "${TMP_DIR}/software.json"

python3 - "$TMP_DIR" <<'PY'
import json
import sys
from pathlib import Path

tmp = Path(sys.argv[1])

def load(name):
    path = tmp / name
    with path.open() as f:
        return json.load(f)

inventory = load("base.json")

inventory["updates"] = load("updates.json")
inventory["security"] = load("security.json")
inventory["network_exposure"] = load("network-exposure.json")
inventory["container_runtime"] = load("containers.json")
inventory["software_inventory"] = load("software.json")

print(json.dumps(inventory, indent=2))
PY
