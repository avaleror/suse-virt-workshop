# SUSE Virtualization Workshop

Self-hosted companion to the [SUSE Virtualization Rodeo](https://github.com/avaleror/suse-virt-rodeo). Same Vertex Trust Bank story and nine chapters — but you deploy the lab yourself on a bare-metal KVM host with [rodeo-cli](https://github.com/avaleror/rodeo-cli), instead of joining a pre-built Instruqt sandbox.

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

## Deploy on a KVM host

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
cd suse-virt-workshop
rodeo doctor                  # confirm the host can run the harvester profile
rodeo up                      # uses this repo's rodeo-plan.yaml
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

## Repo layout

```
docs/
  index.md                  # Landing page
  exercises/                # Nine chapters (aligned with suse-virt-rodeo)
  reference/                # Lab overview and quick reference
  instructor/               # Host setup and pre-lab checklist
  lab-guide.md              # Single-file printable guide
rodeo-plan.yaml             # Plan consumed by rodeo-cli
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
| Runtime | Instruqt (pre-built image) | Your bare-metal KVM host |
| Infra bring-up | Already done in the image | `rodeo up` (~90–150 min) |
| Lab content | Nine Instruqt chapters | Same nine chapters, adapted for self-host |
| Import Harvester | Chapter 1 / image state | Chapter 1 (plan sets `harvester_auto_import: false`) |

Infrastructure automation lives in [rodeo-cli](https://github.com/avaleror/rodeo-cli). Lab narrative lives in [suse-virt-rodeo](https://github.com/avaleror/suse-virt-rodeo). This repo wires the two together for self-serve hosts.
