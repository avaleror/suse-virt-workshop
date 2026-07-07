# SUSE Virtualization Rodeo: Lab Guide

**Version:** 1.0 | **Duration:** ~3.5 hours
**Author:** Andres Valero, Principal Technology Advocate, SUSE

---

## Before we start

This is a hands-on lab. You will import a running Harvester HCI cluster into Rancher Prime, build its networking and storage, provision and live-migrate a VM, isolate tenant traffic, take VM snapshots, then provision a full Kubernetes cluster on top of it all and deploy a workload to it. The goal is not to click through slides. It's to leave knowing how SUSE Virtualization actually works at the system level.

Your environment is already running: a bare metal host with three Harvester nodes forming a cluster, and a fourth VM running Rancher Prime. **Access credentials** are in `~/.rodeo/secrets.yaml` on the host.

---

## The scenario

AeroGrid Operations runs the IT stack for a regional international airport: baggage handling, gate assignment, check-in kiosks, ramp control, three airline tenants sharing the same infrastructure. When Broadcom's acquisition of VMware closed, the renewal quote came in at 3.2x the previous cost, with NSX, vSAN, and vCenter billed separately.

The decision was made: migrate to SUSE Virtualization. This lab puts you in the seat of the AeroGrid infrastructure team, bringing the new platform online end to end.

## Lab topology

```
KVM host (bare metal, yours)
│
├── harvester1   192.168.122.11   8 vCPU / 16 GiB / 270 GB   bootstrap node
├── harvester2   192.168.122.12   8 vCPU / 16 GiB / 270 GB   join node
├── harvester3   192.168.122.13   8 vCPU / 16 GiB / 270 GB   join node
└── rancher      192.168.122.9    4 vCPU / 8 GiB  / 60 GB    Rancher Prime + K3s

VIP (kube-vip): 192.168.122.10
```

---

## Exercise 1: Import Harvester into Rancher

*(30 min)*

`rodeo deploy` leaves you with two systems that don't know about each other: a healthy 3-node Harvester cluster, and Rancher Prime on its own VM. Connect them, then wire up `kubectl`.

**1. Verify both backends are up:**

```bash
curl -sk https://192.168.122.10/v1 | jq -r '.apiVersion'
curl -sk https://192.168.122.9:30002/v3 | jq -r '.type'
```

**2. Log in to Rancher** at `https://<host-ip>:30002`: user `admin`, password from `~/.rodeo/secrets.yaml` (`rancher_admin_password`). You'll see one cluster, `local`.

**3. Register the Harvester cluster:** Rancher UI → **Virtualization Management** → **Import Existing** → name it exactly `harvester` → **Create**. Copy the registration URL Rancher shows you.

**4. Apply it in Harvester:** log in at `https://<host-ip>:8443` (user `admin`, `harvester_admin_password`) → **Settings** → **cluster-registration-url** → paste the URL → **Save**.

**5. Watch the import** in Rancher's Virtualization Management view: `Pending` → `Waiting` → `Active`.

**6. Configure kubectl through Rancher's proxy**: generate an API token (user avatar → Account & API Keys → Create API Key), then:

```bash
export RANCHER_URL="https://192.168.122.9:30002"
export RANCHER_TOKEN="<bearer token>"

CLUSTER_ID=$(curl -sk -H "Authorization: Bearer $RANCHER_TOKEN" \
  "${RANCHER_URL}/v3/clusters?name=harvester" | jq -r '.data[0].id')

kubectl config set-credentials rancher-bearer --token="$RANCHER_TOKEN"
kubectl config set-cluster susevirt-through-rancher \
  --server="${RANCHER_URL}/k8s/clusters/${CLUSTER_ID}" --insecure-skip-tls-verify=true
kubectl config set-context susevirt-through-rancher \
  --cluster=susevirt-through-rancher --user=rancher-bearer
kubectl config use-context susevirt-through-rancher

kubectl get nodes   # all 3 nodes Ready
```

**7. Register your SSH key** as a Harvester KeyPair for Exercise 3:

