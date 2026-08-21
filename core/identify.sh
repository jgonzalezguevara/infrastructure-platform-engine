#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INPUT="${PROJECT_ROOT}/state/infrastructure.json"
OUTPUT="${PROJECT_ROOT}/state/software-candidates.json"

if [[ ! -f "$INPUT" ]]; then
    echo "ERROR: No infrastructure inventory found."
    echo "Run: ./platform discover"
    exit 1
fi

echo
echo "Software Identification"
echo "======================="
echo

"${PROJECT_ROOT}/identification/software.py" >/dev/null

python3 - "$OUTPUT" <<'PY'
import json
import sys

with open(sys.argv[1]) as f:
    data = json.load(f)

print("Raw components :", data["raw_component_count"])
print("Candidates     :", data["candidate_count"])
print()

print("Highest priority candidates")
print("---------------------------")

for item in data["candidates"][:30]:
    version = item.get("version") or "unknown"
    kind = item.get("kind", "unknown")

    print(
        f'{item["identity"]:35} '
        f'| {str(version):20} '
        f'| {kind}'
    )
PY

echo
echo "Identification file:"
echo "  $OUTPUT"
