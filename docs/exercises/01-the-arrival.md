# Chapter 1 — The Arrival

**Time:** ~30 min  
**Next:** [Chapter 2 — The Subterranean Divide](02-subterranean-divide.md)

---

Vertex Trust Bank is drowning in legacy hypervisor costs. Sarah, the CTO, hands
you a fresh **SUSE Virtualization** (Harvester) cluster and a Rancher Prime
instance that do not know about each other yet. Your first job: connect them,
tour the UIs, and confirm you can drive the platform from a terminal.

!!! note "After `rodeo up`"
    Harvester and Rancher are up; import is intentionally left for you.
    Passwords are in `~/.rodeo/secrets.yaml` on the KVM host
    (`harvester_admin_password`, `rancher_admin_password`).

## Credentials

| Field | Value |
|---|---|
| Username | `admin` |
| Harvester UI | `https://<host-ip>:8443` |
| Rancher UI | `https://<host-ip>:30002` |
| Passwords | from `~/.rodeo/secrets.yaml` |

Both UIs use self-signed certificates — accept the browser warning.

---

## Task 1: Verify both backends

From a shell on the KVM host:

```bash
curl -sk https://192.168.122.10/v1 | jq -r '.apiVersion'
curl -sk https://192.168.122.9:30002/v3 | jq -r '.type'
rodeo status
```

Expect a Harvester API version and `collection` from Rancher. `rodeo status`
should show three Harvester nodes and the rancher VM running.

---

## Task 2: Import Harvester into Rancher

1. Open Rancher at `https://<host-ip>:30002` and log in as `admin`.
2. Left sidebar → **Virtualization Management** → **Import Existing**.
3. **Cluster Name:** `harvester` (exact — later chapters assume this name).
4. **Create**, then copy the registration URL shown
   (`https://192.168.122.9:30002/v3/import/...yaml`).

In the Harvester UI (`https://<host-ip>:8443`):

1. Left sidebar → **Settings** (gear).
2. Find **cluster-registration-url** → edit → paste the URL → **Save**.

Wait 1–3 minutes. In Rancher → Virtualization Management the cluster moves
`Pending` → `Waiting` → **Active**.

---

## Task 3: Tour the SUSE Virtualization dashboard

Open the Harvester UI (directly or via Rancher → Virtualization Management →
**harvester**).

On the **Dashboard**, confirm:

- **Hosts** — three nodes
- **Virtual Machines** — empty for now
- **Images**, **Volumes**, capacity and metrics panels
- Bottom-left **Support** → **Download KubeConfig** (save it; you will need it)
- **Generate Support Bundle** — know where it is for real incidents

Do not change anything yet — this chapter is orientation plus the import.

---

## Task 4: Meet Rancher Prime

Back in Rancher:

- **Cluster Management** still lists `local` (Rancher's own K3s).
- **Virtualization Management** now lists `harvester` as **Active**.

Rancher is the fleet commander: identity, multi-cluster, and later the place
you provision guest Kubernetes. Harvester remains the place you run VMs.

---

## Task 5: Terminal access

From the KVM host:

```bash
rodeo ssh harvester1
kubectl get nodes
kubectl get pods -n harvester-system | grep -v Completed
exit
```

All three nodes should be `Ready`. Core Harvester pods should be running.

Optional — point your laptop kubectl at the kubeconfig you downloaded from
**Support**, or build a Rancher-proxied kubeconfig (API key under the user
avatar → Account & API Keys). Either path works for the rest of the lab.

---

## Checkpoint

- [ ] Both UIs reachable with `admin` / secrets.yaml passwords
- [ ] Cluster `harvester` is **Active** under Virtualization Management
- [ ] `kubectl get nodes` on harvester1 shows three Ready nodes
- [ ] Kubeconfig saved from Support

**Next:** [Chapter 2 — The Subterranean Divide](02-subterranean-divide.md)
