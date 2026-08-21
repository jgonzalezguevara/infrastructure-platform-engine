#!/usr/bin/env python3

import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
STATE_FILE = PROJECT_ROOT / "state" / "infrastructure.json"
OUTPUT_FILE = PROJECT_ROOT / "state" / "audit" / "findings.json"

sys.path.insert(0, str(PROJECT_ROOT))

from auditors.linux.rules.updates import evaluate as evaluate_updates
from auditors.linux.rules.security import evaluate as evaluate_security
from auditors.linux.rules.network import evaluate as evaluate_network
from auditors.linux.rules.containers import evaluate as evaluate_containers


def main():
    if not STATE_FILE.exists():
        print("ERROR: Infrastructure inventory not found.")
        print("Run: ./platform discover")
        sys.exit(1)

    with STATE_FILE.open() as f:
        inventory = json.load(f)

    findings = []

    findings.extend(evaluate_updates(inventory))
    findings.extend(evaluate_security(inventory))
    findings.extend(evaluate_network(inventory))
    findings.extend(evaluate_containers(inventory))

    severity_order = {
        "critical": 0,
        "high": 1,
        "medium": 2,
        "low": 3,
        "info": 4,
    }

    findings.sort(
        key=lambda finding: severity_order.get(
            finding["severity"], 99
        )
    )

    summary = {
        severity: sum(
            1 for finding in findings
            if finding["severity"] == severity
        )
        for severity in severity_order
    }

    result = {
        "host": inventory.get("hostname", "unknown"),
        "summary": summary,
        "findings": findings,
    }

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

    with OUTPUT_FILE.open("w") as f:
        json.dump(result, f, indent=2)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
