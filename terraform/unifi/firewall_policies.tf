# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform
resource "unifi_firewall_zone_policy" "allow_all_to_mqtt_d7d22c" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.52"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ef"
  }
  enabled                 = false
  index                   = 10011
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow all to MQTT"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform
resource "unifi_firewall_zone_policy" "allow_multicat_iot_wireless_d7d214" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = false
  index                   = 10007
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Multicat IOT Wireless"
  protocol                = "igmp"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d23e"
resource "unifi_firewall_zone_policy" "allow_wg_d7d23e" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow WG"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "65e12a299be67854b80077d6"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ec"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d24e"
resource "unifi_firewall_zone_policy" "allow_rocket_d7d24e" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.35"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ed"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Rocket"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ec"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d20c"
resource "unifi_firewall_zone_policy" "allow_internal_d7d20c" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10005
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Internal"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "608c8e539a00ca043deac415"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:6874390dbfaa2268a2236c2c"
resource "unifi_firewall_zone_policy" "allow_plex_236c2c" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.169"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = 32400
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow Plex"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ec"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d22a"
resource "unifi_firewall_zone_policy" "allow_gemini_d7d22a" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "666e7ebaf04e9323b5f85db6"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = "666e7e9ef04e9323b5f85db4"
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ee"
  }
  enabled                 = true
  index                   = 10010
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow gemini"
  protocol                = "tcp"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = "666e7e9ef04e9323b5f85db4"
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform
resource "unifi_firewall_zone_policy" "allow_https_nomad_20d523" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.169"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = false
  index                   = 10020
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow https nomad"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d202"
resource "unifi_firewall_zone_policy" "allow_all_to_windows_d7d202" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "66a7dd7497fe5c1aa83bf1bf"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ee"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow All to Windows"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d230"
resource "unifi_firewall_zone_policy" "allow_gnome_d7d230" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ef"
  }
  enabled                 = false
  index                   = 10012
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow gnome"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["172.16.5.146"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform
resource "unifi_firewall_zone_policy" "allow_all_to_mqtt_d7d22d" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.52"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = false
  index                   = 10013
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow all to MQTT"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d20d"
resource "unifi_firewall_zone_policy" "allow_internal_d7d20d" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ef"
  }
  enabled                 = true
  index                   = 10004
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Internal"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "608c8e539a00ca043deac415"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:69654d587ccb966a4050f931"
resource "unifi_firewall_zone_policy" "dhcp_50f931" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.141"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10006
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "DHCP"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1f0"
  }
}

