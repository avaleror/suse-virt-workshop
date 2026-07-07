# Exercise 2: Bring the cluster online

**Time:** 30 min
**Previous:** [Exercise 1: Import into Rancher](01-import-into-rancher.md)
**Next:** [Exercise 3: First VM and live migration](03-first-vm.md)

---

The cluster is imported and `kubectl` is wired up. Before any workload goes live, confirm the platform is healthy, then build the networking primitives every later exercise depends on: a cluster network, a VM network, and a LoadBalancer IP pool.

## 2.1 Confirm cluster health

```bash
kubectl get nodes
```

All 3 nodes should show `Ready`.

```bash
kubectl get pods -n harvester-system | grep -v Completed
```

All pods should be `Running`.

## 2.2 The five-NIC traffic model

Each Harvester node has five NICs, each carrying a specific traffic type:

| NIC | Role | Used by |
|---|---|---|
| eth0 | Management | Cluster API, node communication |
| eth1 | Storage | Longhorn distributed storage traffic |
| eth2 | Migration | KubeVirt live migration |
| eth3 | Service network 1 | VM workloads, primary |
| eth4 | Service network 2 | VM workloads, secondary |

This separation keeps VM traffic, storage I/O, and live migration off the management path entirely: the same isolation NSX provided on VMware, built directly into the platform.

## 2.3 Create the VM traffic cluster network

Tell Harvester to use `eth3` as the uplink for the primary VM workload cluster network, `vms`.

In the Harvester UI:

1. Go to **Networks > Cluster Networks** → **Create**
2. Name it `vms`
3. Under **Node Network Config**, add an entry for each node:
   - **Add** → select `harvester1` → NIC `eth3`
   - Repeat for `harvester2` and `harvester3`
4. Click **Create**

Wait for all three node configs to show `Active`.

## 2.4 Create the primary VM network

With `vms` active, create the VM network workloads will attach to.

In the Harvester UI, go to **Networks > VM Networks** → **Create**:

- **Name:** `vmnet`
- **Type:** `L2VlanNetwork`
- **Cluster Network:** `vms`
- **VLAN ID:** `1` (untagged)

Click **Create**, then verify:

```bash
kubectl get network-attachment-definitions -n default
```

`vmnet` should be listed.

## 2.5 Set up the LoadBalancer IP pool

Harvester can provision guest Kubernetes clusters. Those clusters need LoadBalancer IPs to expose services externally, and an **IP Pool** pre-allocates a range for that purpose. This pool is used in every remaining exercise.

In the Harvester UI, go to **Networks > IP Pools** → **Create**:

- **Name:** `rodeo-ippool`
- **Range** tab: `192.168.122.200` to `192.168.122.220`
- **Selector** tab: **VM Network** `default/vmnet`, **Namespace** `default`

Click **Create**, then verify:

```bash
kubectl get ippools.network.harvesterhci.io -n default
```

`rodeo-ippool` should be listed. The cluster is ready to provision workloads and expose services.

---

**Next:** [Exercise 3: First VM and live migration](03-first-vm.md)
