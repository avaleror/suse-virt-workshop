# Host Setup: SUSE Virtualization Workshop

This workshop deploys on a bare metal Linux host with KVM. These steps cover host prep and initial deploy.

## Requirements

| Resource | Minimum |
|---|---|
| OS | SLES 16 / SLES 15 SP6 / openSUSE Leap 15.6 |
| RAM | 64 GiB |
| vCPU | 32 |
| Disk | 900 GiB (free in `/var/lib/libvirt/images`) |
| Nested virtualization | Enabled (`cat /sys/module/kvm_intel/parameters/nested` should print `Y`) |
| Network | Internet access during deploy; exercises run against the local cluster only |

## Install rodeo-cli

```bash
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash
```

This installs prerequisites (python3, pip, git), clones the repo to `/opt/rodeo-cli`, creates a venv with system-site-packages (needed for libvirt-python), and symlinks `rodeo` to `/usr/local/bin`.

To pin a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash -s -- --ref v0.10.6
```

## Generate secrets

```bash
rodeo init --profile harvester --dir /path/to/suse-virt-workshop
```

This creates `~/.rodeo/secrets.yaml` with generated passwords. The `rodeo-plan.yaml` in this repo references them via `??placeholder` notation.

## Deploy

From the workshop directory:

```bash
sudo rodeo deploy --config-dir .
```

The deploy runs in phases: `kvm_host → vms → pxe_server → cluster → rancher → finalise`. Total time is **1-2.5 hours**, and the `cluster` phase is the long pole. Nested KVM makes the Harvester install slow (VIP wait up to 60 min, all-3-nodes-Ready up to 90 min). This is expected; do not interrupt it. See [Lab overview](../reference/lab-overview.md) for the full phase breakdown.

When complete, the success screen shows:

- Harvester and Rancher URLs
- Admin password locations
- First commands to try

## harvester_auto_import stays false

`rodeo-plan.yaml` sets `harvester_auto_import: false` on purpose: importing Harvester into Rancher is Exercise 1. Don't do it for students; if you do, skip straight to Exercise 2 when handing off, or redeploy from a clean state.

## Verify before handing to students

```bash
# All 3 Harvester nodes Ready
rodeo ssh harvester1 "kubectl get nodes"

# Rancher API reachable
curl -sk https://192.168.122.9:30002/v3 | jq -r '.type'

# Harvester API reachable
curl -sk https://192.168.122.10/v1 | jq -r '.apiVersion'

# Neither system is imported into the other yet
curl -sk -u admin:$(grep rancher_admin_password ~/.rodeo/secrets.yaml | cut -d'"' -f2) \
  https://192.168.122.9:30002/v3/clusters | jq -r '.data[].name'
# should list only "local"
```

Everything should be green, and only `local` should appear in the Rancher cluster list. That confirms Exercise 1 hasn't been done yet.

## Tear down

```bash
sudo rodeo clean --config-dir . --yes
```

This removes all VMs, disk images, and libvirt network config. The host is left clean.

## Reruns

Nothing here is one-shot. If a cluster gets into a bad state during a workshop, `sudo rodeo clean --config-dir . --yes` followed by `sudo rodeo deploy --config-dir .` gets you back to a known-good starting point.