# __generated__ by Terraform
resource "unifi_firewall_zone_policy" "allow_mqtt_8918f1" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.203"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = 1883
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = false
  index                   = 10002
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow MQTT"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1f0"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d21e"
resource "unifi_firewall_zone_policy" "music_multicast_to_wireless_d7d21e" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10011
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Music Multicast to Wireless"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "63fea9a686eb0d0f1c797445"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:69d997129a9ff05aa8c219d0"
resource "unifi_firewall_zone_policy" "allow_all_to_iot_vlan_c219d0" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1f0"
  }
  enabled                 = false
  index                   = 10000
  ip_version              = "BOTH"
  logging                 = true
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow all to IoT vlan"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:6a1cae75c2f1782030b36023"
resource "unifi_firewall_zone_policy" "allow_all_to_restricted_b36023" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "6a1cae38c2f1782030b35fca"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow all to restricted"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d21d"
resource "unifi_firewall_zone_policy" "music_multicast_to_wired_d7d21d" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ee"
  }
  enabled                 = true
  index                   = 10007
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Music Multicast to Wired"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "63fea9a686eb0d0f1c797445"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:6a458bd73884744706fcd442"
resource "unifi_firewall_zone_policy" "block_traffic_from_172_16_5_245_to_128_116_95_3_fcd442" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["128.116.95.3"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Block Traffic from 172.16.5.245 to 128.116.95.3"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["172.16.5.245"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "6a1cae38c2f1782030b35fca"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d20a"
resource "unifi_firewall_zone_policy" "allow_plex_d7d20a" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.169"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10005
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Plex"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform
resource "unifi_firewall_zone_policy" "allow_multicat_iot_wired_d7d215" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = false
  index                   = 10008
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Multicat IOT Wired"
  protocol                = "igmp"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d200"
resource "unifi_firewall_zone_policy" "allow_all_to_windows_d7d200" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "66a7dd7497fe5c1aa83bf1bf"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ef"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow All to Windows"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d1fd"
resource "unifi_firewall_zone_policy" "allow_all_nebula_d7d1fd" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10002
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow all nebula"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "66a9928697fe5c1aa83cd2a0"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d250"
resource "unifi_firewall_zone_policy" "allow_from_bair_mac_d7d250" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ed"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow From Bair mac"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["172.16.5.146"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ee"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d20e"
resource "unifi_firewall_zone_policy" "allow_internal_d7d20e" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10006
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Internal"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "608c8e539a00ca043deac415"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d201"
resource "unifi_firewall_zone_policy" "allow_all_to_windows_d7d201" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "66a7dd7497fe5c1aa83bf1bf"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10003
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow All to Windows"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d235"
resource "unifi_firewall_zone_policy" "allow_wg_d7d235" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "65e12a299be67854b80077d6"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10015
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow WG"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["608c76d6f515e5053e5dfcb7"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d22f"
resource "unifi_firewall_zone_policy" "allow_gnome_d7d22f" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = false
  index                   = 10016
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow gnome"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["172.16.5.146"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:6a1cadb0c2f1782030b35f4a"
resource "unifi_firewall_zone_policy" "wifi_to_aux_b35f4a" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1f0"
  }
  enabled                 = true
  index                   = 10003
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Wifi to AUX"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["608c753cf515e5053e5dfcad", "608c76d6f515e5053e5dfcb7", "608c70daf1a96a02eba0e842", "67fc0c4ab13e125d1f05eacf"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:6a0a706994b6f648fd955131"
resource "unifi_firewall_zone_policy" "wireless_to_dmz_955131" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1f0"
  }
  enabled                 = true
  index                   = 10002
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Wireless to DMZ"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["608c753cf515e5053e5dfcad"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform

# __generated__ by Terraform from "default:6a0130d994b6f648fd9144b5"
resource "unifi_firewall_zone_policy" "allow_all_to_dmz_9144b5" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1f0"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow all to dmz"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d207"
resource "unifi_firewall_zone_policy" "allow_internal_to_aux_d7d207" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = false
  index                   = 10003
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Internal to AUX"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "608c8e539a00ca043deac415"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d232"
resource "unifi_firewall_zone_policy" "allow_gnome_d7d232" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ee"
  }
  enabled                 = false
  index                   = 10012
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow gnome"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["172.16.5.146"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d1fe"
resource "unifi_firewall_zone_policy" "allow_all_nebula_d7d1fe" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ee"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow all nebula"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "66a9928697fe5c1aa83cd2a0"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d206"
resource "unifi_firewall_zone_policy" "allow_connections_to_ipa_d7d206" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "632c07f2b183d51326746f67"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = "664a44804032902a5e7e870b"
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ee"
  }
  enabled                 = true
  index                   = 10002
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Connections to IPA"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["6093529c89132204bf0f6285"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf59aca6f5001d7d1f2"
resource "unifi_firewall_zone_policy" "block_tiktok_d7d1f2" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = ["tiktok.com", "www.tiktok.com"]
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Block TikTok"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = "2022-11-10"
    date_start     = "2022-11-03"
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = "09:00"
    time_to        = "12:00"
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["608c76d6f515e5053e5dfcb7", "608c753cf515e5053e5dfcad", "608c70daf1a96a02eba0e842"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:699632fb3e266ffbfd1402d2"
resource "unifi_firewall_zone_policy" "print_1402d2" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.62"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = 631
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10008
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Print"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1f0"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d236"
resource "unifi_firewall_zone_policy" "allow_wg_d7d236" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "65e12a299be67854b80077d6"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ee"
  }
  enabled                 = true
  index                   = 10013
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow WG"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["608c76d6f515e5053e5dfcb7"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d229"
resource "unifi_firewall_zone_policy" "allow_gemini_d7d229" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "666e7ebaf04e9323b5f85db6"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = "666e7e9ef04e9323b5f85db4"
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10012
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow gemini"
  protocol                = "tcp"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = "666e7e9ef04e9323b5f85db4"
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d205"
resource "unifi_firewall_zone_policy" "allow_connections_to_ipa_d7d205" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "632c07f2b183d51326746f67"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10004
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow Connections to IPA"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["6093529c89132204bf0f6285"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:686dc953bfaa2268a220d7ff"
resource "unifi_firewall_zone_policy" "allow_to_nomad_20d7ff" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.169", "192.168.1.35", "192.168.1.86"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = 443
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow to nomad"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1f0"
  }
}

