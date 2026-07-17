# Host Setup: SUSE Virtualization Workshop

This workshop deploys on a bare metal Linux host with KVM. These steps cover host prep and initial deploy. Automation is entirely [rodeo-cli](https://github.com/avaleror/rodeo-cli); this repo ships the plan and the lab exercises. Same topology as [suse-virt-rodeo](https://github.com/avaleror/suse-virt-rodeo).

## Requirements

| Resource | Minimum |
|---|---|
| OS | SLES 16 / Leap 16 (Ubuntu 22.04+ and Fedora also work via `install-deps`) |
| RAM | 64 GiB available (~72 GiB total recommended for the `harvester` profile) |
| vCPU | ~32 free |
| Disk | ~1050 GiB free in `/var/lib/libvirt/images` (320 GB × 3 Harvester + Rancher + ISO cache) |
| KVM | `/dev/kvm` present. Nested virt only needed if the host itself is a VM |
| Network | Internet access during deploy |

Confirm readiness:

```bash
rodeo doctor
```

You want a recommendation of **harvester** (or enough RAM to run it).

## Install rodeo-cli

```bash
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash
```

This clones the CLI, sets up its Python environment, and links `rodeo` as a system command. No venv to activate, no PATH tweaks, no `sudo` prefix on day-2 commands. `rodeo up` self-escalates when it needs root.

To pin a release:

```bash
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash -s -- --ref v0.14.2
```

## Deploy this workshop

```bash
git clone https://github.com/avaleror/suse-virt-workshop.git
cd suse-virt-workshop
rodeo up
```

Because you are inside a directory that already contains `rodeo-plan.yaml`, `rodeo up` auto-detects the lab. It will:

1. Wrap itself in a tmux session so a dropped SSH does not kill the deploy
2. Re-run host checks and offer to install missing packages
3. Generate `~/.rodeo/secrets.yaml` with random credentials
4. Drive the pipeline: `kvm_host → vms → pxe_server → cluster → rancher → finalise`
5. Print Harvester / Rancher URLs and where to find passwords

**Typical time:** 90-150 minutes. The `cluster` phase (iPXE install of Harvester inside nested KVM) is the long pole.

### Survive disconnects

```bash
tmux attach -t rodeo-harvester    # session name matches the profile / lab
# Detach without stopping: Ctrl+b  d
```

### Watch progress

From a second shell on the host:

```bash
rodeo watch                 # phases + serial consoles
rodeo logs harvester1       # one node's serial log
rodeo status                # VM state + VIP reachability
```

## harvester_auto_import stays false

`rodeo-plan.yaml` sets `harvester_auto_import: false` on purpose. Importing Harvester into Rancher is **Exercise 1**. Do not import it before handing the lab to students.

## Verify before students start

```bash
# All 3 Harvester nodes Ready
rodeo ssh harvester1 "kubectl get nodes"

# Rancher + Harvester APIs reachable
curl -sk https://192.168.122.9:30002/v3 | jq -r '.type'
curl -sk https://192.168.122.10/v1 | jq -r '.apiVersion'

# Only "local" in Rancher - Harvester not imported yet
curl -sk -u admin:$(grep rancher_admin_password ~/.rodeo/secrets.yaml | cut -d'"' -f2) \
  https://192.168.122.9:30002/v3/clusters | jq -r '.data[].name'
```

External DNAT (from a laptop on the same network):

```bash
curl -sk https://<host-ip>:8443/v1 | jq -r '.apiVersion'
curl -sk https://<host-ip>:30002/v3 | jq -r '.type'
```

See the [pre-lab checklist](pre-lab-checklist.md) for the full gate.

## Hand students

| Item | Value |
|---|---|
| Harvester UI | `https://<host-ip>:8443` |
| Rancher UI | `https://<host-ip>:30002` |
| Username | `admin` |
| Passwords | `harvester_admin_password` and `rancher_admin_password` in `~/.rodeo/secrets.yaml` |
| Lab guide | https://avaleror.github.io/suse-virt-workshop/ |

Both UIs use self-signed certificates. Students must accept the browser warning.

## Tear down / redeploy

```bash
rodeo clean --yes                     # destroy this lab's VMs and disks
rodeo up                              # fresh deploy (reuses secrets)

rodeo clean --all --yes --secrets     # full host reset, wipe credentials
rodeo up                              # new secrets + fresh deploy
```

## Resume a failed deploy

```bash
rodeo status
rodeo deploy --from cluster           # resume from the failed phase
# or
rodeo deploy --force                  # redo every phase
```

## Optional: dedicated data disk

If the host has a second disk for lab images:

```yaml
# in rodeo-plan.yaml
storage:
  device: /dev/nvme1n1          # verify with lsblk first
  mount_point: /var/lib/libvirt/images
  image_dir: /var/lib/libvirt/images
  fs_type: xfs
```

The `kvm_host` phase partitions, formats, and mounts it before creating VMs.

## Further reading

- [rodeo-cli Harvester guide](https://github.com/avaleror/rodeo-cli/blob/main/docs/guide-harvester.md)
- [Bare-metal example](https://github.com/avaleror/rodeo-cli/blob/main/docs/examples/bare-metal.md)
- [Lab overview](../reference/lab-overview.md)
