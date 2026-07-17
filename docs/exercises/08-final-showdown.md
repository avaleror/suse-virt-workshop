# Exercise 8: The Final Showdown

**Time:** 25 min  
**Previous:** [Exercise 7: The Stampede](07-stampede.md)  
**Next:** [Exercise 9: A New Horizon](09-new-horizon.md)

---

The legacy vendor wants forty percent more for the renewal. Sarah declines. The last critical workload, `legacy-ledger-vm`, must land on SUSE Virtualization while the old world is still running.

> **Tip:** The customer Rodeo image includes a ready **ISAware** migration source and a live legacy VM. A clean `rodeo up` lab does not. Below you walk the real **Migration** UI path, then complete the same verification steps on a stand-in ledger VM so every skill still sticks.

## 8.1 Explore the migration bridge

In Harvester: **Advanced → Migration → Sources**.

On the Instruqt Rodeo you would see `isaware-legacy-01` in **Ready** state, credentials to the old hypervisor, no agent required on the source.

On this self-hosted lab the list is empty unless you point a source at a real vSphere/ISAware-compatible endpoint. Open **Create** and read the fields (source type, endpoint, credentials) so you know what production needs. Cancel without saving if you have no legacy cluster.

## 8.2 How extraction works (when a source exists)

**Migrations → Create** (reference, use when a source is Ready):

| Setting | Value |
|---|---|
| Source Type | ISAware (or the type your source uses) |
| Source VM | `legacy-ledger-vm` |
| Target Network | `prod/service` (or mgmt / default lab network) |

The importer copies disks, converts them to Longhorn volumes, and registers a native Harvester VM. Progress is visible on the Migrations page.

## 8.3 Workshop path: stand in the migrated ledger

Create (or reuse) a VM that represents the extracted workload:

| Field | Value |
|---|---|
| Name | `legacy-ledger-vm` |
| Namespace | `prod` |
| Network | `prod/service` |
| Image / SSH | same foundations as Exercise 2 |

Wait until it is **Running**. Open **Console**. The migrated ledger is alive on the new fabric.

## 8.4 Enable guest telemetry

SSH into the VM and start the QEMU guest agent:

```bash
ssh opensuse@MIGRATED_VM_IP
sudo systemctl enable --now qemu-guest-agent
exit
```

Back in the UI, the VM should report richer guest info (IP, memory tools) once the agent is up.

## 8.5 Treat the refugee like a citizen

Prove day-one parity on the new platform:

1. Take a snapshot named `post-migration-baseline`.
2. Live-migrate `legacy-ledger-vm` to another node (Exercise 4 skills).
3. Optional CLI:

```bash
kubectl get vm -n prod | grep legacy-ledger
kubectl get virtualmachineimports -A    # empty unless a real import ran
```

On ISAware, live migration was often a licensed add-on. Here it is standard.

---

**Next:** [Exercise 9: A New Horizon](09-new-horizon.md)
