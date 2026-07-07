# Exercise 6: Provision a K3s cluster

**Time:** 45 min
**Previous:** [Exercise 5: Snapshots and DR](05-storage-snapshots.md)
**Next:** [Exercise 7: NOC dashboard](07-noc-dashboard.md)

---

AeroGrid passengers currently queue at staffed desks to check in. That changes now: a self-service check-in portal, running on Kubernetes, provisioned directly on top of the Harvester platform. Rancher handles the full lifecycle from one interface: VM creation, OS install, CNI setup, storage wiring, load balancer integration.

## 6.1 Rancher as the control plane

When Rancher Prime manages Harvester, it treats the platform as a **cloud provider**: the same way it talks to GCP, AWS, or Azure. You provision Kubernetes clusters on your on-prem HCI using the same workflow you'd use for the cloud.

| VMware | Rancher + SUSE Virtualization |
|---|---|
| vCenter + vSphere roles | Rancher RBAC + Projects |
| vSphere with Tanzu | Rancher + Harvester node driver |
| Namespace isolation | Rancher Projects |
| Identity federation | Rancher auth providers (LDAP, OIDC, SAML) |

```bash
kubectl get clusters.provisioning.cattle.io -A
```

You should see only `local`: the Harvester platform itself. No application clusters yet.

## 6.2 Configure project RBAC

Rancher uses **Projects** to group namespaces and apply RBAC at scale. A project maps to a team, and members only see what's in their project's scope.

In the Rancher UI: your Harvester cluster → **Projects/Namespaces** → **Create Project**:

- **Name:** `terminal-ops`
- **Members:** add `admin` with role **Project Member** (in production you'd add the real portal team)

Create a namespace scoped to it:

```bash
kubectl create namespace checkin-workloads

kubectl annotate namespace checkin-workloads \
  field.cattle.io/projectId=$(kubectl get projects.management.cattle.io \
    -n local -o jsonpath='{.items[?(@.spec.displayName=="terminal-ops")].metadata.name}') \
  --overwrite
```

Verify:

```bash
kubectl get namespace checkin-workloads -o jsonpath='{.metadata.annotations.field\.cattle\.io/projectId}'
```

## 6.3 Create the cloud credential

Before Rancher can provision VMs on Harvester, it needs a credential to authenticate against the Harvester API.

In the Rancher UI: top-right user menu → **Cloud Credentials** → **Create** → **Harvester**:

- **Name:** `harvester-local`
- **Cluster:** the imported `harvester` cluster

Click **Create**, then verify (reusing `$RANCHER_TOKEN` / `$RANCHER_URL` from Exercise 1):

```bash
curl -sk \
  -H "Authorization: Bearer $RANCHER_TOKEN" \
  "${RANCHER_URL}/v3/cloudcredentials" \
  | jq -r '.data[].name'
```

`harvester-local` should appear.

## 6.4 Provision the check-in portal cluster

In the Rancher UI: **Cluster Management** → **Create** → **RKE2/K3s** → **Infrastructure: Harvester**:

- **Cluster Name:** `checkin-cluster`
- **Kubernetes Version:** K3s v1.35.x
- **Cloud Credential:** `harvester-local`

Node pool:

- **Pool Name:** `agents`, **Machine Count:** `1`, **Namespace:** `default`
- **Image:** `default/leap16`, **CPU:** `2`, **Memory:** `4 GiB`, **Disk:** `40 GiB`
- **Network:** `default/vmnet`, **SSH User:** `opensuse`

Under **Cluster Configuration > Add-Ons** (Rancher 2.14 may show this as **System Services**), enable:

- **Harvester CSI Driver**: Longhorn-backed persistent volumes
- **Harvester Cloud Provider**: LoadBalancer services via `rodeo-ippool`

Click **Create** and watch:

```bash
watch kubectl get clusters.provisioning.cattle.io -A
```

Rancher creates the VM on Harvester, waits for it to boot, installs K3s via cloud-init, and registers the cluster back to Rancher. Takes 5-10 minutes. Once it shows `Active`, `Ctrl+C`.

> Every node in `checkin-cluster` is a VM managed by Harvester. Longhorn provides its storage. The IP pool from Exercise 2 provides its load balancer addresses.

## 6.5 Retrieve the cluster kubeconfig

You'll need this in Exercise 7 to deploy the NOC dashboard.

```bash
CLUSTER_ID=$(curl -sk \
  -H "Authorization: Bearer $RANCHER_TOKEN" \
  "${RANCHER_URL}/v3/clusters?name=checkin-cluster" \
  | jq -r '.data[0].id')

curl -sk -X POST \
  -H "Authorization: Bearer $RANCHER_TOKEN" \
  "${RANCHER_URL}/v3/clusters/${CLUSTER_ID}?action=generateKubeconfig" \
  | jq -r .config > ~/.kube/checkin-cluster.yaml

KUBECONFIG=~/.kube/checkin-cluster.yaml kubectl get nodes
```

`checkin-cluster` is online: kubeconfig saved at `~/.kube/checkin-cluster.yaml`.

## 6.6 What you have now

In Rancher, **Cluster Management** shows:

- `local`: Harvester HCI, 3 nodes, Longhorn storage, Kube-OVN networking
- `checkin-cluster`: K3s, provisioned as a VM on the platform, managed by Rancher

One Rancher instance, two clusters, no VMware, no Broadcom invoice.

---

**Next:** [Exercise 7: NOC dashboard](07-noc-dashboard.md)