```bash
kubectl apply -f - <<EOF
apiVersion: harvesterhci.io/v1beta1
kind: KeyPair
metadata:
  name: workshop-host
  namespace: default
spec:
  publicKey: >-
    $(cat ~/.ssh/id_ed25519.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub)
EOF
```

Full detail: [Exercise 1](exercises/01-import-into-rancher.md)

---

## Exercise 2: Bring the cluster online

*(30 min)*

**1. Confirm health:**

```bash
kubectl get nodes
kubectl get pods -n harvester-system | grep -v Completed
```

**2. Create the VM cluster network**: Harvester UI → **Networks > Cluster Networks** → **Create** → name `vms` → add a Node Network Config entry per node with NIC `eth3`.

**3. Create the primary VM network**: **Networks > VM Networks** → **Create** → name `vmnet`, type `L2VlanNetwork`, cluster network `vms`, VLAN ID `1`.

```bash
kubectl get network-attachment-definitions -n default   # vmnet listed
```

**4. Set up the LoadBalancer IP pool**: **Networks > IP Pools** → **Create** → name `rodeo-ippool`, range `192.168.122.200`–`192.168.122.220`, VM Network `default/vmnet`, namespace `default`.

```bash
kubectl get ippools.network.harvesterhci.io -n default
```

Full detail: [Exercise 2](exercises/02-cluster-online.md)

---

## Exercise 3: First VM and live migration

*(30 min)*

**1. Provision virt1**: Rancher UI → Virtualization Management → Virtual Machines → Create: name `virt1`, 2 CPU / 2 GiB, SSH key `default/workshop-host`, volume from image `default/leap16` (20 GiB), network `default/vmnet` with static IP `192.168.122.50` via cloud-init Network Data:

```yaml
version: 2
ethernets:
  enp1s0:
    addresses: ["192.168.122.50/24"]
    gateway4: 192.168.122.1
    nameservers:
      addresses: ["8.8.8.8"]
```

Node Scheduling: **Run virtual machine on any available node**. Create, wait for `Running`.

**2. Verify:**

```bash
until ssh -o StrictHostKeyChecking=no opensuse@192.168.122.50 "uname -a" 2>/dev/null; do sleep 10; done
ssh opensuse@192.168.122.50 "cat /etc/os-release"
```

**3. Live-migrate it:** Rancher UI → Virtual Machines → `virt1` → **⋮** → **Migrate** → pick a different node → **Apply**.

```bash
kubectl get vmi virt1 -n default -o jsonpath='{.status.nodeName}'
ssh opensuse@192.168.122.50 "hostname && uptime"   # confirms zero downtime
```

Full detail: [Exercise 3](exercises/03-first-vm.md)

---

## Exercise 4: Networking and isolation

*(30 min)*

**1. VLAN backbone**: Harvester UI → **Networks > VM Networks** → Create: name `vlan100`, type `L2VlanNetwork`, cluster network `mgmt`, VLAN ID `100`.

**2. Two isolated tenant zones** (same CIDR, fully isolated via Kube-OVN):

```bash
cat << EOF | kubectl apply -f -
apiVersion: kubeovn.io/v1
kind: Subnet
metadata:
  name: containment-alpha
spec:
  cidrBlock: "172.16.0.0/24"
  gateway: "172.16.0.1"
  excludeIps: ["172.16.0.1"]
  protocol: IPv4
  natOutgoing: false
  private: true
EOF
```

Repeat for `containment-beta` (same CIDR; use `172.16.1.0/24` if validation rejects the duplicate).

```bash
kubectl get subnets.kubeovn.io -o custom-columns=NAME:.metadata.name,CIDR:.spec.cidrBlock,NAT:.spec.natOutgoing
```

Full detail: [Exercise 4](exercises/04-networking.md)

---

## Exercise 5: Snapshots and DR

*(30 min)*

**1. Add a second storage policy** (2 replicas, dev/test):

```bash
cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: harvester-longhorn-2rep
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  numberOfReplicas: "2"
  staleReplicaTimeout: "30"
  fsType: ext4
EOF
```