# __generated__ by Terraform from "default:6a458bf13884744706fcd44a"
resource "unifi_firewall_zone_policy" "block_traffic_from_172_16_5_245_to_128_116_48_3_fcd44a" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["128.116.48.3"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Block Traffic from 172.16.5.245 to 128.116.48.3"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["172.16.5.245"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "6a1cae38c2f1782030b35fca"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d203"
resource "unifi_firewall_zone_policy" "allow_connections_to_ipa_d7d203" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "632c07f2b183d51326746f67"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10002
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow Connections to IPA"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["6093529c89132204bf0f6285"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform

# __generated__ by Terraform
resource "unifi_firewall_zone_policy" "allow_plex_d7d254" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.69"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ed"
  }
  enabled                 = false
  index                   = 10004
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Plex"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform

# __generated__ by Terraform from "default:68743809bfaa2268a2236b60"
resource "unifi_firewall_zone_policy" "allow_plex_236b60" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.169"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = 32400
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow Plex"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1f0"
  }
}

# __generated__ by Terraform from "default:6a458bd73884744706fcd445"
resource "unifi_firewall_zone_policy" "block_traffic_from_128_116_95_3_to_172_16_5_245_fcd445" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["172.16.5.245"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "6a1cae38c2f1782030b35fca"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Block Traffic from 128.116.95.3 to 172.16.5.245"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["128.116.95.3"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ec"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d258"
resource "unifi_firewall_zone_policy" "allow_appletv_d7d258" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.156"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ed"
  }
  enabled                 = true
  index                   = 10007
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow AppleTV"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d24f"
resource "unifi_firewall_zone_policy" "allow_from_bair_mac_d7d24f" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ed"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow From Bair mac"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["172.16.5.146"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d227"
resource "unifi_firewall_zone_policy" "allow_gemini_d7d227" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "666e7ebaf04e9323b5f85db6"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = "666e7e9ef04e9323b5f85db4"
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10014
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow gemini"
  protocol                = "tcp"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = "666e7e9ef04e9323b5f85db4"
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d1fb"
resource "unifi_firewall_zone_policy" "allow_all_nebula_d7d1fb" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow all nebula"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "66a9928697fe5c1aa83cd2a0"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d243"
resource "unifi_firewall_zone_policy" "allow_dns_d7d243" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["1.1.1.1"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow DNS"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ee"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d1f8"
resource "unifi_firewall_zone_policy" "drop_incoming_http_d7d1f8" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = "65c2c59194620e1b4015cb4c"
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ef"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Drop incoming http"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ec"
  }
}

# __generated__ by Terraform from "default:68c489696b6215100ebda84a"
resource "unifi_firewall_zone_policy" "allow_all_to_printserver_bda84a" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.62"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = 631
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10022
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow All to printserver"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:6a3f57813884744706f98a23"
resource "unifi_firewall_zone_policy" "allow_restricted_to_ingress_f98a23" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.7.207"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow Restricted to Ingress"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "6a1cae38c2f1782030b35fca"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d237"
resource "unifi_firewall_zone_policy" "allow_wired_to_omega_d7d237" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10018
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Wired to Omega"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["608c76d6f515e5053e5dfcb7"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d204"
resource "unifi_firewall_zone_policy" "allow_connections_to_ipa_d7d204" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.24"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10007
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow Connections to IPA"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1f0"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d1fc"
resource "unifi_firewall_zone_policy" "allow_all_nebula_d7d1fc" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ef"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow all nebula"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "66a9928697fe5c1aa83cd2a0"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d23c"
resource "unifi_firewall_zone_policy" "allow_wg_d7d23c" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10016
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow WG"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "65e12a299be67854b80077d6"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d21b"
resource "unifi_firewall_zone_policy" "music_multicast_to_wired_d7d21b" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ef"
  }
  enabled                 = true
  index                   = 10007
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Music Multicast to Wired"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "63fea9a686eb0d0f1c797445"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:6913c23bae57506ed655fd35"
resource "unifi_firewall_zone_policy" "dhcp_test_55fd35" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["172.16.4.67"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10003
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "DHCP test"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1f0"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d228"
resource "unifi_firewall_zone_policy" "allow_gemini_d7d228" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "666e7ebaf04e9323b5f85db6"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = "666e7e9ef04e9323b5f85db4"
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ef"
  }
  enabled                 = true
  index                   = 10010
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow gemini"
  protocol                = "tcp"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = "666e7e9ef04e9323b5f85db4"
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:6a35c5433884744706f4c351"
resource "unifi_firewall_zone_policy" "allow_internal_to_ingress_f4c351" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.7.207"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10024
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow Internal to ingress"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d259"
resource "unifi_firewall_zone_policy" "allow_appletv_d7d259" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.156"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ed"
  }
  enabled                 = true
  index                   = 10002
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow AppleTV"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ee"
  }
}

