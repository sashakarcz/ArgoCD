# Postmortem: Longhorn Rebuild Storm from USB (UAS) Storage Stalls

- **Date of incident:** 2026-07-30 (onset) → 2026-08-02 (root-caused and fixed)
- **Severity:** SEV-2 (degraded redundancy cluster-wide; no data loss, no hard outage)
- **Duration:** ~2 days of intermittent oscillation; ~several hours of active investigation/remediation on 2026-08-02
- **Status:** Resolved
- **Affected systems:** Longhorn block storage on the Talos/k8s cluster (nearly all volumes at times), and by extension every stateful workload's redundancy (Wazuh, FleetDM, FreeScout, Gatus, Grafana, Jellyfin, Overseerr, Seafile, eve-notifier, etc.)

---

## TL;DR

The cluster's Longhorn volumes kept flapping between healthy and degraded (oscillating from ~2 to ~28 degraded volumes). The root cause was **not** Longhorn, Kubernetes, or the network: it was the **physical storage tier**. Each Proxmox host backs its Longhorn data on a **single USB-attached Samsung Portable SSD T7**, connected via the **UAS (USB Attached SCSI) driver**. Under sustained Longhorn rebuild I/O, the UAS link **stalls** — writes that should take microseconds took **4-12 seconds**, tripping Longhorn's 30-second replica timeout. Longhorn then marked the replica errored, triggered a rebuild, which generated more I/O, which stalled the USB link again: a self-feeding loop.

The fix was to force the T7s off the flaky UAS driver onto the older-but-stable `usb-storage` (BOT) driver via a kernel quirk (`usb-storage.quirks=04e8:4001:u`) on all five Proxmox hosts, then roll-reboot them. Pool write latency dropped from seconds back to **2-3 ms**, and the oscillation stopped.

**No data was ever lost.** Every volume retained at least one healthy replica throughout; the impact was lost redundancy and churn, not unavailability.

---

## Impact

- **Redundancy:** For extended periods, most volumes ran on 1-2 replicas instead of 3. At no point did any volume reach zero healthy replicas, so there was no data loss and no application-level outage from storage.
- **Performance:** Stateful workloads on the affected virtual disks experienced multi-second I/O stalls during the stall windows.
- **Operational:** Constant Longhorn rebuild churn, a large volume of alert noise / events, and significant engineer time. Several remediation attempts (see Contributing Factors) temporarily **worsened** the churn.
- **Wazuh manager:** briefly recreated once when its RWO queue volume momentarily lost its last replica during the storm; recovered automatically, data intact.

---

## Environment / Architecture

- **Compute:** 5 mini-PCs running Proxmox VE (`pve1`-`pve5`, `192.168.7.101`-`.105`), each hosting one Talos Linux VM that is a Kubernetes node.
  - Node ↔ host map: node `192.168.7.20x` = `talos-0x` = `pveX`.
  - `pve1`/zv2-ov6, `pve2`/hb1-9mk, `pve3`/p93-8cq (control-plane), `pve4`/dg8-q1t (control-plane), `pve5`/1yg-rc3.
- **Storage:** Longhorn (v1.11.3), default 3 replicas.
  - Each VM's Longhorn data disk is a **virtio disk (`sdb`, 537 GB, xfs, `/var/lib/longhorn`)**, backed by a ZFS pool `fast-storage` on the Proxmox host.
  - **`fast-storage` on every host is a single-disk vdev on a USB Samsung Portable SSD T7** (USB ID `04e8:4001`), attached via the **UAS** driver.
  - Mini-PC form factor → USB external SSD is effectively the only bulk-storage option.

---

## Root Cause

**USB Samsung T7 SSDs, driven by UAS, stall under sustained Longhorn rebuild I/O.**

Evidence gathered:

- **Longhorn engine logs:** `R/W Timeout. No response received in 30s`; `REQ ... W[4kB@...] 30829906us failed` — a **4 KB write took 30.8 seconds**, then `Setting replica <ip> to ERR`.
- **ZFS pool latency (`zpool iostat -l`) on the stalling hosts:** `total_wait` write of **4-12 seconds** under load, versus **sub-millisecond when idle**.
- **VM guest kernel logs:** `Buffer I/O error`, `EXT4-fs: I/O error while writing superblock`, `lost sync page write`, and repeated `Power-on or device reset occurred` — i.e., the underlying USB device **resetting**.
- **SMART on the T7s:** flash **healthy** — 0 media/integrity errors, ~11% wear — but **near-100% unsafe-shutdown ratio** (e.g., 40 of 41, 26 of 27 power cycles), the signature of a USB link that keeps dropping. One host also logged thermal-warning time.
- **ZFS `zpool status`:** pools **ONLINE, 0 read/write/cksum errors** — confirming it is **latency, not corruption**. Longhorn marks the disk "Ready" because its check is liveness, not latency, so it keeps scheduling replicas onto the stalling disks.

