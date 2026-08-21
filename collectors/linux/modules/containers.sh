#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import shutil
import subprocess

data = {
    "docker": {
        "detected": False
    },
    "podman": {
        "detected": False
    },
    "containerd": {
        "detected": False
    },
    "kubernetes": {
        "detected": False
    }
}

if shutil.which("docker"):
    data["docker"]["detected"] = True

    try:
        containers = subprocess.check_output(
            ["docker", "ps", "-q"],
            stderr=subprocess.DEVNULL,
            text=True
        ).split()

        data["docker"]["running_containers"] = len(containers)
    except Exception:
        data["docker"]["running_containers"] = None

if shutil.which("podman"):
    data["podman"]["detected"] = True

if shutil.which("containerd"):
    data["containerd"]["detected"] = True

if shutil.which("kubectl"):
    data["kubernetes"]["client_detected"] = True

    try:
        subprocess.check_call(
            ["kubectl", "cluster-info"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=5
        )

        data["kubernetes"]["detected"] = True

    except Exception:
        pass

print(json.dumps(data))
PY
