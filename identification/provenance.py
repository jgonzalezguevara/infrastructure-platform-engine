#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from identification.providers.docker import inspect_image

INPUT = PROJECT_ROOT / "state" / "software-candidates.json"
OUTPUT = PROJECT_ROOT / "state" / "software-provenance.json"


def running_images():
    try:
        output = subprocess.check_output(
            ["docker", "ps", "--format", "{{.Image}}"],
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=10,
        )

        return list(dict.fromkeys(
            line.strip()
            for line in output.splitlines()
            if line.strip()
        ))

    except Exception:
        return []


def main():
    with INPUT.open() as f:
        candidates = json.load(f)

    images = running_images()

    image_metadata = []

    for image in images:
        result = inspect_image(image)

        if result:
            image_metadata.append(result)

    output = {
        "candidate_count": candidates["candidate_count"],
        "container_images_inspected": len(image_metadata),
        "container_images": image_metadata,
    }

    OUTPUT.write_text(
        json.dumps(output, indent=2) + "\n"
    )

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
