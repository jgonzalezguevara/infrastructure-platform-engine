def evaluate(inventory):
    findings = []

    updates = inventory.get("updates", {})

    pending = updates.get("updates_available", 0)
    security = updates.get("security_updates", 0)

    if security > 0:
        findings.append({
            "id": "UPD-001",
            "severity": "high",
            "category": "updates",
            "title": "Security updates pending",
            "evidence": f"{security} security updates are pending",
        })

    if pending > 0:
        findings.append({
            "id": "UPD-002",
            "severity": "medium",
            "category": "updates",
            "title": "Package updates pending",
            "evidence": f"{pending} package updates are available",
        })

    if pending == 0:
        findings.append({
            "id": "UPD-003",
            "severity": "info",
            "category": "updates",
            "title": "No package updates pending",
            "evidence": "The package manager reports no pending updates",
        })

    return findings
