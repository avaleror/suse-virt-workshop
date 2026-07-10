# Exercise 3: First VM and live migration

**Time:** 30 min
**Previous:** [Exercise 2: Bring the cluster online](02-cluster-online.md)
**Next:** [Exercise 4: Networking and isolation](04-networking.md)

---

The cluster is healthy and networked. Time to put a VM on it: Vertex Trust Bank's core ledger service (transaction posting, account balances, settlement queue), still running on the old ISAware cluster today. Under ISAware this ran on a proprietary clustering layer. Here it runs on KubeVirt and KVM, and moves between nodes with the same zero-downtime guarantee.

## 3.1 Check the base image

This lab ships a pre-loaded **openSUSE Leap 16** cloud image called `leap16`. It's the standard production path for VM provisioning, since it boots fast and supports full cloud-init customization.

```bash
kubectl get virtualmachineimages -n default
```

You should see `leap16` with status `Active`.

## 3.2 Provision legacy-ledger-vm

In the Rancher UI, go to **Virtualization Management > harvester > Virtual Machines** → **Create**:

- **Name:** `legacy-ledger-vm`
- **CPU:** `2`, **Memory:** `2 GiB`
- **SSH Keys:** select `default/workshop-host` (the key you registered in Exercise 1)
- **Volumes:** **Add Volume** → **Image** → `default/leap16`, root disk size `20 GiB`

## 3.3 Assign network and cloud-init config

- **Networks** tab: **Add Network** → `default/vmnet`
- Expand **Advanced Options** and paste into **Network Data**:

```yaml
version: 2
ethernets:
  enp1s0:
    addresses:
      - 192.168.122.50/24
    gateway4: 192.168.122.1
    nameservers:
      addresses:
        - 8.8.8.8
```

This assigns `legacy-ledger-vm` a fixed IP of `192.168.122.50` at first boot, no manual post-deploy networking.

## 3.4 Node scheduling

Harvester offers three placement policies:

- **Any available node**, Kubernetes schedules the VM; live migration is enabled
- **Specific node**, pinned, no migration
- **Scheduling rules**, affinity based on node labels (GPU capability, NUMA topology, network zone, etc.)

Go to **Node Scheduling** and select **Run virtual machine on any available node**. It's required for the live migration step below.

Click **Create** and wait for `legacy-ledger-vm` to reach `Running`.

## 3.5 Confirm legacy-ledger-vm is operational

Because your host has a direct route to `virbr0`, you can reach `legacy-ledger-vm` straight from your shell, no proxy needed:

```bash
until ssh -o StrictHostKeyChecking=no opensuse@192.168.122.50 "uname -a" 2>/dev/null; do
  echo "Waiting for legacy-ledger-vm..."
  sleep 10
done
```

When kernel info prints, cloud-init has configured the network and injected your SSH key.

```bash
ssh opensuse@192.168.122.50 "cat /etc/os-release"
```

## 3.6 Live migration: zero-downtime node mobility

A maintenance window is coming on one of the cluster nodes. `legacy-ledger-vm` needs to move to another node without going offline: banking operations run 24/7.

Check which node `legacy-ledger-vm` is on:

```bash
kubectl get vmi legacy-ledger-vm -n default -o jsonpath='{.status.nodeName}'
```

In the Rancher UI, find `legacy-ledger-vm` in **Virtual Machines**, click **⋮** → **Migrate**, pick a different node, click **Apply**. Watch the status go `Migrating` → `Running`.

Confirm it landed on a new node:

```bash
kubectl get vmi legacy-ledger-vm -n default -o jsonpath='{.status.nodeName}'
```

Confirm it never went offline:

```bash
ssh opensuse@192.168.122.50 "hostname && uptime"
```

`legacy-ledger-vm` moved between nodes with zero downtime: the migration ISAware never offered without a full clustering license, now standard on open-source KubeVirt.

---

**Next:** [Exercise 4: Networking and isolation](04-networking.md)
