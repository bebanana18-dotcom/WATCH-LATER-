# 🧠 What are Requests and Limits?

Each container can define resource requirements:

* **Requests** → minimum guaranteed resources (used for scheduling)
* **Limits** → maximum allowed usage (enforced at runtime)

---

# 🔁 Step-by-Step Working

### 1. Pod Specification

You define resources in the Pod spec:

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
  limits:
    cpu: "1"
    memory: "512Mi"
```

---

### 2. Scheduling Decision

* Kubernetes scheduler looks **only at requests**
* It places the Pod on a node that has enough available requested resources

👉 Limits are ignored at this stage

---

### 3. Runtime Enforcement

* Once running, the container runtime enforces **limits using cgroups**

* CPU:

  * If usage exceeds limit → **throttled**

* Memory:

  * If usage exceeds limit → **OOMKilled (terminated)**

---

### 4. Resource Contention

If multiple Pods compete:

* Pods exceeding their requests are more likely to be throttled or evicted
* Behavior depends on QoS class

---

# 🧬 QoS Classes (Derived Automatically)

Kubernetes assigns a **QoS class** to each Pod based on its requests and limits.

---

## 🥇 Guaranteed

### Condition:

* Requests = Limits for **all containers**

```yaml
resources:
  requests:
    cpu: "1"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "512Mi"
```

---

### Behavior:

* Highest priority
* Least likely to be evicted
* Strongest resource guarantees

---

## 🥈 Burstable

### Condition:

* Requests < Limits (or only some resources defined)

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
  limits:
    cpu: "1"
    memory: "512Mi"
```

---

### Behavior:

* Guaranteed minimum (requests)
* Can use extra resources (up to limits)
* Medium eviction priority

---

## 🥉 BestEffort

### Condition:

* No requests and no limits defined

```yaml
resources: {}
```

---

### Behavior:

* No guarantees
* Scheduled anywhere
* First to be evicted under pressure

---

# 🔥 Key Insights

* **Scheduler uses requests, not limits**
* **Limits are enforced by the kernel (not Kubernetes directly)**
* **CPU is throttled, memory is killed**
* **QoS class determines survival under pressure**

---

# 🧩 Example Scenario

Node capacity: 4 CPU, 4Gi memory

Pods:

| Pod | Request         | Limit       | QoS        |
| --- | --------------- | ----------- | ---------- |
| A   | 1 CPU / 1Gi     | 1 CPU / 1Gi | Guaranteed |
| B   | 0.5 CPU / 512Mi | 1 CPU / 1Gi | Burstable  |
| C   | none            | none        | BestEffort |

---

### Under memory pressure:

1. Pod C (BestEffort) → evicted first
2. Pod B (Burstable) → evicted if exceeding request
3. Pod A (Guaranteed) → last to be evicted

---

# 🧠 Conclusion

Requests and limits define how resources are reserved and enforced, while QoS classes determine how Pods are treated under contention. Together, they form the foundation of Kubernetes resource management, ensuring efficient utilization while prioritizing critical workloads.
