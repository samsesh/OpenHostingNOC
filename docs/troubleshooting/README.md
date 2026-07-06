# Troubleshooting Guide

## Quick Diagnostic Commands

```bash
# Health check
./scripts/healthcheck.sh

# Service status
docker compose ps

# Resource usage
docker stats

# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f <service>

# Check disk space
df -h

# Check port listening
sudo netstat -tulpn | grep -E ':(80|443|9090|3000)'
```

## Common Issues

### Services Not Starting

**Symptoms**: Containers exit immediately or keep restarting

**Check**:
```bash
# View logs
docker compose logs <service>

# Check syntax (for config-dependent services)
docker compose config

# Check port conflicts
sudo netstat -tulpn | grep <port>
```

**Solutions**:
1. Port conflict: `sudo lsof -i :<PORT>` then stop conflicting service
2. Config error: Check docker compose logs for syntax errors
3. Permission: Check `/var/run/docker.sock` permissions
4. Resource: Check disk space with `df -h`

### LibreNMS Database Connection Failed

**Symptoms**: LibreNMS web UI shows database error

**Check**:
```bash
# Check MariaDB is running
docker compose ps mariadb

# Test connection
docker compose exec mariadb mysqladmin ping -u root -p"$MARIADB_ROOT_PASSWORD"

# Check LibreNMS logs
docker compose logs librenms
```

**Solutions**:
1. Restart MariaDB: `docker compose restart mariadb`
2. Check credentials in `.env`
3. Re-initialize: `docker compose exec librenms php /opt/librenms/init.php`

### Prometheus Targets Down

**Symptoms**: Dashboards show "No data" for certain metrics

**Check**:
```bash
# Prometheus target status (in browser)
open https://prometheus.$DOMAIN/targets

# Via API
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up") | .labels.instance'
```

**Solutions**:
1. Verify target host is reachable: `ping <target>`
2. Check exporter is running: `curl http://<target>:9100/metrics`
3. Update targets file in `prometheus/targets/`

### Certificate Errors

**Symptoms**: Browser shows "Not Secure" or certificate warnings

**Check**:
```bash
# Check Traefik logs
docker compose logs traefik | grep -i acme

# Check certificate expiry
echo | openssl s_client -connect localhost:443 -servername grafana.$DOMAIN 2>/dev/null | openssl x509 -noout -dates
```

**Solutions**:
1. Verify DNS records point to your NOC IP
2. Check Traefik logs for ACME challenges
3. Ensure port 80 is reachable from internet (for HTTP-01 challenge)

### OpenSearch Out of Memory

**Symptoms**: OpenSearch keeps restarting, or cluster status is red

**Check**:
```bash
# Check logs
docker compose logs opensearch | grep -i "out of memory\|OOM"

# Check heap usage
docker stats opensearch

# Check cluster health
curl -sk -u admin:$OPENSEARCH_PASSWORD https://localhost:9200/_cluster/health
```

**Solutions**:
1. Increase `OPENSEARCH_JVM_HEAP_SIZE` in `.env`
2. Increase host RAM
3. Reduce shard count: `OPENSEARCH_NUMBER_OF_SHARDS`
4. Clear cache: `POST /_cache/clear`

### Loki Disk Space

**Symptoms**: Loki logs show "disk space full" or retention errors

**Check**:
```bash
# Check Loki data size
du -sh /var/lib/docker/volumes/opennoc_loki_data/_data/

# Check compaction status
docker compose exec loki wget -qO- http://localhost:3100/compactor/ring
```

**Solutions**:
1. Reduce retention period in `.env`: `LOKI_RETENTION_HOURS=336` (14 days)
2. Run compaction: Handled automatically by Loki
3. Add more storage: Expand volume or mount larger disk

### Telegram Alerts Not Working

**Check**:
```bash
# Check Alertmanager logs
docker compose logs alertmanager | grep -i telegram

# Test Telegram API
curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe"
```

**Solutions**:
1. Verify `TELEGRAM_BOT_TOKEN` is correct
2. Bot must be added to the chat/channel
3. Check `TELEGRAM_CHAT_ID` (can be negative for groups)
4. Verify Alertmanager can reach api.telegram.org

### ntopng Flow Data Not Receiving

**Check**:
```bash
# Check ntopng logs
docker compose logs ntopng

# Check if collector ports are listening
sudo netstat -ulpn | grep -E '2055|6343|4739'

# Generate test flow
softflowd -i eth0 -n 127.0.0.1:2055 -T full -t 30
```

**Solutions**:
1. Ensure network device is sending flows to correct IP/port
2. Check firewall: `sudo ufw allow 2055/udp`
3. Verify ntopng config has collectors enabled

## Performance Issues

### Slow Dashboards

**Check**:
```bash
# Prometheus query performance
# Check query duration in Prometheus UI

# Check system resources
./scripts/healthcheck.sh
```

**Solutions**:
1. Reduce query range
2. Add more RAM to Prometheus/Loki
3. Increase `PROMETHEUS_RETENTION_SIZE` or decrease retention time
4. Enable Prometheus recording rules for expensive queries

### High CPU/Memory

```bash
# Find resource-heavy containers
docker stats --no-stream

# Check top processes per container
docker top <container>

# Check memory inside container
docker exec <container> ps aux --sort=-%mem
```

## Network Debugging

```bash
# Test internal DNS
docker compose exec prometheus nslookup grafana

# Test container connectivity
docker compose exec prometheus ping -c 2 grafana

# Check network routes
docker network inspect opennoc_internal

# Check firewall rules
sudo iptables -L -n
```

## Logs Collection for Support

```bash
# Collect all logs for debugging
./scripts/backup.sh --output /tmp/debug-logs
docker compose logs --tail=1000 > /tmp/opennoc-all-logs.txt

# Include system info
uname -a > /tmp/debug-system.txt
free -h >> /tmp/debug-system.txt
df -h >> /tmp/debug-system.txt
docker compose ps >> /tmp/debug-system.txt
