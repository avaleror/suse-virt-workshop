# Quick reference

## Access

| Resource | Value |
|---|---|
| KVM host IP | your host's IP |
| Harvester UI | `https://<host-ip>:8443` · from host: `https://192.168.122.10` |
| Rancher UI | `https://<host-ip>:30002` · from host: `https://192.168.122.9:30002` |
| Admin user | `admin` |
| Passwords | `cat ~/.rodeo/secrets.yaml` (`harvester_admin_password`, `rancher_admin_password`) |
| kubectl (Harvester) | download kubeconfig from Harvester **Support → Download KubeConfig**, or via Rancher after Chapter 1 |
| Guest SSH (after Ch 3) | `ssh opensuse@192.168.122.50` |

## Node reference

| Node | IP | Role |
|---|---|---|
| harvester1 | 192.168.122.11 | Bootstrap |
| harvester2 | 192.168.122.12 | Join |
| harvester3 | 192.168.122.13 | Join |
| rancher | 192.168.122.9 | Rancher Prime + K3s |
| VIP | 192.168.122.10 | Harvester API / UI |
| algo-trader-01 | 192.168.122.50 | Chapter 3 calculation engine |

## Key lab objects (created during chapters)

| Object | Chapter |
|---|---|
| Import cluster name `harvester` | 1 |
| Namespaces `prod`, `dev` | 2 |
| StorageClass `harvester-longhorn-1rep` | 2 |
| Network `prod/service` (UntaggedNetwork on `mgmt`) | 2 |
| KeyPair `prod/default` | 2 |
| Image `official-images/sles16` (or SLES cloud image) | 2 |
| VM `prod/algo-trader-01` | 3 |
| VM `prod/webserver-prod` | 4 |
| Cluster network `closed-loop` / NAD `prod/secure-loop-prod` | 5 |
| Overlay `dev/secure-loop-dev` + subnet | 5 |
| Snapshot `pre-disaster-backup` | 6 |
| Template `harvester-public/prod-basic` | 7 |
| VM `prod/legacy-ledger-vm` | 8 |

## Deploy and day-2 (rodeo-cli)

```bash
# First-time deploy (from this repo)
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash
cd suse-virt-workshop
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
