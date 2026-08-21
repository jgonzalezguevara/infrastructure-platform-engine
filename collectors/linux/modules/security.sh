#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import os
import pwd
import subprocess

def command_exists(cmd):
    return subprocess.call(
        ["sh", "-c", f"command -v {cmd} >/dev/null 2>&1"]
    ) == 0

def ssh_effective(name):
    try:
        result = subprocess.check_output(
            ["sshd", "-T"],
            stderr=subprocess.DEVNULL,
            text=True
        )

        for line in result.splitlines():
            parts = line.split(None, 1)
            if len(parts) == 2 and parts[0].lower() == name.lower():
                return parts[1]

    except Exception:
        pass

    return "unknown"

uid0_users = []

for user in pwd.getpwall():
    if user.pw_uid == 0:
        uid0_users.append(user.pw_name)

firewall = "unknown"

if command_exists("ufw"):
    try:
        output = subprocess.check_output(
            ["ufw", "status"],
            stderr=subprocess.DEVNULL,
            text=True
        )
        firewall = "active" if "Status: active" in output else "inactive"
    except Exception:
        pass

elif command_exists("firewall-cmd"):
    try:
        subprocess.check_call(
            ["firewall-cmd", "--state"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        firewall = "active"
    except Exception:
        firewall = "inactive"

data = {
    "ssh": {
        "permit_root_login": ssh_effective("permitrootlogin"),
        "password_authentication": ssh_effective("passwordauthentication"),
        "pubkey_authentication": ssh_effective("pubkeyauthentication")
    },
    "firewall": firewall,
    "uid0_users": uid0_users
}

print(json.dumps(data))
PY
