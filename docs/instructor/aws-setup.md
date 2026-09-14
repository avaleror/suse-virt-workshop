# Host Setup: AWS

Deploy this workshop on a fresh AWS EC2 host instead of your own bare-metal box. Same 8 exercises, same [`custom/scripts/`](../reference/lab-overview.md#custom-scripts) pre-lab automation — only the host changes. Automation is entirely [rodeo-cli](https://github.com/avaleror/rodeo-cli); this repo's `aws/` directory ships the plan.

For a bare-metal host instead, see [Host Setup](host-setup.md).

## Requirements

| Resource | Value |
|---|---|
| AWS account | Permissions for EC2 (`RunInstances`, `Describe*`, `ModifyInstanceAttribute`, security groups) — no extra IAM beyond that |
| VPC/subnet | Any subnet with an internet gateway (public IP reachable) |
| Local machine | Just needs `rodeo-cli` installed and AWS credentials configured (`aws configure` / SSO) — no bare-metal resources needed |

### Instance tiers

Set via `provider.instance_tier` in `rodeo-plan.yaml` (default: `recommended`), or pin `provider.instance_type` directly to bypass tiers entirely. Specs below are AWS's own instance-type data (`aws ec2 describe-instance-types`); prices are on-demand Linux, `eu-north-1`, fetched live from the AWS Price List API on 2026-09-14 — **always check current pricing for your region**, these change over time.

| Tier | Instance | vCPU | RAM | Local storage | ~$/hr (eu-north-1) | Notes |
|---|---|---|---|---|---|---|
| `recommended` | `m8id.8xlarge` | 32 | 128 GiB | 1× 1900 GB NVMe (single device) | $2.22 | Best fit for this profile's real ~1560 GB need (500 GB × 3 Harvester nodes + 60 GB Rancher) — live-verified end to end 2026-09-14 |
| `performance` | `m7i.metal-24xl` | 96 | 384 GiB | EBS only (bare metal) | $5.14 | Bare-metal instance — max nested-virtualization performance, for when the extra vCPU/RAM matters more than local NVMe |

The deploy itself takes ~30-90 min on `recommended`; total cost is that plus however long you keep the instance running afterward. There is no `budget` tier for this 3-node profile: an EBS-only, more-vCPU/RAM instance (`m7i.16xlarge`) actually costs *more* than `recommended` here, since local NVMe matters more for nested Harvester's Longhorn I/O than raw compute — so it isn't a real budget option. `rodeo-cli` ships a genuinely cheaper path as a separate profile (`virt-workshop-aws-2n`, 2-node Harvester on a smaller instance) if you want one; it isn't wired into this repo's docs/deploy flow.

Confirm your AWS credentials work before starting:

```bash
aws sts get-caller-identity
```

## Install rodeo-cli (on your local machine)

```bash
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash
```

Unlike the bare-metal path, this installs on **your laptop**, not the lab host — rodeo-cli here acts as the control plane that provisions EC2, then the EC2 host bootstraps its own copy of rodeo-cli to actually deploy.

## Deploy this workshop

```bash
git clone https://github.com/avaleror/suse-virt-workshop.git
cd suse-virt-workshop/aws
```

Edit `rodeo-plan.yaml`'s `provider:` block for your own AWS account:

```yaml
provider:
  type: aws
  region: eu-central-1          # <- your region
  subnet_id: subnet-CHANGE-ME   # <- must be in a VPC with an internet gateway
  instance_tier: recommended    # recommended | performance (no budget tier — see below)
```

Then:

```bash
rodeo up --profile virt-workshop-aws --target aws
# or override the tier without editing the file:
rodeo up --profile virt-workshop-aws --target aws --instance-tier performance
```

This will:

1. Provision the EC2 instance (region/subnet/size from `rodeo-plan.yaml` above)
2. Create and scope a security group to your current public IP (skip by setting `provider.security_group_ids` yourself)
3. SSH in and bootstrap rodeo-cli on the host
4. Drive the full pipeline remotely: `kvm_host → vms → pxe_server → cluster → rancher → finalise → custom_scripts`
5. Print Harvester / Rancher URLs and where to find passwords

**Typical time:** 30-90 minutes (faster than bare-metal — AWS's NVMe and consistent CPU generation help). No tmux needed: the local `rodeo up` process holds the connection until the remote deploy finishes.

> **Known limitation:** on a very long remote deploy, the SSH connection between your machine and the EC2 host can occasionally drop silently (a network-level timeout, not a rodeo-cli bug). If `rodeo up` seems to hang with no new output for well past its usual phase timing, check whether the process is still alive; if the connection died, SSH into the host directly and check `rodeo status` — phases already completed are cached and won't re-run, so you can resume cleanly rather than starting over.

### Watch progress (from a second terminal)

```bash
ssh -i ~/.rodeo/ssh/id_ed25519 ec2-user@<host-ip>
rodeo status                 # VM state + VIP reachability, no sudo needed
sudo tail -f /root/.rodeo/logs/aws-up.log
```

## harvester_auto_import stays false

Same as bare-metal: `rodeo-plan.yaml` sets `harvester_auto_import: false` on purpose. Importing Harvester into Rancher is **Exercise 1**.

## Verify before students start

```bash
ssh -i ~/.rodeo/ssh/id_ed25519 ec2-user@<host-ip>

# All 3 Harvester nodes Ready
export KUBECONFIG=~/.rodeo/harvester-kubeconfig
kubectl get nodes

# Exercise 4/6 pre-lab state (custom_scripts)
kubectl get vm -n prod webserver-prod daily-batch-processor
sudo systemctl is-active rodeo-image-cache.service
sudo exportfs -v
```

External UI access (from your own machine, outside AWS):

```bash
curl -sk https://<host-ip>:8443/v1 | jq -r '.apiVersion'
curl -sk https://<host-ip>:30002/v3 | jq -r '.type'
```

See the [pre-lab checklist](pre-lab-checklist.md) for the full gate (bare-metal-focused, but the verification steps apply here too).

## Hand students

| Item | Value |
|---|---|
| Harvester UI | `https://<host-ip>:8443` |
| Rancher UI | `https://<host-ip>:30002` |
| Username | `admin` |
| Passwords | `harvester_admin_password` and `rancher_admin_password` — `ssh ec2-user@<host-ip> "cat ~/.rodeo/secrets.yaml"` |
| Lab guide | https://avaleror.github.io/suse-virt-workshop/ |

Both UIs use self-signed certificates. Students must accept the browser warning.

If students need to SSH into the host themselves, share the private key file (`~/.rodeo/ssh/id_ed25519` on your machine) securely, or create per-student IAM/key access instead for a real multi-attendee workshop — this single-host setup assumes one instructor/student pair per instance.

## Tear down

```bash
cd suse-virt-workshop/aws
rodeo destroy --cloud --yes
```

Terminates the EC2 instance and deletes the security group rodeo created. Nothing else in your AWS account is touched. Verify no billable resources remain:

```bash
aws ec2 describe-instances --region <region> \
  --filters "Name=tag:ManagedBy,Values=rodeo" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name]' --output text
```

An empty result means clean.

## Cost safety

For a workshop you might forget to tear down, consider arming a self-terminate timer as a backstop:

```bash
aws ec2 modify-instance-attribute --region <region> --instance-id <id> \
  --instance-initiated-shutdown-behavior terminate
ssh -i ~/.rodeo/ssh/id_ed25519 ec2-user@<host-ip> "sudo shutdown -h +180"   # 3 hours
```

Verify with `sudo shutdown -c` to cancel, or check `who -b`/`last` style timing if unsure whether it's armed.

## Further reading

- [Deploy on a bare-metal host instead](host-setup.md)
- [Lab overview](../reference/lab-overview.md)
- [rodeo-cli's `virt-workshop-aws` profile](https://github.com/avaleror/rodeo-cli/tree/main/rodeo/data/examples/virt-workshop-aws) — this workshop's AWS deploy re-seeds from this bundled profile on the remote host; see its README for live-verification details
