# NetFlow / sFlow / IPFIX Export Examples

## ntopng Collector Ports

| Protocol | Port | Transport |
|---|---|---|
| NetFlow v5/v9 | 2055 | TCP+UDP |
| IPFIX | 4739 | TCP+UDP |
| sFlow | 6343 | TCP+UDP |

## Device Configuration Examples

### MikroTik RouterOS

```bash
# Enable flow accounting
/ip traffic-flow set enabled=yes cache-entries=64k \
    active-flow-timeout=30m inactive-flow-timeout=15s

# Add collector
/ip traffic-flow target add address=<NOC_IP> port=2055 version=9

# Verify
/ip traffic-flow print
/ip traffic-flow target print
```

### Cisco IOS / IOS-XE

```bash
! Configure flow exporter
flow exporter NOC-EXPORTER
 description NOC Flow Export
 destination <NOC_IP>
 transport udp 2055
 template data timeout 300
 option interface-table
 option application-table
 option vlan-table
!
! Configure flow monitor
flow monitor NOC-MONITOR
 description NOC Monitoring
 exporter NOC-EXPORTER
 record netflow ipv4 original-input
!
! Apply to interfaces
interface GigabitEthernet0/0/0
 description Uplink to Internet
 ip flow monitor NOC-MONITOR input
 ip flow monitor NOC-MONITOR output
!
! Verify
show flow exporter
show flow monitor
show flow record
```

### Cisco Nexus (NX-OS)

```bash
! Hardware accelerated flow
hardware flow exporter NOC
  destination <NOC_IP> source-interface mgmt0
  transport udp 2055
  version 9
!
hardware flow monitor NOC
  exporter NOC
  record netflow-original
!
hardware flow monitor NOC
  module 1
!
system flow enable
!
! Verify
show hardware flow exporter
show hardware flow monitor statistics
```

### Juniper JunOS

```bash
forwarding-options {
    sampling {
        instance {
            NOC-SAMPLING {
                input {
                    rate 1000;  # 1:1000 sampling
                }
                family inet {
                    output {
                        flow-server <NOC_IP> {
                            port 2055;
                            version 9;
                            template {
                                ipv4;
                            }
                        }
                        inline-jflow {
                            source-ip <SOURCE_IP>;
                        }
                    }
                }
            }
        }
    }
}
interfaces {
    ge-0/0/0 {
        unit 0 {
            family inet {
                sampling {
                    input;
                }
            }
        }
    }
}
```

### Arista EOS

```bash
! Enable sFlow
sflow source-interface Management1
sflow destination <NOC_IP> 6343
sflow sample 10000
sflow polling-interval 30
sflow run

! Or NetFlow (hardware accelerated)
flow exporter NOC
  destination <NOC_IP>
  transport udp 2055
  format ipfix
!
flow monitor NOC
  exporter NOC
  record netflow
!
interface Ethernet1
  flow monitor NOC input
!
! Verify
show sflow
show flow exporter
```

### Fortinet FortiGate

```bash
config system sflow
    set collector-ip <NOC_IP>
    set collector-port 6343
    set source-ip <SOURCE_IP>
end

config system netflow
    set collector-ip <NOC_IP>
    set collector-port 2055
    set source-ip <SOURCE_IP>
    set version 9
    set template-interval 300
end
```

### OPNsense / pfSense

#### OPNsense
```
Services > Netflow > Settings
- Enable Netflow: Yes
- Capture on: WAN, LAN
- Protocol: Both (UDP/TCP)
- Destination: <NOC_IP>:2055
- Version: 5 or 9
```

#### pfSense
```
Services > Softflowd
- Enable: Yes
- Interface: WAN, LAN
- Target: <NOC_IP>:2055
- Protocol: udp
- Version: 5
```

### Linux softflowd

```bash
# Install
apt-get install softflowd

# Run on interface
softflowd -i eth0 -n <NOC_IP>:2055 -T full -t 60

# Run as daemon
softflowd -i eth0 -n <NOC_IP>:2055 -T full -t 60 \
    -p /var/run/softflowd.pid -D

# Auto-start (systemd)
cat > /etc/systemd/system/softflowd.service << 'EOF'
[Unit]
Description=softflowd NetFlow exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/softflowd -i eth0 -n <NOC_IP>:2055 -T full -t 60
ExecStop=/usr/sbin/softflowctl shutdown
PIDFile=/var/run/softflowd.pid
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable softflowd
systemctl start softflowd
```

## Verification

### Check ntopng is receiving flows

```bash
# Check ntopng logs
docker compose logs ntopng | grep -i flow

# Check collector ports are listening
sudo netstat -ulpn | grep -E '2055|4739|6343'

# Send test NetFlow v9 packet
# Use flowgen to test
docker run --rm -it iwase/flowgen \
    -a <NOC_IP>:2055 -n 1000
```

### Troubleshooting

| Issue | Check |
|---|---|
| No flows in ntopng | Verify collector IP/port in device config |
| | Check firewall: `sudo ufw allow 2055/udp` |
| | Verify ntopng logs: `docker compose logs ntopng` |
| High CPU on ntopng | Reduce sampling rate on devices |
| | Increase ntopng resources in `.env` |
| | Reduce flow timeout values |
| Missing interface data | Verify interface names match SNMP |

## Performance Notes

- **NetFlow v9**: Preferred for most devices (template-based, extensible)
- **IPFIX**: Same as NetFlow v9 but standardized (IETF RFC 7011)
- **sFlow**: Best for high-speed links (statistical sampling, lower CPU)
- **Sampling Rate**: Start with 1:1000 at 10Gbps, adjust based on ntopng CPU usage
- **Flow Timeout**: Active 30min, Inactive 15s (balances granularity vs volume)
