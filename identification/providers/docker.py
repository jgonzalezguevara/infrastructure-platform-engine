#!/usr/bin/env python3

import json
import subprocess


def inspect_image(image):
    try:
        raw = subprocess.check_output(
            ["docker", "image", "inspect", image],
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=10,
        )

        data = json.loads(raw)[0]
        labels = data.get("Config", {}).get("Labels") or {}

        return {
            "image": image,
            "image_id": data.get("Id"),
            "repo_digests": data.get("RepoDigests") or [],
            "metadata": {
                "title": labels.get("org.opencontainers.image.title"),
                "version": labels.get("org.opencontainers.image.version"),
                "source": labels.get("org.opencontainers.image.source"),
                "url": labels.get("org.opencontainers.image.url"),
                "documentation": labels.get(
                    "org.opencontainers.image.documentation"
                ),
                "vendor": labels.get("org.opencontainers.image.vendor"),
                "revision": labels.get("org.opencontainers.image.revision"),
                "created": labels.get("org.opencontainers.image.created"),
                "licenses": labels.get("org.opencontainers.image.licenses"),
            },
        }

    except Exception:
        return None
