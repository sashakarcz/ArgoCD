# FreeRADIUS (FreeIPA-backed) for WPA-Enterprise WiFi — Design

Date: 2026-08-25
Status: Draft, pending review

## Goal

A well-made RADIUS server for WPA2/3-Enterprise (802.1X) WiFi that authenticates
FreeIPA users, presents a pinned EAP certificate, and runs on the Talos k8s
cluster behind its own MetalLB UDP listener.

## Decisions (from brainstorming)

| Decision | Choice | Notes |
|---|---|---|
| Use case | WPA-Enterprise WiFi (802.1X) | UniFi APs/UDM are the RADIUS clients (NAS) |
| EAP methods | **PEAP-MSCHAPv2 AND EAP-TTLS/PAP (both)** | Device picks; max compatibility |
| — PEAP inner MSCHAPv2 | `mschap` vs `NT-Password` from `ipaNTHash` | Native on all OSes incl. Windows |
| — TTLS inner PAP | LDAP **bind as user** | Covers users without `ipaNTHash`; no hash needed |
| Auth backend | FreeIPA `ipa9.starnix.net`, realm `STARNIX.NET` | LDAPS :636 |
| Authorization | Existing FreeIPA group `wifi` (GID 1730000019) | `memberOf=cn=wifi,cn=groups,cn=accounts,dc=starnix,dc=net` |
| Pinned cert | EAP server cert from the **FreeIPA Dogtag CA** | Supplicants trust IPA CA + verify server CN |
| Hosting | Talos/k8s + MetalLB UDP LoadBalancer | GitOps via ArgoCD; WiFi auth depends on cluster health (accepted) |
| FreeIPA changes | **One minor**: `ipa-acme-manage enable` | For k8s-native cert renewal only. NO `adtrust`/resets — `ipaNTHash` already populated (verified: 26 users) |
| RADIUS clients (NAS) | UDM `192.168.1.1` and `192.168.2.1` | Widen to the /24 if APs send RADIUS directly |
| Cert renewal | FreeIPA ACME + cert-manager (dns-01 via knot) | k8s-native, auto-renewed |

## Architecture

```
UniFi AP / UDM ──RADIUS UDP 1812(auth)/1813(acct)──▶ MetalLB LB 192.168.7.214
                                                      (externalTrafficPolicy: Local)
                                                          │
                                             FreeRADIUS pod  (ns: freeradius, ArgoCD)
                                             ├─ EAP outer TLS: server cert from FreeIPA CA (pinned)
                                             ├─ PEAP → inner MSCHAPv2 → mschap(NT-Password ← ipaNTHash)
                                             └─ TTLS → inner PAP → LDAP bind as user
                                                  both paths: LDAPS to ipa9, require memberOf=wifi
```

`externalTrafficPolicy: Local` is **mandatory** so FreeRADIUS sees the real AP
source IP and matches it to a `client{}` block + shared secret (a `Cluster`
policy would SNAT every request to a node IP). Mirrors authentik-radius (.213).

## FreeRADIUS config (mounted over image defaults via ConfigMap)

- **`mods-enabled/ldap`** — `server = ldaps://ipa9.starnix.net`, `base_dn =
  cn=accounts,dc=starnix,dc=net`, service bind account (`svc-radius`), user
  filter `(uid=%{%{Stripped-User-Name}:-%{User-Name}})`, group membership check
  against `cn=wifi,...`. In `update { control:NT-Password := 'ipaNTHash' }` so
  MSCHAPv2 has the hash when present.
- **`mods-enabled/eap`** — `tls-config` uses the IPA-issued server cert/key +
  the IPA CA bundle; both `peap` and `ttls` enabled, each
  `virtual_server = inner-tunnel`, `copy_request_to_tunnel`,
  `use_tunneled_reply`.
- **`mods-enabled/mschap`** — default; consumes `NT-Password` set by ldap.
- **`sites-enabled/default`** — outer: EAP only (identity is anonymous outer).
- **`sites-enabled/inner-tunnel`** —
  - `authorize`: `ldap` (find user, set `NT-Password` from `ipaNTHash`, enforce
    `memberOf=wifi`); if `User-Password` present (PAP) → `Auth-Type := ldap`;
    else `eap`/`mschap` handle MSCHAPv2.
  - `authenticate`: `Auth-Type LDAP { ldap }` (PAP → bind) and
    `Auth-Type MSCHAP { mschap }` (MSCHAPv2 → hash compare).
- **`clients.conf`** — UDM source IPs `192.168.1.1` and `192.168.2.1` + shared
  secret (from Secret); widen to the /24 if APs send RADIUS directly.

## Components

