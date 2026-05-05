# FleetDM Runbook

## Architecture

| Component | Storage | Notes |
|-----------|---------|-------|
| mysql | Longhorn RWO PVC → static PV | Data PVC; see static binding section |
| redis | Longhorn RWO PVC (dynamic) | Session cache; loss is recoverable |
| fleet | Stateless | 2 replicas; init container runs DB migrations |

### Static PV binding (mysql)

The mysql PVC is bound to a manually-created PV (`fleetdm-mysql-restored-pv`) that wraps a
specific Longhorn volume (`fleetdm-mysql-restored`). The PV uses `spec.claimRef` to reserve
itself for `mysql-pvc` in the `fleetdm` namespace — the PVC manifest needs **no** `volumeName`
field, which avoids an ArgoCD diff loop (see Troubleshooting below).

To check the current binding:
```
kubectl get pv fleetdm-mysql-restored-pv
kubectl get pvc mysql-pvc -n fleetdm
```

---

## Restoring MySQL from a Longhorn Backup

Use this procedure if the mysql data is lost or corrupted.

### 1. Find the latest backup

```bash
kubectl -n longhorn-system get backupvolumes.longhorn.io | grep pvc-<mysql-pv-volume-handle>
```

The backup volume name encodes the original Longhorn volume ID. Find the current volume handle:
```bash
kubectl get pv fleetdm-mysql-restored-pv -o jsonpath='{.spec.csi.volumeHandle}'
```

List available backups:
```bash
kubectl -n longhorn-system get backups.longhorn.io | grep <backup-volume-name>
```

Get the backup URL (needed for restore):
```bash
kubectl -n longhorn-system get backup <backup-name> -o jsonpath='{.status.url}'
# Example output: s3://longhorn-backups@us-east-1/?backup=backup-xxx&volume=pvc-xxx
```

### 2. Disable ArgoCD auto-sync

Prevent ArgoCD from fighting you during the restore:
```bash
kubectl patch application fleetdm -n argocd --type merge \
  -p '{"spec":{"syncPolicy":{"automated":null}}}'
```

### 3. Scale down mysql and fleet

```bash
kubectl scale deployment fleet -n fleetdm --replicas=0
kubectl scale statefulset mysql -n fleetdm --replicas=0
until [ "$(kubectl get pods -n fleetdm -l 'app in (fleet,mysql)' --no-headers 2>/dev/null | wc -l)" = "0" ]; do sleep 3; done
echo "Down"
```

### 4. Delete the current mysql PVC

```bash
kubectl delete pvc mysql-pvc -n fleetdm
```

If the PVC is stuck Terminating (Longhorn volume not releasing), see **Stuck PVC** below.

### 5. Create a new Longhorn volume from backup

```bash
kubectl apply -f - <<EOF
apiVersion: longhorn.io/v1beta2
kind: Volume
metadata:
  name: fleetdm-mysql-restored
  namespace: longhorn-system
spec:
  fromBackup: "<backup-url-from-step-1>"
  numberOfReplicas: 3
  size: "21474836480"
  frontend: blockdev
  dataEngine: v1
EOF
```

Wait for the restore to complete (volume transitions from `attached/restore:true` to `detached`):
```bash
until kubectl -n longhorn-system get volumes.longhorn.io fleetdm-mysql-restored \
  -o jsonpath='{.status.state}' | grep -q "detached"; do
  kubectl -n longhorn-system get volumes.longhorn.io fleetdm-mysql-restored \
    -o jsonpath='{.status.state} restore:{.status.restoreRequired}'
  echo; sleep 10
done
echo "Restore complete"
```

> If the volume name `fleetdm-mysql-restored` already exists, choose a new name (e.g.
> `fleetdm-mysql-restored-2`) and update the PV manifest and `fleetdm.yaml` accordingly.

### 6. Prepare the PV for rebinding

Clear the old `claimRef` UID so the PV becomes Available again:
```bash
kubectl patch pv fleetdm-mysql-restored-pv --type json \
  -p '[{"op":"remove","path":"/spec/claimRef/uid"},{"op":"remove","path":"/spec/claimRef/resourceVersion"}]'
kubectl get pv fleetdm-mysql-restored-pv   # should show STATUS=Available
```

