# Exercise 7: NOC dashboard

**Time:** 20 min
**Previous:** [Exercise 6: Provision a K3s cluster](06-provision-k3s.md)

---

`checkin-cluster` is running but dark: the NOC has no visibility into node count, architecture, Kubernetes version, or load. This exercise deploys **alien-geeko**, a small Node.js app that queries the Kubernetes API at runtime and renders live cluster vitals, then exposes it with a LoadBalancer IP pulled straight from `rodeo-ippool`.

## 7.1 Connect to the check-in cluster

```bash
export KUBECONFIG=~/.kube/checkin-cluster.yaml
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
  name: alien-geeko
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
  name: alien-geeko
  namespace: alien-geeko
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: alien-geeko-reader
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
  name: alien-geeko-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: alien-geeko-reader
subjects:
  - kind: ServiceAccount
    name: alien-geeko
    namespace: alien-geeko
EOF
```

**Cluster display name**: this is what shows on the dashboard:

```bash
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: alien-geeko-config
  namespace: alien-geeko
data:
  CLUSTER_NAME: "AEROGRID-CHECKIN-01"
EOF
```

**Dashboard deployment and LoadBalancer Service:**

```bash
kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alien-geeko
  namespace: alien-geeko
  labels:
    app: alien-geeko
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alien-geeko
  template:
    metadata:
      labels:
        app: alien-geeko
    spec:
      serviceAccountName: alien-geeko
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: alien-geeko
          image: docker.io/avaleror/alien-geeko:latest
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
                  name: alien-geeko-config
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
  name: alien-geeko
  namespace: alien-geeko
spec:
  selector:
    app: alien-geeko
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 3000
EOF
```

Wait for it to come up:

```bash
kubectl rollout status deployment/alien-geeko -n alien-geeko
```

## 7.3 Open the dashboard

Because `rodeo-ippool` addresses (`192.168.122.200-220`) sit on the same NAT network as your host, the LoadBalancer IP is reachable directly. No port-forward needed.

```bash
kubectl get svc alien-geeko -n alien-geeko
```

Open `http://<EXTERNAL-IP>` in a browser. You should see `checkin-cluster`'s live vitals: node count, OS, Kubernetes version, memory, CPU, and load average.

## 7.4 Set the NOC terminal instance name

```bash
kubectl patch configmap alien-geeko-config -n alien-geeko \
  --patch '{"data":{"CLUSTER_NAME":"AEROGRID-NOC-TERMINAL-1"}}'

kubectl rollout restart deployment/alien-geeko -n alien-geeko
kubectl rollout status deployment/alien-geeko -n alien-geeko
```

Refresh the dashboard. It now identifies this instance as `AEROGRID-NOC-TERMINAL-1`.

## 7.5 Verify the IP pool connection

```bash
LB_IP=$(kubectl get svc alien-geeko -n alien-geeko \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -s http://$LB_IP/health
```

The `EXTERNAL-IP` came from `rodeo-ippool`: the same pool created in Exercise 2.

## The full stack

```
Bare metal (3 nodes)
  └── Harvester (KubeVirt + Longhorn + Kube-OVN)
        └── checkin-cluster VM (K3s, provisioned by Rancher)
              └── alien-geeko (NOC dashboard, LoadBalancer via rodeo-ippool)
```

Every component is open source. Every component is SUSE-supported. AeroGrid's platform is live.
