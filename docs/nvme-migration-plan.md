# Plan: Migrate Longhorn Storage from USB T7 to Internal NVMe

**Status:** v2 — revised after adversarial review (3 independent reviewers, all verified live, read-only). Core approach validated; safety rails, offline fallback, and monitoring reworked.
**Goal:** Move each Talos node's Longhorn data disk off the USB Samsung T7 (`fast-storage` ZFS) onto the internal NVMe (`local-lvm` LVM-thin), eliminating the USB failure class, with **no volume ever below 1 healthy replica** and **no re-creation of the incident's I/O profile**, one node at a time.

---

## 1. Success criteria

- All 5 nodes: Longhorn data disk (`scsi1`) backed by `local-lvm` (NVMe).
- Cluster starts and ends at **0 degraded**, all volumes 3/3.
- **No volume ever drops below 1 healthy replica** (note: the pre-move gate is *necessary but not sufficient* — see §5/§8; the live path + source-host latency watch is what actually enforces this mid-move).
- No change to Longhorn volumes, PVCs, or app config.
- USB T7 tier idle, repurposable.

---

## 2. Current state (VERIFIED live by review)

- **Proxmox:** `pve-manager 9.1.1`, `pve-qemu-kvm 10.1.2`. Each VM: `scsi0: local-lvm ...100G` (OS, NVMe) + `scsi1: fast-storage:vm-<id>-disk-0,discard=on,iothread=1,size=500G` (Longhorn, USB), `scsihw: virtio-scsi-single`. No `serial=` on any `scsi1`.
- **Talos selects the Longhorn disk by static device PATH** — `cluster/talos/patch.yaml`: `machine.disks: - device: /dev/sdb / partitions: - mountpoint: /var/lib/longhorn` (+ bind `extraMount`). **Not** serial/WWID. A same-slot move (scsi1 stays scsi1 ⇒ `/dev/sdb`) preserves this. **This is the linchpin and it is verified safe.**
- **Source zvols are THICK** (`volsize=500G`, `refreservation=508G`) but hold only **~48-80 GB referenced** data. A block copy scans the device surface, so the read load is heavier than the ~50-80 GB "data" figure; the *target* lands near referenced size (thin + zero-detection), so it does **not** inflate to 500 GB on NVMe.
- **`local-lvm` is on the internal NVMe** (`/dev/nvme0n1p3`, verified), separate from the USB T7 (`sda`).
- **Longhorn:** v1.11.3, 3 replicas/volume, **hard anti-affinity** (`replica-soft-anti-affinity=false`) ⇒ 3 distinct nodes each. `replica-replenishment-wait-interval=600`, `concurrent-replica-rebuild-per-node-limit=2`. Currently **31 volumes, all healthy 3/3** (93 replicas).
- **Replica load per node** (heaviest = control-plane): dg8-q1t/pve4 = 22, p93-8cq/pve3 = 21, hb1-9mk/pve2 = 19, 1yg-rc3/pve5 = 16, zv2-ov6/pve1 = 15.
- **Control-plane nodes (3):** pve2/hb1-9mk, pve3/p93-8cq, pve4/dg8-q1t. **Never take two offline together (etcd quorum).**
- All 5 hosts on the stable `usb-storage` (BOT) driver.

---

## 3. Approach

### Primary: **live `qm move-disk` with a bandwidth cap + source-latency watch**

`qm move-disk <vmid> scsi1 local-lvm --delete 0 --bwlimit <KBps>` (or `qm disk move`, the current name) live-mirrors `scsi1` to NVMe while the VM runs, keeping slot `scsi1` ⇒ guest `/dev/sdb` unchanged ⇒ Talos re-mounts `/var/lib/longhorn` unchanged ⇒ Longhorn untouched. **No node downtime, no Longhorn reconfiguration.**

Two controls make it safe (the mirror is a sustained read of the same T7 that is *simultaneously serving that node's live replica writes* — the incident's I/O profile):
- **`--bwlimit`** to cap mirror read throughput and leave write headroom.
- **Live `zpool iostat -l fast-storage` watch on the source host during the mirror**; abort/throttle if write-wait climbs toward the 30 s Longhorn timeout.

