# cloudflared on Talos (HA) -- Migration Design

Date: 2026-08-27
Status: Approved (pending spec review)

## Goal

Move the Cloudflare tunnel connector (`cloudflared`) off the UDM router -- where
UniFi firmware updates periodically wipe it, causing unannounced tunnel outages
(Cloudflare error 1033) that only a manual re-install fixes -- and run it in the
Talos/k8s cluster as a highly-available Deployment. While migrating, convert
ingress routes that currently target MetalLB VIPs to in-cluster Kubernetes
service DNS names, so the tunnel no longer depends on the MetalLB L2/ARP path
for traffic it can reach directly in-cluster.

## Background (current state)

- `cloudflared` runs on the **UDM** using `TUNNEL_TOKEN`. The k8s `cloudflare`
  namespace holds only config: a `tunnel-config` ConfigMap (`ingress.yaml`) and a
  **Sync-hook Job** (`apply-tunnel-config`) that PUTs the ingress to the CF API
  and upserts a proxied CNAME (`<tunnel>.cfargotunnel.com`) per hostname.
- Tunnel is **remotely-managed**: the connector pulls its ingress config from
  Cloudflare; the hook is what writes that config via the API.
- Secrets: OpenBao -> ESO -> k8s Secret `cloudflare-secrets` (keys
  `CF_API_TOKEN`, `CF_DNS_TOKEN`, `TUNNEL_TOKEN`). Account
  `f4bee6a7808c0215d33dee04ef9da0e3`, tunnel `ab9094f8-d05c-47d2-b660-1a403a2e739e`.
- ~45 ingress routes. 12 target the Traefik VIP `192.168.7.207`; the rest are a
  mix of `*.starnix.net` DNS names (resolve in-cluster via CoreDNS->Knot) and raw
  LAN/external IPs. CoreDNS already forwards `starnix.net` to Knot in-cluster.

## Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Host | Talos/k8s Deployment (off the UDM) |
| HA / load balancing | **3 replicas** + soft `podAntiAffinity`; Cloudflare edge load-balances across all replica connections (cloudflared is outbound-only, no k8s Service) |
| Tunnel config delivery | Keep **remotely-managed** (`--token`, existing sync-hook PUTs ingress) |
| Ingress conversion | **Full audit**: reclassify every route (see methodology) |
| Traefik-fronted routes | Point at the **Traefik service DNS**, NOT direct-to-app -- preserves Traefik routing + Authentik forward-auth middleware |
| Cutover | **Parallel then decommission**: run k8s alongside the UDM, verify, then remove UDM cloudflared. Zero downtime |
| Rollback | The existing UDM cloudflared re-install script |

## Architecture

```
Internet -> Cloudflare edge --(tunnel: N outbound connections)--> cloudflared Deployment
                                                                   (cloudflare ns, 3 replicas)
                                                                        |
                    +---------------------------+-----------------------+------------------+
                    |                           |                                          |
         traefik.traefik.svc            <app>.<ns>.svc                        LAN/external IPs
         (Traefik-fronted apps,         (standalone k8s LB                    (192.168.1.86 VM,
          keeps middlewares)             services: jellyfin, ...)              bork, warp, sky, ...)
```

cloudflared makes only **outbound** connections to Cloudflare's edge; there is no
inbound listener, so no Service, LoadBalancer, or MetalLB VIP is involved for the
connector itself. Running 3 replicas gives 3x the connections; Cloudflare
distributes requests across them and drops dead ones automatically.

## Components

### 1. cloudflared Deployment (`applications/cloudflare/cloudflare.yaml`)
- Image: `cloudflare/cloudflared:<pinned tag>` (pin, `--no-autoupdate`).
- Replicas: 3; `podAntiAffinity` `preferredDuringScheduling` on hostname.
- Args: `tunnel --no-autoupdate --metrics 0.0.0.0:2000 run --token $(TUNNEL_TOKEN)`
  with `TUNNEL_TOKEN` from `cloudflare-secrets`.
- Probes: `readinessProbe`/`livenessProbe` HTTP GET `/ready` on `:2000`.
- `terminationGracePeriodSeconds: 30` for connection drain; small resource
  requests/limits; run as non-root.

### 2. Config (unchanged mechanism)
- Keep `tunnel-config` ConfigMap + the `apply-tunnel-config` Sync-hook. Only the
  `ingress.yaml` *targets* change (below). cloudflared pulls config from CF via
  `--token`, so the Deployment does not mount `ingress.yaml`.