# __generated__ by Terraform from "default:687438c7bfaa2268a2236c21"
resource "unifi_firewall_zone_policy" "allow_plex_236c21" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.169"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = 32400
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10021
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow Plex"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d23d"
resource "unifi_firewall_zone_policy" "allow_wg_d7d23d" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow WG"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "65e12a299be67854b80077d6"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ef"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d209"
resource "unifi_firewall_zone_policy" "allow_plex_d7d209" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.169"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ef"
  }
  enabled                 = true
  index                   = 10003
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Plex"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform
resource "unifi_firewall_zone_policy" "allow_all_to_mqtt_d7d22e" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.52"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ee"
  }
  enabled                 = false
  index                   = 10011
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow all to MQTT"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d240"
resource "unifi_firewall_zone_policy" "allow_dns_d7d240" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["1.1.1.1"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10017
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow DNS"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d233"
resource "unifi_firewall_zone_policy" "allow_wg_d7d233" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "65e12a299be67854b80077d6"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10017
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow WG"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["608c76d6f515e5053e5dfcb7"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform
resource "unifi_firewall_zone_policy" "allow_all_freebsd_bastille_8da05d" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = unifi_firewall_group.freebsd_bastille.id
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10009
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow all FreeBSD/Bastille"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1f0"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d234"
resource "unifi_firewall_zone_policy" "allow_wg_d7d234" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "65e12a299be67854b80077d6"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ef"
  }
  enabled                 = true
  index                   = 10013
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow WG"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["608c76d6f515e5053e5dfcb7"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform
resource "unifi_firewall_zone_policy" "allow_all_to_mqtt_d7d22b" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.52"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = false
  index                   = 10015
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow all to MQTT"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d1f7"
resource "unifi_firewall_zone_policy" "drop_incoming_http_d7d1f7" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = "65c2c59194620e1b4015cb4c"
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Drop incoming http"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ec"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d1ff"
resource "unifi_firewall_zone_policy" "allow_all_to_windows_d7d1ff" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = "66a7dd7497fe5c1aa83bf1bf"
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow All to Windows"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d1fa"
resource "unifi_firewall_zone_policy" "drop_incoming_http_d7d1fa" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = "65c2c59194620e1b4015cb4c"
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ee"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Drop incoming http"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ec"
  }
}

# __generated__ by Terraform from "default:6913c4a9ae57506ed655ff0a"
resource "unifi_firewall_zone_policy" "allow_all_to_rocket_55ff0a" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.35"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10004
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow all to rocket"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1f0"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d20b"
resource "unifi_firewall_zone_policy" "allow_plex_d7d20b" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.169"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ee"
  }
  enabled                 = true
  index                   = 10003
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Plex"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d231"
resource "unifi_firewall_zone_policy" "allow_gnome_d7d231" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = false
  index                   = 10014
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow gnome"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["172.16.5.146"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d21c"
resource "unifi_firewall_zone_policy" "music_multicast_to_wired_d7d21c" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10009
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Music Multicast to Wired"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "63fea9a686eb0d0f1c797445"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:6a458bf13884744706fcd44d"
resource "unifi_firewall_zone_policy" "block_traffic_from_128_116_48_3_to_172_16_5_245_fcd44d" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["172.16.5.245"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "6a1cae38c2f1782030b35fca"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Block Traffic from 128.116.48.3 to 172.16.5.245"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["128.116.48.3"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ec"
  }
}

