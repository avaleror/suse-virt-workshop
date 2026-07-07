# Pre-lab checklist

Run through this before handing the lab to students. The deploy (`rodeo deploy`) takes 1-2.5 hours on nested KVM, so leave time for this checklist on top.

## After deploy completes

```bash
# 1. All 3 Harvester nodes Ready
rodeo ssh harvester1 "kubectl get nodes"

# 2. Core Harvester systems healthy
rodeo ssh harvester1 "kubectl get pods -n harvester-system | grep -v Completed"

# 3. Rancher API reachable
curl -sk https://192.168.122.9:30002/v3 | jq -r '.type'

# 4. Harvester API reachable (via VIP)
curl -sk https://192.168.122.10/v1 | jq -r '.apiVersion'

# 5. Rancher shows only "local" - confirms Harvester is NOT yet imported
curl -sk -u admin:$(grep rancher_admin_password ~/.rodeo/secrets.yaml | cut -d'"' -f2) \
  https://192.168.122.9:30002/v3/clusters | jq -r '.data[].name'

# 6. DNAT ports respond externally
curl -sk https://<host-ip>:8443/v1 | jq -r '.apiVersion'
curl -sk https://<host-ip>:30002/v3 | jq -r '.type'

# 7. All 4 VMs set to autostart (survive a host reboot)
virsh list --all --autostart | grep -E 'harvester|rancher'
```

Everything is automated by `rodeo deploy` up to this point. No manual setup steps needed beyond the checklist above.

## Timing notes

- The `cluster` phase is the bottleneck: VIP wait up to 60 min, all-3-nodes-Ready up to 90 min. Entirely a nested-KVM slowness artifact, not a bug.
- Exercise 1 (import + kubectl wiring) takes about 30 min including waiting for the Rancher agent to register.
- Exercises 2-5 are UI + kubectl heavy and run quickly once the platform is imported.
- Exercise 6 (Rancher-provisioned K3s cluster) takes 5-10 minutes of actual wait time inside the exercise, so plan for it.

## Student credentials

| Item | Where to find |
|---|---|
| Harvester admin password | `harvester_admin_password` in `~/.rodeo/secrets.yaml` on the host |
| Rancher admin password | `rancher_admin_password` in `~/.rodeo/secrets.yaml` on the host |
| KVM host IP | Output of `rodeo deploy` success screen, or `ip addr show` |
| SSH key for VMs | Whatever key is on the host running rodeo-cli (`~/.ssh/id_ed25519` or `id_rsa`), registered as a Harvester KeyPair in Exercise 1 |

## Common failure points

- **VIP never comes up:** almost always a disk-space issue on the Harvester nodes, not CPU/RAM. Check `disk_gb` in `rodeo-plan.yaml` is at least 250 (Harvester's documented minimum). Smaller values fill the COS_PERSISTENT partition and RKE2's containerd stalls.
- **DNAT not reaching the VIP from outside:** if the host has multiple NICs on the same subnet, ARP ambiguity can misdirect packets. `net.ipv4.conf.all.arp_announce=2` (set by the `kvm_host` phase) fixes this. Confirm it's applied if external access fails.
- **`sudo rodeo <cmd>` says "command not found":** `/usr/local/bin` isn't in sudo's `secure_path` on some distros. Use the full path (`sudo /usr/local/bin/rodeo <cmd>`) for day-2 operations.
