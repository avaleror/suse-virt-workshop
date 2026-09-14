---
hide:
  - toc
---

<div class="hero">
  <div class="subtitle">SUSE Virtualization: Hands-on Workshop</div>
  <h1>The Virtualization Rodeo</h1>
  <div class="tagline">Vertex Trust Bank &bull; Harvester HCI &bull; Rancher Prime &bull; deployed with rodeo-cli</div>

  <a href="#choose-your-platform" class="md-button md-button--primary">Choose your platform &rarr;</a>
  &nbsp;
  <a href="exercises/01-the-arrival/" class="md-button">Start the lab &rarr;</a>
  &nbsp;
  <a href="reference/quick-reference/" class="md-button">Quick reference</a>
</div>

---

## The scenario

<div class="scenario">
Vertex Trust Bank is drowning in legacy hypervisor renewal costs. Sarah, the CTO, hands you the keys to a fresh <strong>SUSE Virtualization</strong> platform and a list of problems that will not wait. Across eight exercises you bring the cluster online, ship a VM under pressure, dodge a hardware failure with live migration, wall off a sensitive network, recover a deleted record, and scale a fleet from templates.
</div>

This workshop is the **self-hosted** twin of SUSE's customer-facing
[Virtualization Rodeo](https://github.com/avaleror/suse-virt-rodeo). Same story,
same skills, same 8 exercises regardless of where you deploy it — only the
infrastructure bring-up step differs per platform, with its own precise
instructions below, driven by
[`rodeo-cli`](https://github.com/avaleror/rodeo-cli) instead of joining Instruqt.

---

## Choose your platform

<div class="exercise-grid">

<a href="instructor/host-setup/" class="exercise-card">
  <div class="ex-number">Bare metal</div>
  <div class="ex-title">Your own KVM host</div>
  <div class="ex-time">⏱ 90-150 min</div>
  <div class="ex-desc">Min: 64 GiB RAM / 32 vCPU / ~1 TB disk. Recommended: 80-96 GiB / 40+ vCPU. /dev/kvm present, survives SSH drops via tmux.</div>
</a>

<a href="instructor/aws-setup/" class="exercise-card">
  <div class="ex-number">AWS</div>
  <div class="ex-title">Fresh EC2 host</div>
  <div class="ex-time">⏱ 30-90 min</div>
  <div class="ex-desc">3 instance tiers, ~$2.22-5.14/hr. Recommended: m8id.8xlarge (32 vCPU / 128 GiB / 1.9 TB NVMe).</div>
</a>

<div class="exercise-card" style="opacity:0.6; cursor:default;">
  <div class="ex-number">GCP</div>
  <div class="ex-title">Coming soon</div>
  <div class="ex-time">⏱ —</div>
  <div class="ex-desc">Not yet available. Use bare metal or AWS for now.</div>
</div>

</div>

**Quick start (bare metal):**

```bash
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash
git clone https://github.com/avaleror/suse-virt-workshop.git
cd suse-virt-workshop/baremetal
rodeo doctor
rodeo up
```

`rodeo up` takes **90-150 minutes**, survives SSH drops via tmux, and prints
Harvester (`:8443`) and Rancher (`:30002`) URLs when done. Full instructor steps,
and the AWS equivalent: [Host setup: bare metal](instructor/host-setup.md) ·
[Host setup: AWS](instructor/aws-setup.md).

## Lab topology

<div class="topology">
<pre>
KVM host (bare metal, yours)
│
├── harvester1   192.168.122.11   8 vCPU / 16 GiB / 320 GB   bootstrap
├── harvester2   192.168.122.12   8 vCPU / 16 GiB / 320 GB   join
├── harvester3   192.168.122.13   8 vCPU / 16 GiB / 320 GB   join
└── rancher      192.168.122.9    4 vCPU / 8 GiB  / 60 GB    Rancher Prime + K3s

VIP (kube-vip): 192.168.122.10
DNAT: host:8443 → VIP:443 · host:30002 → rancher:30002
</pre>
</div>

---

## Exercises

<div class="exercise-grid">

<a href="exercises/01-the-arrival/" class="exercise-card">
  <div class="ex-number">Exercise 01</div>
  <div class="ex-title">The Arrival</div>
  <div class="ex-time">⏱ 30 min</div>
  <div class="ex-desc">Import Harvester into Rancher, tour both UIs, confirm storage and terminal access.</div>
</a>

<a href="exercises/02-subterranean-divide/" class="exercise-card">
  <div class="ex-number">Exercise 02</div>
  <div class="ex-title">The Subterranean Divide</div>
  <div class="ex-time">⏱ 30 min</div>
  <div class="ex-desc">Map node topology, create prod/dev workspaces, tune Longhorn tiers, build the service network.</div>
</a>

<a href="exercises/03-flash-crash/" class="exercise-card">
  <div class="ex-number">Exercise 03</div>
  <div class="ex-title">The Flash Crash</div>
  <div class="ex-time">⏱ 30 min</div>
  <div class="ex-desc">Provision algo-trader-01 with volumes, network, cloud-init, and a fixed IP under pressure.</div>
</a>

<a href="exercises/04-rising-tide/" class="exercise-card">
  <div class="ex-number">Exercise 04</div>
  <div class="ex-title">The Rising Tide</div>
  <div class="ex-time">⏱ 25 min</div>
  <div class="ex-desc">Zero-downtime live migration of the payment gateway, then evacuate a damaged node.</div>
</a>

<a href="exercises/05-invisible-intruder/" class="exercise-card">
  <div class="ex-number">Exercise 05</div>
  <div class="ex-title">The Invisible Intruder</div>
  <div class="ex-time">⏱ 30 min</div>
  <div class="ex-desc">Build a closed-loop cluster network and an overlay vault so lateral movement dies.</div>
</a>

<a href="exercises/06-unthinkable-error/" class="exercise-card">
  <div class="ex-number">Exercise 06</div>
  <div class="ex-title">The Unthinkable Error</div>
  <div class="ex-time">⏱ 30 min</div>
  <div class="ex-desc">Snapshot, clone to staging, restore production, wire an NFS backup target and schedule.</div>
</a>

<a href="exercises/07-stampede/" class="exercise-card">
  <div class="ex-number">Exercise 07</div>
  <div class="ex-title">The Stampede</div>
  <div class="ex-time">⏱ 25 min</div>
  <div class="ex-desc">Forge a golden VM template and stamp out a calculation fleet on demand.</div>
</a>

<a href="exercises/08-new-horizon/" class="exercise-card">
  <div class="ex-number">Exercise 08</div>
  <div class="ex-title">A New Horizon</div>
  <div class="ex-time">⏱ 10 min</div>
  <div class="ex-desc">Recap what you mastered and where the skills go next.</div>
</a>

</div>

### Bonus (self-hosted only, no rodeo counterpart)

<div class="exercise-grid">

<a href="exercises/bonus-final-showdown/" class="exercise-card">
  <div class="ex-number">Bonus</div>
  <div class="ex-title">The Final Showdown</div>
  <div class="ex-time">⏱ 25 min</div>
  <div class="ex-desc">Explore Harvester's real Migration UI and extract a stand-in legacy ledger onto SUSE Virtualization.</div>
</a>

</div>

---

## Legacy → SUSE mapping

| Old world (ISAware) | SUSE Virtualization |
|---|---|
| Proprietary hypervisor | KubeVirt + KVM/QEMU |
| Storage array | Longhorn (or any CSI driver) |
| Closed-source SDN | Kube-OVN + Multus |
| Command console | Rancher Prime + Harvester UI |

## Component versions

| Component | Version |
|---|---|
| Harvester | 1.8.1 |
| Rancher Prime | 2.14.1 |
| K3s | v1.35.3+k3s1 |
| cert-manager | v1.20.1 |
| rodeo-cli | v0.14.x |