### 1. k8s — `applications/freeradius/` (raw manifests, matches authentik pattern)
- **Deployment**: `freeradius/freeradius-server` image (pinned), single replica;
  config from ConfigMap(s), cert + secrets from Secrets.
- **Service**: `type: LoadBalancer`, `externalTrafficPolicy: Local`,
  `metallb.universe.tf/loadBalancerIPs: 192.168.7.214`, UDP 1812 + 1813.
- **Cilium NetworkPolicy**: ingress UDP 1812/1813 from the UniFi subnet only;
  egress to `ipa9.starnix.net:636` + DNS.
- **ArgoCD Application**: new entry under the applications app-of-apps,
  `CreateNamespace=true`.

### 2. FreeIPA side (no mode/schema changes)
- **`svc-radius`** system account (`cn=sysaccounts,cn=etc,dc=starnix,dc=net`),
  read access to users + group membership + `ipaNTHash`. Password in OpenBao.
- **EAP server cert** — issued + auto-renewed **k8s-native via ACME**:
  - Enable FreeIPA's ACME responder: `ipa-acme-manage enable` on ipa9 (the one
    minor FreeIPA change).
  - cert-manager `Issuer` (ACME, directory `https://ipa9.starnix.net/acme/directory`)
    with a **dns-01 RFC2136 solver** to knot (reuses the existing externalDNS TSIG
    plumbing), issuing a `Certificate` for `CN=radius.starnix.net` from the IPA CA
    into a k8s Secret. RADIUS is reached by IP (.214), so no A record is required —
    only the `_acme-challenge` TXT in the starnix.net zone.
  - FreeRADIUS mounts that Secret (cert/key + IPA CA chain); cert-manager renews.
  - Verify FreeIPA ACME issuance policy permits `radius.starnix.net` at implementation.

### 3. Secrets
- **OpenBao → ESO** (into `freeradius` ns): `svc-radius` LDAP bind password;
  RADIUS shared secret (UniFi ↔ FreeRADIUS).
- **cert-manager** (into `freeradius` ns): the EAP server cert/key + IPA CA chain
  (see cert renewal above) — auto-renewed, not via ESO.

### 4. UniFi (manual, one-time)
- RADIUS profile → `192.168.7.214` (auth 1812 / acct 1813) + shared secret.
- Target SSID set to WPA-Enterprise using that profile.
- Confirm the AP/UDM management subnet is the RADIUS source (matches `clients.conf`).

### 5. Client trust — the "pinning"
- Distribute the **FreeIPA CA cert** to devices; WiFi profile trusts that CA
  **and** verifies server name `radius.starnix.net`. That validation is the
  security boundary — see below.

## Security notes
- Inner credentials (MSCHAPv2 response or PAP password) are only ever inside the
  EAP TLS tunnel; confidentiality depends entirely on the **pinned server cert**.
  Client-side CA + server-name validation is therefore **not optional** — it is
  the anti-evil-twin control. PAP in particular is cleartext-in-tunnel.
- PAP path never stores/sees a hash (LDAP bind). MSCHAPv2 path uses the existing
  `ipaNTHash` (unsalted MD4 — acceptable only because it is TLS-wrapped + pinned).
- Least privilege: only `wifi` group members pass authz; `svc-radius` is read-only.

## Out of scope (v1)
- Dynamic per-user/group VLAN assignment (`Tunnel-Private-Group-ID`).
- RADIUS accounting dashboards / long-term session logging.
- HA / second replica (single replica v1; revisit if WiFi-auth uptime demands it).

## Acceptance criteria
1. A `wifi`-group IPA user joins the WPA-Enterprise SSID via **PEAP-MSCHAPv2**
   (e.g. Windows/Android) **and** via **EAP-TTLS/PAP** (e.g. macOS/iOS/Linux).
2. A non-`wifi` IPA user is rejected (authz); a wrong password is rejected on
   both paths — verified in FreeRADIUS logs.
3. `eapol_test` succeeds for both a PEAP-MSCHAPv2 and a TTLS-PAP identity against
   192.168.7.214.
4. The supplicant validates the server cert against the IPA CA + CN; an untrusted
   cert is refused client-side.
5. FreeRADIUS logs show real AP source IPs (etp:Local) matching the shared secret.

## Resolved (confirm at apply time)
- MetalLB IP **192.168.7.214** (verify free in main-pool at apply).
- RADIUS clients: UDM **192.168.1.1** + **192.168.2.1** (widen to /24 if APs send direct).
- Cert renewal: **FreeIPA ACME + cert-manager**, dns-01 via knot; requires
  `ipa-acme-manage enable` on ipa9 and a permissive ACME issuance policy for
  `radius.starnix.net`.
