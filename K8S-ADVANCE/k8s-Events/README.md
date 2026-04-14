
# ⚡ Kubernetes Events — Complete DevOps Notes (Updated)

---

## 🧠 What Events Actually Are

> **Events = Kubernetes decision log (short-lived, high-signal)**

They answer:

* Why did my pod fail?
* Why didn’t it schedule?
* Why was it restarted/killed?
* What is Kubernetes *trying* to tell me?

👉 Think:
**Events = “Why K8s acted”**
**Logs = “What app did”**

---

## 🔍 Core Commands (Muscle Memory)

### 📌 Get all events (sorted)

```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

---

### 📌 Filter only warnings

```bash
kubectl get events --field-selector type=Warning
```

---

### 📌 Watch events live (real-time debugging)

```bash
kubectl get events --watch
```

---

### 📌 Events for specific resource

```bash
kubectl get events \
  --field-selector involvedObject.name=<pod-name>
```

---

### 📌 Deep dive (most important)

```bash
kubectl describe pod <pod-name>
```

Scroll to:

```
Events:
```

👉 This is your **primary debugging signal**

---

## 🧩 Event Anatomy

Example:

```text
Warning  FailedScheduling  2m  default-scheduler  
0/3 nodes available: insufficient memory
```

| Field   | Meaning              |
| ------- | -------------------- |
| Type    | Normal / Warning     |
| Reason  | What happened        |
| Age     | When                 |
| Source  | Who triggered it     |
| Message | Detailed explanation |

---

## 🔥 High-Value Event Patterns (Memorize These)

---

### 💣 FailedScheduling

```text
0/3 nodes available: insufficient cpu
```

👉 Pod cannot be placed

**Causes:**

* Resource shortage
* Taints / tolerations mismatch
* Node affinity rules
* Fragmented resources

---

### 💀 CrashLoopBackOff

```text
Back-off restarting failed container
```

👉 App is repeatedly crashing

---

### 🔐 FailedMount

```text
Unable to mount volumes
```

👉 Issue with:

* PVC
* ConfigMap
* Secret
* Permissions

---

### 🌐 FailedCreatePodSandBox

```text
network plugin failed
```

👉 CNI / networking issue

---

### 🔥 Unhealthy (Probe failures)

```text
Liveness probe failed
```

👉 Kubernetes is killing your container

---

### ⚠️ ImagePullBackOff

```text
Failed to pull image
```

👉 Issues:

* Wrong image name/tag
* Registry auth failure
* Image not found

---

## 🕵️ Debugging Scenarios (Real Thinking)

---

### 🚫 Pod not starting

Event:

```text
FailedScheduling
```

👉 Conclusion:

* NOT app issue
* NOT container issue
* **Cluster capacity problem**

---

### 🔁 Pod restarting

Event:

```text
BackOff restarting failed container
```

👉 Next step:

```bash
kubectl logs <pod-name>
```

---

### 🌐 Service not reachable

Event:

```text
FailedCreatePodSandBox
```

👉 Root cause:

* Networking / CNI

---

### ⏳ Pod stuck in ContainerCreating

Event:

```text
FailedMount
```

👉 Root cause:

* Storage / volume issue

---

## ⚠️ Critical Reality (Most People Ignore This)

---

### 🧠 1. Events Are Ephemeral

![Image](https://images.openai.com/static-rsc-4/t9TViHza90o4krUgi8b980APpuU2TBUEBG6j9KxbMimvuJcM10ekcOikKjB-C30FjbkaOV89XuEHx2X2KPZkx5aF5lSM7e6MrNKEhb-O7NtIhk-0WLy62O9SPgPw0g1sDxqocwvTbcdav5v0ERW62B7J7Q6oTOymHZov_fM_06u993Jf-iFZEGZkuQEIRiU0?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/aROnWD3-9KvMoTfSeb05CUknNLTvMbgcRsB4e5BZ9Vglmb-XxkrUi8YKZ5sUm0OWvEI0oOkiY_9zIiNwpCx62FAIXV-RT5EPXOVhmWzdv2ixEBiJEand_5jgytURq8llYw7FcIG2-uuk37xl9kCBH-JRfUsJDO8osGk4bMrmHozjwGLQGKPnWSBnJc3nyfU2?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/yLj3lXcFCQxD37BxkqlwnLhk1FDC196955ObWOTXqdlPWqu70Vp4nYDTYSsF0gR5qwT72m--_p30XJabakZyGlXIVPNfgY7GOoJF14leSyleF6_4PsxiWH_GzE6IB13-QGLvu3VsxxbvuzVnDuaD5IQBe60pr4COds-FxAAHdcMg-sJ7dU45WviFXChEIggI?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/QfGt_55-XehUx2FUp0OOlLB2zMu5duvH6R39C3xsyOXHqUSkS8BYNsqXP2Qe4HLLrf_rFTilxDiNbMI3sFYIqPhk1xNuchce6vIu9q7hWYh5mkf-gBKAXdQfqrerf59Byv5cPFoC34dsrclW09mnDtX4tYUfJxmKQcTR4zbWhXTjUoQ9WeRXZBUMXfnCw2QC?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/-13Gq-B2ISELU5MjH9F298q6Uu0PTGc3g1v1fJJ7_m5GrPrvTE8kw4U39pwSQf-DpoOsdboNojhDefMz4Lgi7ZL-WD21t0r89aIqjR4ZpmmINfgAw_-4jEN4dY-jehMCUD7K7DWzULsAIHWfENvslk7eKJyL8v-yeZ-kUG-cM2-pwBOb6zmF9yfhXGf5dOLO?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/pN6frvjzCDt40DjCpuXr9cFwj8XYAkIA-3w4B7dkFMCpnf0mF_wzrJaToow4LovTjF78KtPw00nnKhWQAtBh9l3YKjAmSnWdpKHX1PLbTsoEG_MuFl4p9MiUhtIiYGqCtq-oop44rnV5aJMFisvmxZ4kUfypkYZ2IQFAeB8mDUCfekgqBgkosej7IHE1FrGg?purpose=fullsize)

* Stored in etcd
* TTL ≈ **~1 hour (cluster dependent)**
* Automatically deleted

👉 Meaning:

> If you didn’t check → evidence is gone

---

### 🧠 2. Events Show Symptoms, Not Always Root Cause

Example:

```text
insufficient cpu
```

Reality might be:

* Node taints
* Affinity mismatch
* Resource fragmentation

👉 Always ask:

> “What CAUSED this?”

---

### 🧠 3. Event Frequency Matters

```text
BackOff restarting failed container (x50 over 10m)
```

* `(x50)` = severity signal

👉 Interpretation:

* x1 → transient issue
* x50 → persistent failure

---

### 🧠 4. Events Can Be Throttled

* Kubernetes may:

  * Aggregate events
  * Drop excessive events

👉 Missing errors ≠ no problem

---

## 🔗 Cross-Resource Correlation (Senior Skill)

![Image](https://images.openai.com/static-rsc-4/sNRHM_0KBsTaug5pJaiaSjJJ5ulKd5rO1iFrGHabb3rf546ZF4dUbz_0rIt5iz6S-LvEUMFvGMVIceH9Ww9zQvRAGfbnW8LmZnL7Tv5zO5UzlpDK8kzGzwFWFZx3kkPTNlxKI2YyHfJ5vgVRuToUvlHL8C8Gv_FPwwIVvFT5iuD6do8v-lcF1w_xAC-ryZ-w?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/jsWp5ObJoAJ9PxBYcRISFSjTrifCiJ07vVI3F_559jNaEDl3G3xfoy6vWXFrsBPzf9R3ytBr0BQg16_T-9socK11j0U_nfF06_FRJqBWLjpkcZ-JT437HR-9c2QGqn5yJvSkpFdtG1PCZX7HICX7uQaaw39bY1dpZ3j2McivR2T3SEQsfQgBJEOhBY-hJ5A7?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/R-LdKbKL_6UeA3RR1OFh7qw0s183E8nhrzKpJotINv-a5qfhR4BIWuUhV3WQjHhrt5hcUbzfTDWcHcORqA0oZwpKHPk6skwLGSsV9puCtZSSQMtPEVhp0sn4mjEFL04bOTJtDYH2mRKK9s0bddC2Xs3M-yKM946f61OQUj_r5xk_TvijCxELNc7irmnJfNJL?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/KBs459nFH0Z3kKH3NxJtrjHSRv2QCzg1CPsDjbodNZkhGvZNc-rUD9O9l4qpubARAfbQfEX0cNV3Hb_-r1cQAGfmO9rg90mG5Iv-uVd3Q0fA-LSeZbxbppcjYrKxxVztaRMEGPnSDm9pzMdWlW0yQmGSCklgKWM4Wj6prAhzkPiOE9HhawijBi8o6pOvCtXs?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/-ShKP-mPBMfXtuWilP4c_xDJ0ROUO5zJYlogkE-ZW7-718J_puyrhDbf-XVPmTG09RD-ZyO6KRo6JGc5uFRBznBd4pGDH4n5bMuluGVAlGcSKCztStzyeOxOFvY34d1n416LrTKbzVIiG6iI90KktMeUopDia1uMdeWSYC_TBffA3zL839cze83t5yziNZs0?purpose=fullsize)

Never debug in isolation.

Follow the chain:

```text
Deployment → ReplicaSet → Pod → Node
```

---

### Example:

* Pod:

  ```
  FailedScheduling
  ```
* Node:

  ```
  NodeNotReady
  ```
* Cluster:

  ```
  Autoscaler triggered
  ```

👉 Now you see the **full story**

---

## 🖥️ Node-Level Events (Often Missed)

Check nodes:

```bash
kubectl describe node <node-name>
```

Look for:

```text
MemoryPressure
DiskPressure
PIDPressure
NodeNotReady
```

👉 Explains:

* Pod evictions
* Scheduling failures
* Random restarts

---

## 🎯 Advanced Filtering (Reduce Noise)

```bash
kubectl get events \
  --field-selector involvedObject.kind=Pod,type=Warning \
  --sort-by=.metadata.creationTimestamp
```

👉 Shows only:

* Pod-related
* Warning-level
* Time-ordered issues

---

## ⚔️ Events vs Logs (Never Confuse)

| Events        | Logs         |
| ------------- | ------------ |
| Cluster-level | App-level    |
| Why K8s acted | What app did |
| Short-lived   | Persistent   |
| High signal   | Often noisy  |

---

## 🧠 Pro Debug Flow (Production Grade)

```text
Events 
→ Describe Resource 
→ Logs 
→ Node 
→ Metrics 
→ Network 
→ Config
```

---

## 💀 Common Mistakes

---

### ❌ Ignoring events

👉 You miss root cause

---

### ❌ Jumping straight to logs

👉 Wrong layer debugging

---

### ❌ Not sorting events

👉 Timeline becomes useless

---

### ❌ Debugging only pod

👉 Ignore node/cluster context

---

## ⚡ Final Insight

> Events are Kubernetes saying:
> “Here’s exactly what went wrong… don’t make me repeat it.”

---

## 💀 Brutal Truth

Average engineer:

* Restarts pod
* Hopes it works

Good engineer:

* Reads events
* Fixes issue

Senior engineer:

* Correlates events across system
* Prevents it from happening again

