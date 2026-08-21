#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="${PROJECT_ROOT}/state/infrastructure.json"
FINDINGS_FILE="${PROJECT_ROOT}/state/audit/findings.json"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "ERROR: Infrastructure discovery has not been executed."
    echo "Run: ./platform discover"
    exit 1
fi

if ! python3 -m json.tool "$STATE_FILE" >/dev/null 2>&1; then
    echo "ERROR: Infrastructure inventory is invalid."
    echo "Run: ./platform discover"
    exit 1
fi

echo
echo "Infrastructure Audit"
echo "===================="
echo

"${PROJECT_ROOT}/auditors/linux/audit.py" >/dev/null

if ! python3 -m json.tool "$FINDINGS_FILE" >/dev/null 2>&1; then
    echo "ERROR: Audit engine generated invalid output."
    exit 1
fi

python3 - <<PY
import json

with open("$FINDINGS_FILE") as f:
    audit = json.load(f)

print("Host:", audit["host"])
print()
print("Findings")
print("--------")

for severity in ("critical", "high", "medium", "low", "info"):
    print(f"{severity.upper():8} {audit['summary'][severity]}")

print()

for finding in audit["findings"]:
    severity = finding["severity"].upper()

    print(
        f"[{severity:8}] "
        f"{finding['id']}  "
        f"{finding['title']}"
    )
    print(f"           {finding['evidence']}")

print()
print("Audit file:")
print("  $FINDINGS_FILE")
PY
