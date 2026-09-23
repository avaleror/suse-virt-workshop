# Pre-lab checklist

Run this after `rodeo up` finishes and before students open Exercise 1. Deploy takes 90-150 minutes on nested KVM; budget extra time for this gate.

## After deploy completes

```bash
# rodeo ssh takes a command via -c, not a trailing positional argument —
# `rodeo ssh harvester1 "kubectl get nodes"` fails with "Got unexpected
# extra argument". And /etc/rancher/rke2/rke2.yaml is root-only, so the
# harvester nodes' `rancher` login needs sudo -E (kubectl's full path,
# since sudo's secure_path doesn't include RKE2's bin directory).
KCTL='export KUBECONFIG=/etc/rancher/rke2/rke2.yaml; sudo -E /var/lib/rancher/rke2/bin/kubectl'

# 1. All 3 Harvester nodes Ready
rodeo ssh harvester1 -c "$KCTL get nodes"

# 2. Core Harvester systems healthy
rodeo ssh harvester1 -c "$KCTL get pods -n harvester-system | grep -v Completed"

# 3. Rancher API reachable — /v3 requires a bearer token even for the root
# document; an anonymous GET (or HTTP Basic Auth, see #5) returns 401.
RANCHER_PW=$(grep '^rancher_admin_password:' ~/.rodeo/secrets.yaml | cut -d'"' -f2)
RANCHER_TOKEN=$(curl -sk -X POST "https://192.168.122.9:30002/v3-public/localProviders/local?action=login" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"admin\",\"password\":\"$RANCHER_PW\"}" | jq -r '.token')
curl -sk -H "Authorization: Bearer $RANCHER_TOKEN" https://192.168.122.9:30002/v3 | jq -r '.type'
# expect: apiRoot (a specific listing like /v3/clusters would say collection)

# 4. Harvester API reachable (VIP)
curl -sk https://192.168.122.10/v1 | jq -r '.id'
# expect: v1

# 5. Rancher shows only "local" - Harvester NOT imported yet
# (Rancher has no HTTP Basic Auth — reuse the bearer token from #3. Also
# note the grep above is anchored with ^ and : — secrets.yaml's own comment
# header repeats each key name right above its value, so an unanchored
# grep matches both lines and garbles the password.)
curl -sk -H "Authorization: Bearer $RANCHER_TOKEN" \
  https://192.168.122.9:30002/v3/clusters | jq -r '.data[].name'
# expect: local only

# 6. DNAT ports respond externally
curl -sk https://<host-ip>:8443/v1 | jq -r '.id'
curl -sk -H "Authorization: Bearer $RANCHER_TOKEN" https://<host-ip>:30002/v3 | jq -r '.type'

# 7. VMs autostart (survive host reboot)
sudo virsh list --all --autostart | grep -E 'harvester|rancher'

# 8. Day-2 CLI works — needs both sudo (libvirt/lab-dir access) and cd'ing
# into the lab dir first (rodeo status doesn't self-escalate the way
# rodeo up/deploy do, see the "sudo rodeo" failure point below)
sudo bash -c 'cd /root/rodeo-lab && rodeo status'

# 9. custom_scripts pre-lab state (Exercise 4 / 6 foundations)
rodeo ssh harvester1 -c "$KCTL get vm -n prod webserver-prod daily-batch-processor"
rodeo ssh harvester1 -c "$KCTL get network-attachment-definitions.k8s.cni.cncf.io -n prod service"
# NFS is only exported to 192.168.122.0/24 (the libvirt network), not the
# internet — on AWS the security group doesn't open the NFS ports (2049/111)
# externally either, by design. Check from the KVM host itself, against the
# gateway IP Exercise 6's backup-target setting actually uses:
sudo exportfs -v   # expect: /srv/backups 192.168.122.0/24(...)
```

Exercise 1 is the import. Exercises 2-7 (and the optional bonus) build namespaces, networks, images, and VMs on top of what deploy automation pre-creates.

