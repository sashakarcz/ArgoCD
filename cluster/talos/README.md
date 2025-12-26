# Talos Cluster Configuration

This directory contains the Talos Linux configuration for the Kubernetes cluster.

## ⚠️ Security Notice

**IMPORTANT**: Most Talos configuration files contain sensitive secrets (tokens, certificates, private keys) and are **NOT committed to git**. They are listed in `.gitignore`.

## Files

### Safe to Commit (in git)
- `patch.yaml` - Machine configuration patch template
  - Includes strictARP for MetalLB
  - VIP configuration (192.168.7.69)
  - Longhorn storage mounts
  - Network interface configuration
  - **Safe**: Contains only configuration directives, no secrets

### NOT in Git (contains secrets)
- `controlplane.yaml` - Generated control plane configuration
  - Contains: cluster certificates, tokens, private keys
  - **Location**: `/tmp/talos-new/controlplane.yaml`
  - **Backup**: Store securely outside of git (e.g., password manager, encrypted storage)

- `worker.yaml` - Generated worker configuration
  - Contains: cluster certificates, tokens, private keys
  - **Location**: `/tmp/talos-new/worker.yaml`

- `talosconfig` - Talos CLI client configuration
  - Contains: client certificates and authentication credentials
  - **Location**: `/tmp/talos-new/talosconfig` (also `~/.talos/config`)
  - **Backup**: Store securely outside of git

## Current Cluster Nodes

- talos-atc-eq8: 192.168.7.185
- talos-dmu-u04: 192.168.7.57
- talos-geg-yo3: 192.168.7.158
- talos-wg3-7g1: 192.168.7.194

## Cluster Details

- **Talos Version**: 1.12.0
- **Kubernetes Version**: 1.35.0
- **VIP**: 192.168.7.69
- **MetalLB Range**: 192.168.7.200-192.168.7.250

## Applying Talos Configuration

These files are for reference and disaster recovery. To apply Talos configuration changes:

```bash
# Apply patch to a node
talosctl apply-config --nodes <node-ip> --file controlplane.yaml --config-patch @patch.yaml

# Bootstrap cluster (only needed once during initial setup)
talosctl bootstrap --nodes 192.168.7.185
```

## Generating New Configurations

If you need to regenerate the cluster configuration:

```bash
talosctl gen config talos-cluster https://192.168.7.69:6443 \
  --config-patch @patch.yaml \
  --output-dir ./new-config
```
