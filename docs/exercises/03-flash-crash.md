# Chapter 3 — The Flash Crash

**Time:** ~30 min  
**Prev:** [Chapter 2](02-subterranean-divide.md) · **Next:** [Chapter 4 — The Rising Tide](04-rising-tide.md)

---

Asian markets are melting down. The quants need a calculation engine **now**.
You will provision a fully configured VM — disk, secondary volume, production
network, SSH key, cloud-init, fixed IP — in one pass.

---

## Task 1: Confirm the OS image

**Images** — confirm your Chapter 2 cloud image is **Active**
(for example `official-images/sles16` or the Leap Micro image you uploaded).

---

## Task 2: Create `algo-trader-01`

**Virtual Machines → Create**:

| Field | Value |
|---|---|
| Name | `algo-trader-01` |
| Namespace | `prod` |
| CPU | `2` |
| Memory | `2 GiB` |
| SSH Key | `prod/default` |

**Labels → Add:**

| Key | Value |
|---|---|
| `stage` | `prod` |

Do **not** click Create yet.

---

## Task 3: Volumes and network

**Volumes** tab:

- Root volume: select your cloud image, size **5 GiB**
- **Add Volume** → name `market-data-vol`, size **1 GiB**

**Networks** tab:

| Field | Value |
|---|---|
| Network | `prod/service` |

---

## Task 4: Cloud-init and fixed IP

**Advanced Options → Cloud Configuration**:

- **User Data Template:** `prod/prod` (if you created it), or paste equivalent user-data
- **Network Data:**

```yaml
version: 2
ethernets:
  enp1s0:
    addresses:
      - 192.168.122.50/24
    gateway4: 192.168.122.1
    nameservers:
      addresses:
        - 192.168.122.1
```

!!! note
    Interface name may be `eth0` on some images. If the VM boots without the
    static address, check `ip link` in the web console and adjust.

**Node Scheduling (optional):** run on nodes matching label `stage=prod` only
if you labeled hosts; otherwise leave default (any node).

Click **Create**. Wait until the VM is **Running** and shows an IP.

---

## Task 5: Web console and SSH

1. Open the VM → **Console** — confirm login / cloud-init finished.
2. From the KVM host:

```bash
ssh -o StrictHostKeyChecking=no opensuse@192.168.122.50
# or the default user for your image
hostname
exit
```

---

## Checkpoint

- [ ] `algo-trader-01` Running in `prod`
- [ ] Secondary volume `market-data-vol` attached
- [ ] SSH works at `192.168.122.50` with `prod/default`

**Next:** [Chapter 4 — The Rising Tide](04-rising-tide.md)
