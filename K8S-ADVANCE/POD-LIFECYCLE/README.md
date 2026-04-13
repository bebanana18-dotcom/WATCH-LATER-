# 🧠 What is Pod Lifecycle?

The Pod lifecycle represents the different **states and transitions** a Pod goes through from creation to termination, along with the internal conditions that determine whether it is actually usable.

---

# 🔁 Step-by-Step Lifecycle

### 1. Pod Creation (Pending)

* A Pod is created via API (e.g., Deployment)
* Stored in the API server
* Scheduler assigns it to a node
  👉 Phase: **Pending**

---

### 2. Scheduling & Initialization

* Scheduler selects a node
* Kubelet pulls container images
* Init containers (if any) are executed
  👉 Still **Pending** until containers start

---

### 3. Container Startup (Running)

* Containers are created and started by the container runtime
  👉 Phase: **Running**

⚠️ Important:

* “Running” only means containers are alive
* Application may still be:

  * Starting up
  * Misconfigured
  * Failing internally

---

### 4. Readiness Check (Ready vs Not Ready)

* Kubernetes uses **readiness probes** to decide if the Pod can receive traffic
* If probe fails:

  * Pod remains Running
  * But is marked **Not Ready**
  * Removed from Service endpoints

---

### 5. Health Monitoring (Liveness)

* **Liveness probes** check if the container is still healthy
* If probe fails:

  * Container is restarted

---

### 6. Failure & Restart (CrashLoop)

* If container repeatedly fails:

  * Enters states like **CrashLoopBackOff**
* Pod may still show **Running**, but is unstable

---

### 7. Termination

* When Pod is deleted:

  * Marked as *Terminating*
  * Receives **SIGTERM**
  * Given grace period to shut down
  * Then force killed (SIGKILL if needed)

---

### 8. Completion (Succeeded / Failed)

* For batch jobs:

  * **Succeeded** → completed successfully
  * **Failed** → terminated with error

---

# 🔥 Key Insights

* **Running ≠ Ready** → Pod may not serve traffic
* **Running ≠ Healthy** → App can still be broken
* **Pod status is coarse** → Need probes for real state
* **Pods are ephemeral** → They are created, destroyed, and replaced frequently

---

# 🧩 Example Scenario

A Pod shows:

```text
Phase: Running
```

But:

* Readiness probe fails → no traffic
* Liveness probe fails → container restarts
* App logs show errors

👉 System appears “up” but is functionally down

---

# 🧠 Conclusion

Understanding the Pod lifecycle requires looking beyond simple phases and focusing on **conditions, probes, and transitions**. Kubernetes treats Pods as temporary, self-healing units, and only through readiness and health checks can we determine whether a Pod is truly operational.
