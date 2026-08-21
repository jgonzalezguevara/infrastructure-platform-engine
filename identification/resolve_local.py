#!/usr/bin/env python3

import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]

CANDIDATES_FILE = PROJECT_ROOT / "state" / "software-candidates.json"
PROVENANCE_FILE = PROJECT_ROOT / "state" / "software-provenance.json"
OUTPUT_FILE = PROJECT_ROOT / "state" / "software-resolved-local.json"


def normalize_version(value):
    if not value:
        return None

    value = str(value).strip()

    if value.startswith("v"):
        value = value[1:]

    return value


def main():
    with CANDIDATES_FILE.open() as f:
        candidates_data = json.load(f)

    with PROVENANCE_FILE.open() as f:
        provenance_data = json.load(f)

    provenance_by_image = {
        item["image"]: item
        for item in provenance_data.get("container_images", [])
    }

    resolved = []

    for candidate in candidates_data.get("candidates", []):
        item = {
            "identity": candidate.get("identity"),
            "display_name": candidate.get("display_name"),
            "kind": candidate.get("kind"),
            "running": candidate.get("running"),
            "priority": candidate.get("priority"),
            "detected_version": normalize_version(
                candidate.get("version")
            ),
            "resolved_version": normalize_version(
                candidate.get("version")
            ),
            "vendor": None,
            "official_source": None,
            "documentation": None,
            "revision": None,
            "evidence": {
                "candidate": candidate.get("evidence", {})
            },
            "confidence": "detected",
            "needs_external_lookup": True,
        }

        if candidate.get("kind") == "container-image":
            image = candidate.get("evidence", {}).get("image")

            provenance = provenance_by_image.get(image)

            if provenance:
                metadata = provenance.get("metadata", {})

                item["evidence"]["oci"] = metadata

                oci_version = normalize_version(
                    metadata.get("version")
                )

                detected_version = normalize_version(
                    candidate.get("version")
                )

                #
                # Prefer OCI version when:
                # - candidate has no concrete version
                # - OCI version is clearly more specific
                #
                if oci_version:
                    if not detected_version:
                        item["resolved_version"] = oci_version
                    elif len(oci_version) > len(detected_version):
                        item["resolved_version"] = oci_version

                item["vendor"] = metadata.get("vendor")
                item["official_source"] = metadata.get("source")
                item["documentation"] = metadata.get("documentation")
                item["revision"] = metadata.get("revision")

                if item["official_source"]:
                    item["confidence"] = "provenance"
                elif item["vendor"]:
                    item["confidence"] = "partial-provenance"

        #
        # Decide if external research is still needed.
        #
        # Even with a source URL we still want lifecycle/security lookup,
        # so this remains True. Provenance only improves the starting point.
        #
        item["needs_external_lookup"] = True

        resolved.append(item)

    result = {
        "host": candidates_data.get("host"),
        "candidate_count": len(resolved),
        "components": resolved,
    }

    OUTPUT_FILE.write_text(
        json.dumps(result, indent=2) + "\n"
    )

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
