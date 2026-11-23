# Exercise 6: The Unthinkable Error

**Time:** 30 min  
**Previous:** [Exercise 5: The Invisible Intruder](05-invisible-intruder.md)  
**Next:** [Exercise 7: The Stampede](07-stampede.md)

---

![Exercise 6](../assets/ch6-header.jpg)

A junior admin deleted the wrong file on the transaction ledger. You will snapshot, clone to staging, verify, restore production, then point the cluster at an off-cluster NFS backup target and schedule backups.

## 6.1 Prepare a ledger VM

If you do not already have a suitable VM, create `transaction-ledger` in `prod` on `prod/service` (1 CPU / 1 GiB, root volume left at the image's own virtual size — see Exercise 3.3's note on why a smaller size leaves the PVC `Pending` forever — same image and SSH key as before). Note its IP from the UI.

SSH in and create the record:

```bash
ssh sles@TRANSACTION_LEDGER_IP
echo "CLIENT: BRUCE WAYNE | AMOUNT: 100,000,000 | STATUS: CLEARED" > /home/sles/ledger.txt
cat /home/sles/ledger.txt
```

Leave the SSH session open or reconnect as needed.

## 6.2 Take a snapshot, then break production

**Virtual Machines** → `transaction-ledger` → ⋮ → **Take Virtual Machine Snapshot** → name `pre-disaster-backup` → **Create**. Find it under **Backup and Snapshots → Virtual Machine Snapshots** and wait until it's **Ready**.

On the VM:

```bash
rm /home/sles/ledger.txt
cat /home/sles/ledger.txt   # should fail
exit
```

![Snapshotting then simulating the deletion](../assets/ch6-task1-simulate-destruction.gif)

## 6.3 Clone to staging from the snapshot

**Backup and Snapshots → Virtual Machine Snapshots** → `pre-disaster-backup` → ⋮ → **Restore New**:

| Field | Value |
|---|---|
| Name | `ledger-staging-verify` |

![Cloning staging from the snapshot](../assets/ch6-task2-clone-staging.gif)

Wait for the clone to boot and get an IP. SSH in and confirm:

```bash
ssh sles@STAGING_IP
cat /home/sles/ledger.txt
exit
```

![Verifying the data in the staging clone](../assets/ch6-task5-verify-staging-data.gif)

## 6.4 Restore production

1. **Stop** `transaction-ledger` (⋮ → **Stop**) and wait until it's **Off**.
2. **Backup and Snapshots → Virtual Machine Snapshots** → `pre-disaster-backup` → ⋮ → **Replace Existing** → **Create**.
3. The VM starts again on its own once the restore finishes. If it stays **Off**, start it.
4. SSH and `cat /home/sles/ledger.txt`. The record is back.

![Restoring production from the snapshot](../assets/ch6-task6-restore-production.gif)

## 6.5 Connect an NFS backup target

Snapshots live on the same cluster. Real DR needs an off-cluster target.

Deploy automation already exported `/srv/backups` from the KVM host over NFS to the lab network (`192.168.122.0/24`). If you deployed the lab yourself, `sudo exportfs -v` on the host shows the export (optional).

In Harvester: **Advanced → Settings → backup-target** → Edit:

| Field | Value |
|---|---|
| Type | NFS |
| Endpoint | `192.168.122.1:/srv/backups/` |

**Save**.

![Connecting the off-cluster backup vault](../assets/ch6-task3-backup-vault.gif)

> **Tip:** If the setting doesn't turn configured, `custom_scripts`' NFS step may have failed non-fatally (ask your instructor on a claim-portal lab). Most likely an unsupported host OS package manager, see the [pre-lab checklist](../instructor/pre-lab-checklist.md#common-failure-points). Fall back to setting it up by hand: `sudo mkdir -p /srv/backups && sudo chmod 777 /srv/backups`, then install and configure an NFS server exporting that path to `192.168.122.0/24` (package name differs by distro: `nfs-kernel-server` on Ubuntu, `nfs-server`/`nfs-utils` on SLES/Fedora). Either way, the skill is knowing where backup-target lives. S3 endpoints work the same way in production.

## 6.6 Schedule backups

**Virtual Machines** → `transaction-ledger` → ⋮ → **Create Schedule**:

| Field | Value |
|---|---|
| Type | Backup (needs the backup target from 6.5) or Snapshot |
| Cron Schedule | `0 * * * *` (hourly) |
| Retain | `3` |
| Max Failure | `2` (must be lower than Retain) |

Confirm the schedule appears under **Backup and Snapshots → Virtual Machine Schedules**.

![Putting backups on a schedule](../assets/ch6-task4-backup-schedule.gif)

Exact UI labels vary slightly by Harvester minor version. The goal is a **policy**, not a one-off click.

**Check your work:** `/opt/suse-virt-workshop/checks/check-exercise-6.sh`. This exercise has no automated grading by design (nothing later reads back state created here). The script just points you at what to verify in the UI.

---

**Next:** [Exercise 7: The Stampede](07-stampede.md)