The live block mirror is **crash-consistency-safe** (block-layer transparent; guest never remounts; on abort the VM stays on the source, no data touched). The only residual is the historic `iothread + virtio-scsi-single + drive-mirror` abort class, which **fails safe** (stays on source).

### Fallback: **offline `qm move-disk`** — LAST RESORT, reworked (see §6). The naive "treat as a reboot" was wrong: a full-device copy off USB takes tens of minutes, **exceeds the 600 s replenishment window**, and triggers a rebuild storm onto still-USB survivors — the incident's failure mode. Only used with the mitigations in §6.

### Rejected: Longhorn add-disk + evict — eviction reads the USB source anyway (same saturation) with more moving parts.

---

## 4. Pre-flight (once, before any node)

- **PF1 — RESOLVED (was "blocking").** Talos selects by `/dev/sdb` path; same-slot move preserves it. **DROP the serial-pinning idea entirely** — it's unnecessary and dangerous: a live `qm set -scsi1 serial=` stages *pending* (applies at next reboot, changing `by-id`) and/or forces a hot detach of the mounted data disk. Never mutate `scsi1` device properties on a live, mounted disk.
- **PF2 — Cluster fully healthy:** 0 degraded, every volume 3/3, before start and between every node.
- **PF3 — Capacity & thin-pool safety (REWORKED).** Autoextend is **off** and the VG has only **~16 GiB** free, so autoextend is not a real safety net; `lv_when_full=queue` means a full pool **hangs I/O**, and post-migration the OS root and Longhorn share this one 816 GiB pool (new failure coupling). Therefore:
  - **Cap Longhorn's disk** via `storageReserved` (and/or `storageMaximumSize`) on the Longhorn node disk so it can never consume beyond `pool_size − OS_headroom`.
  - Track `data_percent` of the thin pool (not the overcommit "Available").
  - Prefer keeping rollback state as the **retained source ZFS disk (`--delete 0`)**, not an LVM-thin snapshot (which would consume the shared pool).
- **PF4 — Monitoring MUST exist first (new; currently absent — no node-exporter on the pve hosts at all):**
  - Host thin-pool `Data%` alert (e.g. warn 75 / crit 85).
  - Host `zpool iostat -l fast-storage` write-latency alert.
  - These are the postmortem's leading indicators and gate the whole migration.
- **PF5 — Backups verified per-volume:** BackupTarget `default` is healthy, but **not every volume is in the backup group** (some `backupvolumes` are stale, e.g. months old). Confirm recent backups specifically for the volumes whose replicas live on the node being migrated.
- **PF6 — Canary first**, worker node, with `--delete 0`, full validation before touching any other node.

---

## 5. Per-node procedure (one node at a time, worker canary first)

1. **Gate:** cluster at 0 degraded; and no volume has its sole RW replica on `<node>`.
2. **Live move:** `qm disk move <vmid> scsi1 local-lvm --delete 0 --bwlimit <KBps>`. During the mirror, watch `zpool iostat -l fast-storage` on that host; throttle/abort if write-wait rises toward the timeout.
3. **Verify — mount & identity (BEFORE anything irreversible):**
   - Guest: `/dev/sdb1` present, xfs, mounted at `/var/lib/longhorn`.
   - Longhorn: the node's disk `diskUUID` unchanged and `Ready=True`; the node's replicas are `RW`.
   - Host: `qm config <vmid>` shows `scsi1: local-lvm:...`; `fast-storage` no longer lists this VM's disk.
4. **Verify — no churn & correct path:**
   - **Zero Longhorn rebuild events** attributable to this node during/after the move.
   - **NVMe is in the I/O path** (guest `sdb` no longer maps to the USB-backed zvol; host shows the disk on `local-lvm`).
5. **Soak:** wait for cluster back to **0 degraded**.
6. **Only then** delete the retained source (`qm disk move` already switched; free the old zvol manually) and proceed to the next node.

**Silent-reformat trapdoor:** `machine.disks: /dev/sdb` is declarative — if a node ever boots with `sdb` present-but-**unpartitioned** (bad copy / empty target), Talos will **format a fresh partition** and Longhorn comes up as an empty "Ready" disk with a new `diskUUID` — **silent** data loss, not a loud error. This is why step 3 verifies `sdb1`/xfs **and** the matching Longhorn `diskUUID` *before* deleting the source or uncordoning.

