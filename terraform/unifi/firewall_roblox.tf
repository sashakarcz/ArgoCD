# Zone IDs are stable per-controller (from the UDM Pro zone matrix).
locals {
  zone_internal = "68339bf59aca6f5001d7d1eb"
  zone_external = "68339bf59aca6f5001d7d1ec"
}

# Roblox game-server ranges (ASN AS22697). The zone-policy `ips` field only
# accepts single IPv4 addresses, so subnets live in an address-group referenced
# by the policy. Refresh periodically -- Roblox rotates IPs.
resource "unifi_firewall_group" "roblox_ips" {
  name = "Roblox-AS22697"
  type = "address-group"
  members = [
    "103.140.28.0/23",
    "128.116.0.0/17",
    "141.193.3.0/24",
    "205.201.62.0/24",
  ]
}

# Layer-3 block of Roblox (DoH-proof).
# NOTE: ordering (index) is controller-managed and not settable here; this rule
# must sit above the permissive "allow ... -> ANY" rules, done once in the UI.
resource "unifi_firewall_zone_policy" "block_roblox_ips" {
  name    = "Block Roblox IPs (AS22697)"
  action  = "BLOCK"
  enabled = true

  source = {
    zone_id = local.zone_internal
  }

  destination = {
    zone_id     = local.zone_external
    ip_group_id = unifi_firewall_group.roblox_ips.id
  }

  protocol   = "all"
  ip_version = "BOTH"

  # NOTE: `index` (rule order) is NOT settable -- the controller ignores writes to it
  # and the provider errors on the mismatch. Left computed. Order the rule ABOVE the
  # permissive "allow ... -> ANY" rules once, by hand, in the UI. Everything else here
  # (match, action, enabled, schedule) is managed by Terraform.

  schedule = {
    mode = "ALWAYS"
  }
}
