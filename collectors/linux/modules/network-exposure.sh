#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import subprocess

listeners = []

try:
    output = subprocess.check_output(
        ["ss", "-lntupH"],
        stderr=subprocess.DEVNULL,
        text=True
    )

    for line in output.splitlines():

        parts = line.split()

        if len(parts) < 5:
            continue

        protocol = parts[0]
        local = parts[4]

        process = ""

        for item in parts[5:]:
            if "users:" in item:
                process = item
                break

        listeners.append({
            "protocol": protocol,
            "local_address": local,
            "process": process
        })

except Exception:
    pass

print(json.dumps({
    "listening_services": listeners,
    "listener_count": len(listeners)
}))
PY
