# Exercise 5: The Invisible Intruder

**Time:** 30 min  
**Previous:** [Exercise 4: The Rising Tide](04-rising-tide.md)  
**Next:** [Exercise 6: The Unthinkable Error](06-unthinkable-error.md)

---

Someone is probing lateral movement from a compromised app tier toward the ledger. You will build an isolated production path on a dedicated NIC fabric and a cheaper overlay vault for development, then show how to attach VMs.

> **Note:** Nested Harvester nodes from rodeo-cli typically expose multiple virtio NICs. This exercise uses `ens5` as the uplink for the closed-loop cluster network. Confirm the interface name under **Hosts → node → Network** and adjust if your lab shows `enp*s*` or similar.

## 5.1 Closed-loop cluster network (physical isolation)

**Networks → Cluster Network Configuration → Create a Cluster Network**:

| Field | Value |
|---|---|
| Name | `closed-loop` |

On the `closed-loop` row → **Create Network Configuration** (uplink):

| Field | Value |
|---|---|
| Name | `closed-loop` |
| Uplink NICs | `ens5` (or the spare NIC on your nodes) |

Then **Virtual Machine Networks → Create**:

| Field | Value |
|---|---|
| Namespace | `prod` |
| Name | `secure-loop-prod` |
| Type | `UntaggedNetwork` |
| Cluster Network | `closed-loop` |

Confirm `prod/secure-loop-prod` is **Active**.

## 5.2 Overlay vault for development (Kube-OVN)

**Virtual Machine Networks → Create**:

| Field | Value |
|---|---|
| Namespace | `dev` |
| Name | `secure-loop-dev` |
| Type | `OverlayNetwork` |

**Networks → Virtual Private Cloud** → on `ovn-cluster` → **Create Subnet**:

| Field | Value |
|---|---|
| Name | `secure-vpc-dev` |
| CIDR | `192.168.32.0/24` |
| Provider | `dev/secure-loop-dev` |
| Gateway IP | `192.168.32.1` |
| DHCP | Enabled |
| Private Subnet | Enabled |

VMs on `dev/secure-loop-dev` only talk to peers on that overlay.

## 5.3 Attach a VM to the vault

Pick a non-critical VM (for example `daily-batch-processor`):

1. ⋮ → **Edit Config** → **Networks** → select `prod/secure-loop-prod` (or `dev/secure-loop-dev` for a dev VM).
2. **Save**.
3. **Stop** the VM if required, then **Start** / **Restart** so the NIC change applies.

> **Important:** Hot-plug of network changes is limited. Stopping first is the reliable path.

You have shown the bank how production rides a dedicated fabric and how development gets isolation without new cables.

## 5.4 Optional CLI drills

```bash
kubectl get network-attachment-definitions -A
kubectl get subnets.kubeovn.io
kubectl get vpcs.kubeovn.io
```

---

**Next:** [Exercise 6: The Unthinkable Error](06-unthinkable-error.md)
