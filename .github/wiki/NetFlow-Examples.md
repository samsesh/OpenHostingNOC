# NetFlow / sFlow / IPFIX Export Examples

## Collector Ports

| Protocol | Port | Transport |
|---|---|---|
| NetFlow v5/v9 | 2055 | TCP+UDP |
| IPFIX | 4739 | TCP+UDP |
| sFlow | 6343 | TCP+UDP |

## Device Configs

### MikroTik RouterOS

```
/ip traffic-flow set enabled=yes cache-entries=64k active-flow-timeout=30m inactive-flow-timeout=15s
/ip traffic-flow target add address=<NOC_IP> port=2055 version=9
```

### Cisco IOS / IOS-XE

```
flow exporter NOC-EXPORTER
 destination <NOC_IP>
 transport udp 2055
 template data timeout 300
!
flow monitor NOC-MONITOR
 exporter NOC-EXPORTER
 record netflow ipv4 original-input
!
interface GigabitEthernet0/0/0
 ip flow monitor NOC-MONITOR input
 ip flow monitor NOC-MONITOR output
```

### Cisco Nexus (NX-OS)

```
hardware flow exporter NOC
  destination <NOC_IP> source-interface mgmt0
  transport udp 2055
  version 9
hardware flow monitor NOC
  exporter NOC
  record netflow-original
system flow enable
```

### Juniper JunOS

```
forwarding-options {
    sampling {
        instance NOC-SAMPLING {
            input { rate 1000; }
            family inet {
                output {
                    flow-server <NOC_IP> { port 2055; version 9; }
                }
            }
        }
    }
}
```

### Arista EOS

```
sflow source-interface Management1
sflow destination <NOC_IP> 6343
sflow sample 10000
sflow run
```

### Fortinet FortiGate

```
config system sflow
    set collector-ip <NOC_IP>
    set collector-port 6343
end
config system netflow
    set collector-ip <NOC_IP>
    set collector-port 2055
    set version 9
end
```

### Linux softflowd

```bash
apt-get install softflowd
softflowd -i eth0 -n <NOC_IP>:2055 -T full -t 60
```

## Verification

```bash
docker compose logs ntopng | grep -i flow
sudo netstat -ulpn | grep -E '2055|4739|6343'
```

## Performance Tips

- **NetFlow v9**: Preferred for most devices
- **sFlow**: Best for high-speed links (statistical sampling)
- **Start with 1:1000 sampling** at 10Gbps
- **Flow timeout**: Active 30min, Inactive 15s

---

*Full reference: [docs/configuration/netflow-examples.md](../docs/configuration/netflow-examples.md)*
