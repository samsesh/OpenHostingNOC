# Security Configuration

This directory contains security-related configuration files.

## Components

- **suricata/**: IDS/IPS configuration (optional native install)
- **fail2ban/**: Fail2ban configuration for host-level protection
- **crowdsec/**: Crowdsec configuration (optional)
- **ldap/**: LDAP bootstrap configuration

## Suricata

Suricata is deployed natively (not in Docker) because it requires direct access to network interfaces for packet capture.

### Installation

```bash
# Run the install script
sudo bash security/suricata/install.sh

# Configure
sudo bash security/suricata/configure.sh

# Start
sudo systemctl enable suricata
sudo systemctl start suricata
```

### Architecture

```
Suricata (native) --> eve.json --> Filebeat (Docker) --> OpenSearch
                    --> Syslog (optional) --> Loki
```

## Fail2Ban

Fail2Ban runs on the host to protect SSH and other services.

### Configuration

```bash
sudo cp security/fail2ban/jail.local /etc/fail2ban/
sudo systemctl restart fail2ban
```
