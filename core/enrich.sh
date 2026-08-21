#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INPUT="${PROJECT_ROOT}/state/software-resolved-local.json"
OUTPUT="${PROJECT_ROOT}/state/software-enriched.json"

if [[ ! -f "$INPUT" ]]; then
    echo "ERROR: Local software resolution not found."
    echo
    echo "Required processing:"
    echo "  ./platform discover"
    echo "  ./platform identify"
    exit 1
fi

echo
echo "Software Enrichment"
echo "==================="
echo

"${PROJECT_ROOT}/enrichment/enrich.py"

python3 - "$OUTPUT" <<'PY'
import json
import sys
from collections import Counter

with open(sys.argv[1]) as f:
    data = json.load(f)

statuses = Counter(
    component["external"]["status"]
    for component in data["components"]
)

print("Components :", data["component_count"])
print()

for status, count in sorted(statuses.items()):
    print(f"{status:30} {count}")

print()
print("External enrichment file:")
print(f"  {sys.argv[1]}")
PY
