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

## Future: Automated Secret Management

Consider implementing:
- **Sealed Secrets**: Encrypt secrets for safe Git storage
- **External Secrets Operator**: Sync from external vaults (Vault, AWS Secrets Manager, etc.)
- **SOPS**: Encrypt YAML files with age or PGP keys
