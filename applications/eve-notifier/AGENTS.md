# eve-notifier

zKillboard killmail notifier. It polls kills and posts to Discord per a rules
config that is **git-synced from a separate repo**
(`github.com/ComaDoofWarrior/zKillBot`, branch `main`) by a git-sync sidecar
every 60s. The app image (`registry.starnix.net/library/eve-notifier`) is built
from a different, private source repo; this repo only carries the deployment.

Secrets (`git-pat`, `alert_webhook_url` fallback) come from OpenBao via ESO
(`ClusterSecretStore openbao`, key `cluster/eve-notifier-secrets`).

---

## Config validation gate (blue/green)

A bad config commit used to reach the running process and crashloop the pod. The
deployment now gates every synced config before it can take effect. Two config
slots, both `emptyDir`:

| Slot          | Path                     | Written by      | Read by                       |
|---------------|--------------------------|-----------------|-------------------------------|
| candidate     | `/config/current`        | git-sync (60s)  | `config-gate` (validation)    |
| live (active) | `/live/config.yaml`      | `config-gate`   | `eve-notifier` (`--config`)   |

eve-notifier reads the **live** slot, never the raw git output. The `seed-config`
initContainer copies git HEAD into `/live` once at boot so the app always starts
with a config.

### config-gate sidecar

Runs from the **eve-notifier image itself** (so it has the real parser at
`/app/eve-notifier`). On each candidate change:

1. **yamllint** (relaxed profile) -- syntax only.
2. **Real-parser check.** Copy the candidate, rewrite every Discord webhook token
   to `.../webhooks/0/blackhole` (keeps the `discord.com` host so any host
   validation still passes), boot `/app/eve-notifier` against it in a throwaway
   state dir under `timeout 8`. Surviving to the timeout (GNU `timeout` rc `124`)
   means config **and rules** loaded clean. A fast non-zero exit is a parse/schema
   error.
3. **Pass** -> `cp` candidate to `/live` (eve-notifier hot-reloads it, see below)
   and post a Discord ✅.
   **Fail** -> leave `/live` untouched (last-good keeps running) and post a
   Discord ❌ with the error. The alert webhook is read from the **last-good**
   `/live`, so a broken candidate still reaches Discord.

Verified live 2026-07-31: a good change promotes and hot-reloads; the historical
`or:`-as-a-map bug is rejected at step 2 (yamllint passes it) with `/live` and the
process untouched.

---

## Gotchas

- **eve-notifier hot-reloads its `--config` file** (fsnotify; logs
  `config: hot-reloaded rules=N`). So the `cp` to `/live` alone rolls a new config
  out -- no restart or signal needed. This is *why* gating what reaches `/live` is
  the whole protection: the app watches the gated slot, so a rejected candidate is
  never seen. (Only rules were observed to hot-reload; a global-setting change --
  poll intervals, etc. -- may need a manual pod restart, but `/live` is always
  valid so a restart is always safe.)
- **yamllint is not enough.** The bug that started this (`filter.or` written as a
  map instead of a list -> `cannot unmarshal !!map into []*rules.FilterNode`) is
  *valid YAML*. Only the real parser rejects it. That is why the gate boots the
  binary; yamllint is just a fast first pass with nicer line numbers.
- **The synced config.yaml has CRLF line endings** (edited on Windows). yamllint's
  `new-lines` rule flags CRLF as an error even under `relaxed`, so the gate's
  yamllint profile disables `new-lines`. Do not "fix" the line endings expecting
  it to matter; the Go parser handles CRLF fine.
- **No `--check` flag.** The binary only has `--config`; there is no dry-run mode,
  which is why validation boots the real process with webhooks neutered. Adding a
  native `--check` to the app source would let the gate drop the timeout/neuter
  dance -- the clean long-term fix.

---

## Changing the config

Edit `config.yaml` in `github.com/ComaDoofWarrior/zKillBot` and push to `main`.
Within ~60s git-sync pulls it, the gate validates, and either promotes it (✅ in
Discord, live within seconds via hot-reload) or rejects it (❌ in Discord, last
good config keeps running). No action in this repo is needed for a config change.

Watch a change land:
```bash
kubectl -n eve-notifier logs deploy/eve-notifier -c config-gate -f
# "candidate changed -> ... ; validating" then "PROMOTED ..." or "REJECTED ...: <reason>"
```

---

## Troubleshooting

- **Config change did not take effect.** Check the config-gate log for `REJECTED`
  and the reason; the candidate failed validation and `/live` was kept. Fix the
  config in the zKillBot repo and re-push.
- **Pod crashlooping on boot.** The committed config is broken *and* was seeded to
  `/live` at boot (the boot-time `seed-config` copy is unconditional). Fix the
  config in the zKillBot repo; the gate prevents this at steady state, but a fresh
  pod seeds whatever git HEAD is.
- **No Discord ✅/❌ on a change.** The gate reads the alert webhook from
  `/live`'s `alert_webhook_url`. Confirm it is present and a `discord.com` URL:
  ```bash
  kubectl -n eve-notifier exec deploy/eve-notifier -c eve-notifier -- \
    grep '^alert_webhook_url:' /live/config.yaml
  ```
- **Manually force a full reload** (e.g. after a global-setting change):
  ```bash
  kubectl -n eve-notifier rollout restart deploy/eve-notifier
  ```
