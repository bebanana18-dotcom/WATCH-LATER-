**PromQL** is where people go from:

> “Grafana looks cool”

to:

> “I can prove exactly when and why your system betrayed you.”

---

# 🧠 What PromQL really is

PromQL = **query language for time-series data**

It answers:

* What is happening?
* Over what time?
* Compared to what?

---

# ⚙️ The Core Building Blocks

## 1. Metrics

Example:

```promql
http_requests_total
```

This is a **counter** (only goes up… like your cloud bill).

---

## 2. Labels (THIS is where power comes from)

```promql
http_requests_total{method="GET", status="200"}
```

👉 Filters data
👉 Enables slicing like a data ninja

---

## 3. Time

PromQL always thinks in **time windows**

```promql
[5m]
```

---

# 🔥 The Most Important Functions (you’ll use daily)

---

## ⚡ 1. `rate()` — your best friend

```promql
rate(http_requests_total[5m])
```

👉 Converts counter → requests per second

---

## 💀 If you forget `rate()`:

You’ll see ever-increasing numbers and panic for no reason.

---

## ⚡ 2. `sum()`

```promql
sum(rate(http_requests_total[5m]))
```

👉 Total RPS across all pods

---

## ⚡ 3. `by()` grouping

```promql
sum(rate(http_requests_total[5m])) by (status)
```

👉 Breaks down by HTTP status

---

## ⚡ 4. `avg()`

```promql
avg(container_memory_usage_bytes)
```

---

## ⚡ 5. `max()` / `min()`

```promql
max(container_cpu_usage_seconds_total)
```

---

# 🎯 Real DevOps Queries (this is the good stuff)

---

## 📈 Requests per second (RPS)

```promql
sum(rate(http_requests_total[1m]))
```

---

## ❌ Error rate

```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) 
/
sum(rate(http_requests_total[5m]))
```

👉 % of failed requests

---

## ⏱️ p95 latency

```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

👉 This is what users actually feel

---

## 🔥 CPU usage per pod

```promql
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)
```

---

## 💣 Memory usage per pod

```promql
sum(container_memory_usage_bytes) by (pod)
```

---

# 🧠 Labels = Superpower (or your downfall)

Example:

```promql
http_requests_total{service="payment", status="500"}
```

You can slice by:

* pod
* namespace
* service
* region

---

## 💀 Cardinality Explosion (classic mistake)

Bad idea:

```text
user_id=123456
session_id=abcdef
```

👉 Prometheus:

> “I’m about to die.”

---

# ⚔️ Combining Metrics (this is where magic happens)

---

## 🔥 Error % per service

```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
/
sum(rate(http_requests_total[5m])) by (service)
```

---

## 🚨 Detect spike

```promql
rate(http_requests_total[1m]) > 100
```

---

## 🧪 Compare past vs present

```promql
rate(http_requests_total[5m])
/
rate(http_requests_total[5m] offset 1h)
```

👉 “Are we worse than 1 hour ago?”

---

# 🧠 Advanced Concepts (where people get confused)

---

## ⏳ `increase()`

```promql
increase(http_requests_total[5m])
```

👉 Total requests in 5 min (not per second)

---

## 🔄 `irate()` (faster, noisier)

```promql
irate(http_requests_total[1m])
```

👉 Real-time spikes

---

## 🧮 `topk()`

```promql
topk(5, sum(rate(http_requests_total[5m])) by (pod))
```

👉 Top 5 busiest pods

---

# 🔍 Debugging Scenario (real life)

User: “App is slow”

You run:

---

### Step 1: Traffic

```promql
sum(rate(http_requests_total[5m]))
```

👉 Normal → not traffic issue

---

### Step 2: Errors

```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
```

👉 Spiking → something broke

---

### Step 3: Latency

```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

👉 High → users suffering

---

### Step 4: Drill down

```promql
sum(rate(http_requests_total{status="500"}[5m])) by (pod)
```

