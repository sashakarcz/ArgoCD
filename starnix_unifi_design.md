# `starnix.unifi` Ansible Collection -- Design Document

Status: Approved for implementation
Target: ansible-core 2.21, Python 3.14 (confirmed local environment)
Controller: `heimdal.starnix.net` (UniFi Network API v10.4.57, application v9.1.0)
API: official UniFi Network **Integration API** v1, API-key auth

This document is the definitive build spec. It synthesizes the API reference, the
draft design, and the two adversarial reviews. Every material review finding is
resolved in Section 8, and the resolutions are already reflected in Sections 4-7.
Where the reviews contradicted the draft, the decision and rationale are stated
inline.

---

## 1. Overview, Goals, Scope, Non-Goals

### 1.1 Overview

`starnix.unifi` is a dependency-free Ansible collection that manages the UniFi
zone-based firewall and networks through the official UniFi Network Integration
API (`/proxy/network/integration/v1`). It provides declarative, idempotent,
check-mode-aware modules for firewall zones, traffic-matching lists
(address/port "groups"), firewall policies, per-zone-pair policy ordering, and
networks, plus a read-only site/info helper.

### 1.2 Goals (hard requirements)

- **G1 -- Declarative & idempotent.** Repeated runs of an unchanged play converge
  to `changed: false`. This is validated by the integration gate "re-run
  identical -> not changed."
- **G2 -- Check mode + diff.** Every mutating module supports `--check` and
  `--diff` and never mutates the controller in check mode.
- **G3 -- No runtime dependencies.** Built on `ansible.module_utils.urls.Request`
  (ships with ansible-core). Standalone-installable; no `requests`, no other
  collections.
- **G4 -- Honest to the API export's gaps.** The doc export collapses several
  nested objects (`trafficFilter`, `action`, `ipProtocolScope`, `schedule`,
  matching-list `items[]`) to `{}`. The collection never hardcodes guessed enum
  values as hard `choices`, and never invents a nested-object schema it then
  round-trips blindly.
- **G5 -- Full error transparency.** Every API error surfaces the standard error
  envelope (`code`, `statusName`, `requestPath`, `requestId`) to `fail_json`.
- **G6 -- Publishable to Galaxy.** Passes `ansible-test sanity`
  (`validate-modules` in particular) green on every ansible-core version we
  actually test.

### 1.3 Scope (v1.0.0)

- Firewall **zones** CRUD (custom zones).
- **Traffic-matching lists** CRUD (address/port lists), surfaced as
  `unifi_firewall_group`.
- Firewall **policies** CRUD.
- Firewall **policy ordering** per directed zone pair.
- **Networks** CRUD (only the fields this API version exposes).
- **Site/info** read-only helper (`unifi_site_info`).

### 1.4 Non-Goals (v1.0.0)

- **DHCP service configuration and DHCP-provided DNS.** This API version's network
  object exposes only `management`, `name`, `enabled`, `vlanId`, and
  `dhcpGuarding`. There are NO fields for subnet/CIDR, gateway/interface IP, DHCP
  range, lease time, or DHCP-provided DNS servers. The module documents this
  limitation up front.
- **DNS policies** (A-records). Documented in the reference for completeness (a
  separate resource), but no `unifi_dns_policy` module ships in v1.0.0.
- **ACL rules.** Separate mechanism from firewall policies; out of scope.
- **Read-only "Supporting Resources"** (WANs, VPN tunnels/servers, RADIUS
  profiles, device tags, DPI categories, country codes).
- **Typed sub-options for opaque nested objects.** Deferred to v1.1 pending
  `schema_discovery` output (see Section 8, finding R12).
- **Molecule scenarios.** Not shipped (see finding R-mol).
- **Server-side `filter` optimization.** Not used in v1.0.0; client-side
  pagination + name match only (see finding R16).

---

## 2. COMPLETE API Reference (ground truth)

This section carries over the full endpoint- and field-level detail. It is the
authoritative contract the modules are built against. Base URL pattern:

```
https://<host>:<port>/proxy/network/integration/v1/...
```

Auth: API key in the **`X-API-KEY`** request header on every request. Bodies are
`application/json`. Path/version segment is `v1` (path-based versioning; no
version header). Internal `requestPath` in errors is integration-relative (e.g.
`/integration/v1/sites/123`); the externally reachable prefix is
`/proxy/network/integration`.

### 2.1 Conventions

**Pagination (all list/collection GETs).** Query params:

| Param | Type | Default | Constraints |
|---|---|---|---|
| `offset` | integer `<int32>` | `0` | `>= 0` |
| `limit` | integer `<int32>` | `25` | `[0 .. 200]` (max page size 200) |
| `filter` | string | -- | optional, where supported |

Response envelope (every list endpoint):

| Field | Type | Meaning |
|---|---|---|
| `offset` | integer | applied offset |
| `limit` | integer | applied (echoed) limit -- may be lower than requested |
| `count` | integer | items in this page (`data.length`) |
| `totalCount` | integer | total items available |
| `data` | array | page of resource objects |

Termination rule (verbatim from reference): iterate `offset += <applied count>`
until `offset + count >= totalCount`. **Advance by the items actually returned,
never by the requested page size** (see Section 4 pagination and finding R1/R12).

