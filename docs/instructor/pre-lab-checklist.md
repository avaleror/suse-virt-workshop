# Pre-lab checklist

Run this after `rodeo up` finishes and before students open Chapter 1. Deploy
takes 90–150 minutes on nested KVM; budget extra time for this gate.

## After deploy completes

```bash
# 1. All 3 Harvester nodes Ready
rodeo ssh harvester1 "kubectl get nodes"

# 2. Core Harvester systems healthy
rodeo ssh harvester1 "kubectl get pods -n harvester-system | grep -v Completed"

# 3. Rancher API reachable
curl -sk https://192.168.122.9:30002/v3 | jq -r '.type'
# expect: collection

# 4. Harvester API reachable (VIP)
curl -sk https://192.168.122.10/v1 | jq -r '.apiVersion'
# expect: harvesterhci.io/v1beta1 (or similar)

# 5. Rancher shows only "local" — Harvester NOT imported yet
curl -sk -u admin:$(grep rancher_admin_password ~/.rodeo/secrets.yaml | cut -d'"' -f2) \
  https://192.168.122.9:30002/v3/clusters | jq -r '.data[].name'
# expect: local only

# 6. DNAT ports respond externally
curl -sk https://<host-ip>:8443/v1 | jq -r '.apiVersion'
curl -sk https://<host-ip>:30002/v3 | jq -r '.type'

# 7. VMs autostart (survive host reboot)
virsh list --all --autostart | grep -E 'harvester|rancher'

# 8. Day-2 CLI works
rodeo status
```

Nothing beyond this checklist should be pre-done. Chapter 1 is the import;
Chapters 2+ build namespaces, networks, images, and VMs.

## Timing notes

| Phase | Expect |
|---|---|
| `rodeo up` total | 90–150 min |
| `cluster` phase | VIP wait up to ~60 min; all-3-Ready up to ~90 min on nested KVM |
| Chapter 1 (import + tour) | ~25–30 min |
| Chapters 2–8 | UI-heavy; keep ~20–30 min each |
| Chapter 9 (recap) | ~10 min |

## Student credentials

| Item | Where |
|---|---|
| Harvester admin password | `harvester_admin_password` in `~/.rodeo/secrets.yaml` |
| Rancher admin password | `rancher_admin_password` in `~/.rodeo/secrets.yaml` |
| KVM host IP | `rodeo up` success screen, or `hostname -I` |
| SSH into nested nodes | `rodeo ssh harvester1` |
| Guest VM SSH (later chapters) | `ssh opensuse@192.168.122.50` (after Chapter 3); key from the host's `~/.ssh/id_rsa` or `id_ed25519` registered in Chapter 2 |

## Common failure points

- **VIP never comes up:** usually disk pressure on Harvester nodes. Confirm `disk_gb: 320` in `rodeo-plan.yaml`. Check `rodeo logs harvester1`.
- **External DNAT fails:** multi-NIC ARP ambiguity. The `kvm_host` phase sets `net.ipv4.conf.all.arp_announce=2`; confirm it if clients cannot reach `:8443`.
- **`sudo rodeo` → command not found:** do not wrap day-2 commands in sudo. `rodeo up` / `rodeo deploy` self-escalate. If you must use sudo, call the full path (`sudo /usr/local/bin/rodeo …`).
- **SSH drops mid-deploy:** re-attach with `tmux attach -t rodeo-harvester`. Do not start a second deploy while one is running.
- **Import already done:** if Virtualization Management already lists `harvester`, skip Chapter 1 import steps or `rodeo clean --yes && rodeo up` for a clean start.

## Day-2 ops cheat sheet

```bash
rodeo status
rodeo watch
rodeo ssh harvester1
rodeo stop --all --yes
rodeo start --all --yes
rodeo clean --yes
rodeo deploy --from cluster        # resume
```
