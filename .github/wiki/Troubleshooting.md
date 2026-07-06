# Troubleshooting Guide

## Quick Diagnostics

```bash
./scripts/healthcheck.sh     # Full health check
docker compose ps            # Service status
docker compose logs -f       # Live logs
docker stats                 # Resource usage
df -h                        # Disk space
```

## Common Issues

### Service Won't Start

```bash
docker compose logs <service>   # Check logs
sudo netstat -tulpn | grep <port>  # Port conflicts
df -h                          # Disk space
```

### LibreNMS Database Error

```bash
docker compose ps mariadb                    # Is MariaDB running?
docker compose logs librenms                 # Check LibreNMS logs
docker compose exec mariadb mysqladmin ping  # Test connection
```

### Prometheus Targets Down

Check target status at `https://prometheus.<DOMAIN>/targets` or:

```bash
# Via API
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
```

### Certificate Errors

```bash
docker compose logs traefik | grep -i acme
echo | openssl s_client -connect localhost:443 -servername grafana.$DOMAIN 2>/dev/null | openssl x509 -noout -dates
```

### OpenSearch OOM

```bash
docker compose logs opensearch | grep -i "out of memory\|OOM"
curl -sk -u admin:$OPENSEARCH_PASSWORD https://localhost:9200/_cluster/health
```

Increase `OPENSEARCH_JVM_HEAP_SIZE` in `.env`.

### Telegram Alerts Not Working

```bash
docker compose logs alertmanager | grep -i telegram
curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe"
```

### ntopng Not Receiving Flows

```bash
docker compose logs ntopng
sudo netstat -ulpn | grep -E '2055|6343|4739'
```

## Performance

```bash
# Find resource-heavy containers
docker stats --no-stream

# Test connectivity
docker compose exec prometheus ping -c 2 grafana
```

## Debug Data Collection

```bash
./scripts/backup.sh --output /tmp/debug-logs
docker compose logs --tail=1000 > /tmp/opennoc-all-logs.txt
```

---

*Full reference: [docs/troubleshooting/](../docs/troubleshooting/)*
