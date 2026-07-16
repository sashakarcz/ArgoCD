# Phase 2: Argo CD 7.7.20 -> 10.1.3 (v2.13 -> v3.4) upgrade plan

**Status:** DONE (2026-07-15). Executed as written. Commits: `5b88033`
(config-only prep), `67e518c` (-> 8.6.4 / v3.1.8), `7a559d8` (-> 10.1.3 /
v3.4.5). Both hops rolled in ~60-75s; fleet stayed green throughout (v3.0
default exclusions even cleared prior drift, 66/2 -> 68/0); the CVE-2026-15416
netpol survived and is now the chart's upstream default. Only the optional
post-upgrade cleanup (section 7) remains. Outcome notes at the bottom of this
file.

**Owner:** Sasha  ·  **Cluster:** Talos, Cilium-enforced, ~68 apps under the
app-of-apps  ·  **Control-plane app:** `argocd-helm` (in
`infrastructure/infrastructure-apps.yaml`, sync-wave 6)

---

## 1. Objective

Move the `argocd-helm` chart pin from **7.7.20** (Argo CD **v2.13.3**) to
**10.1.3** (Argo CD **v3.4.5**) to get onto a maintained line. The v2->v3
boundary is the only hard part; everything else is minor.

| Chart | Argo CD (appVersion) | What lands here |
|-------|----------------------|-----------------|
| 7.7.20 (now) | v2.13.3 | current |
| 8.6.4 | v3.1.8 | **the v2->v3 break** + all chart-8 changes |
| 9.7.1 | v3.4.4 | chart-9 `configs.params` default removal |
| 10.1.3 (target) | v3.4.5 | chart-10 `networkPolicy` default flip |

Recommended path: **2 steps** -- `7.7.20 -> 8.6.4`, then `8.6.4 -> 10.1.3`.
Step 1 absorbs the entire Argo CD v2->v3 behavioral change; step 2 is a
chart-schema catch-up with a trivial v3.1->v3.4 app bump. (A 3-step 8->9->10
walk is available if you want maximum isolation; a single 7->10 jump is
technically fine once the config changes below are pre-applied, but is not
recommended for the control plane itself.)

---

## 2. Pre-flight: what actually applies to THIS cluster

I checked each documented breaking change against the live cluster. Most do
not apply. The short list that DOES:

### 2a. BLOCKER -- CRD client-side-apply annotation limit
- `applications.argoproj.io` CRD carries a **144 KB**
  `kubectl.kubernetes.io/last-applied-configuration` annotation and is
  `managed-by: Helm`. The v3.x Application CRD is larger; a client-side apply
  can exceed the **256 KB** annotation ceiling and fail the sync. The
  `argocd-helm` app currently syncs with only `CreateNamespace=true`.
- **Fix (do this first, see step 3):** apply the target CRDs with server-side
  apply out-of-band, and add `ServerSideApply=true` to the app's syncOptions.

### 2b. Resource tracking flips label -> annotation (v3.0)
- `application.resourceTrackingMethod` is unset (default `label`). At v3.0 the
  default becomes `annotation`, triggering a **relabel of every tracked
  resource across all ~68 apps** on first reconcile -- avoidable churn during
  an already-risky upgrade.
- **Fix:** pin `application.resourceTrackingMethod: label` in `configs.cm`
  BEFORE step 1. Migrate to `annotation` later as its own change (section 7).

### 2c. NetworkPolicy default flip (chart 10.0.0) -- already handled
- Chart 10.x defaults `global.networkPolicy.create` true. We already set it
  `true` explicitly in phase 1, so this is a no-op. Keep the explicit setting
  (documents intent; harmless that it now matches the default). Post-upgrade,
  re-verify component connectivity under Cilium (see 2f).

### 2d. Dead `server.config.repositories` block -- hygiene
- Your values still declare repos under `server.config.repositories`, but
  `server.config` was removed from the chart at 6.0.0, so that block is a
  **silent no-op** today. The real repos are served by two Secrets that exist
  in-cluster but are effectively unmanaged: `repo-1527747537` (the git repo)
  and `vikunja-helm-oci`.
- The v3.0 legacy-repo-config removal (`argocd-cm.repositories`) does **NOT**
  affect you -- that key is empty.
- **Fix (do during the upgrade):** delete the dead `server.config` block and
  redeclare both repos under `configs.repositories` so they are chart-managed.
  Example:
  ```yaml
  configs:
    repositories:
      argocd-repo:
        url: https://github.com/usenix17/ArgoCD.git
        type: git
      vikunja-helm-oci:
        url: ghcr.io/go-vikunja/helm-chart
        type: helm
        enableOCI: "true"
        name: vikunja
  ```
  Verify the generated secret names/labels match what apps reference before
  deleting the old orphan secrets.

### 2e. RBAC -- no action needed
- Only `g, admins, role:admin` plus `policy.default: role:readonly`. The v3.0
  logs-RBAC enforcement and application sub-resource RBAC changes do not bite:
  `role:admin` is wildcard, and v3's `role:readonly` includes `logs, get`.
