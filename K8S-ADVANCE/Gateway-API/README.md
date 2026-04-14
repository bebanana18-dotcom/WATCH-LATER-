
# 🧠 Kubernetes Gateway API — Complete Notes

---

# 🔥 1. What Was the Problem?

Before Gateway API, we had:

👉 **Kubernetes Ingress**

---

## 💀 Problems with Ingress


### ❌ 1. Too Simple (and inconsistent)

Ingress tried to do everything in one resource:

```yaml
host + path + tls + routing + controller-specific stuff
```

👉 Result:

* Messy configs
* Hard to scale
* Hard to extend

---

### ❌ 2. Controller-Specific Behavior

Example:

* NGINX Ingress → annotations
* Traefik → different config

👉 Same YAML, different behavior

```text
“Standard API… but not really standard”
```

---

### ❌ 3. No Role Separation

* Platform team
* App team

👉 Both edit same Ingress resource → chaos

---

### ❌ 4. Limited Routing Capabilities

* No advanced traffic splitting
* No proper extensibility
* No clear abstraction layers

---

## 🧠 Summary of Problem

```text
Ingress = too basic + too overloaded + not extensible
```

---

# 🚀 2. What is Gateway API?

> Gateway API = **next-gen Kubernetes networking API for traffic routing**

---

## 🧠 Core Idea

Split responsibilities into **multiple resources**:

```text
Infrastructure (Gateway) ≠ Routing (Routes)
```

---

# ⚙️ 3. Core Components

---

## 🧩 1. GatewayClass

> Defines *who implements the gateway*

Example:

```yaml
kind: GatewayClass
```

👉 Like:

```text
“Which controller is managing this?”
```

Examples:

* Istio
* Envoy
* NGINX

---

## 🧩 2. Gateway

> Defines infrastructure (load balancer, ports, TLS)

---

## 🧩 3. HTTPRoute (and others)

> Defines routing rules

---

## 🧠 Clean Separation

```text
GatewayClass → Gateway → Route
```

---

# 🔁 4. Architecture Flow


## 🔄 Flow

```text
Client → Gateway → Route → Service → Pod
```

---

# 🧠 5. Role-Based Model (Big Upgrade)

---

## 👷 Platform Team

Manages:

* GatewayClass
* Gateway

👉 Infra-level control

---

## 👨‍💻 App Team

Manages:

* HTTPRoute

👉 App-level routing

---

## 🎯 Benefit

```text
Separation of concerns → no more YAML wars
```

---

# ⚔️ 6. Gateway API vs Ingress

| Feature          | Ingress | Gateway API |
| ---------------- | ------- | ----------- |
| Extensibility    | ❌       | ✅           |
| Role separation  | ❌       | ✅           |
| Advanced routing | ❌       | ✅           |
| Standardization  | Weak    | Strong      |
| Structure        | Flat    | Layered     |

---

# 🔧 7. Basic Example

---

## 🧩 Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - protocol: HTTP
    port: 80
```

---

## 🧩 HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route
spec:
  parentRefs:
  - name: my-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: my-service
      port: 80
```

---

# 🔥 8. Key Features (Why It Matters)

---

## ✅ 1. Advanced Routing

* Header-based routing
* Traffic splitting
* Canary deployments

---

## ✅ 2. Extensible

Supports:

* HTTP
* TCP
* UDP
* gRPC

---

## ✅ 3. Policy Attachment

You can attach:

* Auth
* Rate limiting
* Security policies

---

## ✅ 4. Multi-Tenant Friendly

Different teams → different responsibilities

---

# 💀 9. Common Mistakes

---

### ❌ Treating Gateway like Ingress

👉 It’s NOT a single resource system

---

### ❌ Ignoring GatewayClass

👉 Without it → nothing works

---

### ❌ Not checking controller support

👉 Gateway API needs implementation (like Ingress)

---

# 🧠 10. Mental Model

---

## Ingress mindset:

```text
One resource → everything
```

---

## Gateway mindset:

```text
Infra (Gateway) + Routing (Route) + Controller (GatewayClass)
```

---

# ⚡ 11. Final Insight

> Gateway API is not just a replacement for Ingress
> It’s a **re-architecture of Kubernetes networking**

---

# 💀 Brutal Truth

Ingress:

```text
“Just make it work”
```

Gateway API:

```text
“Make it scalable, structured, and sane”
```

---

