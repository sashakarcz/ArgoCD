# MetalLB L2 Troubleshooting on Talos Linux

## Environment
- **Talos Version**: 1.12.0
- **Kubernetes Version**: 1.35.0
- **MetalLB Version**: Upgraded from v0.14.8 to v0.15.3
- **Cluster**: 4 control-plane nodes (talos-dmu-u04, talos-geg-yo3, talos-atc-eq8, talos-wg3-7g1)
- **Network**: 192.168.7.0/24

## Problem Statement
MetalLB L2 mode is not announcing LoadBalancer services via ARP, preventing external access to services like Traefik despite correct IP assignment.

## Steps Taken

### 1. Initial MetalLB Installation (v0.14.8)
```bash
helm install metallb metallb/metallb --namespace metallb-system --version 0.14.8 \
  --create-namespace \
  --set controller.tolerations[0].key="node-role.kubernetes.io/control-plane" \
  --set controller.tolerations[0].operator="Exists" \
  --set controller.tolerations[0].effect="NoSchedule" \
  --set speaker.tolerations[0].key="node-role.kubernetes.io/control-plane" \
  --set speaker.tolerations[0].operator="Exists" \
  --set speaker.tolerations[0].effect="NoSchedule"
```

### 2. Fixed PodSecurity Issues
MetalLB speaker pods require privileged access. Applied labels:
```bash
kubectl label namespace metallb-system \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged \
  --overwrite
```

### 3. Talos Machine Configuration
Applied to `/home/sasha/ArgoCD/cluster/talos/patch.yaml`:

```yaml
cluster:
  allowSchedulingOnControlPlanes: true
  proxy:
    mode: ipvs
    extraArgs:
      ipvs-strict-arp: "true"  # Required for MetalLB L2
machine:
  nodeLabels:
    node.kubernetes.io/exclude-from-external-load-balancers: ""
  kubelet:
    extraArgs:
      node-labels: node.kubernetes.io/exclude-from-external-load-balancers=false
    extraMounts:
      - destination: /var/lib/longhorn
        type: bind
        source: /var/lib/longhorn
        options:
          - rw
          - rshared
          - bind
  network:
    firewall:
      rules:
        - name: metallb-memberlist
          portRanges:
            - 7946
          protocol: tcp
          ingress:
            - subnet: 192.168.7.0/24
    interfaces:
      - deviceSelector:
          busPath: 0*
        dhcp: true
        vip:
          ip: 192.168.7.69
    nameservers:
      - 192.168.7.1
      - 1.1.1.1
  disks:
    - device: /dev/sdb
      partitions:
        - mountpoint: /var/lib/longhorn
```

**Note**: Firewall configuration was added to patch.yaml but may not be supported in all Talos versions.

### 4. Disabled tx-checksum-ip-generic
MetalLB L2 requires hardware offloading to be disabled. Created DaemonSet:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: disable-tx-checksum
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: disable-tx-checksum
  template:
    metadata:
      labels:
        name: disable-tx-checksum
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: disable-offload
        image: nicolaka/netshoot:latest
        command:
        - /bin/bash
        - -c
        - |
          ethtool -K eth0 tx-checksum-ip-generic off || true
          echo "Disabled tx-checksum-ip-generic on eth0"
          sleep infinity
        securityContext:
          privileged: true
      tolerations:
      - effect: NoSchedule
        key: node-role.kubernetes.io/control-plane
        operator: Exists
```

**Verification**:
```bash
kubectl exec -n kube-system disable-tx-checksum-xxxxx -- ethtool -k eth0 | grep "tx-checksum-ip-generic"
# Output: tx-checksum-ip-generic: off
```

### 5. MetalLB Configuration
Created IPAddressPool and L2Advertisement:

**IPAddressPool** (`infrastructure/metallb/config/ipaddresspool.yaml`):
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

**L2Advertisement** (`infrastructure/metallb/config/l2advertisement.yaml`):
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
  # NOTE: interfaces specification was removed - let MetalLB auto-detect
```

### 6. Upgraded to MetalLB v0.15.3
```bash
# Uninstall old version
helm uninstall metallb -n metallb-system

# Wait for cleanup
kubectl wait --for=delete pod -l app.kubernetes.io/name=metallb -n metallb-system --timeout=60s

# Install v0.15.3
helm install metallb metallb/metallb --namespace metallb-system --version 0.15.3 \
  --set controller.tolerations[0].key="node-role.kubernetes.io/control-plane" \
  --set controller.tolerations[0].operator="Exists" \
  --set controller.tolerations[0].effect="NoSchedule" \
  --set speaker.tolerations[0].key="node-role.kubernetes.io/control-plane" \
  --set speaker.tolerations[0].operator="Exists" \
  --set speaker.tolerations[0].effect="NoSchedule"

# Reapply configuration
kubectl apply -f infrastructure/metallb/config/
```

## Current Status

