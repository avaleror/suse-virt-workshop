---
hide:
  - toc
---

<div class="hero">
  <div class="subtitle">SUSE Virtualization: Hands-on Workshop</div>
  <h1>The Virtualization Rodeo</h1>
  <div class="tagline">Harvester HCI &bull; Rancher Prime &bull; Kube-OVN &bull; Longhorn &bull; alien-geeko</div>

  <a href="exercises/01-import-into-rancher/" class="md-button md-button--primary">Start the lab &rarr;</a>
  &nbsp;
  <a href="reference/quick-reference/" class="md-button">Quick reference</a>
</div>

---

## The scenario

<div class="scenario">
AeroGrid Operations runs the IT stack for a regional international airport: baggage handling, gate assignment, check-in kiosks, ramp control, three airline tenants sharing the same infrastructure. When Broadcom's acquisition of VMware closed, the renewal quote came in at 3.2x the previous cost, with NSX, vSAN, and vCenter billed separately.

The decision was made: migrate to SUSE Virtualization. This workshop puts you in the seat of the AeroGrid infrastructure team, bringing the new platform online end to end, from importing the cluster into Rancher to running a passenger-facing K3s workload on top of it.
</div>

## Lab topology

<div class="topology">
<pre>
KVM host (bare metal, yours)
│
├── harvester1   192.168.122.11   8 vCPU / 16 GiB / 270 GB   bootstrap node
├── harvester2   192.168.122.12   8 vCPU / 16 GiB / 270 GB   join node
├── harvester3   192.168.122.13   8 vCPU / 16 GiB / 270 GB   join node
└── rancher      192.168.122.9    4 vCPU / 8 GiB  / 60 GB    Rancher Prime + K3s

VIP (kube-vip): 192.168.122.10
</pre>
</div>

This is the same 3-node Harvester + Rancher Prime topology used in SUSE's customer-facing Harvester Rodeo, deployed here on your own bare metal host via `rodeo-cli` instead of a hosted sandbox. Run it, break it, rerun it as many times as you like.

---

## Exercises

<div class="exercise-grid">

<a href="exercises/01-import-into-rancher/" class="exercise-card">
  <div class="ex-number">Exercise 01</div>
  <div class="ex-title">Import Harvester into Rancher</div>
  <div class="ex-time">⏱ 30 min</div>
  <div class="ex-desc">Connect the two systems with a registration URL, then wire up kubectl to talk to the cluster through Rancher's proxy.</div>
</a>

<a href="exercises/02-cluster-online/" class="exercise-card">
  <div class="ex-number">Exercise 02</div>
  <div class="ex-title">Bring the cluster online</div>
  <div class="ex-time">⏱ 30 min</div>
  <div class="ex-desc">Confirm node and pod health, build the primary VM cluster network and VM network, and set up the LoadBalancer IP pool.</div>
</a>

<a href="exercises/03-first-vm/" class="exercise-card">
  <div class="ex-number">Exercise 03</div>
  <div class="ex-title">First VM and live migration</div>
  <div class="ex-time">⏱ 30 min</div>
  <div class="ex-desc">Provision a cloud-image VM with cloud-init, SSH into it, then move it live between nodes with zero downtime.</div>
</a>

<a href="exercises/04-networking/" class="exercise-card">
  <div class="ex-number">Exercise 04</div>
  <div class="ex-title">Networking and isolation</div>
  <div class="ex-time">⏱ 30 min</div>
  <div class="ex-desc">Build a VLAN backbone with Multus, then isolate two airline tenants on overlapping CIDRs with Kube-OVN.</div>
</a>

<a href="exercises/05-storage-snapshots/" class="exercise-card">
  <div class="ex-number">Exercise 05</div>
  <div class="ex-title">Snapshots and DR</div>
  <div class="ex-time">⏱ 30 min</div>
  <div class="ex-desc">Add a second Longhorn storage policy, checkpoint a VM, simulate corruption, and restore it clean.</div>
</a>

<a href="exercises/06-provision-k3s/" class="exercise-card">
  <div class="ex-number">Exercise 06</div>
  <div class="ex-title">Provision a K3s cluster</div>
  <div class="ex-time">⏱ 45 min</div>
  <div class="ex-desc">Set up project RBAC and a Harvester cloud credential, then let Rancher provision a full K3s cluster as VMs on the platform.</div>
</a>

<a href="exercises/07-noc-dashboard/" class="exercise-card">
  <div class="ex-number">Exercise 07</div>
  <div class="ex-title">NOC dashboard</div>
  <div class="ex-time">⏱ 20 min</div>
  <div class="ex-desc">Deploy alien-geeko on the new cluster and expose it via LoadBalancer, pulling an IP straight from the pool you built in Exercise 2.</div>
</a>

</div>

---

## What replaces what

| VMware (Broadcom pricing) | SUSE Virtualization | Version in this lab |
|---|---|---|
| ESXi | KubeVirt + KVM | KubeVirt v1.7.0 |
| vSAN | Longhorn distributed storage | Longhorn v1.11.1 |
| NSX | Kube-OVN + Multus | Kube-OVN v1.15.4 |
| vCenter | SUSE Rancher Prime | Rancher Prime v2.14.1 |

No vendor lock-in, no per-feature license tiers, one platform and one bill.

## Resources

<div class="link-row">
  <a href="reference/quick-reference/">📋 Quick reference</a>
  <a href="reference/lab-overview/">🗺️ Lab overview</a>
  <a href="lab-guide/">📄 Full lab guide (print)</a>
  <a href="instructor/host-setup/">🔧 Instructor: host setup</a>
  <a href="instructor/pre-lab-checklist/">✅ Instructor: pre-lab checklist</a>
  <a href="https://github.com/avaleror/rodeo-cli" target="_blank">⚙️ rodeo-cli</a>
</div>

---

## Component versions

| Component | Version |
|---|---|
| Harvester | 1.8.1 |
| Rancher Prime | 2.14.1 |
| K3s (management cluster) | v1.35.3+k3s1 |
| cert-manager | v1.20.1 |
| KubeVirt | v1.7.0 |
| Longhorn | v1.11.1 |
| Kube-OVN | v1.15.4 |
