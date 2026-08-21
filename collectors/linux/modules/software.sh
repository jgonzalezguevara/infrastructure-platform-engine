#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import shutil
import subprocess

software = []
seen = set()

def add(name, version=None, source=None, running=None, kind=None):
    key = (name, version, source)
    if key in seen:
        return

    seen.add(key)

    item = {
        "detected_name": name,
        "version": version,
        "source": source,
    }

    if running is not None:
        item["running"] = running

    if kind:
        item["kind"] = kind

    software.append(item)


# -------------------------------------------------------------------
# Installed packages
# -------------------------------------------------------------------

if shutil.which("dpkg-query"):
    try:
        output = subprocess.check_output(
            [
                "dpkg-query",
                "-W",
                "-f=${binary:Package}\t${Version}\n"
            ],
            stderr=subprocess.DEVNULL,
            text=True
        )

        for line in output.splitlines():
            if "\t" not in line:
                continue

            name, version = line.split("\t", 1)

            add(
                name=name,
                version=version,
                source="dpkg",
                kind="package"
            )

    except Exception:
        pass


elif shutil.which("rpm"):
    try:
        output = subprocess.check_output(
            [
                "rpm",
                "-qa",
                "--qf",
                "%{NAME}\t%{VERSION}-%{RELEASE}\n"
            ],
            stderr=subprocess.DEVNULL,
            text=True
        )

        for line in output.splitlines():
            if "\t" not in line:
                continue

            name, version = line.split("\t", 1)

            add(
                name=name,
                version=version,
                source="rpm",
                kind="package"
            )

    except Exception:
        pass


# -------------------------------------------------------------------
# Active systemd services
# -------------------------------------------------------------------

if shutil.which("systemctl"):
    try:
        output = subprocess.check_output(
            [
                "systemctl",
                "list-units",
                "--type=service",
                "--state=running",
                "--no-legend",
                "--no-pager"
            ],
            stderr=subprocess.DEVNULL,
            text=True
        )

        for line in output.splitlines():
            parts = line.split()

            if not parts:
                continue

            service = parts[0]

            add(
                name=service,
                source="systemd",
                running=True,
                kind="service"
            )

    except Exception:
        pass


# -------------------------------------------------------------------
# Important binaries / runtimes
# -------------------------------------------------------------------

commands = [
    "docker",
    "podman",
    "containerd",
    "kubectl",
    "k3s",
    "rke2",
    "helm",
    "python3",
    "python",
    "java",
    "node",
    "npm",
    "php",
    "perl",
    "ruby",
    "go",
    "openssl",
    "ssh",
    "nginx",
    "apache2",
    "httpd",
    "postgres",
    "psql",
    "mysql",
    "mariadb",
    "redis-server",
    "mongod",
    "smbd",
    "zabbix_server",
    "zabbix_agentd",
    "prometheus",
]

for command in commands:

    path = shutil.which(command)

    if not path:
        continue

    version = None

    for flag in ("--version", "-version", "-v", "-V"):

        try:
            result = subprocess.check_output(
                [path, flag],
                stderr=subprocess.STDOUT,
                text=True,
                timeout=3
            ).strip()

            if result:
                version = result.splitlines()[0][:500]
                break

        except Exception:
            continue

    add(
        name=command,
        version=version,
        source="binary",
        running=None,
        kind="runtime"
    )


# -------------------------------------------------------------------
# Docker images and containers
# -------------------------------------------------------------------

if shutil.which("docker"):

    try:
        containers = subprocess.check_output(
            [
                "docker",
                "ps",
                "--format",
                "{{.Names}}\t{{.Image}}"
            ],
            stderr=subprocess.DEVNULL,
            text=True
        )

        for line in containers.splitlines():

            if "\t" not in line:
                continue

            name, image = line.split("\t", 1)

            add(
                name=image,
                source="docker-image",
                running=True,
                kind="container-image"
            )

    except Exception:
        pass


result = {
    "count": len(software),
    "components": software
}

print(json.dumps(result))
PY
