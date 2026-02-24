# Secrets Management

Secrets are NOT stored in this Git repository for security reasons.

## Required Secrets

### cert-manager namespace

1. **cloudflare-api-token-secret**
   - Required for: Let's Encrypt DNS-01 validation
   - Creation command:
     ```bash
     kubectl create secret generic cloudflare-api-token-secret \
       --namespace=cert-manager \
       --from-literal=api-token=YOUR_CLOUDFLARE_API_TOKEN
     ```
   - Status: ✅ Already created during bootstrap

### Application-Specific Secrets

Some applications may require additional secrets. Create these manually in their respective namespaces:

- Any database passwords
- API keys
- Authentication tokens

Check each application's manifest for secret references.

#### homepage namespace

1. **homepage-secrets**
   - Required for: Sonarr and Radarr API widgets
   - Creation command:
     ```bash
     kubectl create secret generic homepage-secrets \
       --namespace=homepage \
       --from-literal=sonarr-api-key=YOUR_SONARR_API_KEY \
       --from-literal=radarr-api-key=YOUR_RADARR_API_KEY \
       --from-literal=sabnzbd-api-key=YOUR_SABNZBD_API_KEY
     ```
   - Sonarr/Radarr: Settings → General → Security
   - SABnzbd: Config → General → API Key

## Future: Automated Secret Management

Consider implementing:
- **Sealed Secrets**: Encrypt secrets for safe Git storage
- **External Secrets Operator**: Sync from external vaults (Vault, AWS Secrets Manager, etc.)
- **SOPS**: Encrypt YAML files with age or PGP keys
