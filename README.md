# Infrastructure Platform Engine

Infrastructure discovery, assessment and automation engine focused on real-world infrastructure environments.

The project is designed to discover existing infrastructure without assuming the technologies deployed in advance, build a normalized technical inventory, identify relevant software and services, enrich discovered components with external information from their declared or resolved upstream sources, and generate auditable infrastructure findings.

## Current capabilities

- Linux infrastructure discovery.
- Hardware, operating system, kernel and filesystem inventory.
- Network and exposed-service discovery.
- SSH and firewall posture inspection.
- Pending package and security-update discovery.
- Docker, containerd and Kubernetes detection.
- Installed package, service, runtime and container-image inventory.
- Software candidate identification and prioritization.
- OCI/Docker provenance inspection.
- Local software version and source resolution.
- External enrichment using discovered upstream GitHub repositories.
- Initial audit engine with severity-based findings.
- Detection of floating container tags.
- Runtime state stored outside Git.

## Processing pipeline

```text
DISCOVER
   ↓
IDENTIFY
   ↓
PROVENANCE
   ↓
LOCAL RESOLUTION
   ↓
ENRICH
   ↓
AUDIT
```

## Commands

```bash
./platform init
./platform discover
./platform identify
./platform enrich
./platform audit
./platform status
```

## Project direction

Planned capabilities include:

- Dynamic official-source discovery for unknown software.
- Software lifecycle, deprecation and end-of-support analysis.
- Security advisory and vulnerability correlation.
- Infrastructure risk prioritization.
- Architecture assessment and optimization recommendations.
- Migration planning.
- Human-approved automated remediation.
- Bare-metal provisioning.
- Kubernetes and platform deployment.
- Infrastructure validation and reporting.

## Security

Runtime configuration, discovered infrastructure data, generated reports, credentials and secrets are excluded from version control.

No environment-specific credentials should be committed to the repository.

## Status

Early functional PoC under active development.
