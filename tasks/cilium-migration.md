# Flannel → Cilium CNI Migration

## OUTCOME (completed 2026-06-16)
DONE and verified green: Cilium 1.19.4 on all 5 nodes, 0 not-ready pods,
Longhorn 37/37 healthy, MetalLB all 10 LB IPs intact, ArgoCD apps Healthy,
Hubble UI live at https://hubble.starnix.net. kube-proxy retained (KPR = future).

### What went wrong + the key lesson
The cutover wedged Longhorn for ~30 min. Root cause: a mass
`kubectl rollout restart deploy,sts,ds` does NOT cover operator-managed
STANDALONE pods -- specifically Longhorn `instance-manager` pods. They kept
running with their old flannel netns (now dead; Cilium can't retrofit a running
pod's networking), so longhorn-manager → instance-manager:8501 TCP was silently
dropped (SYN blackholed → i/o timeout), while pod→service/DNS still worked. That
froze every volume. Fix: find all non-hostNetwork pods created BEFORE the
cutover and force-delete them so they recreate on Cilium.

Secondary cleanup after the storage recovered:
- RWO Multi-Attach deadlocks from duplicate ReplicaSets (rollout left old+new
  pods both claiming one volume) -> delete the stale ReplicaSet.
- Prometheus CrashLoop (exit 137) -> node-level OOM during the restart thundering
  herd (no mem limit, overcommitted node). Resolved by restarting once settled.

### Diagnostic that saved a needless rollback
`nc` to a closed port returns "refused" (RST); a policy/blackhole drop returns
"timeout". CoreDNS pod TCP = refused/succeeded (dataplane fine), instance-manager
TCP = timeout (that pod's netns dead). Proved Cilium itself was healthy.


## Why
Flannel does not enforce NetworkPolicy. Migrating to Cilium enables real
pod-level network policy cluster-wide (the original goal: lock down the
aur-mirror builder's egress so a malicious build can't reach Vault / internal
services), plus Hubble flow observability.

## Cluster facts (gathered 2026-06-15)
- Talos v1.12.0, Kubernetes v1.34.2, 5 nodes (talos-dg8/hb1/p93 = control-plane,
  talos-1yg/zv2 = workers)
- Pod CIDR: `10.244.0.0/16` (per-node /24, kube-controller allocated)
- Service CIDR: `10.96.0.0/12` (kubernetes svc = 10.96.0.1)
- Flannel + kube-proxy are **Talos-managed** (deployed because
  `cluster.network.cni.name: flannel`, `cluster.proxy.disabled: false`)
- Managed via **Omni** — machine config changes go through `omnictl apply
  configpatch`, NOT direct talosctl (Omni blocks `talosctl patch mc`)
- KubePrism available at `localhost:7445` (use for Cilium k8sServiceHost so it
  reaches the API without depending on a kube-proxy service VIP)

## Design decisions
1. **Dataplane-only swap first; keep kube-proxy.** Cilium runs with
   `kubeProxyReplacement=false` alongside the existing kube-proxy. This isolates
   the change to the CNI dataplane. KPR (`cluster.proxy.disabled: true`) is a
   SEPARATE, later pass once Cilium is proven stable. (Deviation from the
   AskUserQuestion preview, which showed proxy.disabled — deferring it lowers
   blast radius.)
2. **Reuse existing CIDRs** via `ipam.mode: kubernetes` — Cilium uses the
   per-node podCIDRs Talos already assigns. No renumbering, no CIDR conflict.
3. **Bootstrap out-of-band via Helm**, not ArgoCD. cilium-agent runs in the host
   netns, so it comes up with no CNI present — solving the chicken-and-egg
   (ArgoCD pods need CNI to run, so ArgoCD can't install the CNI). Adopt into
   ArgoCD AFTER it's validated.
4. **Disruptive cutover in a maintenance window** (recommended for a 5-node
   homelab): simpler and faster than Cilium's per-node dual-overlay migration.
   In-cluster services blip while pods restart onto Cilium; the API/control
   plane stay up (host network). Per-node low-downtime migration is the
   alternative if a window isn't acceptable.

## MetalLB coverage (verified 2026-06-15)
MetalLB was hard-won; it must survive the cutover untouched. Status:
- **Mode**: L2 (L2Advertisement on interface `eth0`), pool `192.168.7.206-250`
- **Speaker is `hostNetwork: true`** → announces via the node's eth0 directly,
  independent of pod networking, so the CNI swap doesn't break announcements
- **Cilium LB features DISABLED** in our values (`enableLBIPAM: false`,
  `loadBalancer.l2.enabled: false`, `bgpControlPlane.enabled: false`) →
  Cilium can never claim a LoadBalancer service; MetalLB stays sole owner.
  (Cilium ships `enable-lb-ipam: true` by default — this is the key override.)
- **kube-proxy retained** (pass 1) → LoadBalancer datapath unchanged
- **eth0 unchanged**: Cilium adds cilium_host/lxc* but does NOT rename the host
  NIC, so the L2Advertisement `eth0` pin stays valid (confirm in validation)

### Baseline LoadBalancer IPs (must all return identical after cutover)
```
authentik/authentik-ldap     192.168.7.212  Cluster
authentik/authentik-radius   192.168.7.213  Cluster
borgwarehouse/borgwarehouse  192.168.7.209  Cluster
cometdb/cometdb-service      192.168.7.233  Cluster
jellyfin/jellyfin-service    192.168.7.208  Cluster
knot/knot                    192.168.7.211  Cluster
rustdesk/rustdesk-hbbr+hbbs  192.168.7.221  Cluster
traefik/traefik              192.168.7.207  Cluster   (ingress -- most critical)
wazuh/wazuh-manager-lb       192.168.7.220  Local     (extTrafficPolicy Local -- watch closely)
```

### MetalLB validation (add to Phase 3)
- [ ] All 5 `metallb-speaker` pods Running (hostNetwork); `metallb-controller` Running
- [ ] Every LB service above still has its SAME external IP (no reassignment)
- [ ] `ping`/curl traefik `192.168.7.207` from the LAN (ingress reachable)
- [ ] wazuh `192.168.7.220` (Local policy) reachable -- announced from its pod's node
- [ ] No `CiliumLoadBalancerIPPool` exists; `cilium` configmap shows `enable-lb-ipam: false`
- [ ] MetalLB speaker logs show L2 announcements on eth0 (no interface errors)

## Open questions (confirm before executing)
- [ ] Maintenance window acceptable? (expect minutes of in-cluster service
      disruption — ingress, DNS, ArgoCD, apps — while pods restart)
- [ ] Can you run the Omni `omnictl apply` steps (via `!` in session or Omni UI)?
      I'll provide exact configpatch YAML; I can't run omnictl from my shell.
- [ ] Disruptive-window vs per-node low-downtime strategy?

## Plan

### Phase 0 — Prep & safety (no cluster changes)
- [ ] Snapshot current Omni machine config / configpatches for rollback
- [ ] Confirm Longhorn volumes healthy + recent backups (pods will restart)
- [ ] Render Cilium Helm values; `helm template` and eyeball the output
- [ ] Pin Cilium version compatible with k8s 1.34 (latest stable, e.g. 1.16.x —
      verify at execution time)
- [ ] Write the ArgoCD Application for post-bootstrap adoption (not applied yet)

### Phase 1 — Cilium values (per official Sidero "Cilium on Talos" guide)
```yaml
ipam:
  mode: kubernetes
kubeProxyReplacement: false          # keep kube-proxy for pass 1 (KPR = later)
# Talos-specific: Talos blocks kernel-module loading by workloads, so SYS_MODULE
# is DROPPED from Cilium's default agent capabilities. Use this exact set:
securityContext:
  capabilities:
    ciliumAgent:
      - CHOWN
      - KILL
      - NET_ADMIN
      - NET_RAW
      - IPC_LOCK
      - SYS_ADMIN
      - SYS_RESOURCE
      - DAC_OVERRIDE
      - FOWNER
      - SETGID
      - SETUID
    cleanCiliumState:
      - NET_ADMIN
      - SYS_ADMIN
      - SYS_RESOURCE
cgroup:
  autoMount:
    enabled: false
  hostRoot: /sys/fs/cgroup
operator:
  replicas: 2
hubble:
  enabled: true
  relay:
    enabled: true
# When we later do KPR (Phase 6), ADD:
#   kubeProxyReplacement: true
#   k8sServiceHost: localhost
#   k8sServicePort: 7445   (Talos KubePrism)
```
- [ ] Official guide's preferred method is templating Cilium via helm into the
      Talos machine config (inline manifest). For an EXISTING running cluster we
      bootstrap via `helm install` (cilium-agent is host-netns, comes up without
      CNI), then adopt into GitOps (Phase 4). Equivalent end state.
- [ ] Expect nodes to "hang on phase 18/19" until CNI is up — documented, normal.

### Phase 2 — Cutover (maintenance window)
- [ ] Omni configpatch: set `cluster.network.cni.name: none`
      (leave `cluster.proxy.disabled: false` — keep kube-proxy)
- [ ] Apply via `omnictl apply configpatch` (USER runs)
- [ ] Remove Talos-managed flannel: `kubectl -n kube-system delete ds kube-flannel`
      (and any flannel CNI conf left on nodes — Talos stops writing it at cni:none)
- [ ] `helm install cilium cilium/cilium -n kube-system -f values.yaml`
- [ ] Wait for cilium DaemonSet Ready on all 5 nodes (`cilium status --wait`)
- [ ] Restart all workloads so pods get Cilium IPs:
      `kubectl rollout restart` deploys/daemonsets, or reboot nodes one at a time
- [ ] If nodes were rebooted, drain/uncordon one at a time to limit disruption

### Phase 3 — Validate
- [ ] `cilium status` / `cilium connectivity test`
- [ ] DNS resolution in-cluster (CoreDNS) + node DNS (KubePrism/hostDNS)
- [ ] Ingress works (traefik LB 192.168.7.203/207), cert-manager, ExternalDNS
- [ ] ArgoCD reconciles; apps Healthy
- [ ] Pod-to-pod, pod-to-service, pod-to-internet
- [ ] Confirm a test NetworkPolicy is now ENFORCED (deny test)

### Phase 4 — Adopt into GitOps
- [ ] Commit Cilium ArgoCD Application (Helm) so it's declarative
- [ ] Reconcile; confirm no drift vs the helm-installed release

### Phase 5 — Deliver the original goal
- [ ] Apply the aur-mirror builder NetworkPolicy (default-deny egress; allow
      DNS + internet + pushgateway; deny RFC1918/cluster/Vault)
- [ ] Verify enforcement (builder can reach AUR/internet, cannot reach Vault)
- [ ] (Later, optional) Phase 6: enable Cilium kube-proxy replacement
      (`cluster.proxy.disabled: true`, `kubeProxyReplacement: true`)

## Exact cutover sequence (validated 2026-06-15, ready to run)
Prep done: configpatch snapshotted, `infrastructure/cilium/values.yaml` renders
clean (36 objects, no SYS_MODULE, ipam=kubernetes, KPR off), chart pinned 1.19.4,
omnictl v1.8.2 authenticated, Longhorn all healthy, flannel DS = `kube-flannel`.

```
OMNI="/tmp/omnictl --omniconfig /home/sasha/Downloads/omniconfig.yaml"

# 1. Flip CNI to none in the Omni machine config (keep kube-proxy)
$OMNI get configpatch 200-talos-default -o yaml \
  | sed 's/^\(              name: \)flannel/\1none/' > /tmp/cp-none.yaml
$OMNI apply -f /tmp/cp-none.yaml            # triggers config reconcile on nodes

# 2. Remove the Talos-managed Flannel daemonset (no longer reconciled at cni:none)
kubectl -n kube-system delete daemonset kube-flannel

# 3. Bootstrap Cilium (agent is host-netns; comes up with no CNI present)
helm install cilium cilium/cilium --version 1.19.4 -n kube-system \
  -f infrastructure/cilium/values.yaml

# 4. Wait for Cilium ready on all 5 nodes
kubectl -n kube-system rollout status ds/cilium --timeout=300s
cilium status --wait   # if cilium-cli installed; else check pods

# 5. Restart all workloads so pods get Cilium IPs (flannel IPs are now stale)
kubectl get ns -o name | sed 's|namespace/||' | while read ns; do
  kubectl -n "$ns" rollout restart deploy,ds,sts 2>/dev/null
done
# (CoreDNS, Traefik, ArgoCD, Longhorn mgr, apps -- watch them come Ready)

# 6. Validate (Phase 3 checklist)
```

## Rollback (keep ready throughout)
- [ ] Revert Omni configpatch to `cni.name: flannel`
- [ ] `helm uninstall cilium -n kube-system`
- [ ] Talos redeploys flannel + CNI conf; restart pods
- [ ] Needs Omni / console access — do not start without it
