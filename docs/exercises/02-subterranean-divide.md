# Chapter 2 — The Subterranean Divide

**Time:** ~30 min  
**Prev:** [Chapter 1](01-the-arrival.md) · **Next:** [Chapter 3 — The Flash Crash](03-flash-crash.md)

---

Sarah takes you into the subterranean datacenter. One side of the room is
containerized APIs; the other still runs heavy ledgers. Both will share the
same SUSE Virtualization fabric — but first you map the nodes, carve workspaces,
set storage policy, and build the production service network the later chapters
need.

!!! tip "Bare-metal vs Instruqt"
    The customer Rodeo image pre-creates `prod`, `prod/service`, and an SSH
    key. On this self-hosted lab you create them here so Chapter 3 can launch
    a VM on a clean cluster.

---

## Task 1: Inspect node topology and Longhorn on disk

In the Harvester UI → **Hosts**:

1. Open one host and review reserved vs used CPU/memory, IP, and disks.
2. Each disk you see feeds the Longhorn pool that will hold VM volumes.

From the KVM host terminal:

```bash
rodeo ssh harvester1
ls /var/lib/harvester/defaultdisk
ls /var/lib/harvester/defaultdisk/replicas/
exit
```

Replicas on disk are how Longhorn keeps VM data alive across node loss.

---

## Task 2: Create `prod` and `dev` namespaces

**Namespaces** → **Create**:

| Name |
|------|
| `prod` |
| `dev` |

`prod` holds bank production VMs; `dev` is for cheaper sandboxes.

---

## Task 3: Understand the default storage class

**Advanced → Storage Classes** → open `harvester-longhorn`.

Note **Number Of Replicas = 3**. Production ledgers want that. Disposable quant
sandboxes do not — replica count is a policy, not a law of physics.

---

## Task 4: Build a cost-tier StorageClass

**Advanced → Storage Classes → Create**:

| Field | Value |
|---|---|
| Name | `harvester-longhorn-1rep` |
| Provisioner | `driver.longhorn.io` |
| Number of replicas | `1` |
| Allow volume expansion | yes |
| Reclaim policy | Delete |

Parameters (if the form exposes them as YAML/custom):

```yaml
numberOfReplicas: "1"
staleReplicaTimeout: "30"
migratable: "true"
```

---

## Task 5: Create the production VM network

VMs need a network on the management fabric so you can SSH them from the host.

**Networks → Virtual Machine Networks → Create**:

| Field | Value |
|---|---|
| Namespace | `prod` |
| Name | `service` |
| Type | `UntaggedNetwork` |
| Cluster Network | `mgmt` |

Confirm `prod/service` shows **Active**.

---

## Task 6: Register an SSH key

Generate a key on the KVM host if you do not already have one:

```bash
test -f ~/.ssh/id_ed25519.pub || ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

In Harvester: **Advanced → SSH Keys → Create**:

| Field | Value |
|---|---|
| Namespace | `prod` |
| Name | `default` |
| SSH Public Key | paste the `.pub` contents |

Later chapters select **SSH Key: `prod/default`**.

---

## Task 7: Upload a cloud image

**Images → Create**:

| Field | Value |
|---|---|
| Namespace | `official-images` (create the namespace if prompted) |
| Name | `sles16` |
| URL | a SLES 16 or openSUSE Leap cloud qcow2 URL your lab can reach |

Example openSUSE Leap Micro appliance (works for cloud-init labs):

```text
https://pkg.adfinis.com/opensuse/distribution/leap-micro/6.2/appliances/openSUSE-Leap-Micro.x86_64-Default-qcow.qcow2
```

Wait until the image is **Active** (download is server-side via Longhorn).

If your environment already mirrors a SLES 16 Minimal VM cloud image, prefer
that and note the exact image name — Chapter 3 will reference whatever you
upload here as **the golden OS image**.

---

## Task 8 (optional): Cloud-init user-data template

**Advanced → Cloud Config Templates → Create** (User Data):

| Field | Value |
|---|---|
| Namespace | `prod` |
| Name | `prod` |

Minimal user-data (adjust user to match your image — `opensuse` for Leap Micro,
`sles` / `ec2-user` variants for SLES cloud images):

```yaml
#cloud-config
package_update: true
packages:
  - qemu-guest-agent
runcmd:
  - systemctl enable --now qemu-guest-agent
```

Chapter 3 can select **User Data Template: `prod/prod`**.

---

## Checkpoint

- [ ] `prod` and `dev` namespaces exist
- [ ] `harvester-longhorn-1rep` StorageClass exists
- [ ] `prod/service` network is Active
- [ ] `prod/default` SSH key registered
- [ ] Cloud image in `official-images` is Active

**Next:** [Chapter 3 — The Flash Crash](03-flash-crash.md)
