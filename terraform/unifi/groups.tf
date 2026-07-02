# Address groups referenced by imported policies (subnets can't be inline in a policy).
resource "unifi_firewall_group" "freebsd_bastille" {
  name    = "FreeBSD-Bastille"
  type    = "address-group"
  members = ["10.17.89.0/24"]
}
