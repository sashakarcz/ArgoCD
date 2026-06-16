
## CNI migration: restart standalone/operator-managed pods, not just controllers
When migrating CNI (e.g. Flannel→Cilium) with a mass pod restart, a new CNI
cannot retrofit networking onto an already-running pod -- the pod keeps its old,
now-dead netns and silently blackholes traffic. `kubectl rollout restart
deploy,sts,ds` MISSES standalone pods created directly by operators (Longhorn
instance-manager/engine-image, some CSI pods, bare Pods). Always enumerate ALL
non-hostNetwork pods created before the cutover and force-delete them too.

Diagnostic tell: a dropped/blackholed packet times out; a closed port returns
"connection refused" (RST). If TCP to one pod times out while TCP to another
(closed port) refuses, the dataplane is fine and that specific pod's networking
is dead -- not a CNI-wide failure. Don't roll back the whole migration for it.
