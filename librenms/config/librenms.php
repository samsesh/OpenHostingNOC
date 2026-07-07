<?php
// =============================================================================
// LibreNMS Configuration - OpenHostingNOC
// =============================================================================

// Database
$config['db_host'] = getenv('DB_HOST') ?: 'mariadb';
$config['db_port'] = getenv('DB_PORT') ?: '3306';
$config['db_name'] = getenv('DB_NAME') ?: 'librenms';
$config['db_user'] = getenv('DB_USER') ?: 'librenms';
$config['db_pass'] = getenv('DB_PASSWORD') ?: 'changeme';
$config['db_socket'] = '';

// Redis
$config['redis']['host'] = getenv('REDIS_HOST') ?: 'redis';
$config['redis']['port'] = getenv('REDIS_PORT') ?: 6379;
$config['redis']['db'] = getenv('REDIS_DB') ?: 0;
$config['redis']['password'] = getenv('REDIS_PASSWORD') ?: '';
$config['redis']['timeout'] = 2.5;
$config['redis']['persistent'] = false;

// Application URLs
$config['base_url'] = 'https://' . (getenv('LIBRENMS_SERVER_NAME') ?: 'librenms') . '/';
$config['force_https'] = true;
$config['webui']['login_background_image'] = false;

// Auth
if (getenv('LIBRENMS_LDAP_ENABLED') === 'true') {
    $config['auth_mechanism'] = 'ldap';
    $config['auth_ldap']['server'] = getenv('LIBRENMS_LDAP_SERVER');
    $config['auth_ldap']['port'] = getenv('LIBRENMS_LDAP_PORT') ?: 389;
    $config['auth_ldap']['version'] = getenv('LIBRENMS_LDAP_VERSION') ?: 3;
    $config['auth_ldap']['basedn'] = getenv('LIBRENMS_LDAP_BASE');
    $config['auth_ldap']['binddn'] = getenv('LIBRENMS_LDAP_BIND_DN');
    $config['auth_ldap']['bindpass'] = getenv('LIBRENMS_LDAP_BIND_PASSWORD');
    $config['auth_ldap']['starttls'] = filter_var(getenv('LIBRENMS_LDAP_START_TLS'), FILTER_VALIDATE_BOOLEAN);
    $config['auth_ldap']['uid_attribute'] = 'uid';
    $config['auth_ldap']['mail_attribute'] = 'mail';
    $config['auth_ldap']['name_attribute'] = 'cn';
    $config['auth_ldap']['user_filter'] = getenv('LIBRENMS_LDAP_USER_FILTER') ?: '';
    $config['auth_ldap']['group'] = getenv('LIBRENMS_LDAP_GROUP') ?: '';
    $config['auth_ldap']['groupmemberattr'] = 'memberUid';
    $config['auth_ldap']['groupobjectclass'] = 'posixGroup';
    $config['auth_ldap']['groupmembertype'] = 'uid';
}

// SNMP Settings
$config['snmp']['community'][0] = getenv('LIBRENMS_SNMP_COMMUNITY_V2C') ?: 'public';
$config['snmp']['community'][1] = getenv('LIBRENMS_SNMP_COMMUNITY_V3') ?: '';
$config['snmp']['timeout'] = 1000000;
$config['snmp']['retries'] = 3;
$config['snmp']['max_repeaters'] = 10;
$config['snmp']['oid_timeout'] = 500000;
$config['snmp']['mode'] = 'ipv4';

// Polling & Discovery
$config['discovery_on_poller'] = true;
$config['update_mechanism'] = getenv('LIBRENMS_UPDATE_MECHANISM') ?: 'git';
$config['autofix_enabled'] = true;
$config['poller_modules']['os'] = true;
$config['poller_modules']['bgp-asn'] = true;
$config['poller_modules']['bgp-peers'] = true;
$config['poller_modules']['cispa'] = true;
$config['poller_modules']['mpls'] = true;
$config['poller_modules']['ospf'] = true;
$config['poller_modules']['stp'] = true;
$config['poller_modules']['wireless'] = true;
$config['poller_modules']['fdb-table'] = true;
$config['poller_modules']['wifi'] = true;

