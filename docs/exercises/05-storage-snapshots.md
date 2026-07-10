# Exercise 5: Snapshots and DR

**Time:** 30 min
**Previous:** [Exercise 4: Networking and isolation](04-networking.md)
**Next:** [Exercise 6: Provision a K3s cluster](06-provision-k3s.md)

---

Transaction record retention is a Basel III operational resilience requirement: 7 years minimum. Before any risky change to `legacy-ledger-vm`, take a checkpoint. This exercise configures storage policies, snapshots before a change, simulates corruption, and restores clean.

## 5.1 Vertex Trust Bank's storage architecture

Harvester uses **Longhorn** as its distributed block storage engine: local disks from every cluster node pooled into a replicated volume, no external SAN, no NFS, no proprietary array.

| ISAware | SUSE Virtualization |
|---|---|
| ISAware storage replication | Longhorn |
| ISAware storage policies | Longhorn StorageClasses |
| VM snapshots | Longhorn volume snapshots |
| ISAware Data Protection | S3/NFS backup targets |

Longhorn writes multiple replicas of each volume across different nodes. One node can fail entirely with no data loss and no downtime.

```bash
kubectl get storageclass
kubectl get nodes.longhorn.io -n longhorn-system
```

You should see 3 Longhorn storage nodes, one per cluster node.

## 5.2 Inspect and add storage policies

Harvester ships `harvester-longhorn` as the default StorageClass: 3 replicas, one per node. In the Harvester UI, go to **Advanced > Storage Classes** and open `harvester-longhorn`: note `numberOfReplicas: "3"`.

Add a second policy for dev/test workloads (2 replicas, lower overhead):

```bash
cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: harvester-longhorn-2rep
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  numberOfReplicas: "2"
  staleReplicaTimeout: "30"
  fromBackup: ""
  fsType: ext4
EOF
```

```bash
kubectl get storageclass
```

Two policies now exist: `harvester-longhorn` (3 replicas, production data) and `harvester-longhorn-2rep` (2 replicas, dev/test).

## 5.3 Checkpoint before a risky change

Before a configuration change on `legacy-ledger-vm`, take a snapshot: a point-in-time rollback target.

> **Note:** Harvester snapshots are crash-consistent by default. For application-consistent snapshots (filesystem freeze) use the QEMU guest agent, already pre-installed in the `leap16` image.

In the Harvester UI: **Virtual Machines** → `legacy-ledger-vm` → **⋮** → **Take Snapshot** → name it `legacy-ledger-vm-snap1` → **Create**.

```bash
kubectl get vmsnapshots -n default
```

`ReadyToUse: true` confirms the rollback point is set.

## 5.4 Simulate corruption and restore

Simulate the incident:

```bash
ssh opensuse@192.168.122.50 \
  "echo 'CRITICAL: LEDGER INTEGRITY CHECK FAILED, SETTLEMENT AT RISK' | sudo tee /etc/incident-report.txt"
```

Restore from the checkpoint via the Harvester UI: **Virtual Machines** → `legacy-ledger-vm` → **⋮** → **Restore Snapshot** → select `legacy-ledger-vm-snap1` → **Create new VM** (leaves `legacy-ledger-vm` intact for comparison) → name it `legacy-ledger-vm-restored` → **Restore**.

```bash
kubectl get vm -n default
```

You should see both `legacy-ledger-vm` (post-incident) and `legacy-ledger-vm-restored` (clean checkpoint, no trace of the corruption).

## 5.5 Off-site backup configuration

Snapshots are local. If the cluster is lost, they're lost with it. For real DR, Harvester supports backup to S3-compatible storage or NFS.

```bash
kubectl get settings.harvesterhci.io backup-target -o yaml
```

In production this would point to MinIO, AWS S3, or an NFS share at a separate facility. The backup engine is Longhorn-native and can restore full VMs or individual volumes from the off-site target.

## 5.6 Verify replica distribution

```bash
kubectl get volumes.longhorn.io -n longhorn-system

kubectl get replicas.longhorn.io -n longhorn-system -o custom-columns=\
NAME:.metadata.name,\
NODE:.spec.nodeID,\
VOLUME:.spec.volumeName,\
STATE:.status.currentState
```

Each volume should have replicas spread across different nodes: ISAware-grade resilience without the ISAware storage license.

---

**Next:** [Exercise 6: Provision a K3s cluster](06-provision-k3s.md)
