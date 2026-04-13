# 🧠 What is a Reconciliation Loop?

A reconciliation loop is a continuous control process that:

> Compares the desired state (from the API server) with the actual state (in the cluster) and takes action if they differ.

---

# 🔁 Step-by-Step Working

### 1. Desired State is Submitted

* You apply a configuration using `kubectl apply`
* The specification (e.g., Deployment with 3 replicas) is stored in the API server (and persisted in etcd)

---

### 2. Controller Watches for Changes

* Controllers (like Deployment or ReplicaSet controllers) continuously **watch** the API server for new or updated objects
* This is event-driven, not constant polling

---

### 3. Compare Desired vs Actual State

* The controller checks:

  * Desired: 3 replicas
  * Actual: e.g., 1 running Pod

---

### 4. Detect Difference (Drift)

* A mismatch is identified:

  * Missing 2 Pods

---

### 5. Take Corrective Action

* Controller creates additional Pods to match desired state
* This may trigger other components:

  * Scheduler assigns Pods to nodes
  * Kubelet starts containers

---

### 6. Continuous Reconciliation

* Even after reaching 3 Pods, the loop **does not stop**
* If a Pod crashes or is deleted:

  * Controller detects drift again
  * Recreates the Pod

---

# 🔥 Key Characteristics

* **Continuous**: Runs forever, not one-time
* **Level-based**: Focuses on current state, not past events
* **Self-healing**: Automatically fixes failures
* **Eventually consistent**: System converges to desired state over time

---

# 🧩 Example

If a Deployment specifies:

```yaml
replicas: 3
```

And one Pod is deleted manually:

* Actual state → 2 Pods
* Controller detects mismatch
* Creates 1 new Pod

👉 System returns to 3 Pods automatically

---

# 🧠 Conclusion

Reconciliation loops are the core mechanism that makes Kubernetes reliable and autonomous. By continuously comparing and correcting the system state, they ensure that the cluster always moves toward the declared configuration, regardless of failures or unexpected changes.
