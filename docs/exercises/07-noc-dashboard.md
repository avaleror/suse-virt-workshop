# Exercise 7: Platform ops console

**Time:** 20 min
**Previous:** [Exercise 6: Provision a K3s cluster](06-provision-k3s.md)

---

`ledger-cluster` is running but dark: the platform team has no visibility into node count, architecture, Kubernetes version, or load. This exercise deploys **vertex-bank-app**, a small Node.js app that queries the Kubernetes API at runtime and renders live cluster vitals in a fintech ops console, then exposes it with a LoadBalancer IP pulled straight from `rodeo-ippool`.

## 7.1 Connect to the ledger cluster

```bash
export KUBECONFIG=~/.kube/ledger-cluster.yaml
kubectl get nodes
```

You should see the K3s worker node provisioned on Harvester in Exercise 6.

## 7.2 Deploy the dashboard

Apply the manifest stack in order.

**Namespace:**

```bash
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: vertex-bank
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/warn: restricted
EOF
```

**Service account and read permissions:**

```bash
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vertex-bank
  namespace: vertex-bank
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: vertex-bank-reader
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list"]
  - nonResourceURLs: ["/version"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vertex-bank-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: vertex-bank-reader
subjects:
  - kind: ServiceAccount
    name: vertex-bank
    namespace: vertex-bank
EOF
```

**Cluster display name**: this is what shows on the console:

```bash
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: vertex-bank-config
  namespace: vertex-bank
data:
  CLUSTER_NAME: "LEDGER-CORE-01"
EOF
```

**Console deployment and LoadBalancer Service:**

```bash
kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vertex-bank
  namespace: vertex-bank
  labels:
    app: vertex-bank
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vertex-bank
  template:
    metadata:
      labels:
        app: vertex-bank
    spec:
      serviceAccountName: vertex-bank
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: vertex-bank
          image: docker.io/avaleror/vertex-bank-app:latest
          ports:
            - containerPort: 3000
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: CLUSTER_NAME
              valueFrom:
                configMapKeyRef:
                  name: vertex-bank-config
                  key: CLUSTER_NAME
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 100m
              memory: 64Mi
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoSchedule
---
apiVersion: v1
kind: Service
metadata:
  name: vertex-bank
  namespace: vertex-bank
spec:
  selector:
    app: vertex-bank
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 3000
EOF
```

Wait for it to come up:

```bash
kubectl rollout status deployment/vertex-bank -n vertex-bank
```

## 7.3 Open the console

Because `rodeo-ippool` addresses (`192.168.122.200-220`) sit on the same NAT network as your host, the LoadBalancer IP is reachable directly. No port-forward needed.

```bash
kubectl get svc vertex-bank -n vertex-bank
```

Open `http://<EXTERNAL-IP>` in a browser. You should see `ledger-cluster`'s live vitals: node count, OS, Kubernetes version, memory, CPU, and load average.

## 7.4 Set the ops console instance name

```bash
kubectl patch configmap vertex-bank-config -n vertex-bank \
  --patch '{"data":{"CLUSTER_NAME":"VERTEX-OPS-CONSOLE-1"}}'

kubectl rollout restart deployment/vertex-bank -n vertex-bank
kubectl rollout status deployment/vertex-bank -n vertex-bank
```

Refresh the console. It now identifies this instance as `VERTEX-OPS-CONSOLE-1`.

## 7.5 Verify the IP pool connection

```bash
LB_IP=$(kubectl get svc vertex-bank -n vertex-bank \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -s http://$LB_IP/health
```

The `EXTERNAL-IP` came from `rodeo-ippool`: the same pool created in Exercise 2.

## The full stack

```
Bare metal (3 nodes)
  └── Harvester (KubeVirt + Longhorn + Kube-OVN)
        └── ledger-cluster VM (K3s, provisioned by Rancher)
              └── vertex-bank-app (platform ops console, LoadBalancer via rodeo-ippool)
```

Every component is open source. Every component is SUSE-supported. Vertex Trust Bank's platform is live.
