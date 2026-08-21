#!/usr/bin/env bash
set -euo pipefail

hostname_fqdn=$(hostname -f 2>/dev/null || hostname)
hostname_short=$(hostname)

os_name=$(awk -F= '/^PRETTY_NAME=/{gsub(/"/,"",$2); print $2}' /etc/os-release 2>/dev/null || echo "unknown")
os_id=$(awk -F= '/^ID=/{gsub(/"/,"",$2); print $2}' /etc/os-release 2>/dev/null || echo "unknown")
os_version=$(awk -F= '/^VERSION_ID=/{gsub(/"/,"",$2); print $2}' /etc/os-release 2>/dev/null || echo "unknown")

kernel=$(uname -r)
architecture=$(uname -m)

cpu_model=$(lscpu | awk -F: '/Model name/{sub(/^[ \t]+/,"",$2); print $2; exit}')
cpu_sockets=$(lscpu | awk -F: '/Socket\(s\)/{gsub(/ /,"",$2); print $2; exit}')
cpu_threads=$(nproc)

memory_total_bytes=$(awk '/MemTotal/{printf "%.0f", $2 * 1024}' /proc/meminfo)
swap_total_bytes=$(awk '/SwapTotal/{printf "%.0f", $2 * 1024}' /proc/meminfo)

uptime_seconds=$(awk '{printf "%.0f", $1}' /proc/uptime)

default_gateway=$(ip route | awk '/^default/{print $3; exit}')
default_interface=$(ip route | awk '/^default/{print $5; exit}')

primary_ip=$(ip -4 addr show "$default_interface" 2>/dev/null \
  | awk '/inet /{print $2}' \
  | cut -d/ -f1 \
  | head -n1)

virtualization=$(systemd-detect-virt 2>/dev/null || true)
virtualization="${virtualization:-none}"

root_device=$(findmnt -n -o SOURCE / 2>/dev/null || echo "unknown")
root_filesystem=$(findmnt -n -o FSTYPE / 2>/dev/null || echo "unknown")
root_size=$(df -B1 / | awk 'NR==2{print $2}')
root_used=$(df -B1 / | awk 'NR==2{print $3}')
root_available=$(df -B1 / | awk 'NR==2{print $4}')
root_usage_percent=$(df -P / | awk 'NR==2{gsub("%","",$5); print $5}')

export hostname_fqdn hostname_short
export os_name os_id os_version kernel architecture
export cpu_model cpu_sockets cpu_threads
export memory_total_bytes swap_total_bytes
export uptime_seconds
export default_gateway default_interface primary_ip
export virtualization
export root_device root_filesystem root_size root_used root_available root_usage_percent

python3 - <<'PY'
import json
import os

def s(name, default="unknown"):
    return os.environ.get(name, default)

def i(name, default=0):
    try:
        return int(os.environ.get(name, default))
    except (TypeError, ValueError):
        return default

data = {
    "hostname": s("hostname_short"),
    "fqdn": s("hostname_fqdn"),

    "operating_system": {
        "name": s("os_name"),
        "id": s("os_id"),
        "version": s("os_version"),
        "kernel": s("kernel"),
        "architecture": s("architecture"),
    },

    "hardware": {
        "cpu_model": s("cpu_model"),
        "cpu_sockets": i("cpu_sockets"),
        "cpu_threads": i("cpu_threads"),
        "memory_total_bytes": i("memory_total_bytes"),
        "swap_total_bytes": i("swap_total_bytes"),
    },

    "virtualization": s("virtualization", "none"),
    "uptime_seconds": i("uptime_seconds"),

    "network": {
        "default_interface": s("default_interface"),
        "primary_ip": s("primary_ip"),
        "default_gateway": s("default_gateway"),
    },

    "root_filesystem": {
        "device": s("root_device"),
        "filesystem": s("root_filesystem"),
        "size_bytes": i("root_size"),
        "used_bytes": i("root_used"),
        "available_bytes": i("root_available"),
        "usage_percent": i("root_usage_percent"),
    },
}

print(json.dumps(data, indent=2))
PY
