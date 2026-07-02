# UniFi firewall as code

Declaratively manages the UDM Pro (`heimdal`, `192.168.1.1`, Network 10.x)
zone-based firewall policies with the [`filipowm/unifi`](https://registry.terraform.io/providers/filipowm/unifi/latest)
Terraform provider.

## What this manages
- `unifi_firewall_zone_policy` resources (zone-based firewall / Policy Engine).
- Starting scope: parental-control rules (Roblox, TikTok). Expand over time.

## What it does NOT manage
- **Rule ordering.** The provider's `index` is read-only and a
  `unifi_firewall_zone_policy_order` resource is not yet released. Order-sensitive
  rules (e.g. a block that must sit above an `allow ... -> ANY` rule) must be
  positioned once by hand in the UI. Terraform still owns the rule's definition,
  action, match, enabled state, and schedule.

## State
- Backend: MinIO (S3) on Mimir jail `192.168.1.150:9000`, bucket `terraform-state`
  (versioned), key `unifi/firewall.tfstate`, native S3 locking (`use_lockfile`).

## Credentials (never committed)
Create `.secrets.env` (gitignored) and `source` it before running Terraform:

```sh
# MinIO (S3 backend) -- scoped svcacct, only the terraform-state bucket
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
# UniFi -- local admin account svc-terraform (NOT a UI.com cloud login)
export UNIFI_USERNAME=svc-terraform
export UNIFI_PASSWORD=...
```

Future: move these into Vault (as with `unifi-poller`) and render at runtime.

## Usage
```sh
source .secrets.env
terraform init      # first time / after backend or provider changes
terraform plan
terraform apply
```

## Importing existing rules
Rules created in the UI are imported so Terraform adopts them without recreating:
```sh
terraform import unifi_firewall_zone_policy.<name> <policy_id>
terraform plan      # iterate resource config until plan shows no changes
```
