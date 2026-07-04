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
# Master on/off switch. true = Roblox blocked (routes exist); flip to false and
# `terraform apply` to UNBLOCK (destroys the routes). The provider's static route
# has no "enabled" field, so toggling = create/destroy. Override without editing
# code via `terraform apply -var block_roblox=false`.
variable "block_roblox" {
  type        = bool
  default     = true
  description = "Blackhole-route all of Roblox (AS22697). false removes the block."
}

locals {
  roblox_as22697 = [
    "103.140.28.0/23",
    "128.116.0.0/17",
    "141.193.3.0/24",
    "205.201.62.0/24",
  ]
}

resource "unifi_static_route" "roblox_blackhole" {
  for_each = var.block_roblox ? toset(local.roblox_as22697) : toset([])

  name     = "Blackhole Roblox ${each.value}"
  type     = "blackhole"
  network  = each.value
  distance = 1
}
