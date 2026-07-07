# Quick Reference

## Access

| Resource | Value |
|---|---|
| KVM host IP | your host's IP (or lab-assigned) |
| Harvester UI | `https://<host-ip>:8443` (external) · `https://192.168.122.10` (from the host) |
| Rancher UI | `https://<host-ip>:30002` (external) · `https://192.168.122.9:30002` (from the host) |
| Admin user | `admin` |
| Admin passwords | `cat ~/.rodeo/secrets.yaml` (`harvester_admin_password`, `rancher_admin_password`) |
| kubectl (Harvester, via Rancher proxy) | see [Exercise 1.6](../exercises/01-import-into-rancher.md#16-configure-kubectl-to-reach-harvester-through-rancher) |
| virt1 SSH | `ssh opensuse@192.168.122.50` (direct — host routes to virbr0) |

## Node reference

| Node | IP | Role |
|---|---|---|
| harvester1 | 192.168.122.11 | Bootstrap |
| harvester2 | 192.168.122.12 | Join |
| harvester3 | 192.168.122.13 | Join |
| rancher | 192.168.122.9 | Rancher Prime + K3s |
| VIP | 192.168.122.10 | Harvester API / UI |
| virt1 | 192.168.122.50 | Workshop VM (Exercise 3) |

## Key commands

```bash
# Cluster health
kubectl get nodes
kubectl get pods -n harvester-system | grep -v Completed

# Networking (Exercise 2 / 4)
kubectl get network-attachment-definitions -n default
kubectl get ippools.network.harvesterhci.io -n default
kubectl get subnets.kubeovn.io

# Storage (Exercise 5)
kubectl get storageclass
kubectl get vmsnapshots -n default
kubectl get volumes.longhorn.io -n longhorn-system

# Rancher-provisioned clusters (Exercise 6)
kubectl get clusters.provisioning.cattle.io -A
watch kubectl get clusters.provisioning.cattle.io -A

# alien-geeko dashboard (Exercise 7)
export KUBECONFIG=~/.kube/checkin-cluster.yaml
kubectl get svc alien-geeko -n alien-geeko
kubectl rollout status deployment/alien-geeko -n alien-geeko
```

## rodeo-cli lifecycle

```bash
rodeo status                    # health + phase progress
rodeo ssh harvester1            # shell into a node
rodeo stop --all --yes          # stop for later
rodeo start --all --yes         # resume
rodeo clean --yes               # tear down everything
```

## Component versions

| Component | Version |
|---|---|
| Harvester | 1.8.1 |
| Rancher Prime | 2.14.1 |
| K3s (management cluster) | v1.35.3+k3s1 |
| cert-manager | v1.20.1 |
| KubeVirt | v1.7.0 |
| Longhorn | v1.11.1 |
| Kube-OVN | v1.15.4 |
