
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

## ExternalDNS + Traefik IngressRoute, and serversTransport can't cross providers
ExternalDNS here runs --source=ingress,service,traefik-proxy. A Traefik
**IngressRoute** CRD needs the traefik-proxy source AND an explicit
`external-dns.alpha.kubernetes.io/target: <traefik-LB-IP>` annotation (IngressRoutes
have no loadBalancer status for ExternalDNS to read). A standard Ingress is
auto-published (Traefik fills its status) -- prefer Ingress unless you need a
feature only IngressRoute has.

For an HTTPS backend with a self-signed cert (e.g. Proxmox :8006), you need a
ServersTransport with insecureSkipVerify. A standard Ingress CANNOT reference a
`@kubernetescrd` ServersTransport (cross-provider) -- Traefik falls back to the
verifying default transport and returns 500 "x509: certificate signed by unknown
authority". Use a Traefik IngressRoute (same provider) so the serversTransport
reference resolves. That's the pve.starnix.net (Proxmox LB) setup.