If you used a **new** volume name in step 5, update the PV's `volumeHandle` and the manifest:
```bash
kubectl patch pv fleetdm-mysql-restored-pv --type merge \
  -p '{"spec":{"csi":{"volumeHandle":"<new-volume-name>"}}}'
# Also update fleetdm.yaml spec.csi.volumeHandle and commit
```

### 7. Re-enable ArgoCD and sync

```bash
kubectl apply -f applications/fleetdm/application.yaml
kubectl patch application fleetdm -n argocd --type merge \
  -p '{"operation":{"initiatedBy":{"username":"sasha"},"sync":{"revision":"HEAD"}}}'
```

Wait for sync:
```bash
until kubectl get application fleetdm -n argocd \
  -o jsonpath='{.status.operationState.phase}' | grep -q "Succeeded"; do sleep 5; done
kubectl get pvc mysql-pvc -n fleetdm   # should show Bound to fleetdm-mysql-restored-pv
```

### 8. Scale back up

```bash
kubectl scale statefulset mysql -n fleetdm --replicas=1
kubectl scale deployment fleet -n fleetdm --replicas=2
until [ "$(kubectl get pods -n fleetdm --no-headers | grep -c '1/1')" = "4" ]; do sleep 5; done
echo "All up"
```

---

## Troubleshooting

### Stuck Terminating PVC

If `kubectl delete pvc mysql-pvc` hangs, the Longhorn volume is stuck. Force it:

```bash
# Find and force-delete stuck replicas
kubectl -n longhorn-system get replicas.longhorn.io | grep <pvc-volume-id>
kubectl -n longhorn-system delete replica <replica-name> --force --grace-period=0

# If the volume itself is stuck in `deleting`, remove its finalizer
kubectl -n longhorn-system patch volume <volume-id> \
  -p '{"metadata":{"finalizers":[]}}' --type=merge

# If the PV is stuck Terminating, remove its finalizer
kubectl patch pv <pv-name> -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### ArgoCD stuck syncing / volumeName diff loop

**Symptom:** ArgoCD repeatedly fails with:
```
PersistentVolumeClaim "mysql-pvc" is invalid: spec: Forbidden: spec is immutable
```
The diff shows it trying to set `VolumeName: ""`.

**Root cause:** Kubernetes strips `spec.volumeName` from the normalized PVC spec for bound
claims. ArgoCD therefore always computes `volumeName = ""` as the desired state, regardless of
what the manifest says. Strategies like `ignoreDifferences` + `RespectIgnoreDifferences=true`
do not reliably fix this because the running sync operation caches the diff at start time.

**Fix (already implemented):** The PV uses `spec.claimRef` to reserve itself for the PVC.
The PVC manifest has **no** `volumeName` — Kubernetes binds via the PV's claimRef instead.
This removes the field from the diff entirely.

**If the loop recurs** (e.g. after recreating the PV without claimRef):
1. Disable auto-sync to stop retries:
   ```bash
   kubectl patch application fleetdm -n argocd --type merge \
     -p '{"spec":{"syncPolicy":{"automated":null}}}'
   ```
2. Ensure the PV has `spec.claimRef.name: mysql-pvc` and
   `spec.claimRef.namespace: fleetdm` (no `uid` field).
3. Delete and recreate the PVC so it binds cleanly without `volumeName`.
4. Re-enable auto-sync and sync manually.

### mysql-0 stuck in ContainerCreating (Multi-Attach error)

The RWO PVC can only attach to one node. If the previous pod is stuck Terminating on a dead
node, the new pod cannot attach.

```bash
kubectl describe pod mysql-0 -n fleetdm | grep -A5 "Events:"
# Look for: MountVolume.MountDevice failed ... Multi-Attach error
```

Force-delete the stuck pod to release the attachment:
```bash
kubectl delete pod mysql-0 -n fleetdm --force --grace-period=0
```

If that doesn't help, detach the volume in the Longhorn UI or via:
```bash
kubectl -n longhorn-system patch volume <volume-id> --type merge \
  -p '{"spec":{"nodeID":""}}'
```
