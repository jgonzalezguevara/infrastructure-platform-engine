def evaluate(inventory):
    findings = []

    security = inventory.get("security", {})
    ssh = security.get("ssh", {})

    firewall = security.get("firewall", "unknown")
    password_auth = ssh.get("password_authentication", "unknown")
    root_login = ssh.get("permit_root_login", "unknown")

    if firewall in ("inactive", "disabled", "not-installed"):
        findings.append({
            "id": "SEC-001",
            "severity": "high",
            "category": "security",
            "title": "Host firewall is not active",
            "evidence": f"Detected firewall state: {firewall}",
        })

    elif firewall == "active":
        findings.append({
            "id": "SEC-002",
            "severity": "info",
            "category": "security",
            "title": "Host firewall is active",
            "evidence": "An active host firewall was detected",
        })

    if password_auth == "yes":
        findings.append({
            "id": "SEC-003",
            "severity": "medium",
            "category": "security",
            "title": "SSH password authentication enabled",
            "evidence": "PasswordAuthentication is enabled",
        })

    if root_login == "yes":
        findings.append({
            "id": "SEC-004",
            "severity": "high",
            "category": "security",
            "title": "Direct SSH root login enabled",
            "evidence": "PermitRootLogin is configured as yes",
        })

    elif root_login in ("without-password", "prohibit-password"):
        findings.append({
            "id": "SEC-005",
            "severity": "info",
            "category": "security",
            "title": "SSH root password login restricted",
            "evidence": f"PermitRootLogin is configured as {root_login}",
        })

    return findings