👉 One pod misbehaving → kill it (professionally)

---

# ⚠️ Common Mistakes

---

### ❌ Using raw counters

```promql
http_requests_total
```

👉 Useless alone

---

### ❌ Wrong time window

* Too small → noisy
* Too big → slow to react

---

### ❌ Ignoring labels

👉 Missing the real problem

---

# 🧠 Mental Model (remember this)

PromQL is:

> **Math over time + labels**

---


# 🚨 Part 1: Writing Production-Grade Alerts

(*a.k.a. how to avoid alert spam + ignored pages*)

---

## 🧠 Golden Rule

> If everything alerts → nothing alerts.

---

## ⚙️ What makes a *good* alert?

A real alert must answer:

* ❓ Is this user-impacting?
* ❓ Is it actionable?
* ❓ Do I need to wake someone up?

If not → it’s a **dashboard metric**, not an alert.

---

## 🔥 Use SLO-based alerting (this is pro-level)

Instead of:

> “CPU > 80%”

Use:

> “Users are experiencing failures or latency”

---

## 🎯 The RED Signals (your core alerts)

* **Rate** (traffic drop)
* **Errors** (failures)
* **Duration** (latency)

---

## ✅ Example: Error Rate Alert (GOOD)

```yaml
- alert: HighErrorRate
  expr: |
    sum(rate(http_requests_total{status=~"5.."}[5m])) 
    /
    sum(rate(http_requests_total[5m])) > 0.05
  for: 5m
```

### Why this is good:

* Uses **rate** (correct)
* Uses **percentage** (not raw numbers)
* Has **for: 5m** (avoids flapping)

---

## ❌ Bad Alert (classic mistake)

```yaml
cpu_usage > 80%
```

Why it’s garbage:

* No context
* No user impact
* Will spam you forever

---

## ⚡ Multi-window burn rate (SRE-level alerting)

You combine:

* Fast signal (catch spikes)
* Slow signal (avoid noise)

Example:

```yaml
# Fast burn
rate(errors[5m]) > 0.1

# Slow burn
rate(errors[1h]) > 0.05
```

👉 Alert only if BOTH are true

This avoids:

* False positives
* Missing real incidents

---

## 🧠 Alert Severity Levels

### 🔴 Critical

* Users affected NOW
* Wake someone up

### 🟡 Warning

* Might become a problem
* Slack/Email only

---

## 🔥 Add context (underrated)

Bad:

```
High error rate
```

Good:

```
Payment service error rate is 12% for last 5 minutes (threshold: 5%)
```

---

## ⚙️ Labels & annotations

```yaml
labels:
  severity: critical

annotations:
  summary: "High error rate on payment service"
  description: "Error rate >5% for 5m"
```

---

## 💀 Common Alerting Mistakes

* ❌ No `for:` → alert flaps like crazy
* ❌ Alert on infrastructure only
* ❌ Too many alerts → ignored
* ❌ No runbook → panic mode
* ❌ No grouping → 500 alerts for same issue

---

# ⚔️ Part 2: Debugging Real Outages Using PromQL

Let’s simulate reality:

---

## 💣 Scenario: “Users say app is slow”

(Your favorite vague complaint)

---

# 🔍 Step-by-Step Investigation

---

## 🥇 Step 1: Check traffic

```promql
sum(rate(http_requests_total[5m]))
```

👉 Is traffic:

* Normal → continue
* Spiking → load issue

---

## 🥈 Step 2: Check error rate

```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

👉 If high:

* App is failing

---

## 🥉 Step 3: Check latency (this is key)

```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

👉 If p95 high:

* Users suffering

---

## 🧠 Decision Tree

* High latency + low errors → slow dependency
* High errors → broken service
* High traffic → scaling issue

---

## 🔥 Step 4: Drill down by service

```promql
sum(rate(http_requests_total[5m])) by (service)
```