That pre-created state (`prod` namespace, node labels, `prod/service` network, the cached VM image, the NFS backup target, and the `webserver-prod`/`daily-batch-processor` pair) mirrors what the Instruqt Rodeo image bakes in. So Exercises 4 and 6 start from parity with the customer-facing track instead of asking the student to build those foundations by hand. See [Lab overview: custom_scripts](../reference/lab-overview.md#custom-scripts) for what each script does.

## Timing notes

| Phase | Expect |
|---|---|
| `rodeo up` total | 90-150 min (includes `custom_scripts`: ~10-15 min, mostly the image download) |
| `cluster` phase | VIP wait up to ~60 min; all-3-Ready up to ~90 min on nested KVM |
| Exercise 1 (import + tour) | ~25-30 min |
| Exercises 2-7 | UI-heavy; keep ~20-30 min each |
| Exercise 8 (recap) | ~10 min |
| Bonus: Final Showdown (optional, self-hosted only) | ~25 min |

## Student credentials

| Item | Where |
|---|---|
| Harvester admin password | `harvester_admin_password` in `~/.rodeo/secrets.yaml` |
| Rancher admin password | `rancher_admin_password` in `~/.rodeo/secrets.yaml` |
| KVM host IP | `rodeo up` success screen, or `hostname -I` |
| SSH into nested nodes | `rodeo ssh harvester1` |
| Guest VM SSH (later exercises) | `ssh sles@192.168.122.50` (after Exercise 3); key from the host's `~/.ssh/id_rsa` or `id_ed25519` registered in Exercise 2 |

## Common failure points

- **VIP never comes up:** usually disk pressure on Harvester nodes. Confirm `disk_gb: 320` in `rodeo-plan.yaml`. Check `rodeo logs harvester1`.
- **External DNAT fails:** multi-NIC ARP ambiguity. The `kvm_host` phase sets `net.ipv4.conf.all.arp_announce=2`; confirm it if clients cannot reach `:8443`.
- **`sudo rodeo` → command not found:** do not wrap day-2 commands in sudo. `rodeo up` / `rodeo deploy` self-escalate. If you must use sudo, call the full path (`sudo /usr/local/bin/rodeo …`).
- **SSH drops mid-deploy:** re-attach with `tmux attach -t rodeo-harvester`. Do not start a second deploy while one is running.
- **Import already done:** if Virtualization Management already lists `harvester`, skip Exercise 1 import steps or `rodeo clean --yes && rodeo up` for a clean start.
- **Cluster stuck on `Pending`/`Waiting`, Harvester shows `{"data":""}`:** the student forgot to check **Insecure Skip TLS Verify** next to the cluster-registration-url field. Rancher's cert is self-signed, so Harvester's backend fails the fetch silently without it.
- **Checkbox was checked, Save clicked, still stuck on `Waiting for API to be available`:** confirm the setting actually saved before troubleshooting further:

  ```bash
  rodeo ssh harvester1 -c 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml; sudo -E /var/lib/rancher/rke2/bin/kubectl get settings.harvesterhci.io cluster-registration-url -o jsonpath="{.value}"'
  ```

  This should print `{"url":"https://...","insecureSkipTLSVerify":true}`. If it prints nothing, or `insecureSkipTLSVerify` is missing or `false`, the UI save did not take. Re-open **cluster-registration-url**, re-check the box, and **Save** again. If it still will not stick, set it directly from the KVM host (the registration URL is on Rancher's cluster page, **Copy Registration Command**):

  ```bash
  rodeo ssh harvester1 -c 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml; python3 -c "
  import json, subprocess
  value = json.dumps({\"url\": \"PASTE_MANIFEST_URL_HERE\", \"insecureSkipTLSVerify\": True})
  patch = json.dumps({\"value\": value})
  subprocess.run([\"sudo\", \"-E\", \"/var/lib/rancher/rke2/bin/kubectl\", \"patch\",
      \"settings.harvesterhci.io\", \"cluster-registration-url\", \"--type=merge\", \"-p\", patch])
  "'
  ```
- **`webserver-prod`/`daily-batch-processor` missing or `ErrorUnschedulable`:** check `custom_scripts` ran (`rodeo deploy --from custom_scripts` to re-run just that phase). It needs outbound internet access on first run to download the cached image (~308 MiB from `download.opensuse.org`), so an air-gapped host will fail here.
- **`showmount -e <host-ip>` shows nothing:** `custom_scripts`' NFS step needs a package manager it recognizes (zypper/apt/dnf); an unsupported distro will fail this step non-fatally (rest of the lab still works, Exercise 6.5 falls back to manual setup).

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