**2. Snapshot virt1**: Harvester UI → Virtual Machines → `virt1` → **⋮** → **Take Snapshot** → name `virt1-snap1`.

**3. Simulate corruption and restore:**

```bash
ssh opensuse@192.168.122.50 "echo 'CRITICAL: GATE ASSIGNMENT DATABASE CORRUPTED' | sudo tee /etc/incident-report.txt"
```

Harvester UI → `virt1` → **⋮** → **Restore Snapshot** → `virt1-snap1` → **Create new VM** → name `virt1-restored`.

```bash
kubectl get vm -n default   # both virt1 and virt1-restored
```

**4. Check replica spread across nodes:**

```bash
kubectl get replicas.longhorn.io -n longhorn-system \
  -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeID,VOLUME:.spec.volumeName,STATE:.status.currentState
```

Full detail: [Exercise 5](exercises/05-storage-snapshots.md)

---

## Exercise 6: Provision a K3s cluster

*(45 min)*

**1. Project RBAC**: Rancher UI → Projects/Namespaces → Create Project `terminal-ops`, add `admin` as Project Member.

```bash
kubectl create namespace checkin-workloads
kubectl annotate namespace checkin-workloads \
  field.cattle.io/projectId=$(kubectl get projects.management.cattle.io -n local \
    -o jsonpath='{.items[?(@.spec.displayName=="terminal-ops")].metadata.name}') --overwrite
```

**2. Cloud credential**: Rancher UI → Cloud Credentials → Create → Harvester → name `harvester-local`, cluster `harvester`.

**3. Provision `checkin-cluster`**: Cluster Management → Create → RKE2/K3s → Infrastructure Harvester: cloud credential `harvester-local`, node pool 1x (2 CPU / 4 GiB / 40 GiB, image `default/leap16`, network `default/vmnet`, SSH user `opensuse`). Enable **Harvester CSI Driver** and **Harvester Cloud Provider**.

```bash
watch kubectl get clusters.provisioning.cattle.io -A
```

**4. Save the kubeconfig:**

```bash
CLUSTER_ID=$(curl -sk -H "Authorization: Bearer $RANCHER_TOKEN" \
  "${RANCHER_URL}/v3/clusters?name=checkin-cluster" | jq -r '.data[0].id')
curl -sk -X POST -H "Authorization: Bearer $RANCHER_TOKEN" \
  "${RANCHER_URL}/v3/clusters/${CLUSTER_ID}?action=generateKubeconfig" \
  | jq -r .config > ~/.kube/checkin-cluster.yaml
```

Full detail: [Exercise 6](exercises/06-provision-k3s.md)

---

## Exercise 7: NOC dashboard

*(20 min)*

**1. Deploy alien-geeko** on `checkin-cluster` (namespace, ServiceAccount + ClusterRole, ConfigMap with `CLUSTER_NAME`, Deployment + LoadBalancer Service). Full manifests in [Exercise 7](exercises/07-noc-dashboard.md).

```bash
export KUBECONFIG=~/.kube/checkin-cluster.yaml
kubectl rollout status deployment/alien-geeko -n alien-geeko
```

**2. Open it directly**: no port-forward needed, the LoadBalancer IP is on your local network:

```bash
kubectl get svc alien-geeko -n alien-geeko
# open http://<EXTERNAL-IP> in a browser
```

**3. Rename the instance:**

```bash
kubectl patch configmap alien-geeko-config -n alien-geeko \
  --patch '{"data":{"CLUSTER_NAME":"AEROGRID-NOC-TERMINAL-1"}}'
kubectl rollout restart deployment/alien-geeko -n alien-geeko
```

---

## The full stack

```
Bare metal (3 nodes)
  └── Harvester (KubeVirt + Longhorn + Kube-OVN)
        └── checkin-cluster VM (K3s, provisioned by Rancher)
              └── alien-geeko (NOC dashboard, LoadBalancer via rodeo-ippool)
```

Every component is open source. Every component is SUSE-supported. AeroGrid's platform is live.
