# Bonus: The Final Showdown

**Time:** 25 min  
**Previous:** [Exercise 7: The Stampede](07-stampede.md)  
**Next:** [Exercise 8: A New Horizon](08-new-horizon.md)

---

> **This is a self-hosted-only bonus, not one of the eight chapters.** [suse-virt-rodeo](https://github.com/avaleror/suse-virt-rodeo) (the Instruqt track this workshop mirrors) has exactly 8 chapters, ending at "A New Horizon." There's no "Final Showdown" chapter there. This exercise exists here because Harvester's real **Migration** feature (importing VMs from a legacy hypervisor) is worth trying hands-on if you have a VMware, OpenStack or OVA source to point it at, but it was never built into the graded rodeo track. Skip straight to [Exercise 8: A New Horizon](08-new-horizon.md) if you don't.

The legacy vendor wants forty percent more for the renewal. Sarah declines. The last critical workload, `legacy-ledger-vm`, must land on SUSE Virtualization while the old world is still running.

> **Tip:** This lab has no legacy hypervisor to migrate from. That infrastructure doesn't exist in either this repo or suse-virt-rodeo's own automation. Below you walk the real **Migration** UI path, then complete the same verification steps on a stand-in ledger VM so the day-one-ops skills still stick.

## B.1 Look at the migration bridge

The import feature ships as an add-on, disabled by default. Enable it first: **Advanced → Add-ons → `vm-import-controller`** → ⋮ → **Enable**, and wait for **Deploy Successful**.

A new top-level menu appears: **Virtual Machine Imports**, with **Source VMware**, **Source OpenStack** and **Source OVA**.

The lists are empty unless you point a source at a real vCenter, OpenStack or OVA URL. Neither this repo nor suse-virt-rodeo's own automation ships one. Open **Create** and read the fields (source type, endpoint, credentials) so you know what production needs. Cancel without saving if you have no legacy cluster.

## B.2 How extraction works (when a source exists)

**Virtual Machine Imports → Virtual Machine Import → Create** (reference, use when a source is Ready):

| Setting | Value |
|---|---|
| Source Type | VMware, OpenStack or OVA (the type of your source) |
| Source VM | `legacy-ledger-vm` |
| Target Network | `prod/service` (or mgmt / default lab network) |

The importer copies disks, converts them to Longhorn volumes, and registers a native Harvester VM. Progress is visible under **Virtual Machine Imports → Virtual Machine Import**.

## B.3 Workshop path: stand in the migrated ledger

Create (or reuse) a VM that represents the extracted workload:

| Field | Value |
|---|---|
| Name | `legacy-ledger-vm` |
| Namespace | `prod` |
| Network | `prod/service` |
| Image / SSH | same foundations as Exercise 2 |

Wait until it is **Running**. Open **Console**. The migrated ledger is alive on the new fabric.

## B.4 Enable guest telemetry

SSH into the VM and start the QEMU guest agent:

```bash
ssh sles@MIGRATED_VM_IP
sudo systemctl enable --now qemu-guest-agent
exit
```

Back in the UI, the VM should report richer guest info (IP, memory tools) once the agent is up.

## B.5 Treat the refugee like a citizen

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

**Next:** [Exercise 8: A New Horizon](08-new-horizon.md)
