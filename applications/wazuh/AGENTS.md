# Wazuh Agent Registry

## Agent Inventory

| Agent ID | Hostname             | OS                | Group            |
|----------|----------------------|-------------------|------------------|
| TBD      | selene.starnix.net   | Arch Linux        | arch             |
| TBD      | print.starnix.net    | Debian 13         | debian           |

Fill in Agent IDs after running: `/var/ossec/bin/manage_agents -l` on the manager.

---

## Group Model

Group configs live in git at `applications/wazuh/shared/<group>/agent.conf` and are
mirrored into the `wazuh-agent-groups` ConfigMap. On every pod start, an initContainer
seeds them into `/var/ossec/etc/shared/<group>/agent.conf` on the NFS PVC. The manager
reads them, generates `merged.mg`, and pushes it to agents in that group within ~10s.

| Group            | OS target          | Key differences                              |
|------------------|--------------------|----------------------------------------------|
| arch             | Arch Linux         | journald log source, pacman/gnupg ignores    |
| debian           | Debian 13+         | auth.log, syslog, dpkg/apt ignores           |
| freebsd          | FreeBSD            | messages, security logs, pkg/ports ignores   |
| kubernetes-node  | Talos/k8s nodes    | container logs, kubelet/containerd ignores   |

---

## Assigning an Agent to a Group

```bash
# On the manager pod:
kubectl exec -n wazuh wazuh-manager-0 -- \
  /var/ossec/bin/agent_groups -a -i <AGENT_ID> -g <GROUP> -r
```

Example:
```bash
kubectl exec -n wazuh wazuh-manager-0 -- \
  /var/ossec/bin/agent_groups -a -i 001 -g arch -r
```

Verify:
```bash
kubectl exec -n wazuh wazuh-manager-0 -- \
  /var/ossec/bin/agent_groups -s -i <AGENT_ID>
```

---

## Enrollment-time Group Assignment (preferred for new agents)

Add a `<groups>` block inside `<enrollment>` in the agent's `ossec.conf`:

```xml
<ossec_config>
  <client>
    <server>
      <address>wazuh.starnix.net</address>
      <port>1514</port>
      <protocol>tcp</protocol>
    </server>
    <enrollment>
      <enabled>yes</enabled>
      <groups>arch</groups>
    </enrollment>
  </client>
</ossec_config>
```

The agent will self-assign to the group at registration time, no manual step needed.

---

## Adding a New Group

1. Create `applications/wazuh/shared/<newgroup>/agent.conf` with an `<agent_config>` block.
2. Add a matching key `<newgroup>.conf` to the `wazuh-agent-groups` ConfigMap in
   `applications/wazuh/wazuh-agent-groups.yaml`.
3. Add the group to the `seed-agent-groups` initContainer loop in `wazuh-manager.yaml`
   (the `for group in ...` line).
4. Commit and push. ArgoCD syncs, the manager pod restarts, initContainer seeds the
   new directory, and the group is available for assignment.

---

## Minimal Agent ossec.conf

Once an agent is in a group, its local `ossec.conf` can be reduced to just the
transport/auth blocks. Everything else (log sources, syscheck, syscollector, sca,
rootcheck) is pushed from the group config.

```xml
<ossec_config>
  <client>
    <server>
      <address>wazuh.starnix.net</address>
      <port>1514</port>
      <protocol>tcp</protocol>
    </server>
    <enrollment>
      <enabled>yes</enabled>
      <groups>GROUPNAME</groups>
    </enrollment>
  </client>

  <client_buffer>
    <disabled>no</disabled>
    <queue_size>5000</queue_size>
    <events_per_second>500</events_per_second>
  </client_buffer>

  <logging>
    <log_format>plain</log_format>
  </logging>
</ossec_config>
```

---

## Migration Runbook

### 1. Push and sync

```bash
git add applications/wazuh/
git commit -m "wazuh: add agent group configs for arch, debian, freebsd, kubernetes-node"
git push origin main
# Wait for ArgoCD to sync, or trigger manually:
kubectl -n argocd patch app wazuh --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD","prune":true}}}'
```

### 2. Verify group dirs on manager

```bash
kubectl exec -n wazuh wazuh-manager-0 -- ls /var/ossec/etc/shared/
# Expected: arch  debian  default  freebsd  kubernetes-node  (plus rootcheck files)

kubectl exec -n wazuh wazuh-manager-0 -- \
  cat /var/ossec/etc/shared/arch/agent.conf
```

### 3. Get current agent IDs

```bash
kubectl exec -n wazuh wazuh-manager-0 -- /var/ossec/bin/manage_agents -l
```

Note the IDs for selene and print. Update the Agent Inventory table above.

### 4. Assign agents to groups

```bash
# selene → arch
kubectl exec -n wazuh wazuh-manager-0 -- \
  /var/ossec/bin/agent_groups -a -i <SELENE_ID> -g arch -r

# print → debian
kubectl exec -n wazuh wazuh-manager-0 -- \
  /var/ossec/bin/agent_groups -a -i <PRINT_ID> -g debian -r
```

### 5. Verify merged.mg on each agent (within ~10s)

On selene:
```bash
cat /var/ossec/etc/shared/merged.mg
# Should contain the arch agent_config block
```

On print:
```bash
cat /var/ossec/etc/shared/merged.mg
# Should contain the debian agent_config block
```

### 6. Slim down local ossec.conf on each agent

Replace `/var/ossec/etc/ossec.conf` on each agent with the minimal template above
(substituting the correct group name). Keep a backup first:

```bash
cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.bak
```

### 7. Restart agent and confirm events flow

```bash
systemctl restart wazuh-agent
# Wait ~30s, then check the Wazuh dashboard for events from the host.
```

If events stop flowing, restore from backup and check `/var/ossec/logs/ossec.log`.
