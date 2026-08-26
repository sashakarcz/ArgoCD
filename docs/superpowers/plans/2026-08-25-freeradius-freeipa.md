# FreeRADIUS (FreeIPA-backed) WiFi Auth — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a FreeRADIUS server on Talos/k8s that authenticates FreeIPA `wifi`-group users for WPA-Enterprise (both PEAP-MSCHAPv2 and EAP-TTLS/PAP), with a FreeIPA-CA EAP cert auto-renewed by cert-manager, exposed on a MetalLB UDP listener.

**Architecture:** Raw-manifest k8s app (ns `freeradius`, ArgoCD-managed) mirroring the existing authentik-radius pattern. FreeRADIUS 3.2 config is delivered via ConfigMaps; the LDAP bind password is injected at pod start via an initContainer (envsubst) so no secret lands in a ConfigMap. Auth + authz go to FreeIPA over LDAPS; the EAP cert comes from cert-manager (ACME → FreeIPA). MetalLB LoadBalancer with `externalTrafficPolicy: Local` preserves the UDM source IP.

**Tech Stack:** FreeRADIUS 3.2 (`freeradius/freeradius-server`), FreeIPA (Dogtag CA + ACME + LDAP), cert-manager (ACME issuer, dns-01/RFC2136 to knot), ExternalSecrets/OpenBao, MetalLB, Cilium NetworkPolicy, ArgoCD.

Spec: `docs/superpowers/specs/2026-08-25-freeradius-freeipa-design.md`

---

## File Structure

```
applications/freeradius/
  freeradius.yaml          # ns, Deployment, Service(LB), NetworkPolicy, ExternalSecret
  configmap-raddb.yaml     # FreeRADIUS config: clients.conf, mods, sites (template form)
  cert.yaml                # cert-manager Issuer (FreeIPA ACME) + Certificate
infrastructure/infrastructure-apps.yaml   # (no change)
applications/app-of-apps.yaml             # + freeradius Application
```

FreeIPA + OpenBao steps are one-time host/CLI actions (Tasks 1–3), captured here so they are reproducible.

---

## Task 1: Enable FreeIPA ACME responder

**Files:** none (ipa9 host action)

- [ ] **Step 1: Check current ACME state**

Run: `ssh ipa9 'sudo ipa-acme-manage status'`
Expected: prints `disabled` (or an error if never configured).

- [ ] **Step 2: Enable ACME**

Run: `ssh ipa9 'sudo ipa-acme-manage enable && sudo ipa-acme-manage status'`
Expected: status now `enabled`.

- [ ] **Step 3: Verify the ACME directory is reachable**

Run: `curl -sk https://ipa9.starnix.net/acme/directory | head`
Expected: JSON with `newOrder`, `newAccount`, `newNonce` keys.

---

## Task 2: Create the FreeIPA `svc-radius` bind account

**Files:** none (ipa9 host action, requires `kinit admin`)

- [ ] **Step 1: Create the system account (idempotent check first)**

Run:
```bash
ssh ipa9 'kinit admin && \
  ldapsearch -LLL -Y EXTERNAL -H ldapi://%2Frun%2Fslapd-STARNIX-NET.socket \
    -b "uid=svc-radius,cn=sysaccounts,cn=etc,dc=starnix,dc=net" dn 2>/dev/null \
  || echo "NOT PRESENT"'
```
Expected: `NOT PRESENT` (first run).

- [ ] **Step 2: Add the account (generate a strong password locally, keep it for Task 3)**

Run (paste a generated 32-char password at the prompt):
```bash
ssh -t ipa9 'sudo ldapadd -Y EXTERNAL -H ldapi://%2Frun%2Fslapd-STARNIX-NET.socket <<LDIF
dn: uid=svc-radius,cn=sysaccounts,cn=etc,dc=starnix,dc=net
objectClass: account
objectClass: simplesecurityobject
uid: svc-radius
userPassword: <PASTE_GENERATED_PASSWORD>
passwordExpirationTime: 20380101000000Z
nsIdleTimeout: 0
LDIF'
```
Expected: `adding new entry "uid=svc-radius,..."`.

- [ ] **Step 3: Verify it can read a user + `ipaNTHash` + group membership**