# __generated__ by Terraform from "default:6a0a534994b6f648fd95440b"
resource "unifi_firewall_zone_policy" "allow_to_unbound_95440b" {
  action                    = "ALLOW"
  auto_allow_return_traffic = true
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.53"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = 53
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10010
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow to unbound"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1f0"
  }
}

# __generated__ by Terraform from "default:686dc509bfaa2268a220d5f7"
resource "unifi_firewall_zone_policy" "allow_https_nomad_copy_20d5f7" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10019
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = null
  match_opposite_protocol = false
  name                    = "Allow https nomad Copy"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["6093529c89132204bf0f6285"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:6a458c123884744706fcd45a"
resource "unifi_firewall_zone_policy" "block_traffic_from_172_16_5_245_to_128_116_127_3_fcd45a" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["128.116.127.3"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10002
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Block Traffic from 172.16.5.245 to 128.116.127.3"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["172.16.5.245"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "6a1cae38c2f1782030b35fca"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d23f"
resource "unifi_firewall_zone_policy" "allow_wg_d7d23f" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow WG"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "65e12a299be67854b80077d6"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ee"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d1f9"
resource "unifi_firewall_zone_policy" "drop_incoming_http_d7d1f9" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = "65c2c59194620e1b4015cb4c"
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10000
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Drop incoming http"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ec"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d208"
resource "unifi_firewall_zone_policy" "allow_plex_d7d208" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["192.168.1.169"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10004
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Plex"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d21a"
resource "unifi_firewall_zone_policy" "music_multicast_to_wired_d7d21a" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1eb"
  }
  enabled                 = true
  index                   = 10010
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Music Multicast to Wired"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "63fea9a686eb0d0f1c797445"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d20f"
resource "unifi_firewall_zone_policy" "allow_internal_d7d20f" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ee"
  }
  enabled                 = true
  index                   = 10004
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow Internal"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = "608c8e539a00ca043deac415"
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}

# __generated__ by Terraform from "default:6a458c123884744706fcd45d"
resource "unifi_firewall_zone_policy" "block_traffic_from_128_116_127_3_to_172_16_5_245_fcd45d" {
  action                    = "BLOCK"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["172.16.5.245"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "6a1cae38c2f1782030b35fca"
  }
  enabled                 = true
  index                   = 10002
  ip_version              = "BOTH"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Block Traffic from 128.116.127.3 to 172.16.5.245"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = ["128.116.127.3"]
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ec"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d241"
resource "unifi_firewall_zone_policy" "allow_dns_d7d241" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["1.1.1.1"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10001
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow DNS"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ef"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d242"
resource "unifi_firewall_zone_policy" "allow_dns_d7d242" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = ["1.1.1.1"]
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10002
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow DNS"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = null
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1ec"
  }
}

# __generated__ by Terraform from "default:68339bf69aca6f5001d7d244"
resource "unifi_firewall_zone_policy" "allow_out_for_omega_d7d244" {
  action                    = "ALLOW"
  auto_allow_return_traffic = false
  connection_state_type     = "ALL"
  connection_states         = null
  description               = null
  destination = {
    app_category_ids     = null
    app_ids              = null
    ip_group_id          = null
    ips                  = null
    match_opposite_ips   = false
    match_opposite_ports = false
    port                 = null
    port_group_id        = null
    regions              = null
    web_domains          = null
    zone_id              = "68339bf59aca6f5001d7d1ec"
  }
  enabled                 = true
  index                   = 10018
  ip_version              = "IPV4"
  logging                 = false
  match_ip_sec_type       = "MATCH_IP_SEC"
  match_opposite_protocol = false
  name                    = "Allow out for Omega"
  protocol                = "all"
  schedule = {
    date           = null
    date_end       = null
    date_start     = null
    mode           = "ALWAYS"
    repeat_on_days = null
    time_all_day   = false
    time_from      = null
    time_to        = null
  }
  site = "default"
  source = {
    client_macs             = null
    ip_group_id             = null
    ips                     = null
    mac                     = null
    macs                    = null
    match_opposite_ips      = false
    match_opposite_networks = false
    match_opposite_ports    = false
    network_ids             = ["67fc0c4ab13e125d1f05eacf"]
    port                    = null
    port_group_id           = null
    zone_id                 = "68339bf59aca6f5001d7d1eb"
  }
}
