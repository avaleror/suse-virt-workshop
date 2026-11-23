# Host Setup: AWS

Deploy this workshop on a fresh AWS EC2 host instead of your own bare-metal box. Same 8 exercises, same [`custom/scripts/`](../reference/lab-overview.md#custom-scripts) pre-lab automation. Only the host changes.

Automation is entirely [rodeo-cli](https://github.com/avaleror/rodeo-cli). This repo's `aws/` directory ships the plan.

For a bare-metal host instead, see [Host Setup](host-setup.md).

## Requirements

| Resource | Value |
|---|---|
| AWS account | Permissions for EC2 (`RunInstances`, `Describe*`, `ModifyInstanceAttribute`, security groups). No extra IAM needed. |
| VPC/subnet | Any subnet with an internet gateway (public IP reachable) |
| Local machine | Just `rodeo-cli` installed and AWS credentials configured (`aws configure` / SSO). No bare-metal resources needed. |

### Instance tiers

Set via `provider.instance_tier` in `rodeo-plan.yaml` (default: `recommended`), or pin `provider.instance_type` directly to skip tiers entirely. Specs below come from AWS's own instance-type data (`aws ec2 describe-instance-types`). Prices are on-demand Linux, `eu-north-1`, pulled live from the AWS Price List API on 2026-09-14.

**Always check current pricing for your region.** These change over time.

| Tier | Instance | vCPU | RAM | Local storage | ~$/hr (eu-north-1) | Notes |
|---|---|---|---|---|---|---|
| `recommended` | `m8id.8xlarge` | 32 | 128 GiB | 1× 1900 GB NVMe (single device) | $2.22 | Best fit for this profile's real ~1560 GB need (500 GB × 3 Harvester nodes + 60 GB Rancher). Live-verified end to end 2026-09-14. |
| `performance` | `m7i.metal-24xl` | 96 | 384 GiB | EBS only (bare metal) | $5.14 | Bare-metal instance for max nested-virtualization performance, when extra vCPU/RAM matters more than local NVMe |

The deploy itself takes 30-90 minutes on `recommended`. Total cost is that plus however long you keep the instance running afterward.

There's no `budget` tier for this 3-node profile. An EBS-only, more-vCPU/RAM instance (`m7i.16xlarge`) actually costs *more* than `recommended` here, since local NVMe matters more for nested Harvester's Longhorn I/O than raw compute. So it isn't a real budget option. `rodeo-cli` ships a genuinely cheaper path as a separate profile (`virt-workshop-2n`, 2-node Harvester on a smaller instance) if you want one, but it isn't wired into this repo's docs or deploy flow.

Confirm your AWS credentials work before starting:

```bash
aws sts get-caller-identity
```

## Install rodeo-cli (on your local machine)

```bash
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash
```

Unlike the bare-metal path, this installs on **your laptop**, not the lab host. rodeo-cli here acts as the control plane: it provisions EC2, then the EC2 host bootstraps its own copy of rodeo-cli to actually deploy.

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
  instance_tier: recommended    # recommended | performance (no budget tier, see below)
```

Then approve the lab once and deploy:

```bash
rodeo trust      # once, and again after any edit to the files in aws/
rodeo up --profile virt-workshop --target aws
# or override the tier without editing the file:
rodeo up --profile virt-workshop --target aws --instance-tier performance
```

`rodeo trust` approves this lab directory. Since rodeo-cli v0.31.0, rodeo refuses to deploy a lab you haven't approved, because a deploy runs the lab's scripts as root. (`virt-workshop-aws` is the profile's old name. It still works, with a warning.)

This will:

1. Provision the EC2 instance (region/subnet/size from `rodeo-plan.yaml` above)
2. Create and scope a security group to your current public IP (skip by setting `provider.security_group_ids` yourself)
3. SSH in and bootstrap rodeo-cli on the host
4. Drive the full pipeline remotely: `kvm_host → vms → pxe_server → cluster → rancher → finalise → custom_scripts`
5. Print Harvester / Rancher URLs and where to find passwords

**Typical time:** 30-90 minutes (about 60 on `recommended` in a 2026-11-23 run). Faster than bare-metal, thanks to AWS's NVMe and consistent CPU generation. No tmux needed: the local `rodeo up` process holds the connection until the remote deploy finishes.

The local `rodeo up` prints nothing between "Provisioning AWS KVM host" and the final summary. That's expected: the deploy runs on the host. Follow it from a second terminal (below), or start it with `--detach`, which returns as soon as the host has started and leaves the deploy running there.

The deploy keeps running on the host if your laptop sleeps or the connection drops. Running `rodeo up` again while it's still going won't start a second deploy; it tells you one is already running.

### Watch progress (from a second terminal)

From the `aws/` directory on your machine:

```bash
rodeo status --cloud         # running / finished + the tail of the host's log
rodeo ssh primary            # a shell on the EC2 host, as ec2-user
```

On the host, `sudo tail -f /root/.rodeo/logs/aws-up.log` follows the whole log. rodeo creates an SSH key for this lab only, in `~/.rodeo/ssh/labs/suse-virt-workshop-aws/id_ed25519` on your machine (the directory is the plan's `name:`), and `rodeo ssh primary` uses it.

### `rodeo ssh <vm>` needs `sudo` on AWS

```bash
sudo rodeo ssh harvester1
```

`rodeo status` and other read-only commands don't need `sudo`.

## harvester_auto_import stays false

Same as bare-metal: `rodeo-plan.yaml` sets `harvester_auto_import: false` on purpose. Importing Harvester into Rancher is **Exercise 1**.

## Verify before students start

```bash
rodeo ssh primary            # from aws/ on your machine
sudo -i                      # the lab, its kubeconfig and secrets belong to root on the host

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
curl -sk https://<host-ip>:8443/v1 | jq -r '.id'     # expect: v1
curl -sk https://<host-ip>:30002/ping; echo          # expect: pong
```

See the [pre-lab checklist](pre-lab-checklist.md) for the full gate. It's written with bare-metal in mind, but the verification steps apply here too.

## Hand students

| Item | Value |
|---|---|
| Harvester UI | `https://<host-ip>:8443` |
| Rancher UI | `https://<host-ip>:30002` |
| Username | `admin` |
| Passwords | `harvester_admin_password` and `rancher_admin_password` in `~/.rodeo/secrets.yaml` on **your** machine: rodeo sends them to the host, so both sides use the same values |
| Lab guide | https://avaleror.github.io/suse-virt-workshop/ |

Both UIs use self-signed certificates. Students need to accept the browser warning.

If students need to SSH into the host themselves, share the lab's private key (`~/.rodeo/ssh/labs/suse-virt-workshop-aws/id_ed25519` on your machine) securely: `ssh -i <that key> ec2-user@<host-ip>`. It's created for this lab and deleted with it. Or set up per-student IAM/key access for a real multi-attendee workshop. This single-host setup assumes one instructor/student pair per instance.

## Tear down

```bash
cd suse-virt-workshop/aws
rodeo destroy --cloud --yes
```

Terminates the EC2 instance and deletes the security group and key pair rodeo created. Nothing else in your AWS account gets touched. Verify no billable resources remain:

```bash
aws ec2 describe-instances --region <region> \
  --filters "Name=tag:ManagedBy,Values=rodeo" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name]' --output text
```

An empty result means clean.

## Cost safety

rodeo arms a dead-man switch on every instance it creates: the host terminates itself 6 hours after launch, and `rodeo up` prints the exact time ("Self-destructs: ..."). For a longer workshop, set `provider.ttl_hours` in `rodeo-plan.yaml` (up to 168) before `rodeo up`. Still run `rodeo destroy --cloud --yes` when you finish: the timer is a backstop, not the plan.

## Further reading

- [Deploy on a bare-metal host instead](host-setup.md)
- [Lab overview](../reference/lab-overview.md)
- [rodeo-cli's `virt-workshop` profile](https://github.com/avaleror/rodeo-cli/tree/main/rodeo/data/examples/virt-workshop). The AWS host takes this workshop's scripts and checks from this bundled profile. See its README for live-verification details.
