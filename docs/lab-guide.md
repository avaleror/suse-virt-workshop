# Full lab guide (printable)

Self-hosted **SUSE Virtualization Rodeo** — nine chapters aligned with
[suse-virt-rodeo](https://github.com/avaleror/suse-virt-rodeo), deployed with
[rodeo-cli](https://github.com/avaleror/rodeo-cli).

**Versions:** Harvester 1.8.1 · Rancher 2.14.1 · K3s v1.35.3+k3s1 · rodeo-cli v0.14.x

---

## 0. Deploy the lab (instructor / self-serve)

```bash
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash
git clone https://github.com/avaleror/suse-virt-workshop.git
cd suse-virt-workshop
rodeo doctor
rodeo up
```

- Time: **90–150 min**. Survive disconnects: `tmux attach -t rodeo-harvester`
- UIs: Harvester `https://<host>:8443` · Rancher `https://<host>:30002`
- User `admin` · passwords in `~/.rodeo/secrets.yaml`
- Tear down: `rodeo clean --yes`

Full detail: [Host setup](instructor/host-setup.md).

---

## Chapter 1 — The Arrival (~30 min)

1. `curl -sk https://192.168.122.10/v1` and `:30002/v3` — both healthy; `rodeo status` OK.
2. Rancher → Virtualization Management → **Import Existing** → name `harvester` → copy URL.
3. Harvester → Settings → **cluster-registration-url** → paste → Save → wait until **Active**.
4. Tour Dashboard / Hosts / Support (download kubeconfig).
5. `rodeo ssh harvester1` → `kubectl get nodes` — three Ready.

---

## Chapter 2 — The Subterranean Divide (~30 min)

1. Inspect **Hosts**; `rodeo ssh harvester1` → `ls /var/lib/harvester/defaultdisk/replicas`.
2. Create namespaces `prod` and `dev`.
3. Review StorageClass `harvester-longhorn` (3 replicas).
4. Create StorageClass `harvester-longhorn-1rep` (1 replica).
5. Create VM network `prod/service` (UntaggedNetwork on `mgmt`).
6. Register SSH key `prod/default` from the host's `~/.ssh/*.pub`.
7. Upload cloud image into `official-images` (wait Active).
8. Optional: cloud-init user-data template `prod/prod` with qemu-guest-agent.

---

## Chapter 3 — The Flash Crash (~30 min)

Create VM `prod/algo-trader-01`: 2 CPU / 2 GiB, SSH `prod/default`, label
`stage=prod`, root disk from cloud image (5 GiB) + volume `market-data-vol`
(1 GiB), network `prod/service`, network-data static IP `192.168.122.50/24`.
Console + `ssh opensuse@192.168.122.50`.

---

## Chapter 4 — The Rising Tide (~25 min)

1. Create `webserver-prod` and `daily-batch-processor` on `prod/service`.
2. Pause the batch VM; `ping` the gateway IP; leave it running.
3. Migrate `webserver-prod` to another node; confirm ping/uptime survive.
4. Unpause batch; put the old node in **Maintenance Mode**; watch evacuation.

---

## Chapter 5 — The Invisible Intruder (~30 min)

1. Cluster network `closed-loop` with uplink NIC (often `ens5`).
2. VM network `prod/secure-loop-prod` (Untagged on `closed-loop`).
3. Overlay `dev/secure-loop-dev` + subnet `secure-vpc-dev` (`192.168.32.0/24`).
4. Edit a VM → attach isolated network → stop/start to apply.

---

## Chapter 6 — The Unthinkable Error (~30 min)

1. On `transaction-ledger` (create if needed): write `ledger.txt`, snapshot
   `pre-disaster-backup`, delete the file.
2. Restore snapshot to new VM `ledger-staging-verify`; verify file.
3. Power off prod → Restore snapshot → power on → verify.
4. Set **backup-target** NFS to `192.168.122.1:/srv/backups/` (lab NFS on host).
5. Create a recurring backup/snapshot schedule.

---

## Chapter 7 — The Stampede (~25 min)

1. Template `harvester-public/prod-basic` (1 CPU / 1 GiB, `prod/default`,
   cloud image, `prod/service`, label `stage=prod`).
2. Create `calc-engine-01`…`03` from template; scale to five; delete extras.

---

## Chapter 8 — The Final Showdown (~25 min)

1. Open **Advanced → Migration → Sources** (Instruqt has `isaware-legacy-01`;
   bare metal may be empty — learn the form).
2. Create stand-in `legacy-ledger-vm` on `prod/service`.
3. `systemctl enable --now qemu-guest-agent` inside the guest.
4. Snapshot `post-migration-baseline`; live-migrate once.

---

## Chapter 9 — A New Horizon (~10 min)

Review the skill table; bookmark SUSE Virtualization docs; tear down with
`rodeo clean --yes` when finished.

---

## Cheat sheet

| Item | Value |
|---|---|
| Harvester | `https://<host>:8443` |
| Rancher | `https://<host>:30002` |
| VIP / nodes | `.10` / `.11–.13` · rancher `.9` |
| Passwords | `~/.rodeo/secrets.yaml` |
| Guest example | `ssh opensuse@192.168.122.50` |
| Ops | `rodeo status` · `rodeo ssh harvester1` · `rodeo watch` |
