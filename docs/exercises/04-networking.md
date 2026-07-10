# Exercise 4: Networking and isolation

**Time:** 30 min
**Previous:** [Exercise 3: First VM and live migration](03-first-vm.md)
**Next:** [Exercise 5: Snapshots and DR](05-storage-snapshots.md)

---

Vertex Trust Bank runs two divisions on shared infrastructure: Retail Banking and Wealth Management. Each one's customer data, transaction traffic, and settlement traffic must be fully isolated. Under ISAware this meant micro-segmentation policies, distributed firewall rules, and a dedicated network segmentation license. On SUSE Virtualization, it's two kubectl manifests.

## 4.1 The networking stack

| Layer | Technology | Use case | ISAware equivalent |
|---|---|---|---|
| L2 / VLAN bridging | Multus | Backbone VLAN, VM attachment | Distributed Switch |
| SDN / isolated zones | Kube-OVN | Banking division isolation | ISAware micro-segmentation |

**Multus** attaches multiple network interfaces to a VM and bridges them to physical VLANs on the host. This is how a workload gets onto a dedicated backbone VLAN.

**Kube-OVN** (v1.15.4, non-primary CNI mode) owns VM overlay and VPC traffic only, while the management bridge handles pod networking. It adds a full SDN layer with isolated subnets, NAT gateways, and support for **overlapping CIDR ranges**: two divisions can each use `10.0.0.0/24` in their own zone with zero traffic crossing between them.

Check current state:

```bash
kubectl get network-attachment-definitions -n default
```

You should see `vmnet` from Exercise 2. Now add the VLAN backbone and the tenant isolation zones.

## 4.2 Create the settlement backbone VLAN

VLAN 100 tags interbank settlement traffic separately from the management bus. Any upstream switch port connected to the cluster nodes needs VLAN 100 trunked for real external connectivity.

In the Harvester UI, go to **Networks > VM Networks** → **Create**:

- **Name:** `vlan100`
- **Type:** `L2VlanNetwork`
- **Cluster Network:** `mgmt`
- **VLAN ID:** `100`

Click **Create**, then verify:

```bash
kubectl get network-attachment-definitions vlan100 -n default -o yaml | grep -A5 config
```

You should see `"vlanId": 100`.

## 4.3 Create banking division isolation zones

Each division needs an isolated zone, air-gapped from the outside and from each other. In Harvester this is a Kube-OVN subnet with `natOutgoing: false` and `private: true`.

First division (Retail Banking):

```bash
cat << EOF | kubectl apply -f -
apiVersion: kubeovn.io/v1
kind: Subnet
metadata:
  name: containment-retail
spec:
  cidrBlock: "172.16.0.0/24"
  gateway: "172.16.0.1"
  excludeIps:
    - "172.16.0.1"
  protocol: IPv4
  natOutgoing: false
  private: true
EOF
```

Second division (Wealth Management): same CIDR, fully isolated from the first, demonstrating Kube-OVN's overlapping-CIDR support:

```bash
cat << EOF | kubectl apply -f -
apiVersion: kubeovn.io/v1
kind: Subnet
metadata:
  name: containment-wealth
spec:
  cidrBlock: "172.16.0.0/24"
  gateway: "172.16.0.1"
  excludeIps:
    - "172.16.0.1"
  protocol: IPv4
  natOutgoing: false
  private: true
EOF
```

> **Note:** if the second apply returns a validation error about duplicate CIDRs, use `172.16.1.0/24` for `containment-wealth` instead. The isolation demonstration still holds, just with different addresses.

Verify both zones are live with no outgoing NAT:

```bash
kubectl get subnets.kubeovn.io -o custom-columns=NAME:.metadata.name,CIDR:.spec.cidrBlock,NAT:.spec.natOutgoing
```

Both subnets should show `natOutgoing: false`. Neither division's zone can reach the other, and neither has a path to the outside: the ISAware capability Vertex Trust Bank was paying for, now running on open-source Kube-OVN.

## 4.4 Full network inventory

```bash
kubectl get network-attachment-definitions -n default && \
kubectl get subnets.kubeovn.io
```

You should have:

- `vmnet`: untagged management bridge (Exercise 2)
- `vlan100`: VLAN 100 settlement backbone (this exercise)
- `containment-retail` / `containment-wealth`: isolated Kube-OVN division zones (this exercise)

---

**Next:** [Exercise 5: Snapshots and DR](05-storage-snapshots.md)