**The self-feeding loop:** USB stall → replica write times out → Longhorn errors the replica → rebuild scheduled → rebuild I/O hits the same (or a peer) USB link → stall → repeat. This is why the degraded count oscillated (e.g., 2 → 8 → 2) and never settled.

**Onset / trigger:** the affected hosts rebooted around **2026-07-30**; under the resulting load the marginal USB/UAS links began stalling. The onset also correlated with Cilium agent restarts (3×) on the affected nodes around the same time — a symptom of the same node-level disruption, not an independent cause.

---

## Contributing Factors (including remediation missteps)

Honest accounting — several early actions treated symptoms and made things worse before the true cause was found:

1. **UAS on USB storage** is fragile under sustained random I/O; single-disk vdevs mean any stall directly impacts a volume with no local redundancy.
2. **Misdiagnosis 1 — "stuck instance-managers."** The three nodes' Longhorn instance-managers were restarted. This cleared *transient* degraded volumes but did **not** fix the oscillation (the disks were the problem, not the IM processes). Each IM restart caused a large degraded spike.
3. **Misdiagnosis 2 — "snapshot-purge deadlock."** A real but *downstream* symptom: failed replicas blocked snapshot purge, which blocked rebuilds. Deleting dead replicas and engine-resetting volumes temporarily healed individual volumes but they **regressed**, because replicas kept landing back on the slow USB disks.
4. **Raising `concurrent-replica-rebuild-per-node-limit` from 2 → 4 made it WORSE** — more parallel rebuilds meant more concurrent I/O on already-saturated USB links, so *more* stalls, not faster recovery. Reverted to 2.
5. **Rolling reboots back-to-back** (to apply the fix) compounded churn: each reboot spiked the degraded count and concentrated "sole surviving replicas" onto the not-yet-fixed nodes, blocking the next reboot.

Key realization that broke the cycle: **stopping all cluster-side churn immediately dropped pool write-wait from 12 s back to 391 µs** — proving the failure was load-driven at the storage layer.

---

## Detection

Detection was manual, during investigation of the persistent degraded/oscillating Longhorn volumes. There was **no direct alerting on the leading indicator** (storage latency / USB resets), which is why it took a long diagnostic path (Longhorn → Proxmox ZFS → USB/SMART/dmesg) to reach the physical root cause. This is the single biggest gap the action items address.

---

## Resolution / The Fix

Force the T7s off UAS onto the stable `usb-storage` (BOT) driver:

1. On each Proxmox host, add the kernel quirk to GRUB:
   - `GRUB_CMDLINE_LINUX="usb-storage.quirks=04e8:4001:u"` in `/etc/default/grub` (the `u` flag = `IGNORE_UAS`), then `update-grub`. (`/etc/default/grub` backed up first.)
2. Roll-reboot all five hosts **one at a time** (see Runbook below), verifying after each that the T7 rebinds to `usb-storage`, the pool imports ONLINE, and the node rejoins.

**Result:** all five T7s now on `usb-storage` (BOT). Pool write latency **2-3 ms** (was 4-12 s under load), USB resets stopped, and the cluster converged (down to ~2 degraded and holding — no more oscillation).

Trade-off accepted: BOT is marginally slower than UAS on paper, but it does not stall/reset under load, which is exactly the failure mode we needed to eliminate. On these mini-PCs, keeping USB storage + BOT is the pragmatic answer.

---

## Timeline (condensed, UTC)

| When | Event |
|------|-------|
| ~2026-07-30 | Affected hosts reboot; USB/UAS links begin stalling under load. Cilium agents restart 3× on affected nodes. Oscillation begins. |
| 2026-08-02 (early) | Investigation of persistent degraded/oscillating Longhorn volumes begins (originally while working on an unrelated Wazuh task). |
| — | Misdiagnosis path: instance-manager restarts (×3), snapshot-purge/deadlock theory, engine resets — each partially helped then regressed. Rebuild concurrency raised to 4, backfired, reverted. |
| — | `zpool iostat -l` on Proxmox reveals **multi-second write latency**; stopping churn drops it to sub-ms → load-driven storage fault confirmed. |
| — | Root cause isolated: `fast-storage` = single **USB Samsung T7 via UAS** on all 5 hosts; SMART shows healthy flash but heavy unsafe-shutdown counts; dmesg shows device resets + EXT4 superblock write errors. |
| — | Fix applied: `usb-storage.quirks=04e8:4001:u` staged on all 5 hosts (GRUB). |
| — | Rolling reboots: pve5 (canary) → verified BOT + 2-3 ms → pve4 → pve2 → pve1 → pve3. |
| 06:xx | All 5 on `usb-storage` (BOT). Cluster converges to ~2 degraded and holds; oscillation eliminated. |

---

## What Went Well

