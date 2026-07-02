# UniFi firewall-as-code. Manages zone-based firewall policies on the UDM Pro
# (heimdal, 192.168.1.1, Network 10.x) declaratively.
#
# State: MinIO (S3-compatible) on Mimir jail 192.168.1.150, bucket terraform-state
# (versioned), with native S3 locking (use_lockfile, requires Terraform >= 1.10).
# Credentials are supplied via env vars (see .secrets.env / README.md), never in git.
terraform {
  required_version = ">= 1.10"

  required_providers {
    unifi = {
      source  = "filipowm/unifi"
      version = ">= 1.0"
    }
  }

  backend "s3" {
    endpoints                   = { s3 = "http://192.168.1.150:9000" }
    bucket                      = "terraform-state"
    key                         = "unifi/firewall.tfstate"
    region                      = "us-east-1" # dummy; MinIO ignores it
    use_path_style              = true
    use_lockfile                = true # native S3 state locking, no DynamoDB
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}
