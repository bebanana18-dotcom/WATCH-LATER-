
# 🧪 LAB: Kubernetes Gateway API (Production-Style)

---

# 🎯 Goal

By the end, you will:

* Install Gateway API + controller
* Create **Gateway (infra layer)**
* Create **HTTPRoute (app layer)**
* Enforce **namespace-level access control**
* Test **real traffic routing**

---

# 🧠 Architecture You Will Build


---

```text
Client → Gateway → HTTPRoute → Service → Pod
```

---

# ⚙️ Step 0: Prerequisites

* Kubernetes cluster (Minikube / Kind / EKS)
* kubectl working

---

# 🚀 Step 1: Install Gateway API CRDs

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
```

---

## ✅ Verify

```bash
kubectl get crds | grep gateway
```

---

# 🚀 Step 2: Install Controller

We’ll use:

👉 Envoy Gateway

---

```bash
helm install eg oci://docker.io/envoyproxy/gateway-helm -n envoy-gateway-system --create-namespace
```

---

## ✅ Verify

```bash
kubectl get pods -n envoy-gateway-system
```

👉 All pods should be Running

---

# 🧩 Step 3: Create Namespaces (Multi-Team Setup)

```bash
kubectl create namespace infra
kubectl create namespace app-team
```

---

# 🧩 Step 4: Create GatewayClass (Platform Team)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

---

```bash
kubectl apply -f gatewayclass.yaml
```

---

# 🧩 Step 5: Create Gateway (Infra Layer)

👉 Platform team controls this

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main-gateway
  namespace: infra
spec:
  gatewayClassName: envoy

  listeners:
  - name: http
    protocol: HTTP
    port: 80

    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            access: allowed
```

---

```bash
kubectl apply -f gateway.yaml
```

---

# 🧠 Key Concept

```text
Gateway controls WHO can attach routes
```

---

# 🧩 Step 6: Allow App Namespace

```bash
kubectl label namespace app-team access=allowed
```

---

👉 Now only this namespace can attach routes

---

# 🚀 Step 7: Deploy Sample App

---

## 🧾 deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: app-team
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

---

## 🧾 service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: app-team
spec:
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
```

---

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

---

# 🧩 Step 8: Create HTTPRoute (App Team)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: nginx-route
  namespace: app-team
spec:
  parentRefs:
  - name: main-gateway
    namespace: infra

  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: nginx
      port: 80
```

---

```bash
kubectl apply -f httproute.yaml
```

---

# 🔍 Step 9: Verify Gateway

```bash
kubectl get gateway -n infra
```

---

👉 Look for:

```text
ADDRESS assigned
```

---

# 🌐 Step 10: Test Traffic

---

## Get external IP

```bash
kubectl get gateway main-gateway -n infra
```

---

## Test

```bash
curl http://<EXTERNAL-IP>
```

---

👉 You should see:

```text
Welcome to nginx!
```

---

# 💀 Step 11: Break It (IMPORTANT)

---

## ❌ Remove namespace label

```bash
kubectl label namespace app-team access-
```

---

👉 Result:

```text
Route stops working
```

---

## 🧠 Insight:

```text
Gateway enforces access control
```

---

# 🔥 Step 12: Advanced Test (Traffic Split)

Edit HTTPRoute:

```yaml
backendRefs:
- name: nginx
  port: 80
  weight: 80
- name: nginx-v2
  port: 80
  weight: 20
```

👉 Canary routing

---

# 🧠 What You Learned

---

## 🔁 Layered Architecture

```text
Gateway (infra) → Route (app) → Service → Pod
```

---

## 🔐 Access Control

```text
Gateway controls which namespaces can attach routes
```

---

## ⚔️ Separation of Concerns

| Team     | Responsibility |
| -------- | -------------- |
| Platform | Gateway        |
| App      | HTTPRoute      |

---

# 💀 Common Issues

---

### ❌ No external IP

👉 Check controller service

---

### ❌ Route not attaching

👉 Check:

* namespace label
* parentRefs

---

### ❌ Controller not working

👉 Check pods/logs

---

# ⚡ Final Mental Model

```text
Gateway API = Traffic Control Plane
```

---

# 🚀 Bonus Challenge

Try:

* Add `/api` route
* Add second service
* Implement canary deployment

---

