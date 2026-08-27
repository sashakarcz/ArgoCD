# cloudflared HA on Talos -- Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run cloudflared as a 3-replica HA Deployment on Talos (off the flaky UDM), and rewrite MetalLB-VIP ingress targets to in-cluster service DNS, without bypassing Traefik's Authentik auth.

**Architecture:** cloudflared is outbound-only, so 3 replicas each dial Cloudflare's edge and Cloudflare load-balances across them (no k8s Service). The existing sync-hook keeps managing tunnel config via the CF API. Traefik-fronted routes are re-pointed at the Traefik ClusterIP service; the one standalone LB service (jellyfin) at its own ClusterDNS; LAN/external targets are unchanged.

**Tech Stack:** Kubernetes (Talos), ArgoCD, cloudflared, Cilium NetworkPolicy, ExternalSecrets, existing CF API sync-hook.

**Repo:** `usenix17/ArgoCD`, branch `feat/cloudflared-talos-ha`. All manifests live in the single file `applications/cloudflare/cloudflare.yaml`.

---

## Audit result (baseline, from 2026-08-27)

Bucket A -- Traefik-fronted (resolve to `192.168.7.207`) -> `https://traefik.traefik.svc.cluster.local`:
`aur, media, auth, status, memegen, matrix, db.bairlabs.org, nova, krampus,
sanitydeclines.com, ouija, semaphore, ha, privatebin, help, fleet, tarot,
radiacode, repeater, argocd, project, seafile, clock.bairlabs.org, lofiweather.net`

Bucket B -- standalone k8s LB service -> ClusterDNS:
`jellyfin.starnix.net` -> `http://jellyfin-service.jellyfin.svc.cluster.local:8096`

Bucket C -- genuine LAN/external (UNCHANGED):
`log(.1.151), ipam(.1.86), password(.1.86), music(bork=.1.86), send(.1.86),
llama(.1.86), s3(.1.150), vance(.8.69), python.bairlabs(.1.86), gellyfin(.1.86),
sky.bairlabs(172.16.5.155), warp(.1.106), tron ssh(.1.52)`

Bucket ? -- did NOT resolve from the workstation; **Task 1 must resolve in-cluster**:
`ntfy(ntfy.service.starnix.net), go(go.service.starnix.net),
data.bairlabs.org(metabase.starnix.net), drop(drop.service.starnix.net),
coturn(coturn.service.starnix.net), inv.bidetcams.com(vid.starnix.net)`

---

## Task 1: Finalize the audit (resolve the 6 unknowns in-cluster)

**Files:** none (produces the mapping used by Task 3).

- [ ] **Step 1: Resolve the unknowns from the cluster's DNS view**

Run a throwaway pod (cloudflared will use CoreDNS, so this is the authoritative view):

```bash
kubectl run dnsq --rm -i --restart=Never --image=busybox:1.36 -- sh -c '
for h in ntfy.service.starnix.net go.service.starnix.net metabase.starnix.net \
         drop.service.starnix.net coturn.service.starnix.net vid.starnix.net; do
  echo -n "$h -> "; nslookup "$h" 2>/dev/null | awk "/^Address: /{print \$2}" | tail -1 || echo FAIL
done'
```

- [ ] **Step 2: Classify each resolved IP**