Run:
```bash
ssh ipa9 'ldapsearch -LLL -x -H ldaps://ipa9.starnix.net \
  -D "uid=svc-radius,cn=sysaccounts,cn=etc,dc=starnix,dc=net" -w "<PASSWORD>" \
  -b "cn=users,cn=accounts,dc=starnix,dc=net" "(uid=<a-wifi-user>)" uid memberOf ipaNTHash'
```
Expected: returns the user with a `memberOf: cn=wifi,...` line (ipaNTHash may or may not be present per-user — both auth paths are covered).

> Note: sysaccounts can read `ipaNTHash` by default via the "Read PassSync Managers" style ACI used by FreeRADIUS integrations. If the ldapsearch above omits `ipaNTHash`, add the standard read ACI for svc-radius during implementation (documented in the FreeIPA+FreeRADIUS guide) — PAP still works regardless.

---

## Task 3: Store secrets in OpenBao

**Files:** none (OpenBao CLI; `VAULT_ADDR=https://vault.starnix.net`)

- [ ] **Step 1: Generate + store the RADIUS shared secret and the bind password**

Run:
```bash
RADSECRET=$(openssl rand -base64 32)
bao kv put secret/cluster/freeradius \
  ldap_bind_password='<PASSWORD_FROM_TASK_2>' \
  radius_shared_secret="$RADSECRET"
echo "shared secret (for UniFi, Task 9): $RADSECRET"
```
Expected: `Success! Data written to: secret/cluster/freeradius`. Save the shared secret for the UniFi step.

- [ ] **Step 2: Verify**

Run: `bao kv get -field=radius_shared_secret secret/cluster/freeradius`
Expected: prints the secret.

---

## Task 4: cert-manager Issuer + Certificate (FreeIPA ACME, dns-01 via knot)

**Files:**
- Create: `applications/freeradius/cert.yaml`

- [ ] **Step 1: Confirm the knot RFC2136 TSIG secret name/key cert-manager can use**

