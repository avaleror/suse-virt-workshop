# Chapter 4 — The Rising Tide

**Time:** ~25 min  
**Prev:** [Chapter 3](03-flash-crash.md) · **Next:** [Chapter 5 — The Invisible Intruder](05-invisible-intruder.md)

---

A coolant leak is flooding the rack under the payment gateway. You need a
**zero-downtime live migration** while transactions keep flowing, then put the
damaged node into maintenance so everything else evacuates automatically.

On the Instruqt Rodeo, `webserver-prod` is pre-baked. Here you create it (and a
batch VM to pause) so the story has something to migrate.

---

## Task 1: Provision the payment gateway and a batch VM

Create two VMs in namespace `prod` on network `prod/service`, using the same
cloud image and `prod/default` SSH key as Chapter 3:

| Name | CPU | Memory | Disk | Purpose |
|---|---|---|---|---|
| `webserver-prod` | 1 | 1 GiB | 5 GiB | Payment gateway (will migrate) |
| `daily-batch-processor` | 1 | 1 GiB | 5 GiB | Non-critical (will pause) |

Use DHCP on `prod/service` (no static network-data required). Wait until both
are **Running** and note the IP of `webserver-prod` from the UI.

You may delete `algo-trader-01` first if the host is tight on RAM:

```bash
# optional — from a host with harvester kubeconfig
kubectl delete vm -n prod algo-trader-01 --wait=false
```

---

## Task 2: Pause non-critical work

**Virtual Machines** → `daily-batch-processor` → ⋮ → **Pause**.  
Wait until state is **Paused**.

---

## Task 3: Establish a heartbeat

On the KVM host (replace with the gateway IP from the UI):

```bash
ping <webserver-prod-ip>
```

Leave ping running. Do not stop it.

---

## Task 4: Live-migrate the gateway

1. Note which **Node** `webserver-prod` is on.
2. ⋮ → **Migrate** → pick a **different** healthy node → **Apply**.
3. Watch the UI; keep an eye on the ping window.

When migration finishes, stop ping (`Ctrl+C`). At most you might see one slower
reply — the guest OS did not reboot.

```bash
ssh opensuse@<webserver-prod-ip> "hostname && uptime"
```

Uptime should **not** have reset. The **Node** column should show the new host.

---

## Task 5: Resume batch work

`daily-batch-processor` → ⋮ → **Unpause**.

---

## Task 6: Evacuate the damaged rack

**Hosts** → the node `webserver-prod` **was** on before migration → ⋮ →
**Enable Maintenance Mode**.

Watch **Virtual Machines**: remaining guests on that node live-migrate away
automatically. When the host shows **Maintenance** and is empty, the "flooded"
rack is safe for hardware work.

Disable maintenance when you are done exploring so the cluster returns to full
capacity (⋮ → **Disable Maintenance Mode**).

---

## Checkpoint

- [ ] Ping survived the migration
- [ ] `webserver-prod` runs on a different node; uptime preserved
- [ ] Maintenance mode evacuated the source node

**Next:** [Chapter 5 — The Invisible Intruder](05-invisible-intruder.md)