- No data loss; every volume kept ≥1 healthy replica throughout.
- Once the true (physical) layer was investigated, the root cause was unambiguous and the fix was targeted and verified.
- A canary-first rolling reboot validated the fix before committing to all hosts.
- Strict per-reboot safety gate (never reboot a node holding a volume's *sole* replica) prevented any data-availability loss during the risky rolling reboots.

## What Went Poorly

- No alerting on the leading indicators (storage latency, USB resets) → long, manual root-cause path.
- Early remediation attacked the Kubernetes/Longhorn layer and repeatedly treated symptoms, temporarily amplifying churn.
- Rolling reboots done back-to-back on an already-churning cluster compounded the degraded state.

---

## Action Items

### Prevent

| # | Action | Priority |
|---|--------|----------|
| P1 | **Bake the UAS quirk into host provisioning** so new/rebuilt Proxmox hosts get `usb-storage.quirks=04e8:4001:u` automatically (Ansible/IaC), not just the current manual GRUB edit. | High |
| P2 | **Disable USB autosuspend** on the Proxmox hosts (`usbcore.autosuspend=-1` or per-device `power/control=on`) — USB power management is another common stall/reset trigger. | High |
| P3 | **Pin `concurrent-replica-rebuild-per-node-limit=2` (do not raise) on this cluster** and document why (higher concurrency saturates USB links). Consider it a hard rule for USB-backed Longhorn. | High |
| P4 | **Physical hardening of the T7s:** direct motherboard USB 3 ports (no hubs), known-good cables, verify power delivery, and ensure adequate cooling/airflow (thermal throttling was observed on one host). | Medium |
| P5 | **Document a maintenance rule:** reboot USB-backed storage nodes **one at a time, waiting for full Longhorn recovery (0 degraded) between each**, never two control-plane nodes together, and never a node holding a volume's sole replica. (Runbook below.) | Medium |
| P6 | **Evaluate reducing rebuild pressure:** review RecurringJob snapshot/backup schedules and `replica-replenishment-wait-interval` so routine churn stays within what the USB tier can absorb. | Low |
| P7 | **Long-term storage evaluation:** assess whether any internal NVMe/SATA capacity exists for a small dedicated Longhorn tier, or whether a more robust external enclosure is warranted. (Constraint acknowledged: mini-PCs are USB-limited.) | Low |

### Monitor / Detect

| # | Action | Priority |
|---|--------|----------|
| M1 | **Alert on ZFS pool write latency** — the leading indicator. Scrape `zpool iostat -l` per host (or `arcstat`/node-level I/O await) and alert when sustained write-wait exceeds a threshold (e.g., >100 ms for >1 min). This would have caught this days earlier. | High |
| M2 | **Alert on USB device resets** in host `dmesg`: patterns like `Power-on or device reset occurred`, `reset .*USB`, `usb .* reset`. Ship Proxmox host kernel logs to Graylog and alert on rate. | High |
| M3 | **Track SMART `Unsafe Shutdowns` deltas** on the T7s (rising count = USB link dropping) and **temperature** (thermal-warning time). Export via node-exporter textfile collector or a smartctl cron. | Medium |
| M4 | **Alert on Longhorn health:** volumes degraded > N minutes, repeated `FailedRebuilding` events, `instance-manager` restarts, and any Longhorn node `Ready=False`. | Medium |
| M5 | **Dashboard:** per-host ZFS pool write latency + USB reset count + cluster degraded-volume count on one board, so the storage-tier → Longhorn correlation is visible at a glance. | Medium |
| M6 | **Add a "no-progress" alert:** degraded count oscillating or flat (not trending to 0) for > 30 min — distinguishes a stuck/oscillating cluster from normal transient rebuilds. | Low |

---

## Appendix: Node-reboot Runbook (USB-backed Longhorn)

Per host, one at a time, only when the cluster is fully healthy (0 degraded):

1. **Safety gate:** confirm no volume has its *sole* `RW` replica on the target node (cross-reference engine `replicaModeMap` with replica `nodeID`).
2. `kubectl cordon <node>`
3. `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --force --timeout=130s` (the Longhorn instance-manager may not evict due to its PDB — that's fine).
4. Reboot the Proxmox host reliably: `ssh root@<pve> 'qm stop <vmid>; sleep 3; systemctl reboot'` — **stop the drained VM first**; a plain `reboot` can hang on the VM's ACPI shutdown.
5. Wait for the host back, verify: T7 on `usb-storage` (`readlink /sys/bus/usb/devices/*/‹iface›/driver`), `zpool status fast-storage` ONLINE, `zpool iostat -l` latency normal.
6. Wait for the k8s node `Ready`, then `kubectl uncordon <node>`.
7. **Wait for full Longhorn recovery (0 degraded) before the next host.**

Notes: VMs have `onboot: 1` (auto-start). SSH to Proxmox uses the default key (`root@192.168.7.10x`). Never reboot two control-plane nodes simultaneously (etcd quorum).
