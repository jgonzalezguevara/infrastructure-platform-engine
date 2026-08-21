def evaluate(inventory):
    findings = []

    software = inventory.get(
        "software_inventory",
        {}
    )

    for item in software.get("components", []):

        if item.get("kind") != "container-image":
            continue

        image = item.get(
            "detected_name",
            ""
        )

        if image.endswith(
            (
                ":latest",
                ":stable",
                ":current",
                ":edge"
            )
        ):
            findings.append({
                "id": "CNT-001",
                "severity": "medium",
                "category": "containers",
                "title": "Floating container image tag detected",
                "evidence": (
                    f"Running image '{image}' "
                    f"does not pin an immutable version"
                ),
            })

    return findings
