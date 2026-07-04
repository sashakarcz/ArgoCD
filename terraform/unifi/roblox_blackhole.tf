# Block all of Roblox by BLACKHOLE-ROUTING its ASN (AS22697) on the UDM Pro.
#
# Why routing, not firewall/app rules: this drops traffic at Layer 3, BEFORE the
# firewall (so it's order-independent -- no rule-index problem) and needs NO DNS
# or DPI. That matters here because clients resolve via Knot, not the UDM, so
# UniFi's DNS/SNI-based app blocking can never see Roblox. A blackhole route
# applies to every client and VLAN at once.
#
# Refresh the prefix list periodically from RIPEstat announced-prefixes for
# AS22697 -- Roblox rotates IPs:
#   https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS22697
locals {
  roblox_as22697 = [
    "103.140.28.0/23",
    "128.116.0.0/17",
    "141.193.3.0/24",
    "205.201.62.0/24",
  ]
}

resource "unifi_static_route" "roblox_blackhole" {
  for_each = toset(local.roblox_as22697)

  name     = "Blackhole Roblox ${each.value}"
  type     = "blackhole"
  network  = each.value
  distance = 1
}