### 3. Ingress full-audit methodology
Each route is resolved and classified into exactly one bucket. The per-route
mapping table is produced and **reviewed before apply** during implementation, by
cross-referencing every ingress hostname against `kubectl get
svc,ingress,ingressroute -A` and in-cluster DNS resolution.

- **Bucket A -- Traefik-fronted** (currently `https://192.168.7.207`, or a
  `*.starnix.net` name Traefik serves): rewrite to
  `https://traefik.traefik.svc.cluster.local`, keep `noTLSVerify: true` and the
  existing `httpHostHeader`. Rationale: these apps depend on Traefik's routing and
  Authentik forward-auth; pointing cloudflared at the backing service directly
  would bypass authentication.
- **Bucket B -- standalone k8s LB service** (own MetalLB VIP, no Traefik in front;
  e.g. jellyfin `192.168.7.208`): rewrite to the service ClusterDNS
  (`jellyfin-service.jellyfin.svc.cluster.local:8096`), preserving scheme/host
  options.
- **Bucket C -- genuine external/LAN** (`192.168.1.86` VM and its ports,
  `192.168.1.150/151`, `192.168.1.106`, `192.168.8.69`, `172.16.5.155`,
  `bork.starnix.net`, `tron` ssh, etc.): **unchanged**; the pod reaches them over
  the LAN.

### 4. Egress NetworkPolicy (CiliumNetworkPolicy)
cloudflared legitimately talks to many destinations. Allow:
- DNS to kube-dns (CoreDNS).
- Cloudflare edge: TCP/UDP 7844 + TCP 443 to the internet (or CF IP ranges).
- In-cluster: Traefik ClusterIP:443 + the ClusterIPs/pods of Bucket-B services.
- LAN CIDRs for Bucket-C targets (`192.168.1.0/24`, `192.168.7.0/24`,
  `192.168.8.0/24`, `172.16.5.0/24`).

### 5. Cutover (parallel, zero-downtime)
1. Merge the Deployment + rewritten `ingress.yaml`. ArgoCD deploys 3 replicas and
   the sync-hook re-PUTs config.
2. Both k8s replicas and the UDM connector now serve the same tunnel; Cloudflare
   load-balances across all connections.
3. Verify: all 3 pods `/ready`, `cloudflared tunnel info <id>` shows the new
   connectors, and a spot-check of representative hostnames from each bucket
   returns 200 through the tunnel.
4. **Then** stop/disable cloudflared on the UDM.
5. Rollback at any point: re-run the UDM re-install script (the k8s side can also
   be scaled to 0).

## Acceptance criteria
1. 3 cloudflared pods `Running`/`Ready` on distinct nodes; `/ready` returns 200.
2. Cloudflare dashboard/`tunnel info` shows the cluster connectors healthy.
3. Every hostname still resolves end-to-end through the tunnel: at least one
   Bucket-A (Traefik-fronted, auth still enforced), one Bucket-B (standalone
   service), and one Bucket-C (LAN) verified returning expected responses.
4. A Traefik-fronted app behind Authentik still requires auth (no middleware
   bypass).
5. After the UDM connector is stopped, all hostnames continue to work (served
   solely by the k8s replicas).
6. Killing one cloudflared pod does not drop the tunnel (remaining replicas serve).

## Risks / considerations
- **Do not bypass Traefik auth** (Bucket A) -- the single most important
  correctness/security point.
- `*.starnix.net` targets already resolve in-cluster; leaving them as DNS names is
  acceptable, but Bucket-B conversion to ClusterDNS is preferred where a k8s
  service exists (avoids the MetalLB path).
- Egress policy must not be so tight it blackholes a Bucket-C LAN target.
- cloudflared graceful shutdown: use `--grace-period` / termination grace so
  rolling updates don't drop in-flight requests.
- Confirm the `TUNNEL_TOKEN` in `cloudflare-secrets` matches the intended Vault
  secret (`cluster/cloudflare-secret` vs the current `cluster/cloudflared-secrets`
  extract) at implementation.

## Out of scope (v1)
- WARP / private-network (`warp-routing`) exposure of internal subnets.
- Splitting into multiple tunnels or changing the tunnel identity.
- Migrating the sync-hook to locally-managed config.yaml.
