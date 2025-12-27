# MetalLB L2 Configuration and Troubleshooting

## Environment
- **Talos Version**: 1.12.0 (Omni-managed)
- **Kubernetes Version**: 1.34.2
- **MetalLB Version**: v0.15.3
- **Cluster**: Omni-managed (3 control planes + 1 worker)
- **Network**: 192.168.7.0/24
- **IP Pool**: 192.168.7.200-192.168.7.250

## ✅ Working Configuration

MetalLB L2 mode is now successfully announcing LoadBalancer services. This document covers the working configuration and troubleshooting steps.

## Configuration

### 1. MetalLB Helm Chart (via ArgoCD)

File: `infrastructure/infrastructure-apps.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: metallb-helm
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  project: default
  source:
    repoURL: https://metallb.github.io/metallb
    chart: metallb
    targetRevision: 0.15.3
    helm:
      releaseName: metallb
      values: |
        speaker:
          ignoreExcludeLB: true  # CRITICAL: Ignore exclude-from-external-load-balancers labels
          secretName: metallb-memberlist
  destination:
    server: https://kubernetes.default.svc
    namespace: metallb-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
```

**Key Setting**: `speaker.ignoreExcludeLB: true` - This tells MetalLB to ignore the `node.kubernetes.io/exclude-from-external-load-balancers` label that Talos automatically applies to control plane nodes.

### 2. IPAddressPool Configuration

File: `infrastructure/metallb/config/ipaddresspool.yaml`

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: main-pool
  namespace: metallb-system
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  addresses:
  - 192.168.7.200-192.168.7.250
```

### 3. L2Advertisement Configuration

File: `infrastructure/metallb/config/l2advertisement.yaml`

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-adv
  namespace: metallb-system
  annotations:
    argocd.argoproj.io/sync-wave: "2"
spec:
  ipAddressPools:
  - main-pool
  interfaces:
  - eth0  # REQUIRED: Specify the network interface for L2 announcements
```

**Critical**: The `interfaces` field MUST be specified. Without it, MetalLB will not create ServiceL2Status resources or announce services.

### 4. Service Configuration

#### Working: Cluster Traffic Policy

```yaml
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: traefik
  annotations:
    metallb.universe.tf/loadBalancerIPs: "192.168.7.203"  # Deprecated but functional
spec:
  type: LoadBalancer
  externalTrafficPolicy: Cluster  # RECOMMENDED: Works reliably
  ports:
    - name: web
      port: 80
    - name: websecure
      port: 443
```

#### Not Working: Local Traffic Policy

```yaml
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local  # ⚠️ DOES NOT WORK with current configuration
```

**Issue**: `externalTrafficPolicy: Local` does not work with MetalLB L2 on this cluster, even after:
- Removing `node.kubernetes.io/exclude-from-external-load-balancers` labels
- Setting `speaker.ignoreExcludeLB: true`
- Ensuring pods are ready on announcing nodes

**Trade-off**: Using `Cluster` policy means client source IPs are not preserved (they appear as node IPs), but the service is fully functional.

## Critical Troubleshooting Steps

### Issue 1: No ServiceL2Status Resources Created

**Symptoms**:
- LoadBalancer IPs assigned but not reachable
- No ServiceL2Status resources exist
- Speaker logs show reconciliation but no announcements

**Root Cause**: `node.kubernetes.io/exclude-from-external-load-balancers` label on nodes

**Solution**:
```bash
# Remove the label from all nodes
kubectl label nodes --all node.kubernetes.io/exclude-from-external-load-balancers-

# Restart MetalLB speakers to pick up the change
kubectl delete pods -n metallb-system -l app.kubernetes.io/component=speaker
```

**Why This Happens**:
- Talos adds this label to control plane nodes automatically
- Even with `speaker.ignoreExcludeLB: true`, the label can interfere with L2 announcements
- The label sometimes has an empty value `""` which MetalLB doesn't ignore properly

**Permanent Fix**: The label may be re-added by Talos. Monitor and remove as needed.

### Issue 2: L2Advertisement Missing Interface

**Symptoms**:
- MetalLB controller and speakers running
- IPs allocated but no ServiceL2Status created
- No errors in logs

**Root Cause**: Missing `interfaces` specification in L2Advertisement

**Solution**: Add the interfaces field:
```yaml
spec:
  ipAddressPools:
  - main-pool
  interfaces:
  - eth0  # Add this!
```

### Issue 3: externalTrafficPolicy: Local Not Working

**Symptoms**:
- Service with `externalTrafficPolicy: Local` gets IP but no ServiceL2Status
- Speaker logs show "serviceWithdrawn" with "reason: notOwner"
- Switching to `Cluster` policy immediately creates ServiceL2Status

**Root Cause**: Unknown - likely incompatibility between MetalLB L2 and Local policy on Talos/Omni

**Solution**: Use `externalTrafficPolicy: Cluster` instead
```yaml
spec:
  externalTrafficPolicy: Cluster
```

**Impact**: Client source IPs are not preserved with Cluster policy

## Verification Commands

### Check ServiceL2Status (should exist for each announced service)
```bash
kubectl get servicel2status -A
```

Expected output:
```
NAMESPACE        NAME       ALLOCATED NODE   SERVICE NAME       SERVICE NAMESPACE
metallb-system   l2-qkvhs   talos-vod-aam    traefik            traefik
metallb-system   l2-ncrqw   talos-vod-aam    my-nginx           default
```