👉 Find which service is misbehaving

---

## 🔥 Step 5: Drill down by pod

```promql
sum(rate(http_requests_total{status="500"}[5m])) by (pod)
```

👉 One pod broken? Kill it.

---

## 🧪 Step 6: Check resource bottleneck

### CPU

```promql
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)
```

---

### Memory

```promql
sum(container_memory_usage_bytes) by (pod)
```

---

## 💀 Step 7: Check restarts

```promql
increase(kube_pod_container_status_restarts_total[5m])
```

👉 Crash loop = obvious culprit

---

## 🧠 Step 8: Compare with past

```promql
rate(http_requests_total[5m])
/
rate(http_requests_total[5m] offset 1h)
```

👉 “What changed?”

---

## 🔥 Step 9: Correlate with deploy

If metrics spike after deploy:

👉 Congratulations, you found your villain.

---

# 📊 What this looks like in Grafana

![Image](https://images.openai.com/static-rsc-4/TKBkc3J7z7PO-VTixgpc7wDDz0EvNFa3wnYUM99i8_VfAo33jrJylPI1tINhWJ9f8VRw812q_ZKamAMn-blUDwWBOy213k1j6y0XyCnp8hYOvpUEnewCVMua81JzmS9yO3fGhwp4FpGHnX-wbJSikFG4HPpKUp3mN9hQZx-QKlT19cOeq0bH6wfSXcpegcNY?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/z2KK089381VW-bEeyZxD3pe9whEbpCLQsQ21aRDDPZBgMPK0FsL6m2LCavE_72W4jJTxhYEGmOFTvTnZSWtnZMKHHJv-caKvfBG9sfPrE5Kk8GOlKLC-oZqnE4l5Y0M4RkAIXA825vUur9AZpWnrKUfYtuhWg3B6LrFzHG3fXOZh93BdfWwSkl0HPXm0rgQi?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/i31nFW_KwIfDYGt7szfiwQFqF8i0vqde1Pxy2xAsFRufyTALvs9Szy5IlErUSZ2L52lQP7oAz8BUSlAo666UejA0zARwXvCRvb5gw5jTZ8SJT_LRXdm5Ci_QUmA6q4zQjOY-616qazTj7lpEWZCXL0-mwW2OBtRmGyNyWRur4bg1DRMX0cYnVSVWbRfoQKys?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/GktvUG5yUkkBXNng-DbzRGagZuGNbqIIUw2rONwCu-ML3D9_3zzLCjIRTZbJHtzaZGriF7ZTf2dY5iWRzID01IoyZAQzawrCsqX_WCp1YZo9Ir6W-n_NqBE3mPhrlZcHwOyFlfWeDpdx6tYU7JafCxJDVVO3IidzVrRRtslxxD5RCpvC-Dqbq1HSVrHJePnE?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/LByQ96e5XCCBdZEqM3vrjNg5BjbKMyPg-D2x-SsBJrNAVEAE2vsGQiKycfdxDbsQTSprMeqydBicFjRJHtRiPiFVuon_W0zpGFp9YMSXDf2Bsd_5Jv2AHnEO0mWzSqPPKmf8bryU5hAK1VDM5U1SpWRXKea_7oOopmzeg43fSlE3p-NE-f4v7j4cGYfZzIFM?purpose=fullsize)



---

# 🧠 Real DevOps Insight

Debugging is NOT:

> “Check CPU and pray”

It is:

> **Narrow down → isolate → confirm → fix**

---

# ⚡ The Mental Model

When something breaks:

1. **Is traffic normal?**
2. **Are errors happening?**
3. **Is latency high?**
4. **Which service?**
5. **Which pod?**
6. **What changed?**

---

# 💀 Brutal Truth

Most engineers:

* Look at dashboards
* Guess
* Restart things

Good engineers:

* Use PromQL
* Prove root cause
* Fix once

---

