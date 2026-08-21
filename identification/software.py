#!/usr/bin/env python3

import json
import re
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]

INVENTORY_FILE = PROJECT_ROOT / "state" / "infrastructure.json"
OUTPUT_FILE = PROJECT_ROOT / "state" / "software-candidates.json"


def extract_version(value):
    if not value:
        return None

    # Prefer the first version-like token in the detected product output.
    # Supports versions such as:
    #   29.7.1
    #   24.18.0
    #   9.6p1
    #   v2.11
    patterns = [
        r"(?<![0-9])v?(\d+\.\d+(?:\.\d+)*(?:[A-Za-z]+\d*)?)(?![0-9])",
    ]

    for pattern in patterns:
        match = re.search(pattern, value)

        if match:
            return match.group(1)

    return None


def normalize_container(image):
    image_no_digest = image.split("@", 1)[0]

    # Remove registry hostname but preserve namespace/repository.
    parts = image_no_digest.split("/")

    if len(parts) > 1 and (
        "." in parts[0]
        or ":" in parts[0]
        or parts[0] == "localhost"
    ):
        parts = parts[1:]

    repository = "/".join(parts)

    last = repository.rsplit("/", 1)[-1]

    if ":" in last:
        name, tag = last.rsplit(":", 1)

        if "/" in repository:
            prefix = repository.rsplit("/", 1)[0]
            repository = f"{prefix}/{name}"
        else:
            repository = name
    else:
        tag = "latest"

    return repository, tag


def version_from_container_tag(tag):
    if not tag:
        return None

    if tag in {
        "latest",
        "stable",
        "current",
        "edge",
    }:
        return None

    match = re.match(
        r"^v?(\d+(?:\.\d+)+)",
        tag
    )

    if match:
        return match.group(1)

    return None


def service_details(service):
    result = {
        "service": service,
        "exec_start": None,
        "package": None,
        "package_version": None,
    }

    try:
        output = subprocess.check_output(
            [
                "systemctl",
                "show",
                service,
                "--property=ExecStart",
                "--value",
            ],
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=3,
        ).strip()

        match = re.search(r"path=([^ ;}]+)", output)

        if match:
            executable = match.group(1)
            result["exec_start"] = executable

            try:
                package = subprocess.check_output(
                    ["dpkg-query", "-S", executable],
                    stderr=subprocess.DEVNULL,
                    text=True,
                    timeout=3,
                ).split(":", 1)[0].strip()

                result["package"] = package

                version = subprocess.check_output(
                    [
                        "dpkg-query",
                        "-W",
                        "-f=${Version}",
                        package,
                    ],
                    stderr=subprocess.DEVNULL,
                    text=True,
                    timeout=3,
                ).strip()

                result["package_version"] = version

            except Exception:
                pass

    except Exception:
        pass

    return result


if not INVENTORY_FILE.exists():
    raise SystemExit(
        "Infrastructure inventory not found. Run ./platform discover"
    )

with INVENTORY_FILE.open() as f:
    inventory = json.load(f)


candidates = []


#
# Operating system itself is a product to enrich.
#
os_info = inventory.get("operating_system", {})

candidates.append({
    "identity": os_info.get("id", "unknown"),
    "display_name": os_info.get("name", "unknown"),
    "version": os_info.get("version"),
    "kind": "operating-system",
    "running": True,
    "priority": 1,
    "evidence": {
        "kernel": os_info.get("kernel"),
        "architecture": os_info.get("architecture"),
    }
})


#
# Container images.
#
for component in inventory.get(
    "software_inventory", {}
).get("components", []):

    if component.get("kind") != "container-image":
        continue

    image = component.get("detected_name")
    repository, tag = normalize_container(image)

    candidates.append({
        "identity": repository,
        "display_name": repository,
        "version": version_from_container_tag(tag),
        "kind": "container-image",
        "running": True,
        "priority": 5,
        "evidence": {
            "image": image,
            "tag": tag,
            "floating_tag": tag in {
                "latest",
                "stable",
                "current",
                "edge",
            },
        }
    })


#
# Directly detected runtimes/tools.
#
for component in inventory.get(
    "software_inventory", {}
).get("components", []):

    if component.get("kind") != "runtime":
        continue

    raw_version = component.get("version")

    candidates.append({
        "identity": component.get("detected_name"),
        "display_name": component.get("detected_name"),
        "version": extract_version(raw_version),
        "kind": "runtime",
        "running": None,
        "priority": 10,
        "evidence": {
            "raw_version": raw_version,
        }
    })


#
# Running services.
#
for component in inventory.get(
    "software_inventory", {}
).get("components", []):

    if component.get("kind") != "service":
        continue

    service = component.get("detected_name")

    details = service_details(service)

    identity = (
        details.get("package")
        or re.sub(r"\.service$", "", service)
    )

    candidates.append({
        "identity": identity,
        "display_name": re.sub(
            r"\.service$",
            "",
            service
        ),
        "version": extract_version(
            details.get("package_version")
        ),
        "kind": "service",
        "running": True,
        "priority": 20,
        "evidence": details,
    })


#
# Deduplicate without losing evidence.
#
deduplicated = {}

for candidate in candidates:

    key = (
        candidate["kind"],
        candidate["identity"].lower(),
        candidate.get("version"),
    )

    if key not in deduplicated:
        deduplicated[key] = candidate


ordered = sorted(
    deduplicated.values(),
    key=lambda x: (
        x["priority"],
        x["identity"].lower()
    )
)


result = {
    "host": inventory.get("hostname"),
    "raw_component_count": inventory.get(
        "software_inventory", {}
    ).get("count", 0),

    "package_count": sum(
        1
        for x in inventory.get(
            "software_inventory", {}
        ).get("components", [])
        if x.get("kind") == "package"
    ),

    "candidate_count": len(ordered),
    "candidates": ordered,
}


with OUTPUT_FILE.open("w") as f:
    json.dump(
        result,
        f,
        indent=2
    )


print(json.dumps(result, indent=2))