### Check Service IP Assignment
```bash
kubectl get svc -A --field-selector spec.type=LoadBalancer
```

### Test Connectivity
```bash
# Should return HTTP response
curl -k https://192.168.7.203

# ICMP ping may not work (LoadBalancers often don't respond to ICMP)
ping 192.168.7.203
```

### Check Node Labels
```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,EXCLUDE:.metadata.labels.node\\.kubernetes\\.io/exclude-from-external-load-balancers
```

Should show `<none>` for all nodes.

### Check MetalLB Speaker Logs
```bash
kubectl logs -n metallb-system -l app.kubernetes.io/component=speaker -c speaker --tail=50
```

Look for:
- `start reconcile: <namespace>/<service>` - Service is being processed
- No errors about excluded nodes
- Config reconciliation completing successfully

### Check MetalLB Controller Logs
```bash
kubectl logs -n metallb-system -l app.kubernetes.io/component=controller --tail=50
```

Look for:
- IP allocation messages
- No errors about sharing keys or allocation failures

## Static IP Assignment

### Current Method (Deprecated)
```yaml
metadata:
  annotations:
    metallb.universe.tf/loadBalancerIPs: "192.168.7.203"
```

This annotation is deprecated in MetalLB v0.15.3 but still functional. A deprecation warning will appear in controller logs.

### Alternative Method
Create service-specific IPAddressPool or use MetalLB's native IP assignment.

## Common Issues and Solutions

### Services Being Withdrawn Immediately
**Logs**: `"event":"serviceWithdrawn","reason":"notOwner"`

**Causes**:
1. `externalTrafficPolicy: Local` with pod not on announcing node
2. Node has exclude label
3. Pod not ready

**Solution**: Switch to `externalTrafficPolicy: Cluster`

### No IP Allocated
**Check**: Verify IPAddressPool is created and has available IPs

```bash
kubectl get ipaddresspool -n metallb-system main-pool -o yaml
```

### IP Conflict Errors
**Logs**: `"error":"can't change sharing key for \"namespace/service\", address also in use by other/service"`

**Solution**:
- Check if another service is using the same IP
- Verify annotation format (should use `metallb.universe.tf/` not `metallb.io/`)
- Delete and recreate conflicting services

### Jellyfin Service Example Issue
Encountered error with jellyfin-service using old annotation format:
```yaml
# ❌ Old format (don't use)
annotations:
  metallb.io/loadBalancerIPs: "192.168.7.202"

# ✅ Correct format
annotations:
  metallb.universe.tf/loadBalancerIPs: "192.168.7.202"
```

## Deployment Order (ArgoCD Sync Waves)

```
Wave 0: MetalLB Helm Chart
Wave 1: IPAddressPool + cert-manager Helm
Wave 2: L2Advertisement + cert-manager config
Wave 3: Traefik Helm
Wave 4: Traefik config
Wave 5+: Applications
```

This ensures MetalLB is fully operational before services request LoadBalancer IPs.

## Working Services

Current successfully announced services:
- `traefik/traefik` - 192.168.7.203
- `default/my-nginx` - 192.168.7.201
- `default/nginx-lb-service` - 192.168.7.200

All using `externalTrafficPolicy: Cluster`

## Known Limitations

1. **externalTrafficPolicy: Local** - Does not work, use Cluster instead
2. **Client Source IP** - Not preserved with Cluster policy (IPs appear as node IPs)
3. **Node Labels** - May need to periodically remove exclude-from-external-load-balancers label
4. **Deprecated Annotation** - `metallb.universe.tf/loadBalancerIPs` is deprecated but still works

## Files Modified

- `infrastructure/infrastructure-apps.yaml` - MetalLB Helm configuration with ignoreExcludeLB
- `infrastructure/metallb/config/ipaddresspool.yaml` - IP pool definition
- `infrastructure/metallb/config/l2advertisement.yaml` - L2 advertisement with eth0 interface
- `infrastructure/traefik/traefik-helmchart.yaml` - Traefik with Cluster traffic policy

## References

- MetalLB Documentation: https://metallb.universe.tf/
- MetalLB v0.15.3 Release Notes: https://github.com/metallb/metallb/releases/tag/v0.15.3
- Talos Linux Documentation: https://www.talos.dev/
- Omni Platform: https://www.siderolabs.com/platform/saas-for-kubernetes/

## Resolution Timeline

1. **Initial Issue**: L2 announcements not working despite correct configuration
2. **First Fix**: Added `interfaces: [eth0]` to L2Advertisement
3. **Second Fix**: Removed `node.kubernetes.io/exclude-from-external-load-balancers` labels from all nodes
4. **Third Fix**: Added `speaker.ignoreExcludeLB: true` to Helm values
5. **Final Configuration**: Changed Traefik to `externalTrafficPolicy: Cluster`

Result: ✅ MetalLB L2 fully operational with all services reachable on assigned IPs

## Conclusion

MetalLB L2 mode is now working successfully on Talos Linux 1.12.0 / Kubernetes 1.34.2 with the following requirements:

1. ✅ `speaker.ignoreExcludeLB: true` in Helm values
2. ✅ `interfaces: [eth0]` in L2Advertisement
3. ✅ Remove `node.kubernetes.io/exclude-from-external-load-balancers` labels from nodes
4. ✅ Use `externalTrafficPolicy: Cluster` for services

This configuration provides reliable LoadBalancer functionality for the cluster.
