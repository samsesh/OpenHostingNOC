# About OpenHostingNOC

## What is it?

OpenHostingNOC is a **complete, self-hosted Network Operations Center platform** purpose-built for hosting providers, ISPs, and IT teams that need enterprise-grade monitoring without enterprise licensing costs.

It replaces proprietary NOC solutions (LogicMonitor, SolarWinds, PRTG, Datadog) with a fully open-source stack that you deploy on your own infrastructure.

## Who is it for?

- **Hosting providers** managing hundreds of servers and thousands of customer IPs
- **ISPs** monitoring BGP sessions, transit links, and network infrastructure
- **Data center operators** tracking power, cooling, and network health
- **MSPs** that need multi-tenant monitoring capabilities
- **Enterprise IT** teams consolidating monitoring into a single platform

## What problem does it solve?

| Problem | Solution |
|---|---|
| Multiple monitoring tools to manage | Single unified platform with one reverse proxy |
| Expensive per-device licensing | 100% open source, no licensing costs |
| No customer bandwidth tracking | Per-IP 95th percentile billing built in |
| Security threats go undetected | Real-time DDoS detection and alerting |
| Disconnected alerting systems | Centralized Alertmanager with Telegram/Discord/Slack/Email/PagerDuty |
| Config drift on network devices | Automated backup via Oxidized with git history |
| Hard to scale | Documented scaling path from 1Gbps to 100Gbps |

## Core Philosophy

1. **Open Source First** — Every component is actively maintained open-source software
2. **Production Ready** — Built for real hosting providers with thousands of IPs
3. **Secure by Default** — TLS 1.3, LDAP auth, network segmentation, rate limiting
4. **Easy to Operate** — 9 automation scripts, health checks, backup/restore
5. **Self-Contained** — Everything runs in Docker, single-command deployment

## Version

**v1.0.0** — Initial stable release

## License

MIT License — free to use, modify, and distribute.

## Links

- **Repository**: [github.com/samsesh/OpenHostingNOC](https://github.com/samsesh/OpenHostingNOC)
- **Donate**: [donate.samsesh.net](https://donate.samsesh.net)
