#!/usr/bin/env python3

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from enrichment.github import inspect_repository


INPUT_FILE = (
    PROJECT_ROOT /
    "state" /
    "software-resolved-local.json"
)

OUTPUT_FILE = (
    PROJECT_ROOT /
    "state" /
    "software-enriched.json"
)


def enrich_component(component):

    result = {
        **component,

        "external": {
            "status": "unresolved",
            "checked_at": (
                datetime.now(timezone.utc)
                .isoformat()
            ),
            "sources": [],
        },
    }

    source = component.get(
        "official_source"
    )

    #
    # First external strategy:
    # repository explicitly declared by
    # the installed artifact itself.
    #
    if source:

        github = inspect_repository(
            source
        )

        if github:

            result["external"][
                "status"
            ] = "resolved-source"

            result["external"][
                "sources"
            ].append({
                "type": "github",
                "url": source,
                "confidence": "declared-by-artifact",
                "data": github,
            })

            return result

    #
    # No usable external source yet.
    # Later stages will dynamically search.
    #
    result["external"][
        "status"
    ] = "requires-source-discovery"

    return result


def main():

    if not INPUT_FILE.exists():

        raise SystemExit(
            "Local software resolution missing. "
            "Run identification/provenance first."
        )

    with INPUT_FILE.open() as f:
        data = json.load(f)

    enriched = []

    for component in data.get(
        "components",
        []
    ):
        enriched.append(
            enrich_component(component)
        )

    result = {
        "host": data.get("host"),
        "component_count": len(enriched),
        "generated_at": (
            datetime.now(timezone.utc)
            .isoformat()
        ),
        "components": enriched,
    }

    OUTPUT_FILE.write_text(
        json.dumps(
            result,
            indent=2
        ) + "\n"
    )


if __name__ == "__main__":
    main()
