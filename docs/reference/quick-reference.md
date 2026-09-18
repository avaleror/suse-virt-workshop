# Quick Reference

## Access

| Resource | Value |
|---|---|
| KVM host IP | your host's IP (or lab-assigned) |
| Harvester UI | `https://<host-ip>:8443` · from host: `https://192.168.122.10` |
| Rancher UI | `https://<host-ip>:30002` · from host: `https://192.168.122.9:30002` |
| Admin user | `admin` |
| Passwords | `cat ~/.rodeo/secrets.yaml` (`harvester_admin_password`, `rancher_admin_password`) |
| kubectl (Harvester) | download kubeconfig from Harvester **Support → Download KubeConfig**, or via Rancher after Exercise 1 |
| Guest SSH (after Ex 3) | `ssh sles@192.168.122.50` |

## Node reference

| Node | IP | Role |
|---|---|---|
| harvester1 | 192.168.122.11 | Bootstrap |
| harvester2 | 192.168.122.12 | Join |
| harvester3 | 192.168.122.13 | Join |
| rancher | 192.168.122.9 | Rancher Prime + K3s |
| VIP | 192.168.122.10 | Harvester API / UI |
| algo-trader-01 | 192.168.122.50 | Exercise 3 calculation engine |

## Key lab objects

| Object | Created by |
|---|---|
| Namespace `prod`, node labels, network `prod/service` | deploy automation (`custom_scripts`) |
| Cached image `official-images/Leap-16.0-...` | deploy automation (`custom_scripts`) |
| NFS export `192.168.122.1:/srv/backups/` | deploy automation (`custom_scripts`) |
| VMs `prod/webserver-prod`, `prod/daily-batch-processor` | deploy automation (`custom_scripts`) |
| Import cluster name `harvester` | Exercise 1 |
| Namespace `dev` | Exercise 2 |
| StorageClass `harvester-longhorn-1rep` | Exercise 2 |
| KeyPair `prod/default` | Exercise 2 |
| Image `official-images/sles16` (or SLES cloud image) | Exercise 2 |
| VM `prod/algo-trader-01` | Exercise 3 |
| Cluster network `closed-loop` / NAD `prod/secure-loop-prod` | Exercise 5 |
| Overlay `dev/secure-loop-dev` + subnet | Exercise 5 |
| Snapshot `pre-disaster-backup` | Exercise 6 |
| Template `harvester-public/prod-basic` | Exercise 7 |
| VM `prod/legacy-ledger-vm` | Bonus (self-hosted only) |

## Deploy and day-2 (rodeo-cli)

```bash
# First-time deploy (from this repo; use aws/ instead of baremetal/ for AWS)
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash
cd suse-virt-workshop/baremetal
rodeo doctor
rodeo up

# Operations
rodeo status
rodeo watch
rodeo ssh harvester1
rodeo stop --all --yes
rodeo start --all --yes
rodeo clean --yes
rodeo clean --all --yes --secrets

# Resume / recover
tmux attach -t rodeo-harvester
rodeo deploy --from cluster
rodeo logs harvester1
```

## Component versions

| Component | Version |
|---|---|
| Harvester | 1.8.1 |
| Rancher Prime | 2.14.1 |
| K3s (management) | v1.35.3+k3s1 |
| cert-manager | v1.20.1 |
| rodeo-cli | v0.14.x |
