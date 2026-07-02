# Auth via env vars (UNIFI_USERNAME / UNIFI_PASSWORD) from .secrets.env -- kept
# out of git. api_url is the UniFi OS base (no /api path; the SDK discovers it).
provider "unifi" {
  api_url        = "https://192.168.1.1"
  allow_insecure = true # UDM Pro self-signed cert
  # site defaults to "default"
}
