def evaluate(inventory):
    findings = []

    network = inventory.get("network_exposure", {})
    listener_count = network.get("listener_count", 0)

    if listener_count > 0:
        findings.append({
            "id": "NET-001",
            "severity": "info",
            "category": "network",
            "title": "Listening network services detected",
            "evidence": f"{listener_count} listening sockets were detected",
        })

    return findings