- Minor: `server.rbac.log.enforce.enable` becomes a dangling no-op key at v3.0
  (flag removed). Cosmetic; drop it if convenient.

### 2f. Cilium interaction -- verify, don't assume
- Per project note: Cilium enforces egress that Flannel used to mask. The
  chart-created NetworkPolicies are already live from phase 1 and Argo is
  healthy, so no new netpols land in this upgrade. Still: after each step,
  confirm controller->repo-server, controller->redis, and server->repo-server
  connectivity (sync works, UI works).

### 2g. Authentik OIDC / PKCE (v3.1) -- verify redirect URI
- At v3.1 (which step 1 crosses, since 8.6.4 = v3.1.8) the OIDC
  authorization-code + PKCE flow is handled by the argocd-server, not the UI.
  Ensure the Authentik argocd provider's redirect URIs include
  **`https://argocd.starnix.net/auth/callback`**. Verify before step 1; test
  an SSO login immediately after.

### 2h. Confirmed NON-issues (checked, no action)
- Legacy `argocd-cm.repositories` removal (v3.0 #6): key is empty.
- `applicationsetcontroller.policy` sync->"" (chart 9): no ApplicationSets exist.
- `applyNestedSelectors` ignored (v3.0 #7): no ApplicationSets exist.
- redis-ha immutable-selector break (chart 9.1.0): single-node redis, not HA.
- redis auth-by-default: already configured (`argocd-redis` secret, 201d old).
- Dex RBAC subject change (v3.0 #5): SSO is direct Authentik OIDC, not via Dex.
- `server.insecure` / server TLS: unchanged by the v3.0 guide (keep as-is; do
  NOT flip without moving Traefik to an HTTPS backend).

---

## 3. Backups (before touching anything)

```sh
mkdir -p ~/argocd-upgrade-backup && cd ~/argocd-upgrade-backup
kubectl -n argocd get applications.argoproj.io -o yaml > applications.yaml
kubectl -n argocd get appprojects.argoproj.io  -o yaml > appprojects.yaml
kubectl -n argocd get cm  argocd-cm argocd-rbac-cm argocd-cmd-params-cm \
        argocd-notifications-cm -o yaml > configmaps.yaml
kubectl -n argocd get secret -l argocd.argoproj.io/secret-type=repository \
        -o yaml > repo-secrets.yaml
kubectl get crd applications.argoproj.io applicationsets.argoproj.io \
        appprojects.argoproj.io -o yaml > crds-v2.yaml
```
Note: Argo CD does **not** support downgrades. Rollback (section 6) is
best-effort; the primary safety net is validating each step before proceeding.

---

## 4. Config changes to pre-apply (single commit, BEFORE the image bump)

In `infrastructure/infrastructure-apps.yaml`, in the `argocd-helm` app:

1. Add under `configs.cm:` -> `application.resourceTrackingMethod: label`
   (prevents the 2b mass relabel).
2. Replace the dead `server.config.repositories` block with the
   `configs.repositories` map from 2d.
3. Add `ServerSideApply=true` to `spec.syncPolicy.syncOptions` (for 2a):
   ```yaml
   syncOptions:
     - CreateNamespace=true
     - ServerSideApply=true
   ```
4. (Optional) remove `server.rbac.log.enforce.enable` if present in values.

Push, let it sync on **7.7.20** (no image change yet), and confirm the app is
Synced/Healthy and the UI + a test sync still work. This isolates the config
migration from the version bump.

---

## 5. The rollout

For the control plane, drive the sync **manually** so you control the moment
and can read the diff. Temporarily set the `argocd-helm` app to manual sync
(or be ready to `argocd app sync argocd-helm` right after each pin bump).

### Step 1: 7.7.20 -> 8.6.4  (Argo CD v2.13 -> v3.1.8) -- the big one
1. Pre-apply the target CRDs server-side (avoids 2a):
   ```sh
   kubectl apply --server-side --force-conflicts \
     -k "https://github.com/argoproj/argo-cd/manifests/crds?ref=v3.1.8"
   ```
2. Bump `targetRevision: 7.7.20` -> `8.6.4`. Commit, push.
3. Sync `argocd-helm`, watch the rollout:
   ```sh
   kubectl -n argocd rollout status deploy/argocd-repo-server
   kubectl -n argocd rollout status deploy/argocd-server
   kubectl -n argocd get pods
   ```
4. **Validation gate (must all pass before step 2):**
   - all argocd pods Running, image `v3.1.8`, no CrashLoop;
   - `argocd-helm` app Synced/Healthy;
   - UI `https://argocd.starnix.net` -> HTTP 200, **SSO login via Authentik
     works** (validates 2g);
   - pick 2-3 apps and force a sync -> Synced/Healthy (validates
     controller->repo-server->git path);
   - fleet still green: no unexpected OutOfSync/Degraded across the ~68 apps;
   - spot-check `kubectl logs` via UI for one app (validates logs RBAC).

### Step 2: 8.6.4 -> 10.1.3  (Argo CD v3.1.8 -> v3.4.5)
1. Pre-apply CRDs for the final version:
   ```sh
   kubectl apply --server-side --force-conflicts \
     -k "https://github.com/argoproj/argo-cd/manifests/crds?ref=v3.4.5"
   ```
2. Bump `targetRevision: 8.6.4` -> `10.1.3`. Commit, push, sync.
3. Re-run the same validation gate. Additionally confirm no values-schema
   warnings from the chart (the chart-9 `configs.params` default removal only
   matters for params you set explicitly -- you set none that changed).

---

## 6. Rollback (best-effort)

Downgrade is unsupported by Argo CD, so treat this as damage control:
1. Revert the pin commit (`targetRevision` back to the last-good chart).
2. The chart redeploys the older component images. CRDs remain at the newer
   schema (a v2 controller generally tolerates a newer Application CRD).
3. If Applications misbehave, re-apply the backed-up v2 CRDs and the
   `applications.yaml` / `appprojects.yaml` from section 3.
Because true rollback is fragile, **do not skip the validation gates** -- catch
problems at step 1 while the blast radius is smallest.

---

## 7. Post-upgrade cleanup (separate change, after 10.1.3 is stable)

- Migrate resource tracking to the v3 default: remove the
  `application.resourceTrackingMethod: label` pin (or set `annotation`) and let
  the one-time relabel happen deliberately, watching for churn.
- Delete the orphaned repo Secrets if `configs.repositories` now manages them.
- Remove any remaining dead config keys (`server.rbac.log.enforce.enable`).
- Consider whether Dex is needed at all (SSO is direct Authentik OIDC); if not,
  `dex.enabled: false` trims a component.

---

## 8. Checklist

- [ ] Backups taken (section 3)
- [ ] Authentik redirect URI includes `/auth/callback` (2g)
- [ ] Config-only commit applied on 7.7.20 and Synced/Healthy (section 4)
- [ ] CRDs server-side-applied @ v3.1.8; pin -> 8.6.4; validation gate passed
- [ ] CRDs server-side-applied @ v3.4.5; pin -> 10.1.3; validation gate passed
- [ ] Fleet green; SSO works; sample syncs work; logs viewable
- [ ] Post-upgrade cleanup scheduled (section 7)

**Sources:** argo-helm chart README "Upgrading" section; Argo CD upgrade guides
2.14-3.0, 3.0-3.1, 3.1-3.2; chart Chart.yaml at tags 7.7.20/8.6.4/9.7.1/10.1.3.

---

## 9. Outcome (2026-07-15)

Went exactly to plan. What actually happened:

- **CRD blocker (2a) was real and cleanly solved.** The `applications`
  CRD's ~144KB client-side annotation dropped to 0 bytes after the
  server-side apply; `argocd-controller` took SSA field ownership. No sync ever
  hit the annotation limit.
- **Config-only commit (`5b88033`) synced clean on 7.7.20** -- `ServerSideApply
  =true` caused zero field-manager churn, proving it safe before any version
  bump. Tracking pin landed in `argocd-cm`.
- **Step 1 (`67e518c`, -> v3.1.8):** self-upgrade rolled all components in ~60s,
  0 restarts. Fleet went 66-Synced/2-OutOfSync -> **68/0** (v3.0 default
  exclusions cleared the pre-existing redis-secret-init hook drift). UI 200,
  OIDC callback 200.
- **Step 2 (`7a559d8`, -> v3.4.5):** rolled in ~75s, 0 restarts, fleet green.
- **CVE-2026-15416 netpol survived** and is now delivered by the chart's own
  `global.networkPolicy.create` default (6 policies); repo-server ingress still
  restricted to server/application-controller/notifications/applicationset.
- **Predicted non-issues all held:** no ApplicationSets, single-node redis,
  redis auth pre-set, direct Authentik OIDC (Dex unused), minimal RBAC. Nothing
  from the v3.0 breaking-change list bit us.
- **SSO confirmed:** full Authentik OIDC login round-trip through the UI worked
  post-upgrade (local admin was the standby fallback, never needed).

Rollback was never needed. Backups remain in `~/argocd-upgrade-backup/`.

**Post-upgrade cleanup -- DONE (2026-07-15):**
- `542141e`: moved both standalone repo Secrets into `configs.repositories`
  (chart now owns `argocd-repo-argocd-repo`, `argocd-repo-vikunja-helm-oci`;
  old `repo-1527747537` + `vikunja-helm-oci` pruned; repo access unchanged) and
  disabled the unused Dex (`dex.enabled: false` -- deploy/svc/pods removed).
- `0cf4bde`: switched resource tracking `label` -> `annotation` (v3 default);
  the one-time relabel wave settled to 68/68 in ~2 min.
- Dead `server.rbac.log.enforce.enable` was already dropped by chart 10.x, so no
  action was needed there.
- Verified no regression: CVE netpol repo-server allowlist intact (netpol count
  6->5 only because Dex removal took its own policy), UI 200, fleet 68/68.