**Ordering:** worker canary (zv2-ov6 or 1yg-rc3) → validate → remaining workers → control-plane nodes last, strictly one CP at a time, never overlapping two of pve2/pve3/pve4. **Do not do all 5 in one sitting — soak each.**

---

## 6. Offline fallback (only if the live mirror can't converge)

- **Raise `replica-replenishment-wait-interval` above the canary-measured copy time** *before* stopping the VM, so the intact data returns before Longhorn starts rebuilding. Restore it after.
- Worker nodes only. **Never a control-plane node offline for this** (they hold the most replicas *and* etcd quorum).
- Never run an offline move while any survivor of an affected volume is still USB-backed and under load.
- Otherwise same gates: 0-degraded entry, no-sole-replica, `--delete 0`, verify-before-delete.

---

## 7. Rollback

- **Live mirror fails mid-copy:** VM keeps running on the original T7 disk; retry or fall back. No data touched.
- **After move, node won't mount/rejoin:** with `--delete 0` the source zvol still exists → revert the VM disk to it (or restore the pre-move VM snapshot).
- **"Let Longhorn rebuild from peers" is CONDITIONAL, not unconditional:** valid only when the volume has **≥2 healthy replicas off the failed node** (true at 0-degraded with hard anti-affinity; **false** mid-migration if a prior node is still degraded). Otherwise recover from the retained source / snapshot / backup.
- **Whole-approach abort:** per-node and independent; a mixed NVMe/USB state is stable, so partial completion is fine.

---

## 8. Why the pre-move gate isn't sufficient (and what is)

Hard anti-affinity means the move alone drops an affected volume to at worst 2/3. The danger is a **survivor stalling during the move window** (the incident): a concurrent survivor failure → 1 replica; two → 0 (the postmortem's real Wazuh 0-replica event). The pre-move gate checks state *before* the move and can't prevent that. The actual protections are: (a) the **live path** (no node-down, minimal extra I/O), (b) the **`--bwlimit` + source-host latency watch** that keeps the T7 out of stall territory, and (c) migrating **workers first** so survivors become increasingly NVMe-backed and stall-proof as the roll proceeds.

---

## 9. Post-migration cleanup

- After all 5 healthy and soaked (≥48 h): `fast-storage` holds no VM disks. Repurpose T7s as a backup target or cold spares; don't destroy the ZFS pools immediately.
- Leave the `usb-storage.quirks` GRUB entry (harmless).
- Keep the new thin-pool + zpool-latency alerts permanently.
- Unrelated cleanup noted by review (separate tickets): VMID 104 & 1005 have `bios: ovmf` but **no `efidisk0`** (no persistent EFI NVRAM); remove the dead `ceph-vm-storage` storage entry.

---

## 10. Risk register (post-revision)

| Risk | Sev | Mitigation |
|------|-----|-----------|
| Live mirror saturates T7 → survivor/self replica stall → rebuild | High | `--bwlimit` + `zpool iostat -l` watch; abort on rising write-wait; canary `--delete 0` + confirm 0 rebuild events |
| Offline copy > 600 s → rebuild storm on USB survivors → volume→0 | High | Live path primary; if offline: raise replenishment-wait first, workers only, never CP |
| Full NVMe thin pool hangs OS+Longhorn (new coupling) | High | Cap Longhorn disk (`storageReserved`); thin-pool `Data%` alert (PF4); `--delete 0` not LVM snapshot |
| `--delete 1` frees source before mount verified → no rollback | Med | `--delete 0` everywhere; delete source only after mount+diskUUID verified and 0-degraded soak |
| Silent Talos reformat of empty `sdb` → empty "Ready" disk | Med | Verify `sdb1`/xfs + Longhorn `diskUUID` before delete/uncordon; faithful full-device copy |
| Two CP offline together → etcd quorum loss | Med | Correct 3-CP map; CP last, one at a time, never overlap |
| Rollback-from-peers assumed always safe | Med | Documented precondition (≥2 healthy off target); retain source per node |
| Backups not universal | Low | Verify per-volume recency (PF5) |
| Serial-pin mitigation (removed) | — | Deleted; not applicable to path-based selection |
