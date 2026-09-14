# SUSE Virtualization Workshop

Self-hosted companion to the [SUSE Virtualization Rodeo](https://github.com/avaleror/suse-virt-rodeo). Same Vertex Trust Bank story and eight chapters (plus one self-hosted-only bonus chapter) — but you deploy the lab yourself with [rodeo-cli](https://github.com/avaleror/rodeo-cli), instead of joining a pre-built Instruqt sandbox. Deploy on your own **bare-metal** KVM host or on **AWS** — **GCP support is coming soon**. Each platform has its own precise instructions below.

**Workshop site:** https://avaleror.github.io/suse-virt-workshop/

**Versions:** Harvester 1.8.1 · Rancher Prime 2.14.1 · K3s v1.35 · rodeo-cli v0.14.x  
**Duration:** ~3 hours of lab work after deploy  
**Audience:** DevOps engineers, SREs, platform teams evaluating SUSE Virtualization

---

## What you get

`rodeo up` builds a nested lab on your host:

| Component | IP | Access |
|-----------|----|--------|
| Harvester VIP | 192.168.122.10 | `https://<host>:8443` (DNAT → VIP:443) |
| harvester1–3 | .11–.13 | `rodeo ssh harvester1` |
| Rancher Prime | 192.168.122.9 | `https://<host>:30002` |

Harvester is **not** imported into Rancher at deploy time — that is Chapter 1, same as the customer Rodeo.

---

## Deploy on a KVM host (bare metal)

### 1. Requirements

| Resource | Minimum |
|----------|---------|
| OS | SLES 16 / Leap 16 (Ubuntu 22.04+ and Fedora also work) |
| RAM | 64 GiB available |
| CPU | ~32 vCPU free |
| Disk | ~1050 GiB free under `/var/lib/libvirt/images` |
| KVM | `/dev/kvm` present |

### 2. Install rodeo-cli

```bash
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash
```

### 3. Clone this workshop and deploy

```bash
git clone https://github.com/avaleror/suse-virt-workshop.git
cd suse-virt-workshop/baremetal
rodeo doctor                  # confirm the host can run the harvester profile
rodeo up                      # uses this directory's rodeo-plan.yaml
```

`rodeo up` self-escalates with sudo, generates `~/.rodeo/secrets.yaml`, wraps the deploy in tmux (`rodeo-harvester` / profile name), and prints login URLs when finished. Typical time: **90–150 minutes**.

If your SSH session drops:

```bash
tmux attach -t rodeo-harvester
```

Watch progress from another shell:

```bash
rodeo watch
rodeo status
```

### 4. Open the lab guide

After deploy succeeds, follow the chapters at https://avaleror.github.io/suse-virt-workshop/ — start with [Chapter 1 — The Arrival](https://avaleror.github.io/suse-virt-workshop/exercises/01-the-arrival/).

Credentials: `admin` / values in `~/.rodeo/secrets.yaml` on the host.

### Tear down

```bash
rodeo clean --yes                          # destroy this lab's VMs
rodeo clean --all --yes --secrets          # full host reset
```

---

## Deploy on AWS instead

No spare 64 GiB bare-metal box? `aws/` deploys the exact same lab on a fresh EC2 host instead — same 8 exercises, same `custom/scripts/` pre-lab automation, only the host differs.

```bash
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash
git clone https://github.com/avaleror/suse-virt-workshop.git
cd suse-virt-workshop/aws
# edit rodeo-plan.yaml: set provider.region and provider.subnet_id
# to your own AWS account (any VPC with an internet gateway works)
rodeo up --profile virt-workshop-aws --target aws
```

Two instance tiers (`provider.instance_tier` in `rodeo-plan.yaml`, or `--instance-tier` on the CLI) — real AWS specs, prices are on-demand Linux in `eu-north-1` as of 2026-09-14, always check current pricing:

| Tier | Instance | vCPU | RAM | Local storage | ~$/hr |
|---|---|---|---|---|---|
| `recommended` (default) | `m8id.8xlarge` | 32 | 128 GiB | 1× 1900 GB NVMe | $2.22 |
| `performance` | `m7i.metal-24xl` | 96 | 384 GiB | EBS only (bare metal) | $5.14 |

Full breakdown: [Host setup: AWS](https://avaleror.github.io/suse-virt-workshop/instructor/aws-setup/#instance-tiers).

No local files are uploaded: rodeo boots the host, then the host bootstraps rodeo-cli and deploys itself, so nothing needs a live SSH session babysat for the ~30-90 minute deploy. No extra IAM beyond EC2 permissions — rodeo creates and scopes its own security group to your current public IP. `aws/rodeo-plan.yaml`'s `resources:`/`versions:` sections describe what gets deployed (kept in sync with rodeo-cli's own bundled profile) — only its `provider:` block (region/subnet/instance size/tier) has a direct effect from here; see the comment at the top of that file for why.

Live-verified end to end (3 nodes Ready, both pre-lab VMs Running, both UIs externally reachable) 2026-09-14. Full instructor steps: [Host setup: AWS](https://avaleror.github.io/suse-virt-workshop/instructor/aws-setup/).

Tear down:

```bash
rodeo destroy --cloud --yes   # from suse-virt-workshop/aws
```

---

## Repo layout

```
docs/
  index.md                  # Landing page
  exercises/                # Eight chapters, one-to-one with suse-virt-rodeo,
                             # plus bonus-final-showdown.md (self-hosted only,
                             # no rodeo counterpart)
  reference/                # Lab overview and quick reference
  instructor/               # Host setup and pre-lab checklist
  lab-guide.md              # Single-file printable guide
custom/scripts/             # Pre-lab automation: image cache, NFS backup
                             # target, Exercise 4's webserver-prod +
                             # daily-batch-processor (see lab-overview.md) —
                             # the single copy every platform below symlinks to
baremetal/                  # Deploy on your own KVM host: rodeo-plan.yaml +
                             # custom -> ../custom
aws/                        # Deploy on AWS: rodeo-plan.yaml (region/subnet/
                             # instance size) + custom -> ../custom
                             # (gcp/ coming soon, same shape)
mkdocs.yml
```

## Local docs preview

```bash
pip install -r requirements.txt
mkdocs serve
```

Open http://127.0.0.1:8000

---

## Relationship to suse-virt-rodeo

| | **suse-virt-rodeo** | **This workshop** |
|--|---------------------|-------------------|
| Runtime | Instruqt (pre-built image) | Your own KVM host, or AWS (GCP coming soon) |
| Infra bring-up | Already done in the image | `rodeo up` (~90–150 min bare metal, ~30–90 min AWS), including `custom/scripts/` pre-lab automation |
| Lab content | Eight Instruqt chapters | Same eight chapters, adapted for self-host, plus one bonus chapter with no rodeo counterpart |
| Import Harvester | Chapter 1 / image state | Chapter 1 (plan sets `harvester_auto_import: false`) |
| Exercise 4 pre-lab state (`webserver-prod`, `daily-batch-processor`) | Baked into the image | Pre-created by `custom/scripts/70-webserver-prod.sh` on every `rodeo up` |
| Exercise 6 NFS backup target | Baked into the image | Pre-created by `custom/scripts/60-nfs-backup-target.sh` on every `rodeo up` |

Infrastructure automation lives in [rodeo-cli](https://github.com/avaleror/rodeo-cli). Lab narrative lives in [suse-virt-rodeo](https://github.com/avaleror/suse-virt-rodeo). This repo wires the two together for self-serve hosts.
