# SUSE Virtualization Workshop

Hands-on workshop covering the full SUSE Virtualization (Harvester HCI) lifecycle: importing a cluster into Rancher Prime, VM networking and IP pools, VM provisioning and live migration, tenant network isolation with Kube-OVN, storage snapshots and DR, and provisioning a full K3s cluster on top of the platform.

**Workshop site:** https://avaleror.github.io/suse-virt-workshop/

---

## Repo structure

```
docs/
  index.md                  # Landing page (GitHub Pages home)
  exercises/                # Seven step-by-step exercises
  reference/                # Lab overview and quick reference
  instructor/               # Host setup and pre-lab checklist
  lab-guide.md               # Full single-file version (printable)
rodeo-plan.yaml             # Deployment plan for rodeo-cli
mkdocs.yml                  # MkDocs Material config
.github/workflows/
  deploy.yml                # Auto-deploy to GitHub Pages on push to main
```

## Run the workshop

Deploy the lab environment on a bare metal KVM host:

```bash
curl -fsSL https://raw.githubusercontent.com/avaleror/rodeo-cli/main/install.sh | bash
rodeo init --profile harvester --dir suse-virt-workshop
cd suse-virt-workshop
sudo rodeo deploy --config-dir .
```

Then follow the lab guide at https://avaleror.github.io/suse-virt-workshop/

## Local docs preview

```bash
pip install mkdocs-material
mkdocs serve
```

Open http://127.0.0.1:8000

---

*Deployed with [rodeo-cli](https://github.com/avaleror/rodeo-cli) v0.10.x.*