### ✅ Working
1. MetalLB controller and speaker pods are running (4/4 pods ready)
2. IP addresses are being assigned to LoadBalancer services
3. Traefik service has EXTERNAL-IP: 192.168.7.201
4. ARP responders are created on eth0 interface
5. strictARP is enabled in kube-proxy
6. tx-checksum-ip-generic is disabled on all nodes
7. MetalLB ConfigurationState shows all speakers as "Valid"
8. NodePort access works (http://192.168.7.57:32373)

### ❌ Not Working
1. **No L2 advertisements**: No ServiceL2Status resources are created
2. **No external connectivity**: LoadBalancer IPs (192.168.7.200, 192.168.7.201) are unreachable
3. **No ARP entries**: `ip neigh show` does not show MetalLB IPs
4. **No announcement logs**: Speaker logs show service reconciliation but no actual announcements

### Diagnostics

**Check speaker logs**:
```bash
kubectl logs -n metallb-system -l app.kubernetes.io/component=speaker -c speaker --tail=100
```

**Observations**:
- Services are being reconciled: `start reconcile: traefik/traefik`
- Config is reloaded: `config reloaded`
- ARP responder created: `created ARP responder for interface: eth0`
- BUT no logs like: `announcing from node` or `layer2 announcement`

**Check ServiceL2Status** (should exist but doesn't):
```bash
kubectl get servicel2status -n metallb-system
# Output: No resources found
```

**Check service assignment**:
```bash
kubectl get svc -n traefik traefik
# Shows EXTERNAL-IP assigned but not announced
```

**Test connectivity**:
```bash
# NodePort works
curl http://192.168.7.57:32373
# Output: 404 page not found (expected - Traefik is working)

# LoadBalancer IP doesn't work
curl http://192.168.7.201
# Output: Connection timed out
```

## Possible Root Causes

1. **Kubernetes 1.35.0 Compatibility**: MetalLB v0.15.3 may not fully support K8s 1.35.0 (released Dec 2025)
   - MetalLB v0.15.3 released in 2024
   - May have breaking changes in K8s API usage

2. **Talos-Specific Issues**: Without Omni, certain network configurations may not be available
   - EthernetConfig CRD not available in standard Talos
   - Firewall configuration may not be properly applied
   - Network plugin (Flannel) interaction unclear

3. **Missing Configuration**: v0.15.x may require additional configuration not documented
   - Possible node selector requirements
   - L2Advertisement changes

## Verification Steps

**Verify strictARP**:
```bash
kubectl get cm -n kube-system kube-proxy -o yaml | grep strictARP
# Should show: strictARP: true
```

**Verify memberlist** (for v0.14.8):
```bash
kubectl logs -n metallb-system -l app.kubernetes.io/component=speaker | grep "memberlist join"
# v0.14.8: Should show "memberlist join successfully"
```

**Verify endpoints**:
```bash
kubectl get endpoints -n traefik traefik
# Should show endpoints for Traefik pods
```

## Tested Versions
- ❌ MetalLB v0.14.8: IP assignment works, L2 announcements fail
- ❌ MetalLB v0.14.9: Not fully tested (attempted during troubleshooting)
- ❌ MetalLB v0.15.3: IP assignment works, L2 announcements fail (same behavior as v0.14.8)

## Next Steps to Try

1. **Test with older Kubernetes version** (1.33 or 1.34)
   - May have better MetalLB compatibility

2. **Try BGP mode instead of L2**
   - Requires BGP router configuration
   - May be more reliable than L2 on Talos

3. **Use Kube-VIP instead of MetalLB**
   - Alternative LoadBalancer implementation
   - May have better Talos support

4. **Pivot to different Kubernetes distribution**
   - RKE2: Enterprise-focused, similar to Talos
   - Kairos: Immutable OS like Talos but different architecture
   - K3s: Lightweight, well-tested with MetalLB

5. **Debug at network level**
   - Use tcpdump to capture ARP traffic
   - Check if speakers are even attempting to send ARP announcements
   - Verify no nftables/iptables rules blocking ARP

## Files Modified

- `/home/sasha/ArgoCD/cluster/talos/patch.yaml` - Talos machine configuration
- `/home/sasha/ArgoCD/infrastructure/metallb/metallb-helmchart.yaml` - Updated to v0.15.3
- `/home/sasha/ArgoCD/infrastructure/metallb/config/ipaddresspool.yaml` - IP pool configuration
- `/home/sasha/ArgoCD/infrastructure/metallb/config/l2advertisement.yaml` - L2 advertisement config

## References

- MetalLB Documentation: https://metallb.universe.tf/
- Talos Linux Documentation: https://www.talos.dev/
- MetalLB GitHub Issues: Check for K8s 1.35 compatibility issues
- Previous working setup: `/home/sasha/k8s/metallb-l2-config.yaml` (with Omni)

## Conclusion

Despite extensive troubleshooting and upgrading to the latest MetalLB version (v0.15.3), L2 announcements are not functioning on this Talos Linux 1.12.0 / Kubernetes 1.35.0 cluster. The issue appears to be related to either:
- Kubernetes 1.35.0 compatibility
- Talos-specific networking limitations without Omni
- Missing/undocumented configuration requirements in MetalLB v0.15.x

**Recommendation**: Consider testing with Kubernetes 1.33/1.34 or evaluating alternative solutions (Kube-VIP, BGP mode, or different K8s distribution).