// Discovery modules
$config['discovery_modules']['bgp-peers'] = true;
$config['discovery_modules']['cispa'] = true;
$config['discovery_modules']['mpls'] = true;
$config['discovery_modules']['ospf'] = true;
$config['discovery_modules']['stp'] = true;
$config['discovery_modules']['vlans'] = true;
$config['discovery_modules']['vrf'] = true;
$config['discovery_modules']['wireless'] = true;

// Billing / Bandwidth Accounting
$config['billing']['enabled'] = true;
$config['billing']['base'] = 1000;
$config['billing']['bill_type'] = 'CDR 95th';

// Alerting
$config['alert']['default_copy'] = 'alertmanager';
$config['alert']['transports']['alertmanager'] = true;
$config['alert']['transports']['mail'] = false;
$config['alert']['transports']['api'] = false;
$config['alert']['alertmanager']['url'] = 'http://alertmanager:9093/api/v2/alerts';
$config['alert']['alertmanager']['severity_mapping'] = [
    'critical' => 'critical',
    'warning' => 'warning',
    'ok' => 'resolved',
];
$config['alert']['alertmanager']['auto_resolve'] = true;
$config['alert']['alertmanager']['color'] = true;
$config['alert']['alertmanager']['details'] = true;

// Syslog
$config['enable_syslog'] = true;
$config['syslog']['filter'] = true;
$config['syslog']['purge'] = 30;

// Oxidized (Config Backup)
if (getenv('LIBRENMS_OXIDIZED_ENABLED') === 'true') {
    $config['oxidized']['enabled'] = true;
    $config['oxidized']['url'] = getenv('LIBRENMS_OXIDIZED_URL') ?: 'http://oxidized:8888';
    $config['oxidized']['group_support'] = true;
    $config['oxidized']['default_group'] = 'default';
    $config['oxidized']['reload_nodes'] = true;
}

// API
$config['api']['enabled'] = true;
$config['api']['allow_public'] = false;

// Performance Tuning
$config['poller_threads'] = getenv('LIBRENMS_POLLER_THREADS') ?: 16;
$config['service_poller'] = filter_var(getenv('LIBRENMS_SERVICE_POLLER'), FILTER_VALIDATE_BOOLEAN) ?: true;
$config['service_discovery'] = filter_var(getenv('LIBRENMS_SERVICE_DISCOVERY'), FILTER_VALIDATE_BOOLEAN) ?: true;
$config['service_services'] = filter_var(getenv('LIBRENMS_SERVICE_SERVICES'), FILTER_VALIDATE_BOOLEAN) ?: true;

// RANCID / Oxidized integration
$config['rancid_configs'][0] = '/opt/librenms/.OXIDIZED_HOME/configs';

// Weathermap
$config['weathermap']['enabled'] = true;

// GeoIP
$config['geoip']['enabled'] = filter_var(getenv('GEOIP_ENABLED'), FILTER_VALIDATE_BOOLEAN) ?: false;
$config['geoip']['database'] = getenv('GEOIP_DB_PATH') ?: '/usr/share/GeoIP';

// Device Settings
$config['device']['enable_serial_number'] = true;
$config['device']['enable_inventory'] = true;
$config['device']['enable_temperature'] = true;
$config['device']['enable_humidity'] = true;
$config['device']['enable_fans'] = true;
$config['device']['enable_power'] = true;

// Proxmox
$config['proxmox']['enable'] = true;

// VMware
$config['vmware']['enable'] = true;

// Location settings
$config['enable_autolocation'] = true;

// Port settings
$config['port']['ifName'] = true;
$config['port']['association_mode'] = 'ifIndex';
$config['port']['descr_parser'] = true;

// Billing / 95th Percentile
$config['billing']['enabled'] = true;
$config['billing']['base'] = 1000;
$config['billing']['bill_type'] = 'CDR 95th';

// Performance
$config['timeout'] = 60;
$config['rrd']['step'] = 300;
$config['rrd']['heartbeat'] = 600;
$config['rrd']['enable'] = true;

// Sentry / Error tracking - disable for self-hosted
$config['sentry']['enabled'] = false;

// Custom CSS for dark theme
$config['webui']['custom_css'] = '';
$config['webui']['global_css'] = '';
$config['webui']['dark'] = true;
