# Exercise 1 — Import Harvester into Rancher

**Time:** 30 min
**Next:** [Exercise 2 — Bring the cluster online](02-cluster-online.md)

---

`rodeo deploy` leaves you with two systems that don't know about each other yet: a healthy 3-node Harvester cluster, and a Rancher Prime instance running on its own VM. This exercise connects them, then wires up `kubectl` on your host so every later exercise can talk to Harvester directly.

## 1.1 Verify both backends are up

From a shell on your KVM host:

```bash
curl -sk https://192.168.122.10/v1 | jq -r '.apiVersion'
curl -sk https://192.168.122.9:30002/v3 | jq -r '.type'
```

The first should return `harvesterhci.io/v1beta1` (or similar), the second `collection`. Both backends are reachable.

> **Note:** Both UIs use self-signed certificates. Accept the browser security warning when it appears.

## 1.2 Log in to Rancher

Open `https://<host-ip>:30002` in a browser (or `https://192.168.122.9:30002` if you're browsing from the host itself).

- **Username:** `admin`
- **Password:** the `rancher_admin_password` value in `~/.rodeo/secrets.yaml` on the host

You land on the Rancher home screen with one cluster listed: **local** — that's Rancher's own K3s management cluster, not Harvester. There's no Virtualization Management section yet because nothing is imported.

## 1.3 Register the Harvester cluster in Rancher

In the Rancher UI:

1. Click **Virtualization Management** in the left sidebar
2. Click **Import Existing** (top right)
3. Set **Cluster Name** to `harvester`
4. Click **Create**

Rancher shows a registration URL, something like:

```
https://192.168.122.9:30002/v3/import/xxxxx_c-xxxxx.yaml
```

Copy it. You need it in the next step.

> **Important:** the cluster name must be exactly `harvester` — later exercises assume it.

## 1.4 Apply the registration URL in Harvester

Open `https://<host-ip>:8443` (external, DNAT'd) or `https://192.168.122.10` (internal, from the host) and log in with the same `admin` user and the `harvester_admin_password` from secrets.yaml.

1. Click the **Settings** icon (gear) in the left sidebar
2. Scroll to **cluster-registration-url**
3. Click the row to edit it
4. Paste the URL you copied from Rancher
5. Click **Save**

Harvester deploys a Rancher agent into the cluster and registers itself in the background. This takes 1-3 minutes.

## 1.5 Verify the import

Back in Rancher, watch **Virtualization Management**. The cluster moves through `Pending` → `Waiting` → `Active`.

Once it's `Active`, `harvester` is now a cluster Rancher manages like any other.

## 1.6 Configure kubectl to reach Harvester through Rancher

Rancher proxies the Kubernetes API of every cluster it manages. Rather than SSH into a Harvester node for every `kubectl` command in this workshop, point `kubectl` on your host at that proxy — it's the same access pattern Rancher gives you for any downstream cluster, on-prem or cloud.

Generate a Rancher API token: top-right user avatar → **Account & API Keys** → **Create API Key** → no scope, no expiration → **Create**. Copy the **Bearer Token** shown (you won't see it again).

```bash
export RANCHER_URL="https://192.168.122.9:30002"
export RANCHER_TOKEN="<the bearer token you just copied>"

CLUSTER_ID=$(curl -sk \
  -H "Authorization: Bearer $RANCHER_TOKEN" \
  "${RANCHER_URL}/v3/clusters?name=harvester" \
  | jq -r '.data[0].id')

kubectl config set-credentials rancher-bearer --token="$RANCHER_TOKEN"

kubectl config set-cluster susevirt-through-rancher \
  --server="${RANCHER_URL}/k8s/clusters/${CLUSTER_ID}" \
  --insecure-skip-tls-verify=true

kubectl config set-context susevirt-through-rancher \
  --cluster=susevirt-through-rancher \
  --user=rancher-bearer

kubectl config use-context susevirt-through-rancher
```

Verify:

```bash
kubectl get nodes
```

All three Harvester nodes should show `Ready`. Every `kubectl` command in the rest of this workshop runs from right here — no need to SSH into a Harvester node.

## 1.7 Register your SSH key for later VM access

Exercise 3 provisions a VM with your SSH key injected via cloud-init. Register the host's public key as a Harvester `KeyPair` now:

```bash
kubectl apply -f - <<EOF
apiVersion: harvesterhci.io/v1beta1
kind: KeyPair
metadata:
  name: workshop-host
  namespace: default
spec:
  publicKey: >-
    $(cat ~/.ssh/id_ed25519.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub)
EOF
```

---

**Next:** [Exercise 2 — Bring the cluster online](02-cluster-online.md)
