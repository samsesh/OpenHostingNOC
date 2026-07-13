# OpenHostingNOC Wiki

Welcome to the OpenHostingNOC wiki — a complete, open-source NOC platform for hosting providers.

## 📋 Pages

### Getting Started
- [Installation](Installation) — Full installation guide
- [Quick Start](Quick-Start) — Get running in 5 minutes
- [Configuration](Configuration) — Service configuration reference

### Operations
- [Backup & Restore](Backup-Restore) — Backup strategies and restore procedures
- [Upgrade](Upgrade) — How to upgrade components
- [Troubleshooting](Troubleshooting) — Common issues and solutions

### Networking
- [NetFlow Examples](NetFlow-Examples) — Device configs for flow export

### Security
- [Security Guide](Security) — Hardening and best practices

### Advanced
- [High Availability](High-Availability) — Multi-node deployment
- [Scaling](Scaling) — Performance tuning
- [Disaster Recovery](Disaster-Recovery) — Full recovery procedures

---

## CI/CD Status

| Workflow | Status |
|---|---|
| CI (lint, validate) | [![CI](https://img.shields.io/github/actions/workflow/status/samsesh/OpenHostingNOC/ci.yml?branch=main)](https://github.com/samsesh/OpenHostingNOC/actions/workflows/ci.yml) |
| Tests (BATS) | [![Tests](https://img.shields.io/github/actions/workflow/status/samsesh/OpenHostingNOC/test.yml?branch=main)](https://github.com/samsesh/OpenHostingNOC/actions/workflows/test.yml) |
| Docker Build | [![Docker](https://img.shields.io/github/actions/workflow/status/samsesh/OpenHostingNOC/docker-publish.yml?branch=main)](https://github.com/samsesh/OpenHostingNOC/actions/workflows/docker-publish.yml) |

## Docker Image

A pre-built all-in-one Docker image is available on GHCR:

```bash
docker pull ghcr.io/samsesh/opennoc:latest
```

Includes docker-cli, docker-compose, all scripts and configs.

---

## Links

| Resource | Link |
|---|---|
| Main Repository | [GitHub](https://github.com/samsesh/OpenHostingNOC) |
| Packages | [GHCR](https://github.com/samsesh/OpenHostingNOC/pkgs/container/opennoc) |
| Issues | [GitHub Issues](https://github.com/samsesh/OpenHostingNOC/issues) |
| Discussions | [GitHub Discussions](https://github.com/samsesh/OpenHostingNOC/discussions) |

---

❤️ **Support**: [donate.samsesh.net](https://donate.samsesh.net)

*Last updated: 2026-07-13*