For each returned IP: `192.168.7.207` -> Bucket A (Traefik); a standalone LB IP from `kubectl get svc -A` -> Bucket B (use that service's ClusterDNS); a LAN IP or NXDOMAIN -> Bucket C unchanged. If any name is **NXDOMAIN in-cluster**, that route currently works only via the UDM's resolver and WILL break in-cluster -- flag it: either leave the route pointed at the UDM-served value and keep it out of scope, or add the record to Knot. Do not silently convert an unresolvable name.

- [ ] **Step 3: Record the final mapping**

Append the resolved 6 to the Bucket A/B/C lists above (edit this plan file), so Task 3 has a complete table. This is the review gate: confirm the full 45-route classification before rewriting.

Expected: all 6 resolve to `192.168.7.207` (Bucket A) or a known service; none silently dropped.

---

## Task 2: Add the cloudflared Deployment

**Files:** Modify `applications/cloudflare/cloudflare.yaml` (append a Deployment before the sync-hook Job).

- [ ] **Step 1: Pin the current cloudflared image tag**

```bash
# Get the latest stable tag (pin it, do not use :latest)
crane ls cloudflare/cloudflared 2>/dev/null | grep -E '^20[0-9]{2}\.[0-9]+\.[0-9]+$' | tail -1
# fallback: check https://hub.docker.com/r/cloudflare/cloudflared/tags
```
Use the returned tag (e.g. `2025.11.1`) in Step 2.

- [ ] **Step 2: Add the Deployment**

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared
  namespace: cloudflare
spec:
  replicas: 3
  selector:
    matchLabels: { app: cloudflared }
  template:
    metadata:
      labels: { app: cloudflared }
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector: { matchLabels: { app: cloudflared } }
                topologyKey: kubernetes.io/hostname
      securityContext:
        runAsNonRoot: true
        runAsUser: 65532
      containers:
        - name: cloudflared
          image: cloudflare/cloudflared:PINNED_TAG
          args: ["tunnel", "--no-autoupdate", "--metrics", "0.0.0.0:2000", "--grace-period", "30s", "run"]
          # TUNNEL_TOKEN via env (NOT argv) so the token never appears in the pod spec's command
          env:
            - name: TUNNEL_TOKEN
              valueFrom:
                secretKeyRef: { name: cloudflare-secrets, key: TUNNEL_TOKEN }
          livenessProbe:
            httpGet: { path: /ready, port: 2000 }
            initialDelaySeconds: 10
            periodSeconds: 10
            failureThreshold: 3
          readinessProbe:
            httpGet: { path: /ready, port: 2000 }
            periodSeconds: 10
          resources:
            requests: { cpu: 50m, memory: 64Mi }
            limits: { memory: 128Mi }
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities: { drop: ["ALL"] }
          volumeMounts:
            - { name: tmp, mountPath: /tmp }
      terminationGracePeriodSeconds: 60
      volumes:
        - { name: tmp, emptyDir: {} }
```

- [ ] **Step 3: Validate**

```bash
python3 -c "import yaml; list(yaml.safe_load_all(open('applications/cloudflare/cloudflare.yaml'))); print('YAML OK')"
kubectl apply --dry-run=server -f applications/cloudflare/cloudflare.yaml   # against the live cluster
```
Expected: `YAML OK` and dry-run reports the Deployment as valid (created/configured).

- [ ] **Step 4: Commit**

```bash
git add applications/cloudflare/cloudflare.yaml
git commit -m "feat(cloudflare): add HA cloudflared Deployment on Talos"
```

---

## Task 3: Rewrite ingress targets per the audit

**Files:** Modify the `ingress.yaml` block in the `tunnel-config` ConfigMap.

Transformation rules (apply exactly; **preserve each route's effective Host**):

- **Bucket A**: set `service: https://traefik.traefik.svc.cluster.local`,
  `originRequest.noTLSVerify: true`, and `httpHostHeader:` = the app's public
  hostname (the value Traefik matches on). If the route already has an
  `httpHostHeader`, keep it; if it relied on the target hostname (e.g.
  `service: https://help.starnix.net`), set `httpHostHeader: help.starnix.net`.
- **Bucket B**: `jellyfin.starnix.net` ->
  `service: http://jellyfin-service.jellyfin.svc.cluster.local:8096`
  (keep `noTLSVerify` + `httpHostHeader: jellyfin.service.starnix.net`).
- **Bucket C**: leave unchanged.

- [ ] **Step 1: Rewrite the Bucket A + B routes** in the ConfigMap `ingress.yaml`.

- [ ] **Step 2: Sanity-check no Bucket-A route still points at `192.168.7.207`**

```bash
grep -c '192.168.7.207' applications/cloudflare/cloudflare.yaml   # expect 0 in ingress (may remain in comments)
grep -c 'traefik.traefik.svc.cluster.local' applications/cloudflare/cloudflare.yaml  # expect ~24
```

- [ ] **Step 3: Validate YAML + commit**

```bash
python3 -c "import yaml; list(yaml.safe_load_all(open('applications/cloudflare/cloudflare.yaml'))); print('YAML OK')"
git add applications/cloudflare/cloudflare.yaml
git commit -m "feat(cloudflare): point Traefik-fronted routes at the cluster service"
```

---

## Task 4: Egress NetworkPolicy for cloudflared

**Files:** Append a `CiliumNetworkPolicy` to `applications/cloudflare/cloudflare.yaml`.

- [ ] **Step 1: Add the policy** (allow DNS, Cloudflare edge, Traefik + jellyfin in-cluster, and the LAN CIDRs for Bucket C)

```yaml
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: cloudflared
  namespace: cloudflare
spec:
  endpointSelector: { matchLabels: { app: cloudflared } }
  egress:
    # DNS to CoreDNS
    - toEndpoints: [{ matchLabels: { "k8s:io.kubernetes.pod.namespace": kube-system, "k8s-app": kube-dns } }]
      toPorts: [{ ports: [{ port: "53", protocol: UDP }, { port: "53", protocol: TCP }] }]
    # Cloudflare edge (tunnel): QUIC 7844 + HTTPS 443 to the internet
    - toEntities: ["world"]
      toPorts:
        - ports: [{ port: "7844", protocol: UDP }, { port: "7844", protocol: TCP }, { port: "443", protocol: TCP }]
    # In-cluster: Traefik + jellyfin (and any Bucket-B services)
    - toEndpoints: [{ matchLabels: { "k8s:io.kubernetes.pod.namespace": traefik } }]
      toPorts: [{ ports: [{ port: "443", protocol: TCP }, { port: "80", protocol: TCP }] }]
    - toEndpoints: [{ matchLabels: { "k8s:io.kubernetes.pod.namespace": jellyfin } }]
      toPorts: [{ ports: [{ port: "8096", protocol: TCP }] }]
    # LAN/external Bucket-C targets
    - toCIDR: ["192.168.1.0/24", "192.168.7.0/24", "192.168.8.0/24", "172.16.5.0/24"]
```

- [ ] **Step 2: Validate + commit**

```bash
python3 -c "import yaml; list(yaml.safe_load_all(open('applications/cloudflare/cloudflare.yaml'))); print('YAML OK')"
git add applications/cloudflare/cloudflare.yaml
git commit -m "feat(cloudflare): egress NetworkPolicy for cloudflared"
```

Note: if a Bucket-? name resolved to a service in a namespace other than traefik/jellyfin, add a matching `toEndpoints`/`toCIDR` rule.

---

## Task 5: Deploy and verify in parallel with the UDM

**Files:** none (open a PR; user merges; ArgoCD deploys).

- [ ] **Step 1: Push branch + open PR; user merges.** ArgoCD syncs the Deployment, the netpol, and re-runs the sync-hook (which PUTs the rewritten ingress to Cloudflare). The UDM connector is still running -- both serve the tunnel.

- [ ] **Step 2: Verify the replicas**

```bash
kubectl get pods -n cloudflare -l app=cloudflared -o wide     # 3x Running/Ready, distinct nodes
kubectl get application cloudflare -n argocd -o custom-columns=SYNC:.status.sync.status,HEALTH:.status.health.status
for p in $(kubectl get pods -n cloudflare -l app=cloudflared -o name); do
  kubectl exec -n cloudflare "$p" -- wget -qO- http://127.0.0.1:2000/ready; echo " <- $p"
done
```
Expected: 3 pods Ready on 3 nodes; `/ready` returns `{"status":200,...}` with connector count.

- [ ] **Step 3: Verify Cloudflare sees the new connectors**

Cloudflare dashboard (Zero Trust -> Networks -> Tunnels) shows the cluster connectors healthy alongside the UDM one. The sync-hook log shows `config applied` with the new route count.

- [ ] **Step 4: Spot-check one route per bucket end-to-end**

```bash
# Bucket A (auth still enforced): expect the Authentik login redirect, NOT the app
curl -sSI https://argocd.starnix.net | head -5
# Bucket B
curl -sSI https://jellyfin.starnix.net | head -3
# Bucket C
curl -sSI https://s3.starnix.net | head -3
```
Expected: all reachable; Bucket-A app behind Authentik still challenges for auth (no middleware bypass).

- [ ] **Step 5: Resilience check**

```bash
kubectl delete pod -n cloudflare $(kubectl get pod -n cloudflare -l app=cloudflared -o name | head -1)
curl -sSI https://argocd.starnix.net | head -1   # still works, served by remaining replicas
```

---

## Task 6: Decommission the UDM connector

**Files:** none (manual on the UDM; document only).

- [ ] **Step 1 (user): stop/disable cloudflared on the UDM.** Keep the re-install script as rollback.

- [ ] **Step 2: Confirm the tunnel is now served only by k8s**

```bash
# After the UDM connector stops, re-run the bucket spot-checks; all must still pass.
curl -sSI https://argocd.starnix.net | head -1
curl -sSI https://jellyfin.starnix.net | head -1
curl -sSI https://music.starnix.net | head -1
```
Expected: all still 200/expected; Cloudflare shows only the cluster connectors.

- [ ] **Step 3: Update memory** `project_cloudflare_tunnel.md` -- cloudflared now runs in-cluster (3-replica Deployment in the `cloudflare` ns), NOT on the UDM; error 1033 no longer means "router cloudflared down." Note the Bucket-A -> Traefik-svc routing.

---

## Task 7: Rollback procedure (documented, not executed)

- Re-run the UDM cloudflared re-install script (restores the UDM connector), and/or
- `kubectl scale deploy/cloudflared -n cloudflare --replicas=0` (or revert the PR) to remove the k8s connectors. Because config is remotely-managed, reverting the ingress rewrite requires re-running the sync-hook with the old `ingress.yaml`.

---

## Self-review notes
- Spec coverage: HA Deployment (T2), full audit (T1/T3), Traefik-auth preservation (T3 rule), egress (T4), parallel cutover (T5/T6), rollback (T7) -- all covered.
- The 6 unresolved names are the one genuine unknown; T1 gates on resolving them in-cluster before any rewrite, and explicitly forbids silently converting an NXDOMAIN name.
- Token stays in env (not argv). Image is pinned, not `:latest`.