Run: `kubectl get secret -n cert-manager | grep -iE 'tsig|rfc2136|knot|externaldns'`
Expected: an existing TSIG secret (reuse externalDNS's `externaldns` TSIG key). Note its name + key for the manifest.

- [ ] **Step 2: Write the Issuer + Certificate**

Create `applications/freeradius/cert.yaml`:
```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: freeipa-acme
  namespace: freeradius
spec:
  acme:
    server: https://ipa9.starnix.net/acme/directory
    # FreeIPA's ACME uses the Dogtag CA; skip public-CA email requirements.
    skipTLSVerify: false          # trust chain: ipa CA must be in the cluster trust or set caBundle
    privateKeySecretRef:
      name: freeipa-acme-account
    solvers:
      - dns01:
          rfc2136:
            nameserver: 192.168.7.211:53      # knot authoritative
            tsigKeyName: externaldns
            tsigAlgorithm: HMACSHA256
            tsigSecretSecretRef:
              name: <tsig-secret-name>        # from Step 1
              key: <tsig-secret-key>          # from Step 1
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: radius-eap
  namespace: freeradius
spec:
  secretName: radius-eap-tls
  issuerRef:
    name: freeipa-acme
    kind: Issuer
  commonName: radius.starnix.net
  dnsNames:
    - radius.starnix.net
  duration: 2160h      # 90d
  renewBefore: 720h    # 30d
  privateKey:
    algorithm: RSA
    size: 2048
  # The IPA CA chain is delivered in the secret's ca.crt / tls.crt chain.
```

- [ ] **Step 3: Validate YAML**

Run: `python3 -c "import yaml; list(yaml.safe_load_all(open('applications/freeradius/cert.yaml'))); print('OK')"`
Expected: `OK`.

> Applied via ArgoCD in Task 8. Note the `skipTLSVerify`/`caBundle`: cert-manager must trust FreeIPA's ACME TLS endpoint. If the ipa CA is not already in the cluster trust bundle, add `caBundle: <base64 ipa CA>` under `spec.acme` at implementation. Verify issuance in Task 8.

---

## Task 5: FreeRADIUS config ConfigMap (template form, no secrets)

**Files:**
- Create: `applications/freeradius/configmap-raddb.yaml`

FreeRADIUS 3.2 default `raddb` ships with `eap`, `mschap` enabled and a working
`inner-tunnel`. We override four files. `@LDAP_BIND_PW@` is a placeholder the
initContainer replaces from the mounted secret (Task 6).

- [ ] **Step 1: Write the ConfigMap**

Create `applications/freeradius/configmap-raddb.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: freeradius-raddb
  namespace: freeradius
data:
  clients.conf: |
    client udm-lan {
        ipaddr = 192.168.1.1
        secret = @RADIUS_SECRET@
        require_message_authenticator = yes
        nas_type = other
    }
    client udm-alt {
        ipaddr = 192.168.2.1
        secret = @RADIUS_SECRET@
        require_message_authenticator = yes
        nas_type = other
    }
  mods-ldap: |
    ldap {
        server = 'ldaps://ipa9.starnix.net'
        identity = 'uid=svc-radius,cn=sysaccounts,cn=etc,dc=starnix,dc=net'
        password = '@LDAP_BIND_PW@'
        base_dn = 'cn=accounts,dc=starnix,dc=net'
        sasl { }
        update {
            control:Password-With-Header    += 'userPassword'
            control:NT-Password             := 'ipaNTHash'
            control:                        += 'radiusReplyItem'
        }
        user {
            base_dn = "cn=users,cn=accounts,dc=starnix,dc=net"
            filter  = "(uid=%{%{Stripped-User-Name}:-%{User-Name}})"
        }
        group {
            base_dn = "cn=groups,cn=accounts,dc=starnix,dc=net"
            filter  = "(objectClass=ipausergroup)"
            membership_attribute = 'memberOf'
        }
        options { chase_referrals = yes; rebind = yes }
        tls {
            ca_file     = /etc/raddb/certs/ipa-ca.pem
            require_cert = 'demand'
        }
        pool { start = 2; min = 1; max = 8; spare = 2; idle_timeout = 60 }
    }
  eap-tls-config: |
    # Included into mods-enabled/eap's tls-config block.
    private_key_file = /etc/raddb/certs/radius-eap.key
    certificate_file = /etc/raddb/certs/radius-eap.pem
    ca_file          = /etc/raddb/certs/ipa-ca.pem
    dh_file          = /etc/raddb/certs/dh
    fragment_size    = 1024
    check_cert_cn    =
  inner-authorize: |
    # Fragment spliced into sites-enabled/inner-tunnel `authorize`.
    # 1) look the user up in FreeIPA + enforce wifi-group membership,
    # 2) PAP -> LDAP bind; MSCHAPv2 -> mschap uses NT-Password from ldap.
    ldap
    if (!&LDAP-Group == "wifi") {
        reject
    }
    if (&User-Password) {
        update control { Auth-Type := ldap }
    }
```

- [ ] **Step 2: Validate YAML**

Run: `python3 -c "import yaml; list(yaml.safe_load_all(open('applications/freeradius/configmap-raddb.yaml'))); print('OK')"`
Expected: `OK`.

> The exact splice points (how `eap-tls-config`, `mods-ldap`, `inner-authorize` are wired into the stock `raddb`) are handled by the initContainer script in Task 6, which copies the stock `/etc/raddb`, drops these files in, and enables the `ldap` module + `Auth-Type LDAP` in `inner-tunnel`. Verify the running config parses in Task 7 Step 4 (`radiusd -XC`).

---

## Task 6: Init/entrypoint script (secret injection + config assembly)

**Files:**
- Add to: `applications/freeradius/configmap-raddb.yaml` (a second ConfigMap `freeradius-init` with `assemble.sh`)

- [ ] **Step 1: Append the init-script ConfigMap**

Add to `applications/freeradius/configmap-raddb.yaml`:
```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: freeradius-init
  namespace: freeradius
data:
  assemble.sh: |
    #!/bin/sh
    set -eu
    # Start from the image's stock config, then overlay ours.
    cp -a /etc/raddb/. /assembled/
    # clients.conf + ldap module, with secrets substituted from env.
    sed "s|@RADIUS_SECRET@|${RADIUS_SHARED_SECRET}|g" \
        /tmpl/clients.conf > /assembled/clients.conf
    sed "s|@LDAP_BIND_PW@|${LDAP_BIND_PASSWORD}|g" \
        /tmpl/mods-ldap > /assembled/mods-available/ldap
    ln -sf ../mods-available/ldap /assembled/mods-enabled/ldap
    # EAP: replace tls-config private_key/cert/ca lines with ours.
    cp /tmpl/eap-tls-config /assembled/mods-config/eap-tls-starnix
    sed -i 's|^\(\s*\)private_key_password.*|\1$INCLUDE ${modconfdir}/eap-tls-starnix|' \
        /assembled/mods-enabled/eap || true
    # Splice authz fragment + Auth-Type LDAP into inner-tunnel.
    awk '1; /^authorize \{/ && !x {print "    $INCLUDE ${confdir}/inner-authorize"; x=1}' \
        /assembled/sites-enabled/inner-tunnel > /assembled/sites-enabled/inner-tunnel.new
    mv /assembled/sites-enabled/inner-tunnel.new /assembled/sites-enabled/inner-tunnel
    cp /tmpl/inner-authorize /assembled/inner-authorize
    # Ensure 'Auth-Type LDAP { ldap }' exists in inner-tunnel authenticate.
    grep -q 'Auth-Type LDAP' /assembled/sites-enabled/inner-tunnel || \
      sed -i '/^authenticate \{/a\    Auth-Type LDAP { ldap }' \
        /assembled/sites-enabled/inner-tunnel
    # Certs from the mounted secret.
    cp /certs/tls.crt /assembled/certs/radius-eap.pem
    cp /certs/tls.key /assembled/certs/radius-eap.key
    cp /certs/ca.crt  /assembled/certs/ipa-ca.pem
    [ -f /assembled/certs/dh ] || openssl dhparam -out /assembled/certs/dh 2048
    chown -R freerad:freerad /assembled/certs || true
    echo "assembly complete"
```

- [ ] **Step 2: Validate YAML**

Run: `python3 -c "import yaml; list(yaml.safe_load_all(open('applications/freeradius/configmap-raddb.yaml'))); print('OK')"`
Expected: `OK`.

> The `sed` splice for the eap `tls-config` is best-effort; during implementation, run `radiusd -XC` (Task 7) and adjust the splice until the config parses. This is expected iteration for the EAP block.

---

## Task 7: FreeRADIUS Deployment, Service (MetalLB LB), NetworkPolicy, ExternalSecret

**Files:**
- Create: `applications/freeradius/freeradius.yaml`

- [ ] **Step 1: Write the namespace + ExternalSecret + workload**

Create `applications/freeradius/freeradius.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: freeradius
  labels: { name: freeradius }
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: freeradius-secrets
  namespace: freeradius
spec:
  refreshInterval: 1h
  secretStoreRef: { name: openbao, kind: ClusterSecretStore }
  target: { name: freeradius-secrets }
  data:
    - secretKey: ldap_bind_password
      remoteRef: { key: cluster/freeradius, property: ldap_bind_password }
    - secretKey: radius_shared_secret
      remoteRef: { key: cluster/freeradius, property: radius_shared_secret }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: freeradius
  namespace: freeradius
  annotations:
    configmap.reloader.stakater.com/reload: "freeradius-raddb,freeradius-init"
spec:
  replicas: 1
  selector: { matchLabels: { app: freeradius } }
  template:
    metadata:
      labels: { app: freeradius }
    spec:
      initContainers:
        - name: assemble
          image: freeradius/freeradius-server:3.2.7
          command: ["/bin/sh", "/init/assemble.sh"]
          env:
            - name: LDAP_BIND_PASSWORD
              valueFrom: { secretKeyRef: { name: freeradius-secrets, key: ldap_bind_password } }
            - name: RADIUS_SHARED_SECRET
              valueFrom: { secretKeyRef: { name: freeradius-secrets, key: radius_shared_secret } }
          volumeMounts:
            - { name: assembled, mountPath: /assembled }
            - { name: tmpl, mountPath: /tmpl }
            - { name: init, mountPath: /init }
            - { name: eapcert, mountPath: /certs, readOnly: true }
      containers:
        - name: freeradius
          image: freeradius/freeradius-server:3.2.7
          args: ["-f", "-d", "/assembled"]
          ports:
            - { containerPort: 1812, protocol: UDP, name: auth }
            - { containerPort: 1813, protocol: UDP, name: acct }
          volumeMounts:
            - { name: assembled, mountPath: /assembled }
          readinessProbe:
            exec: { command: ["/bin/sh","-c","radiusd -XCd /assembled >/dev/null 2>&1"] }
            initialDelaySeconds: 5
            periodSeconds: 30
      volumes:
        - { name: assembled, emptyDir: {} }
        - name: tmpl
          configMap:
            name: freeradius-raddb
            items:
              - { key: clients.conf,   path: clients.conf }
              - { key: mods-ldap,      path: mods-ldap }
              - { key: eap-tls-config, path: eap-tls-config }
              - { key: inner-authorize, path: inner-authorize }
        - { name: init, configMap: { name: freeradius-init } }
        - { name: eapcert, secret: { secretName: radius-eap-tls } }
---
apiVersion: v1
kind: Service
metadata:
  name: freeradius
  namespace: freeradius
  annotations:
    metallb.universe.tf/loadBalancerIPs: "192.168.7.214"
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  selector: { app: freeradius }
  ports:
    - { name: auth, port: 1812, targetPort: 1812, protocol: UDP }
    - { name: acct, port: 1813, targetPort: 1813, protocol: UDP }
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: freeradius
  namespace: freeradius
spec:
  endpointSelector: { matchLabels: { app: freeradius } }
  ingress:
    - fromCIDR: ["192.168.1.0/24", "192.168.2.0/24"]
      toPorts:
        - ports:
            - { port: "1812", protocol: UDP }
            - { port: "1813", protocol: UDP }
  egress:
    - toEndpoints: [{ matchLabels: { "k8s:io.kubernetes.pod.namespace": kube-system, "k8s-app": kube-dns } }]
      toPorts: [{ ports: [{ port: "53", protocol: UDP }] }]
    - toCIDR: ["192.168.1.26/32"]     # ipa9
      toPorts: [{ ports: [{ port: "636", protocol: TCP }] }]
```

- [ ] **Step 2: Validate YAML**

Run: `python3 -c "import yaml; list(yaml.safe_load_all(open('applications/freeradius/freeradius.yaml'))); print('OK')"`
Expected: `OK`.

- [ ] **Step 3: Confirm the CiliumNetworkPolicy egress selector matches this cluster's kube-dns labels**

Run: `kubectl get pod -n kube-system -l k8s-app=kube-dns -o name`
Expected: returns the CoreDNS pods (label matches). If empty, adjust the selector (the cluster uses CoreDNS; the label may be `k8s-app: coredns` — verify and fix the policy).

- [ ] **Step 4: (post-deploy) verify the assembled config parses**

Run (after Task 8 sync): `kubectl exec -n freeradius deploy/freeradius -- radiusd -XCd /assembled 2>&1 | tail -5`
Expected: `Configuration appears to be OK`.

---

## Task 8: Wire the ArgoCD Application and sync

**Files:**
- Modify: `applications/app-of-apps.yaml`

- [ ] **Step 1: Add the Application entry (match the existing app-of-apps pattern)**

Append to `applications/app-of-apps.yaml` a new `Application` named `freeradius`,
`source.path: applications/freeradius`, `destination.namespace: freeradius`,
`syncPolicy.automated` with `CreateNamespace=true` + `ServerSideApply=true`,
mirroring the sibling entries in that file exactly.

- [ ] **Step 2: Validate + commit + push on a branch, open PR**

Run:
```bash
python3 -c "import yaml; list(yaml.safe_load_all(open('applications/app-of-apps.yaml'))); print('OK')"
git checkout -b feat/freeradius-freeipa
git add applications/freeradius applications/app-of-apps.yaml docs/superpowers
git commit -m "feat(freeradius): FreeIPA-backed WPA-Enterprise RADIUS"
git push -u origin feat/freeradius-freeipa
gh pr create --base main --title "feat(freeradius): FreeIPA-backed WPA-Enterprise RADIUS" --body "See docs/superpowers/specs/2026-08-25-freeradius-freeipa-design.md"
```
Expected: PR created. (User merges — assistant cannot self-merge.)

- [ ] **Step 3: After merge, verify sync + cert issuance + pod health**

Run:
```bash
kubectl get application -n argocd freeradius -o custom-columns=SYNC:.status.sync.status,HEALTH:.status.health.status
kubectl get certificate -n freeradius radius-eap -o custom-columns=READY:.status.conditions[0].status
kubectl get pods -n freeradius
kubectl get svc -n freeradius freeradius -o custom-columns=EXTIP:.status.loadBalancer.ingress[0].ip
```
Expected: app Synced/Healthy, certificate READY=True, pod Running, EXTIP=192.168.7.214.

---

## Task 9: UniFi RADIUS profile + SSID (manual)

**Files:** none (UniFi Network UI)

- [ ] **Step 1: Create the RADIUS profile**

In UniFi → Settings → Profiles → RADIUS → Create: Auth server `192.168.7.214:1812`,
Accounting `192.168.7.214:1813`, shared secret = the value from Task 3 Step 1.

- [ ] **Step 2: Point an SSID at it**

Create/edit a WiFi SSID → Security = **WPA Enterprise** → RADIUS profile = the one above.

- [ ] **Step 3: Verify a live auth reaches FreeRADIUS**

Join the SSID with a `wifi`-group IPA user; then:
Run: `kubectl logs -n freeradius deploy/freeradius --tail=40 | grep -Ei 'Access-Accept|Access-Reject|Login OK|from 192.168'`
Expected: an `Access-Accept` for the user, source IP = the UDM (192.168.1.1/192.168.2.1), confirming `etp:Local` preserved the source.

---

## Task 10: Functional verification (both EAP paths + authz + cert pinning)

**Files:** none (a throwaway `eapol_test` pod or a LAN host with `eapol_test`)

- [ ] **Step 1: PEAP-MSCHAPv2 accept**

Run `eapol_test` with a PEAP/MSCHAPv2 config for a `wifi` user against
`192.168.7.214:1812` + the shared secret.
Expected: `SUCCESS`.

- [ ] **Step 2: EAP-TTLS/PAP accept**

Run `eapol_test` with a TTLS/PAP config for the same user.
Expected: `SUCCESS`.

- [ ] **Step 3: Non-wifi user reject**

Run `eapol_test` for an IPA user NOT in `wifi`.
Expected: `FAILURE` (Access-Reject); FreeRADIUS log shows the group reject.

- [ ] **Step 4: Wrong password reject**

Run `eapol_test` with a bad password.
Expected: `FAILURE` on both PEAP and TTLS.

- [ ] **Step 5: Cert pinning (client side)**

On a real device, configure the WiFi profile to trust the FreeIPA CA + verify
server name `radius.starnix.net`. Confirm it connects. Then temporarily set the
profile to trust a different CA and confirm the device REFUSES to connect
(proves the pin is enforced).

---

## Rollout / rollback notes
- New SSID (or a test SSID) first; cut the production SSID over only after Task 10 passes.
- Rollback: point the SSID back to the prior auth (PSK or authentik-radius .213); the freeradius app can be left running or the Application pruned.

---

## Self-review — spec coverage
- EAP both methods → Tasks 5/6 (config) + 10 Steps 1-2 (verify). ✓
- FreeIPA LDAP + wifi authz → Tasks 2, 5. ✓
- ipaNTHash for MSCHAPv2 / LDAP-bind for PAP → Task 5 `mods-ldap` + `inner-authorize`. ✓
- Pinned cert from IPA CA via ACME/cert-manager → Tasks 1, 4; pin verified Task 10 Step 5. ✓
- MetalLB .214 + etp:Local → Task 7 Service; source-IP verified Task 9 Step 3. ✓
- Secrets via OpenBao/ESO + no secret in ConfigMap → Tasks 3, 6, 7. ✓
- UniFi clients 192.168.1.1/2.1 → Task 5 clients.conf, Task 7 netpol, Task 9. ✓
- GitOps/ArgoCD → Task 8. ✓
- Out-of-scope (VLAN/HA/accounting) → intentionally absent. ✓
