#!/usr/bin/env bash
set -euo pipefail

echo '{'

if command -v apt-get >/dev/null 2>&1; then

    UPGRADABLE=$(
        apt list --upgradable 2>/dev/null |
        tail -n +2 |
        wc -l
    )

    SECURITY=$(
        apt list --upgradable 2>/dev/null |
        grep -ci security || true
    )

    printf '"package_manager":"apt",'
    printf '"updates_available":%s,' "$UPGRADABLE"
    printf '"security_updates":%s' "$SECURITY"

elif command -v zypper >/dev/null 2>&1; then

    UPDATES=$(
        zypper -q lu 2>/dev/null |
        grep -c '^v ' || true
    )

    PATCHES=$(
        zypper -q lp --category security 2>/dev/null |
        grep -c '^needed' || true
    )

    printf '"package_manager":"zypper",'
    printf '"updates_available":%s,' "$UPDATES"
    printf '"security_updates":%s' "$PATCHES"

elif command -v dnf >/dev/null 2>&1; then

    UPDATES=$(
        dnf -q check-update 2>/dev/null |
        grep -E '^[A-Za-z0-9_.+-]+\.[A-Za-z0-9_]+ ' |
        wc -l || true
    )

    SECURITY=$(
        dnf -q updateinfo list security 2>/dev/null |
        grep -cE 'Important|Critical|Moderate|Low' || true
    )

    printf '"package_manager":"dnf",'
    printf '"updates_available":%s,' "$UPDATES"
    printf '"security_updates":%s' "$SECURITY"

else

    printf '"package_manager":"unknown",'
    printf '"updates_available":null,'
    printf '"security_updates":null'

fi

echo '}'