**Filtering syntax (`filter` query param).** Property expression
`<property>.<function>(<args>)`; compound `and(...)`, `or(...)`; negation
`not(...)`. Types: STRING (single-quoted; escape `'` by doubling to `''`),
INTEGER, DECIMAL, TIMESTAMP (ISO 8601), BOOLEAN, UUID, SET(...). Functions:
`isNull`, `isNotNull`, `eq`, `ne`, `gt`, `ge`, `lt`, `le`, `like` (`.` = one
char, `*` = any chars, `\` = escape), `in`, `notIn`, `isEmpty`, `contains`,
`containsAny`, `containsAll`, `containsExactly`. **Per-endpoint filterable
properties are collapsed/unenumerated in the export for all resources.**

**Standard error envelope (all endpoints, any non-2xx).**

| Field | Type | Notes |
|---|---|---|
| `statusCode` | integer `<int32>` | HTTP status, e.g. `400` |
| `statusName` | string | e.g. `"UNAUTHORIZED"` |
| `code` | string | machine code, e.g. `"api.authentication.missing-credentials"` |
| `message` | string | human-readable |
| `timestamp` | string `<date-time>` | ISO 8601 |
| `requestPath` | string | integration-relative failing path |
| `requestId` | string `<uuid>` | present on 500; use to trace in server log |

Sample:
```json
{
  "statusCode": 400,
  "statusName": "UNAUTHORIZED",
  "code": "api.authentication.missing-credentials",
  "message": "Missing credentials",
  "timestamp": "2024-11-27T08:13:46.966Z",
  "requestPath": "/integration/v1/sites/123",
  "requestId": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
```
(The source pairs `statusCode: 400` with `statusName: "UNAUTHORIZED"`; reproduced
verbatim. Do not rely on statusCode/statusName agreement.)

**Rate limits.** None documented anywhere (no `X-RateLimit-*`, no `429`, no
`Retry-After`). Treat as unspecified; do not assume header names exist.

### 2.2 `GET /v1/info` -- Application Info

- No path/query params, no body.
- `200 OK`: `{ "applicationVersion": "9.1.0" }` (only field documented).

### 2.3 `GET /v1/sites` -- List Local Sites

- Paginated (envelope above); supports `filter`.
- Site object `data[]` element: **only `id` (UUID) is confirmed** by usage (it
  becomes the `siteId` path param, declared `string <uuid>, required` everywhere).
  All other per-site fields (name/isDefault/desc/etc.) are **NOT documented** --
  the export collapses each element to `{}`. Any additional field must be
  discovered from a live response before being relied on.

`siteId` is a mandatory first-resolve for every per-site endpoint below.

### 2.4 Firewall Zones -- `/v1/sites/{siteId}/firewall/zones`

Zone object (returned by Get/Create/Update, and each List `data[]` element):

| Field | Type | Required | Read-only | Notes |
|---|---|---|---|---|
| `id` | `string <uuid>` | resp only | yes | server-assigned; absent from request bodies |
| `name` | `string` | yes | no | sample `"Hotspot\|My custom zone"` (`\|` literal in sample); no length/pattern documented |
| `networkIds` | array of `string <uuid>` | yes | no | `>= 0 items` (empty allowed) |
| `metadata` | object | resp only | yes | `{ "origin": <string> }`; response-only |
| `metadata.origin` | string | -- | yes | sample `"string"`; no enum documented |

Request body (Create + Update): exactly `{ name (req), networkIds (req) }`.

Endpoints:

| Method | Path | Result |
|---|---|---|
| GET | `/firewall/zones` | `200` paginated list (all zones, system + custom) |
| GET | `/firewall/zones/{firewallZoneId}` | `200` single zone |
| POST | `/firewall/zones` | `201` Create **Custom** zone; body `{name, networkIds}` |
| PUT | `/firewall/zones/{firewallZoneId}` | `200` Update (full replace); body `{name, networkIds}` |
| DELETE | `/firewall/zones/{firewallZoneId}` | `200` Delete **Custom** zone; no body documented |

Path params: `siteId` (uuid, req) always; `firewallZoneId` (uuid, req) on item
endpoints.

**System vs custom.** No `system: true` flag on the object. The distinction is
structural: Create/Delete are titled "Custom", Get/List/Update are not. The
module does NOT detect system-vs-custom client-side; deleting/mutating a system
zone is deferred to the API, whose rejection is surfaced.

### 2.5 Traffic Matching Lists -- `/v1/sites/{siteId}/traffic-matching-lists`

("Endpoints for managing port and IP address lists used across firewall policy
configurations.")

Object:

| Field | Type | Required | Read-only | Notes |
|---|---|---|---|---|
| `type` | string | yes | no | discriminator. Only `PORTS` is shown as an example in the export. `IP_ADDRESSES` is inferred (from the section description + `name` sample), **not source-confirmed**. |
| `id` | `string <uuid>` | resp only | yes | server-assigned; absent from request bodies |
| `name` | string (non-empty) | yes | no | sample `"Allowed port list\|Protected IP list"` (`\|` denotes the two example variants, not a literal value) |
| `items` | array of objects ("Port matching"), non-empty (min 1) | yes | no | **element fields NOT expanded in export** (collapsed to `[ {} ]`). Concrete per-element fields (port/port-range; ip/cidr) are absent from the source. Treat as opaque list of dicts. |

`metadata.origin` is not shown on this object in any sample.

Endpoints:

| Method | Path | Result |
|---|---|---|
| GET | `/traffic-matching-lists` | `200` paginated list |
| GET | `/traffic-matching-lists/{trafficMatchingListId}` | `200` single object |
| POST | `/traffic-matching-lists` | `201` Create; body `{type, name, items}` |
| PUT | `/traffic-matching-lists/{trafficMatchingListId}` | `200` Update (full replace); body `{type, name, items}` |
| DELETE | `/traffic-matching-lists/{trafficMatchingListId}` | `200`; no body documented |

Path params: `siteId` (uuid, req) always; `trafficMatchingListId` (uuid, req) on
item endpoints.

### 2.6 Firewall Policies -- `/v1/sites/{siteId}/firewall/policies`

Endpoints:

| Method | Path | Result |
|---|---|---|
| GET | `/firewall/policies` | `200` paginated, filterable list |
| POST | `/firewall/policies` | `201` Create (server assigns `id`, `index`, `metadata`) |
| GET | `/firewall/policies/{firewallPolicyId}` | `200` single |
| PUT | `/firewall/policies/{firewallPolicyId}` | `200` Update (**full replace**) |
| PATCH | `/firewall/policies/{firewallPolicyId}` | `200` partial -- **only `loggingEnabled`** |
| DELETE | `/firewall/policies/{firewallPolicyId}` | `200` |
| GET | `/firewall/policies/ordering` | `200` ordering for a zone pair |
| PUT | `/firewall/policies/ordering` | `200` reorder for a zone pair |

Path params: `siteId` (uuid, req) always; `firewallPolicyId` (uuid, req) on item
endpoints.

Create/Update request body (identical schema for POST and PUT; `id`/`index`/
`metadata` are NOT sent):

| Field | Type | Required | Enum / constraints |
|---|---|---|---|
| `enabled` | boolean | **required** | -- |
| `name` | string | **required** | non-empty |
| `description` | string | optional | -- |
| `action` | object (Firewall policy action) | **required** | see below |
| `source` | object (source) | **required** | see below |
| `destination` | object (destination) | **required** | see below |
| `ipProtocolScope` | object (IP protocol scope) | **required** | see below |
| `connectionStateFilter` | array of strings | optional | items unique, 1..2147483647 items, **Items Enum: `NEW`, `INVALID`, `ESTABLISHED`, `RELATED`**. `null`/omitted matches all states. |
| `ipsecFilter` | string | optional | **Enum: `MATCH_ENCRYPTED`, `MATCH_NOT_ENCRYPTED`**. `null` matches all. |
| `loggingEnabled` | boolean | **required** | also the only PATCH-able field |
| `schedule` | object (Firewall schedule) | optional | `null` = always active |

Nested objects (all **collapsed/unenumerated in the export** -- inferred
placeholders, must be confirmed against a live controller):

- `action`: `{ "type": <string> }`. Enum NOT enumerated. Likely
  `ALLOW`/`BLOCK`/`REJECT` -- unconfirmed.
- `source` / `destination` (same shape): `{ "zoneId": <uuid>,
  "trafficFilter": {} }`. `trafficFilter` is the object that selects
  networks/IPs/IP-lists/ports/apps within a zone. **Its inner fields are absent
  from the entire export** (highest-priority gap). Treat as opaque.
- `ipProtocolScope`: `{ "ipVersion": <string> }`. A `protocol` field is implied
  by the description ("by IP version and protocol") but **not present** in any
  sample. `ipVersion` likely `IPV4`/`IPV6`/a "both" value -- unconfirmed.
- `schedule`: `{ "mode": <string> }`. Enum + any day/time/date fields NOT
  enumerated.

Response object (Get/Create/Update/Patch/List `data[]`):

| Field | Type | Read-only | Notes |
|---|---|---|---|
| `id` | `string <uuid>` | yes | server-assigned |
| `enabled` | boolean | no | |
| `name` | string | no | non-empty |
| `description` | string | no | |
| `index` | integer `int32` | **yes** | eval-order index within its zone pair; managed only via ordering endpoints, not settable in body. Sample `0`. |
| `action` | object | no | `{ "type": <string> }` |
| `source` | object | no | `{ "zoneId": <uuid>, "trafficFilter": {} }` |
| `destination` | object | no | `{ "zoneId": <uuid>, "trafficFilter": {} }` |
| `ipProtocolScope` | object | no | `{ "ipVersion": <string> }` |
| `connectionStateFilter` | array of strings | no | Items Enum: `NEW/INVALID/ESTABLISHED/RELATED` |
| `ipsecFilter` | string | no | `MATCH_ENCRYPTED`/`MATCH_NOT_ENCRYPTED` |
| `loggingEnabled` | boolean | no | |
| `schedule` | object | no | `{ "mode": <string> }` |
| `metadata` | object | **yes** | `{ "origin": <string> }`; response-only |

Full response sample:
```json
{
  "id": "497f6eca-6276-4993-bfeb-53cbbbba6f08",
  "enabled": true,
  "name": "My firewall policy",
  "description": "A description for my firewall policy",
  "index": 0,
  "action": { "type": "string" },
  "source": { "zoneId": "c3920607-5069-4ac3-ba10-00754e7a8e8b", "trafficFilter": {} },
  "destination": { "zoneId": "c3920607-5069-4ac3-ba10-00754e7a8e8b", "trafficFilter": {} },
  "ipProtocolScope": { "ipVersion": "string" },
  "connectionStateFilter": ["NEW"],
  "ipsecFilter": "MATCH_ENCRYPTED",
  "loggingEnabled": true,
  "schedule": { "mode": "string" },
  "metadata": { "origin": "string" }
}
```

**How a policy references a matching list:** via `source.trafficFilter` /
`destination.trafficFilter`. The precise field inside `trafficFilter` that holds
the list reference is **not expanded anywhere** in the export -- must be
confirmed live.

### 2.7 Firewall Policy Ordering -- `/v1/sites/{siteId}/firewall/policies/ordering`

**Model.** Ordering is scoped to one **directed zone pair**
`(sourceFirewallZoneId, destinationFirewallZoneId)`. User-defined policies are
split into two ordered buckets around the immutable system-defined policies:

- `beforeSystemDefined[]` -- user-defined policy UUIDs evaluated before system
  rules. Array order = evaluation order (index 0 first).
- `afterSystemDefined[]` -- user-defined policy UUIDs evaluated after system
  rules. Array order = evaluation order.

System policies are implicit (not listed, not reorderable) and form the fixed
boundary. Both arrays contain only user-defined policy UUIDs; each may be empty.
PUT is a **full replacement** of the ordering for that pair.

`GET /firewall/policies/ordering`:
- Path: `siteId` (uuid, req).
- Query (both required): `sourceFirewallZoneId` (uuid), `destinationFirewallZoneId` (uuid).
- `200`:
  ```json
  { "orderedFirewallPolicyIds": { "beforeSystemDefined": [], "afterSystemDefined": [] } }
  ```

`PUT /firewall/policies/ordering`:
- Same path + same two required query params.
- Body (required): `{ "orderedFirewallPolicyIds": { "beforeSystemDefined": [...],
  "afterSystemDefined": [...] } }` -- full desired ordering. Response echoes the
  same object.

Not paginated; no `filter`. No read-only/deprecated fields in the ordering
object. (Context: the policy `index` field is deprecated/no-effect; ordering must
be done via this endpoint.)

### 2.8 Networks -- `/v1/sites/{siteId}/networks`

Network object:

| Field | Type | Required (write) | Read-only | Constraints |
|---|---|---|---|---|
| `management` | string (enum) | yes | no | only `UNMANAGED` documented |
| `name` | string | yes | no | display name |
| `enabled` | boolean | yes | no | |
| `vlanId` | integer `int32` | yes | no | `[1 .. 4009]`; `1` for the default network, `>= 2` otherwise |
| `dhcpGuarding` | object | optional | no | `{ trustedDhcpServerIpAddresses: [str] }`; omit/`null` = disabled |
| `id` | `string <uuid>` | -- | yes | server-assigned |
| `metadata` | object | -- | yes | `{ origin: string }` response-only |
| `default` | boolean | -- | yes | whether this is the default network |

`dhcpGuarding.trustedDhcpServerIpAddresses`: array of string (rogue-DHCP
protection; not DHCP service config). No item-format constraint documented. This
is the **only** DHCP-related field; there is no DHCP-provided-DNS field.

Endpoints:

| Method | Path | Result |
|---|---|---|
| GET | `/networks` | `200` paginated list |
| GET | `/networks/{networkId}` | `200` single |
| POST | `/networks` | `201` Create; body `{management, name, enabled, vlanId, dhcpGuarding?}` |
| PUT | `/networks/{networkId}` | `200` Update (full replace); same body |
| DELETE | `/networks/{networkId}` | `200`; query `force` (bool, default `false`) |
| GET | `/networks/{networkId}/references` | `200` `{ "referenceResources": [ {} ] }` (item schema not expanded) |

Path params: `siteId` (uuid, req) always; `networkId` (uuid, req) on item
endpoints.

### 2.9 DNS Policies (context only -- NOT in v1.0.0 scope)

`/v1/sites/{siteId}/dns/policies` (A-records). Object: `type` (`A_RECORD`),
`enabled`, `domain` (1..127 chars), `ipv4Address`, `ttlSeconds` (0..86400), plus
read-only `id`, `metadata`. Not DHCP DNS; no `networkId` linkage. Trivially
addable later with the same client, but out of scope for the firewall goal.

### 2.10 Cross-cutting read-only / deprecated

- Read-only, never sent in bodies: `id`, `index` (policies), `metadata`
  (+`metadata.origin`), `default` (networks).
- Deprecated: policy `index` and ACL-rule `index` (no effect; use the reordering
  endpoints). No deprecated fields for zones/networks/matching-lists.
- Read-only reference endpoints: Supporting Resources group (out of scope).

---

## 3. Collection Structure

Install path: `ansible_collections/starnix/unifi/`.

```
starnix/unifi/
├── galaxy.yml
├── README.md
├── LICENSE                          # GPL-3.0-or-later
├── meta/
│   └── runtime.yml
├── changelogs/
│   ├── config.yaml
│   └── fragments/.gitkeep
├── plugins/
│   ├── module_utils/
│   │   └── unifi.py                 # HTTP client, arg-spec helpers, diff helpers
│   ├── doc_fragments/
│   │   └── auth.py                  # shared connection DOCUMENTATION fragment
│   └── modules/
│       ├── unifi_firewall_zone.py
│       ├── unifi_firewall_group.py         # traffic-matching-lists
│       ├── unifi_firewall_policy.py
│       ├── unifi_firewall_policy_order.py
│       ├── unifi_network.py
│       └── unifi_site_info.py
└── tests/
    ├── sanity/
    │   └── ignore-2.21.txt          # only versions we actually run in CI
    ├── unit/
    │   ├── requirements.txt
    │   └── plugins/
    │       ├── module_utils/test_unifi.py
    │       └── modules/
    │           ├── test_unifi_firewall_zone.py
    │           ├── test_unifi_firewall_policy.py
    │           ├── test_unifi_firewall_group.py
    │           ├── test_unifi_firewall_policy_order.py
    │           └── test_unifi_network.py
    └── integration/
        └── targets/
            ├── setup_unifi/                 # resolves siteId, shares vars, guards
            ├── schema_discovery/            # dumps live opaque shapes (BUILD PREREQ)
            ├── unifi_firewall_zone/
            ├── unifi_firewall_group/
            ├── unifi_firewall_policy/
            ├── unifi_firewall_policy_order/
            └── unifi_network/
```

**No `molecule/` tree** (deleted -- finding R-mol). **No `.github` build-ignore
churn beyond what is actually present.**

### 3.1 `galaxy.yml`

```yaml
namespace: starnix
name: unifi
version: 1.0.0
readme: README.md
authors:
  - Sasha Karcz <sasha.karcz@gmail.com>
description: >-
  Manage the UniFi zone-based firewall (zones, policies, policy ordering,
  address/port matching lists) and networks through the official UniFi
  Network Integration API (v1).
license:
  - GPL-3.0-or-later
tags:
  - networking
  - firewall
  - unifi
  - ubiquiti
  - security
repository: https://github.com/usenix17/starnix.unifi
issues: https://github.com/usenix17/starnix.unifi/issues
build_ignore:
  - .github
  - tests/output
  - "*.tar.gz"
dependencies: {}
```

### 3.2 `meta/runtime.yml`

```yaml
---
requires_ansible: ">=2.21.0"        # matches what CI actually tests (finding R10/R6/R16b)
action_groups:
  unifi:
    - unifi_firewall_zone
    - unifi_firewall_group
    - unifi_firewall_policy
    - unifi_firewall_policy_order
    - unifi_network
    - unifi_site_info
```

The `unifi` action group enables one-shot `module_defaults`:

```yaml
module_defaults:
  group/starnix.unifi.unifi:
    host: heimdal.starnix.net
    api_key: "{{ unifi_api_key }}"
    site: default
```

### 3.3 `changelogs/config.yaml`

Standard antsibull-changelog config; **default output location** (collection root
`CHANGELOG.rst`, no `../` template -- finding R14), `keep_fragments: false`,
`title: Starnix UniFi Collection`. One fragment per PR under
`changelogs/fragments/`; `antsibull-changelog release --version X.Y.Z` assembles
at tag time. CI fails a PR touching `plugins/**` without a fragment.

---

## 4. `plugins/module_utils/unifi.py` -- Shared Client

The load-bearing core: connection arg-spec, HTTP client, pagination, site
resolution, error mapping, and diff helpers.

### 4.1 Connection argument spec

```python
def unifi_argument_spec():
    return dict(
        host=dict(type="str", required=True),
        port=dict(type="int", default=443),
        api_key=dict(type="str", required=True, no_log=True,
                     fallback=(env_fallback, ["UNIFI_API_KEY"])),
        validate_certs=dict(type="bool", default=True),
        ca_path=dict(type="path"),
        timeout=dict(type="int", default=30),
        site=dict(type="str", default="default"),
        api_base_path=dict(type="str", default="/proxy/network/integration"),
    )
```

Decisions tied to the reviews:

- `api_key` -> `X-API-KEY`, `no_log=True`, env fallback `UNIFI_API_KEY`
  (confirmed correct -- finding R15).
- **`use_proxy` is removed** (findings R11/O1). It collided with ansible's own
  `use_proxy` (HTTP proxy env-var toggle, a real `Request` kwarg) and gated an
  undocumented `/integration`-only prefix. Replaced by a single `api_base_path`
  string defaulting to the only documented prefix `/proxy/network/integration`.
  It exists solely as an escape hatch; the default is the supported value.
- `validate_certs` + `ca_path` -> `Request(validate_certs=..., ca_path=...)`.
  Homelab private-CA support. If `validate_certs=false` and `ca_path` is set, the
  module `warn`s that the two are contradictory (finding O17). `ca_path`
  (`type="path"`) expands `~`.
- `site` accepts a UUID (authoritative) or the literal `"default"`. Name-based
  matching against undocumented site fields is **not** performed (finding
  R7/R12/O11).
- `port` retained (default 443) though `/proxy/network` deployments are
  effectively always 443; harmless surface (finding O19).

### 4.2 `UniFiClient`

```python
from ansible.module_utils.urls import Request
from ansible.module_utils.six.moves.urllib.error import HTTPError, URLError
from ansible.module_utils.six.moves.urllib.parse import urlencode
import json


class UniFiError(Exception):
    def __init__(self, msg, status=None, code=None, envelope=None, request_path=None):
        super().__init__(msg)
        self.status = status
        self.code = code
        self.envelope = envelope
        self.request_path = request_path


class UniFiClient:
    def __init__(self, host, port, api_key, validate_certs=True, ca_path=None,
                 timeout=30, api_base_path="/proxy/network/integration"):
        self._base = "https://%s:%s" % (host, port)
        self._prefix = api_base_path.rstrip("/")
        self._request = Request(
            headers={
                "X-API-KEY": api_key,
                "Accept": "application/json",
                "Content-Type": "application/json",
            },
            validate_certs=validate_certs,
            ca_path=ca_path,
            timeout=timeout,
        )

    def _url(self, path, query=None):
        url = "%s%s%s" % (self._base, self._prefix, path)
        if query:
            q = {k: v for k, v in query.items() if v is not None}
            if q:
                url = "%s?%s" % (url, urlencode(q))
        return url

    def request(self, method, path, query=None, body=None):
        data = json.dumps(body).encode("utf-8") if body is not None else None
        url = self._url(path, query)
        try:
            resp = self._request.open(method, url, data=data)
            raw = resp.read()
        except HTTPError as e:          # HTTPError is a URLError subclass: catch first
            raise self._to_unifi_error(e)
        except URLError as e:
            raise UniFiError("Connection failed: %s" % (e.reason,))
        if not raw:
            return {}
        try:
            return json.loads(raw)
        except ValueError as e:
            raise UniFiError("Malformed JSON in response: %s" % (e,))
```

**Status handling (findings R2/O3).** `request()` no longer returns or reads
`resp.status`. Success is signaled by the absence of an exception (`Request.open`
raises `HTTPError` on non-2xx). Callers key off exceptions, so an unstable
`.status`/`.getcode()` attribute is never touched. This removes the
`AttributeError`-on-every-call risk entirely.

**Error mapping (findings R3/O4).** Read the `HTTPError` body exactly once,
defensively, and never assume `reason` is populated:

```python
    def _to_unifi_error(self, http_err):
        body = {}
        try:
            payload = http_err.read()      # read once
            if payload:
                body = json.loads(payload)
        except Exception:
            body = {}
        # message precedence: envelope message, then code, then transport reason
        msg = (body.get("message")
               or body.get("code")
               or getattr(http_err, "reason", None)
               or str(http_err)
               or "HTTP error")
        status = body.get("statusCode", getattr(http_err, "code", None))
        parts = ["%s %s: %s" % (status, body.get("statusName", ""), msg)]
        if body.get("code"):
            parts.append("(code=%s)" % body["code"])
        if body.get("requestId"):
            parts.append("[requestId=%s]" % body["requestId"])
        return UniFiError(
            " ".join(parts),
            status=status,
            code=body.get("code"),
            envelope=body,
            request_path=body.get("requestPath"),
        )
```

Convenience verbs `get/post/put/patch/delete` wrap `request`.

### 4.3 Pagination

```python
    def paginate(self, path, query=None, page_size=200):
        query = dict(query or {})
        offset = 0
        while True:
            page = self.request("GET", path,
                                 query=dict(query, offset=offset, limit=page_size))
            data = page.get("data", []) or []
            for item in data:
                yield item
            count = page.get("count", len(data))
            total = page.get("totalCount", 0)
            if count == 0:
                break
            offset += count                 # advance by items RETURNED, not page_size
            if offset >= total:
                break
```

**Termination fix (findings R1/CRITICAL, R12, O5).** Advance `offset += count`
(items actually returned), matching the reference rule `offset + count >=
totalCount`. Advancing by the requested `page_size` skips items whenever the
server applies a smaller `limit` than requested, producing false "not found" and
duplicate POSTs. `count == 0` guards an empty page. `page_size=200` (documented
max) minimizes round-trips.

### 4.4 Site resolution

```python
    _UUID_RE = re.compile(
        r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I)

    def resolve_site(self, site):
        if self._UUID_RE.match(site or ""):
            return site
        # Site object schema is a documented gap: only `id` is confirmed.
        # We do NOT match on invented fields (name/desc/isDefault/...).
        if site == "default":
            sites = list(self.paginate("/v1/sites"))
            if len(sites) == 1:
                return sites[0]["id"]       # single-site controller: unambiguous
            raise UniFiError(
                "site='default' is ambiguous on a multi-site controller "
                "(%d sites). Pass the site UUID explicitly; the UniFi Site "
                "object schema is not documented, so name matching is "
                "unavailable." % len(sites))
        raise UniFiError(
            "site=%r is not a UUID. Only a site UUID (or 'default' on a "
            "single-site controller) is supported, because the UniFi site "
            "object exposes only `id` in the documented schema." % (site,))
```

**Site resolution fix (findings R7/R12/O11).** All matching on undocumented
fields (`isDefault`, `name`, `desc`, `internalReference`) is removed -- it
contradicted the collection's own "don't guess schema" discipline and risked
silently binding writes to the wrong site. Only UUID passthrough and the
single-site `"default"` shortcut (with a hard failure on multi-site ambiguity)
remain. When a live `GET /v1/sites` later confirms a name field, name matching
can be added as a minor bump.

### 4.5 `UniFiModule` binding

```python
class UniFiModule:
    def __init__(self, module):
        self.module = module
        p = module.params
        if p.get("ca_path") and not p["validate_certs"]:
            module.warn("ca_path is set but validate_certs=false; the CA path "
                        "is ignored while certificate validation is disabled.")
        self.client = UniFiClient(
            host=p["host"], port=p["port"], api_key=p["api_key"],
            validate_certs=p["validate_certs"], ca_path=p.get("ca_path"),
            timeout=p["timeout"], api_base_path=p["api_base_path"],
        )
        self.site_id = self.client.resolve_site(p["site"])

    def fail(self, msg, **kw):
        self.module.fail_json(msg=msg, **kw)

    def handle(self, exc):
        self.module.fail_json(
            msg=str(exc),
            unifi_status=exc.status,
            unifi_code=exc.code,
            unifi_request_path=exc.request_path,
            unifi_error=exc.envelope,
        )
```

Every module wraps its body in `try/except UniFiError as e: um.handle(e)` so the
full §2.1 envelope (`code`, `statusName`, `requestPath`, `requestId`) reaches the
user (G5).

### 4.6 Diff / comparison helpers

Two problems the reference forces:

1. Read-only/server-managed fields (`id`, `index`, `metadata`, `default`) must
   never be sent and must be excluded from comparison.
2. Opaque nested objects (`trafficFilter`, `action`, `schedule`,
   `ipProtocolScope`) must be compared **only on the keys the user actually set**
   -- never blanket deep-equal against a server-normalized blob (findings
   R1/R2/R8, O2/O8).

```python
def prune(value):
    """Recursively drop None so omitted == not set."""
    if isinstance(value, dict):
        return {k: prune(v) for k, v in value.items() if v is not None}
    if isinstance(value, list):
        return [prune(v) for v in value]
    return value


def _canon(value):
    """Order-insensitive canonical form for SET-typed fields."""
    return sorted(json.dumps(v, sort_keys=True) for v in value)


def subset_equal(desired, current, set_keys=()):
    """
    True iff, for every key the user specified in `desired`, the current value
    matches. Keys present only in `current` (server-injected defaults, expanded
    opaque sub-keys) are INVISIBLE. Nested dicts recurse with the same rule.
    `set_keys` names fields compared order-insensitively as sets.
    """
    for k, dv in desired.items():
        if dv is None:                       # user did not set it -> ignore
            continue
        cv = current.get(k)
        if k in set_keys and isinstance(dv, list) and isinstance(cv, list):
            if _canon(dv) != _canon(cv):
                return False
        elif isinstance(dv, dict) and isinstance(cv, dict):
            if not subset_equal(dv, cv, set_keys):
                return False
        else:
            if dv != cv:
                return False
    return True


def needs_update(desired_body, current_obj, set_keys=()):
    """
    Returns (changed, {"before": ..., "after": ...}).
    changed is True iff some user-specified key in desired_body differs from
    current_obj under subset semantics. The diff shows only the desired keys and
    their current counterparts, so --diff is meaningful and not noisy.
    """
    changed = not subset_equal(desired_body, current_obj, set_keys)
    before = {k: current_obj.get(k) for k in desired_body if desired_body[k] is not None}
    after = {k: v for k, v in desired_body.items() if v is not None}
    return changed, {"before": before, "after": after}
```

**Comparison model decision (findings R1/R2/R8, O2/O8) -- the single most
important resolution in this design.** The draft compared the whole pruned server
object deep-equal against the desired body. That guarantees perpetual `changed`
the moment the server normalizes or injects defaults into an opaque object (which
`trafficFilter` does on every real controller). We replace it with **subset
semantics**: the module only asserts the keys the user specified, and ignores
server keys the user never set. This is the only idempotency model implementable
without live schema data, and it is correct for a declarative tool: "enforce what
was declared; ignore what was not."

**Outgoing bodies are never canonicalized/sorted (findings R3/R6/R8, O8).** SET
fields (`connectionStateFilter`, `networkIds`,
`trustedDhcpServerIpAddresses`) are compared order-insensitively via `set_keys`,
but the **request body sends the user's array verbatim** (deduped only if the API
rejects duplicates). We never `sorted(set(...))` into the wire body -- that would
silently reorder user intent and could fight a controller that preserves order.

---

## 5. Per-Module Specification

Common skeleton:

```python
DOCUMENTATION = r"""... extends_documentation_fragment: [starnix.unifi.auth] ..."""
EXAMPLES = r"""..."""
RETURN = r"""..."""

from ansible.module_utils.basic import AnsibleModule
from ansible_collections.starnix.unifi.plugins.module_utils.unifi import (
    UniFiModule, unifi_argument_spec, UniFiError, needs_update, prune,
)

def main():
    spec = unifi_argument_spec()
    spec.update(<module spec>)
    module = AnsibleModule(argument_spec=spec, supports_check_mode=True, ...)
    um = UniFiModule(module)
    try:
        run(um)
    except UniFiError as e:
        um.handle(e)

if __name__ == "__main__":
    main()
```

Common conventions:

- `supports_check_mode=True`. In check mode the module computes `changed` and the
  diff, then returns **before** any POST/PUT/PATCH/DELETE (G2).
- `--diff` populates `result["diff"]` from `needs_update`.
- `state: present` (default) / `absent`.
- **Lookup:** each resource accepts an optional `id` (UUID, authoritative) and a
  human `name`. `id` -> GET by id. Else **paginate the collection and match by
  `name` client-side** (no server-side `filter` in v1.0.0 -- finding R16/O16).
  Duplicate `name` -> `fail_json` (ambiguous; disambiguate with `id`).
- **PUT is a full-replace, honestly modeled (findings R2/R8, O2/O13).** The
  merge-over-current strategy is removed. On update the module builds the request
  body **entirely from user params** (the API already requires the full body).
  Idempotency comparison is desired-vs-current under subset semantics, so drift
  in a field the user *did* declare is detected and corrected; fields the user
  did not declare are the API's replace-default. This is documented per module.

### 5.1 `unifi_firewall_zone`

Manages custom zones. Body `{name, networkIds}`; response adds `id`, `metadata`.

Module arg-spec:

| param | type | required | default | choices | notes |
|---|---|---|---|---|---|
| `name` | str | yes | -- | -- | zone name; primary lookup key |
| `id` | str | no | -- | -- | zone UUID; authoritative lookup |
| `network_ids` | list(str) | no | -- | -- | maps `networkIds`; `>= 0` items (empty allowed) |
| `state` | str | no | `present` | present/absent | |

Decisions:

- **`networks` (name-convenience) is dropped for v1.0.0.** It required
  name->UUID resolution and mutual-exclusion bookkeeping; defer to a later minor.
  Only `network_ids` (UUIDs) is accepted.
- **`networkIds` is always sent on create (finding R7).** It is API-required with
  `>= 0` items, so an omitted `network_ids` defaults to `[]` in the body, never
  missing. Post-lookup validation: on create, `network_ids` may be omitted
  (=> `[]`) but must be a list if given.

Body: `{"name": name, "networkIds": network_ids or []}`.

Idempotency: lookup by `id` else by `name`. Compare `{name, networkIds}` with
`needs_update(..., set_keys={"networkIds"})` (membership, not order). Read-only
keys (`id`, `metadata`) are simply absent from the desired body, so subset
semantics ignore them.

State: `present`+absent -> POST (201); `present`+found+diff -> PUT full replace
(both fields sent); `present`+found+no diff -> no-op; `absent`+found -> DELETE
(system-zone rejection deferred to API and surfaced); `absent`+not found -> no-op.

RETURN:
```yaml
zone: {id, name, networkIds, metadata}   # {} when absent
changed: <bool>
diff: {before, after}                     # with --diff
```

### 5.2 `unifi_firewall_group` (traffic-matching lists)

Manages `/traffic-matching-lists`. Named "group" (UniFi admin vernacular).
Body `{type, name, items}`; response adds `id`.

Module arg-spec:

| param | type | required | default | choices | notes |
|---|---|---|---|---|---|
| `name` | str | yes | -- | -- | list name; lookup key |
| `id` | str | no | -- | -- | list UUID; authoritative lookup |
| `type` | str | no | -- | `PORTS`, `IP_ADDRESSES` | discriminator; required on create (enforced in `run()`) |
| `items` | list(dict) | no | -- | -- | opaque list of dicts, passed through verbatim; non-empty on create |
| `state` | str | no | `present` | present/absent | |

Decisions:

- **`items[]` is opaque** (schema `{}` in export): `type=list, elements=dict`,
  sent unchanged, compared with subset/deep-equality per element. **No
  `items_ordered=false` unordered mode (findings R9/O12/O-cut).** Canonicalizing
  an unknown-shape list as an unordered set is unimplementable correctly; cut.
  Comparison is order-sensitive.
- **`type` uses hard `choices=[PORTS, IP_ADDRESSES]` (findings R5/O7/O14).**
  `PORTS` is confirmed; `IP_ADDRESSES` is inferred. We list it as a real choice
  and note in DOCUMENTATION prose that the set may widen (a non-breaking minor
  bump). This keeps `validate-modules` green (no doc/spec `choices` mismatch --
  the "soft choices in prose only" pattern is reserved for the four genuinely
  unenumerated policy enums). If the controller rejects a value, the API error
  surfaces.
- **`type` change on an existing list is refused client-side unless
  `recreate: true` (finding R5).** A discriminator flip via PUT is speculative
  and likely 4xxs. Add:

  | param | type | default | notes |
  |---|---|---|---|
  | `recreate` | bool | `false` | allow changing an existing list's `type` by DELETE+POST |

  If `type` differs and `recreate=false` -> `fail_json` with a clear message.
  If `recreate=true` -> DELETE then POST (reported `changed`).
- **`items` normalization risk is documented** (finding R5): the server may add
  per-item ids / reorder / expand ranges. Subset semantics mitigate server-added
  keys, but if the server reorders `items` the module may report `changed`; the
  module GETs after write and returns the authoritative object, and DOCUMENTATION
  tells users to feed back the server's returned `items` shape if churn appears.
  `schema_discovery` captures the real shape.

Body: `{"type": type, "name": name, "items": items}`.

Idempotency: lookup by `id` else `name`; compare `{type, name, items}`
(subset semantics, `items` order-sensitive).

RETURN:
```yaml
firewall_group: {id, type, name, items}   # {} when absent
changed: <bool>
diff: {before, after}
```

### 5.3 `unifi_firewall_policy`

The richest module. Manages `/firewall/policies`.

**Nested-object model decision (findings R1/R2, O2/O12).** For v1.0.0 the four
unenumerated nested objects -- `action`, `source.trafficFilter` /
`destination.trafficFilter`, `ipProtocolScope`, `schedule` -- are **single opaque
`dict` pass-throughs**, not typed sub-specs with `raw` escape hatches and
soft-enum validation. The draft's "typed keys + `raw` + soft-enum" triple is
three overlapping forward-compat mechanisms for objects whose schema we admit we
do not know; it is speculative API surface we would owe forever under semver.
`connectionStateFilter` and `ipsecFilter` are the only fields the doc actually
pins, so they get hard `choices`. Typed sub-options for the opaque objects arrive
in v1.1 *after* `schema_discovery` yields real shapes.

Module arg-spec:

| param | type | required | default | choices | notes |
|---|---|---|---|---|---|
| `name` | str | yes | -- | -- | policy name; lookup key |
| `id` | str | no | -- | -- | policy UUID; authoritative lookup |
| `enabled` | bool | no | `true` | -- | maps `enabled` |
| `description` | str | no | -- | -- | |
| `action` | dict | cond. | -- | -- | opaque; e.g. `{type: ALLOW}`; required on create |
| `source` | dict | cond. | -- | -- | opaque; `{zoneId, trafficFilter}`; required on create |
| `destination` | dict | cond. | -- | -- | opaque; `{zoneId, trafficFilter}`; required on create |
| `ip_protocol_scope` | dict | cond. | -- | -- | opaque; maps `ipProtocolScope`; required on create |
| `connection_state_filter` | list(str) | no | -- | `NEW,INVALID,ESTABLISHED,RELATED` | maps `connectionStateFilter`; hard choices; omit => match all |
| `ipsec_filter` | str | no | -- | `MATCH_ENCRYPTED,MATCH_NOT_ENCRYPTED` | maps `ipsecFilter`; hard choices; omit => match all |
| `logging_enabled` | bool | no | `false` | -- | maps `loggingEnabled` (API-required; default satisfies) |
| `schedule` | dict | no | -- | -- | opaque; omit/null => always active |
| `state` | str | no | `present` | present/absent | |

Opaque dicts (`action`, `source`, `destination`, `ip_protocol_scope`,
`schedule`) are `type="dict"` with **no `options=`** -- passed through verbatim
to the corresponding camelCase API field. DOCUMENTATION for each states: *"This
object's schema is not documented by the UniFi Integration API export. Obtain a
working shape by GETting an existing policy (see the `schema_discovery`
integration target) and pass it here as a dict; it is sent unchanged."* For
`source`/`destination`, the module maps the Ansible key `zoneId` (or a snake
`zone_id`) and `trafficFilter` straight through; no resolution of zone names in
v1.0.0.

**Create requiredness.** Cannot be expressed as static `required_if` (it depends
on "does the resource already exist"), so it is enforced in `run()` after lookup:
on create, require `action`, `source`, `destination`, `ip_protocol_scope`,
`name`, `enabled`, `logging_enabled` -- `fail_json` listing any missing.

**PUT is full-replace, no merge (findings R2/R8, O2/O13).** On update the body is
built entirely from user params, so the module **requires the full policy body on
update too** (documented). This is honest to a replace API and eliminates: (a)
the drift-suppression bug where the module reports convergence while an
un-respecified field has drifted in the UI; and (b) round-tripping a
server-normalized opaque `trafficFilter` (which may contain response-only sub-keys
PUT rejects) back into the request. The subset comparison still lets `--diff`
show only what the user declared.

**PATCH optimization removed (findings R4/O-cut).** The "PATCH when only
`loggingEnabled` differs" shortcut entangled correctness with the (now removed)
merge diff and could mask real drift. Ship PUT-only for v1.0.0; the sole
documented PATCH field (`loggingEnabled`) is covered by a full PUT. Revisit after
`schema_discovery` proves the round-trip is stable.

Body build:
```python
body = {
    "enabled": enabled,
    "name": name,
    "description": description,               # pruned if None
    "action": action,                         # opaque, verbatim
    "source": source,                         # opaque, verbatim
    "destination": destination,               # opaque, verbatim
    "ipProtocolScope": ip_protocol_scope,     # opaque, verbatim
    "connectionStateFilter": connection_state_filter,   # user order, verbatim
    "ipsecFilter": ipsec_filter,              # pruned if None
    "loggingEnabled": logging_enabled,
    "schedule": schedule,                     # pruned if None
}
body = prune(body)
# id, index, metadata never included
```

Idempotency: lookup by `id` else `name` (dup name -> fail). Compare with
`needs_update(body, current, set_keys={"connectionStateFilter"})`. `set_keys`
makes `connectionStateFilter` order-insensitive (it is a documented unique set).
Opaque nested dicts are compared under subset semantics (only user-set keys
asserted), so server-injected `trafficFilter` defaults never force perpetual
`changed`. After a create/update the module GETs the result and returns it
authoritatively.

State: POST (201) / PUT (200) / DELETE (200, resolving name->id first).

RETURN:
```yaml
firewall_policy:      # full §2.6 response object, {} when absent
  id, enabled, name, description, index, action, source, destination,
  ipProtocolScope, connectionStateFilter, ipsecFilter, loggingEnabled,
  schedule, metadata
changed: <bool>
diff: {before, after}
```

### 5.4 `unifi_firewall_policy_order`

Declarative full-replacement of ordering for one directed zone pair via
`/firewall/policies/ordering`.

Module arg-spec:

| param | type | required | default | notes |
|---|---|---|---|---|
| `source_zone_id` | str | yes | -- | -> `sourceFirewallZoneId` query param |
| `destination_zone_id` | str | yes | -- | -> `destinationFirewallZoneId` |
| `before_system_defined` | list(str) | no | -- | ordered policy UUIDs before system rules |
| `after_system_defined` | list(str) | no | -- | ordered policy UUIDs after system rules |
| `state` | str | no | `present` | `absent` rejected with a clear message (no delete-ordering op; clear a bucket with `[]`) |

`required_one_of`: at least one of `before_system_defined` /
`after_system_defined`.

Decisions (all from the reviews):

- **Zone params are UUID-only.** The `source_zone`/`destination_zone` name
  conveniences and `identify_by: name` policy-name resolution are dropped for
  v1.0.0 (same "don't build resolution on undocumented/opaque data" discipline;
  reduces speculative surface). Users feed policy UUIDs from registered
  `unifi_firewall_policy` results.
- **`prune_unlisted` removed (findings R6/O9/O-cut).** Additive mode has no
  defined fixed point against a full-replace endpoint and can report `changed`
  indefinitely. The module is **strict declarative full-replace only**: the two
  lists ARE the complete desired ordering for the pair. To keep an existing
  policy, list it. Documented loudly.
- **`validate_membership` removed (findings R5/O10/O-cut).** It cross-checked a
  policy's `source.zoneId`/`destination.zoneId` against the pair -- an invented
  invariant (the reference never says a policy's pair is determined solely by
  those fields; `trafficFilter` can scope zones). It would false-fail on valid
  orderings and forced a full policy list every run. Cut. The API is the
  authority: a bogus policy UUID in the body is rejected and surfaced.

Body:
```python
body = {"orderedFirewallPolicyIds": {
    "beforeSystemDefined": before_system_defined or [],
    "afterSystemDefined": after_system_defined or [],
}}
```
Order is preserved verbatim (order == evaluation order).

Idempotency: GET current ordering for the pair; compare both arrays
**positionally** (order matters). `changed` iff either bucket differs in content
or order.

Check mode: before = current arrays, after = desired arrays; PUT skipped.

RETURN:
```yaml
ordering:
  source_zone_id, destination_zone_id
  orderedFirewallPolicyIds: {beforeSystemDefined, afterSystemDefined}
changed: <bool>
diff: {before, after}
```

### 5.5 `unifi_network`

Manages `/networks`. Body `{management, name, enabled, vlanId, dhcpGuarding?}`;
response adds `id`, `metadata`, `default`.

**Scope honesty (Non-Goals).** DOCUMENTATION states up front: no subnet/CIDR/
gateway/DHCP-range/lease/DHCP-DNS fields exist in this API version.

Module arg-spec:

| param | type | required | default | choices | notes |
|---|---|---|---|---|---|
| `name` | str | yes | -- | -- | lookup key |
| `id` | str | no | -- | -- | network UUID; authoritative lookup |
| `management` | str | no | `UNMANAGED` | `UNMANAGED` | hard choice (only documented value); prose notes set may widen |
| `enabled` | bool | no | `true` | -- | |
| `vlan_id` | int | cond. | -- | -- | maps `vlanId`; `[1..4009]`; required on create |
| `dhcp_guarding` | dict | no | -- | -- | sub-spec below; omit/null => disabled |
| `state` | str | no | `present` | present/absent | |
| `force` | bool | no | `false` | -- | on `absent`, passes `?force=true` to DELETE |

`dhcp_guarding` sub-spec (this one IS documented, so it is typed):
```python
dhcp_guarding=dict(type="dict", options=dict(
    trusted_dhcp_server_ip_addresses=dict(type="list", elements="str", default=[]),
))
```
-> `{"trustedDhcpServerIpAddresses": [...]}`.

Decisions:

- **`management` uses hard `choices=[UNMANAGED]` (findings R5/O7).** Only value
  documented; not a soft enum.
- **`vlan_id` validation is only the `[1..4009]` bound (findings R13/O13).** The
  "non-default network must be `vlan >= 2`" rule is un-knowable pre-create and is
  dropped client-side; the API rejects it authoritatively.
- **No client-side default-network delete refusal (findings R8/O18).** The draft
  refused deleting `default: true` unless `force`, then deferred to the API
  anyway -- redundant double-gating that can diverge from server policy. Removed.
  DELETE is sent (with `force` if given) and the API is authoritative.
- **`references` on delete failure is kept (finding O18, a genuine nice touch).**
  If `absent` DELETE fails, the module GETs `/networks/{id}/references` and
  includes `referenceResources` in the failure output, turning "delete failed"
  into "here is what still references it."
- Outgoing `trustedDhcpServerIpAddresses` is sent verbatim; compared
  order-insensitively via `set_keys`.

Body:
```python
body = {
    "management": management,
    "name": name,
    "enabled": enabled,
    "vlanId": vlan_id,
    "dhcpGuarding": ({"trustedDhcpServerIpAddresses": ips} if dhcp_guarding else None),
}
body = prune(body)
```

Idempotency: lookup by `id` else `name`; compare with
`needs_update(body, current, set_keys={"trustedDhcpServerIpAddresses"})`.
Read-only `id`/`metadata`/`default` are absent from the desired body -> ignored.
PUT is full-replace built from user params (no merge).

RETURN:
```yaml
network: {id, management, name, enabled, vlanId, dhcpGuarding, metadata, default}
changed: <bool>
diff: {before, after}
```

### 5.6 `unifi_site_info`

Read-only helper wrapping `GET /v1/info` and `GET /v1/sites`. `argument_spec =
unifi_argument_spec()` only; always `changed: false`; `supports_check_mode=True`.
Useful as a connectivity check and to discover site UUIDs (site schema is a
documented gap, so this is how users obtain the UUID they must pass to `site`).

RETURN:
```yaml
application_version: <str>          # from /v1/info
sites: [ {id, ...raw fields...}, ... ]   # returned verbatim, no field assumptions
```

---

## 6. Policy Ordering Strategy (detailed)

The ordering endpoint is per **directed zone pair** and splits user policies into
`beforeSystemDefined` / `afterSystemDefined` around the immutable system rules.
Consequences baked into `unifi_firewall_policy_order`:

1. **One invocation == one zone pair.** Multiple pairs = multiple tasks (or a
   loop over pair dicts). The module never touches a pair it was not given.
2. **Strict declarative full-replace per bucket.** The two lists are the complete
   desired ordering (matching the API's replace contract). No additive mode.
3. **Order == evaluation order** (index 0 first), preserved verbatim; comparison
   is positional.
4. **Cross-bucket moves** are expressed by listing a policy UUID in the other
   bucket; the module diffs both arrays together.
5. **No client-side membership validation.** Bogus UUIDs are rejected by the API
   and surfaced via the standard envelope.

Composition with `unifi_firewall_policy`: create/update policies first (each
returns its `id`), then one `unifi_firewall_policy_order` task per zone pair
asserts evaluation order using those ids. This mirrors the API's own split (the
policy `index` is read-only/deprecated; ordering is only mutable through this
endpoint).

Example:
```yaml
- name: Ensure LAN->WAN policies exist
  starnix.unifi.unifi_firewall_policy:
    name: "{{ item.name }}"
    enabled: true
    logging_enabled: false
    action: { type: "{{ item.action }}" }
    source: { zoneId: "{{ lan_zone_id }}" }
    destination: { zoneId: "{{ wan_zone_id }}" }
    ip_protocol_scope: { ipVersion: IPV4 }
  loop: "{{ lan_wan_policies }}"
  register: pol

- name: Order LAN->WAN policies
  starnix.unifi.unifi_firewall_policy_order:
    source_zone_id: "{{ lan_zone_id }}"
    destination_zone_id: "{{ wan_zone_id }}"
    before_system_defined: "{{ pol.results | map(attribute='firewall_policy.id') | list }}"
    after_system_defined: []
```

---

## 7. Testing & Galaxy Publish Plan

### 7.1 Sanity

`ansible-test sanity --docker` (or `--venv`) on **ansible-core 2.21 only** (the
confirmed local/CI version). `requires_ansible: ">=2.21.0"` matches exactly what
CI runs -- we do not declare a 2.18/2.19 floor we cannot exercise (findings
R10/R6/R16b/O6). `validate-modules` must be green before any tag: DOCUMENTATION/
EXAMPLES/RETURN present and valid, arg-spec matches docs (no `choices:` in docs
for a param whose spec omits them -- our hard-choice fields have real `choices`,
so this is consistent; finding R14/O7), `no_log` on `api_key`, license header,
Python compat. `tests/sanity/ignore-2.21.txt` holds a (target: empty) allowlist;
CI asserts the sanity job is green, not merely that ignore files exist.

### 7.2 Unit (`pytest`, no network)

Mock `Request.open`. Coverage:

- `UniFiClient`: URL/prefix assembly, header injection, JSON encode/decode,
  empty-body -> `{}`.
- `_to_unifi_error`: a §2.1 envelope round-trips `status`/`code`/`request_path`/
  `requestId`; a body lacking `message` falls back to `code` then `reason` then
  `str(err)` (no `"400 : "` output); body read exactly once.
- `paginate`: multi-page walk, **server-applied-limit-smaller-than-requested**
  case (must NOT skip items), short-page/`count==0` termination, `totalCount`
  boundary, empty result.
- `resolve_site`: UUID passthrough; single-site `"default"`; multi-site
  `"default"` -> fail; non-UUID name -> fail.
- `prune`/`subset_equal`/`needs_update`: read-only exclusion, None-pruning,
  set-normalization (`connectionStateFilter`, `networkIds`,
  `trustedDhcpServerIpAddresses`), **server-injected-key invisibility** (opaque
  object with extra server keys must NOT report changed), nested-dict subset,
  false-positive-change guard.
- Per-module `run()` with a monkeypatched client returning canned objects:
  create, no-op, update (full-replace body), absent, check-mode-returns-before-
  write, `--diff` payload; group `recreate` path; network `references`-on-delete-
  failure path.

### 7.3 Integration (`ansible-test integration`, live controller)

Gated: `aliases` marks targets `unsupported` so generic CI skips them; a
dedicated secret-gated job runs against `heimdal.starnix.net` with `UNIFI_API_KEY`
+ host secrets. Per target: create -> `changed`; re-run identical -> **not
changed** (idempotency gate, G1); modify -> `changed` + diff; check-mode -> no
mutation; `absent` -> gone; `absent` again -> not changed. `block/always`
teardown removes created resources even on failure.

**`schema_discovery` is a BUILD PREREQUISITE, not just a test target (finding
R-structural).** Before the policy/group modules are considered done, this target
GETs one existing policy, one traffic-matching list, and one network and
`debug`-dumps the live `trafficFilter`, `action`, `ipProtocolScope`, `schedule`,
and `items[]` shapes. Its output is the empirical source of truth for the opaque
fields; it validates that subset-comparison converges against real
server-normalized objects, and it feeds v1.1's typed sub-options. `setup_unifi`
resolves `siteId` and shares vars.

### 7.4 DOCUMENTATION / EXAMPLES / RETURN conventions

- Every module `extends_documentation_fragment: [starnix.unifi.auth]`; the
  fragment documents `host`, `port`, `api_key`, `validate_certs`, `ca_path`,
  `timeout`, `site`, `api_base_path` once.
- Each opaque-dict param carries the explicit note about the export gap and points
  to `unifi_site_info` / the `schema_discovery` example.
- `RETURN` documents the resource key, `changed`, and `diff` with
  `type`/`returned`/`sample`.
- `EXAMPLES` show `module_defaults` group usage, UUID-based usage, check/diff, and
  the policy+order composition.
- `version_added: "1.0.0"` on every module and option.

### 7.5 CI matrix (GitHub Actions)

- `sanity` job: ansible-core 2.21 x its supported Python.
- `units` job: same, `ansible-test units --docker`.
- `integration` job: single, manual/secret-gated, live controller.
- `changelog` job: fail a PR touching `plugins/**` without a fragment.

### 7.6 Versioning

Semantic versioning from `1.0.0`. Widening a documented enum's `choices`
(e.g. confirming `IP_ADDRESSES`, adding an `ipVersion` value) is a **minor**.
Adding typed sub-options for the opaque objects is a **minor**. Renaming a param
or changing a default is **major**. antsibull-changelog fragment per PR;
`antsibull-changelog release` assembles `CHANGELOG.rst` at the root at tag time.

---

## 8. Resolved Design Decisions (adversarial review incorporation)

Each material finding, the decision, and why. "Kept" means the draft was correct;
"Changed" means the review won.

### Critical / high correctness

- **R1 / O5 -- pagination advances by requested page size, skipping items.**
  **Changed.** `paginate` now advances `offset += count` (items returned) and
  terminates on `count == 0 or offset >= totalCount`, matching the reference.
  This eliminates the silent non-idempotency / duplicate-resource bug when the
  server applies a smaller `limit` than requested.

- **R2 / O3 -- `resp.status` AttributeError on every call.** **Changed.**
  `request()` no longer reads or returns `resp.status`. Success is the absence of
  an `HTTPError`; the status attribute is never touched. Removes a 100% runtime
  failure risk.

- **R1 / R2 / R8 / O2 / O8 -- deep-equality over server-normalized opaque objects
  guarantees perpetual `changed`; merge-over-current defeats its own diff.**
  **Changed (the core resolution).** Two coupled changes: (1) comparison uses
  **subset semantics** (`subset_equal`) -- only keys the user set are asserted;
  server-injected/expanded keys are invisible. (2) The **merge-over-current PUT
  strategy is removed**; PUT bodies are built entirely from user params (honest to
  a replace API), and the full policy/network body is required on update. Together
  these fix perpetual-`changed` on `trafficFilter`, drift-masking, and
  round-tripping response-only sub-keys PUT may reject.

- **R4 -- PATCH-when-only-`loggingEnabled`-differs.** **Changed (cut).** Its
  correctness depended on the removed merge diff. PUT-only for v1.0.0.

- **R5 / O10 -- `validate_membership` uses an invented policy-to-pair invariant.**
  **Changed (cut).** The API rejects bogus UUIDs; no client-side zone-matching.

- **R6 / O9 -- `prune_unlisted` additive ordering has no fixed point.**
  **Changed (cut).** Ordering module is strict declarative full-replace only.

- **R3 / R6 / R8 / O8 -- SET fields `sorted(set(...))` into the request body.**
  **Changed.** Set fields (`connectionStateFilter`, `networkIds`,
  `trustedDhcpServerIpAddresses`) are compared order-insensitively but the
  **outgoing body sends the user's array verbatim** (no canonicalization on the
  wire).

- **R11 / O1 -- `use_proxy` name collision + undocumented `/integration`
  prefix.** **Changed.** `use_proxy` removed; replaced by `api_base_path`
  (default `/proxy/network/integration`, the only documented prefix). No
  second-prefix "direct" mode.

### Medium

- **R7 / R12 / O11 -- `_resolve_site` matches invented site fields.**
  **Changed.** Removed all matching on `isDefault`/`name`/`desc`/
  `internalReference`. UUID passthrough + single-site `"default"` shortcut only;
  hard-fail on multi-site ambiguity. Consistent with the collection's
  don't-guess-schema discipline.

- **R5 / O7 / O14 -- soft-choices vs `validate-modules`; enum over-application.**
  **Changed.** Hard `choices` for every field with at least one documented value
  (`type` = `PORTS`/`IP_ADDRESSES`, `management` = `UNMANAGED`,
  `connectionStateFilter`, `ipsecFilter`). Soft-enum (prose, no `choices:`) is
  reserved for the genuinely unenumerated opaque objects -- which are now plain
  opaque dicts anyway, so there is no doc/spec `choices` mismatch to trip sanity.

- **R5 -- `unifi_firewall_group` `type` change / `items` churn.** **Changed.**
  Added `recreate` (default false): a `type` change is refused unless
  `recreate=true` (DELETE+POST). `items` normalization risk documented; GET-after-
  write returns the authoritative object.

- **R9 / O12 -- `items_ordered=false` unordered mode on unknown schema.**
  **Changed (cut).** Order-sensitive comparison only.

- **R8 / O18 -- client-side default-network delete refusal.** **Changed (cut).**
  DELETE deferred to the API (authoritative); `references` surfaced on failure
  (kept -- genuinely useful).

- **R13 / O13 -- client-side default-network vlan rule.** **Changed.** Only the
  `[1..4009]` bound is pre-checked; the default/non-default vlan rule is deferred
  to the API.

- **R14 / O14 -- `validate-modules` doc/spec `choices` mismatch risk.** **Kept +
  hardened.** With hard choices on documented-value fields and opaque dicts (no
  `choices:` in prose for typed params), the mismatch cannot occur. CI asserts the
  sanity job green, not merely that ignore files exist.

- **R10 / R16b / O6 -- `requires_ansible: ">=2.18.0"` unverifiable.**
  **Changed.** Floor set to `>=2.21.0` to match the only version CI runs.
  `ignore-2.18/2.19.txt` removed.

- **R16 / O16 -- server-side `filter` optimization is speculative.**
  **Changed (cut for v1.0.0).** Lookups paginate and match `name` client-side.
  Homelab scale makes this cheap; the extra filter-then-verify-then-fallback code
  path is removed.

- **O12 (nested-object triple) -- typed keys + `raw` + soft-enum.** **Changed.**
  Opaque nested objects collapse to single opaque `dict` pass-throughs for
  v1.0.0. Typed sub-options deferred to v1.1 post-`schema_discovery`.

- **R-mol / O15 -- shipped-but-unused `molecule/` tree.** **Changed (deleted).**
  No molecule scaffold in v1.0.0.

### Low / confirmations

- **R11 -- `action.type` optional -> `{"type": None}` -> 4xx.** **Resolved by the
  opaque-dict model.** `action` is now a verbatim pass-through dict; on create the
  module requires `action` (and the other three nested objects) in `run()` and
  fails fast listing what is missing. The old `raw`-escape-hatch-can-omit-`type`
  hazard no longer exists.

- **R3 / O4 -- error message `"400 : "` when body lacks `message`.**
  **Changed.** Message precedence is `message` -> `code` -> `reason` ->
  `str(err)`. `statusCode` is read from the envelope when present. Body read once.

- **O17 -- `ca_path` + `validate_certs=false` contradiction.** **Changed.**
  `UniFiModule` warns when both are set.

- **O19 -- dead `scheme` local / near-useless `port`.** **Changed.** `scheme`
  inlined as `https`; `port` kept (harmless, default 443).

- **R15 -- `no_log` + env fallback on `api_key`.** **Kept** (confirmed correct).

- **R-structural / O2 -- idempotency design depends on `schema_discovery` output
  that runs later.** **Changed.** `schema_discovery` is elevated to a **build
  prerequisite** for the policy/group modules (Section 7.3): subset-comparison
  convergence must be proven against real server-normalized objects before those
  modules are declared done.

---

## 9. Implementation Roadmap (build order)

Build bottom-up; the client and its comparison semantics gate everything.

**Phase 0 -- `module_utils/unifi.py` + tests (foundation).**
1. `unifi_argument_spec` (with `api_base_path`, no `use_proxy`).
2. `UniFiClient`: `_url`, `request` (no `.status`), `_to_unifi_error` (read-once,
   message precedence), verb wrappers.
3. `paginate` (advance by `count`).
4. `resolve_site` (UUID + single-site default; no field guessing).
5. `prune`, `subset_equal`, `needs_update` (subset semantics, `set_keys`).
6. `UniFiModule` binding (+ `ca_path`/`validate_certs` warn).
7. Unit tests for all of the above -- **especially** the applied-limit pagination
   case and the server-injected-key-invisibility comparison case. Gate: units
   green.

**Phase 1 -- `unifi_firewall_policy` (drive the hard cases first).**
Reason: it exercises opaque pass-through, subset comparison, full-replace PUT, and
create-requiredness -- the parts most likely to be wrong. Build the module, then
run the **`schema_discovery`** integration target (build prerequisite) against
`heimdal.starnix.net` to capture real `trafficFilter`/`action`/`ipProtocolScope`/
`schedule` shapes and prove re-run-identical -> not changed. If convergence fails,
STOP and re-plan the comparison before continuing.

**Phase 2 -- `unifi_firewall_zone`.** Simple `{name, networkIds}` CRUD; validates
the CRUD skeleton and set-comparison on `networkIds`.

**Phase 3 -- `unifi_firewall_group`.** Opaque `items`, hard `type` choices,
`recreate` path. Re-run `schema_discovery` for `items[]`.

**Phase 4 -- `unifi_firewall_policy_order`.** Strict full-replace, positional
diff, `state: absent` rejection. Compose with Phase 1 policies in an integration
target.

**Phase 5 -- `unifi_network`.** CRUD + `dhcp_guarding` + `force` +
`references`-on-failure.

**Phase 6 -- `unifi_site_info`.** Trivial read-only wrap; also useful during
earlier phases to discover the site UUID.

**Phase 7 -- packaging & publish.** `galaxy.yml`, `meta/runtime.yml`,
`doc_fragments/auth.py`, changelog config + fragments, README, EXAMPLES.
`ansible-test sanity` green on 2.21; assemble `CHANGELOG.rst`; tag `1.0.0`;
`ansible-galaxy collection build` + publish.

Each phase's exit criteria: unit tests green, integration create/idempotent-rerun/
modify/check-mode/absent gates green against the live controller, and (Phases 1/3)
`schema_discovery` convergence confirmed.
