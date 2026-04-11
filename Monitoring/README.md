# GKE Monitoring Essentials: 10 Metrics That Actually Matter

> *Stop flying blind with expensive infrastructure. If you're not monitoring these, you're just paying for confusion at scale.*

---

## The Golden Rule

Most teams monitor CPU, ignore everything else, then act surprised when users revolt.  
Don't be that team.

---

## The 10 Metrics You Cannot Skip

### 1. 🔥 Request Rate — *Is Anyone Home?*

Are users hitting your service, or is it just vibes and empty dashboards?

```promql
sum by (service) (rate(http_requests_total[5m]))
```

**What it tells you:**
- Which services are actually alive and active
- Traffic spikes and suspicious drops (both are bad, for different reasons)

---

### 2. ❌ Error Rate — *Your Bug Distribution Platform*

If this metric is high, congratulations — you've built something very consistent, just not in a good way.

```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

**What to track:**
- Percentage of 5xx errors
- **Alert threshold:** > 1–5% means something is on fire

---

### 3. ⏱️ Latency — *Slow Is Just Broken with a Delay*

Users don't file tickets. They just leave. Monitor latency before they do.

```promql
histogram_quantile(0.95,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
)
```

**The percentile breakdown:**

| Percentile | What It Means |
|------------|---------------|
| p50 | Normal user experience |
| p95 | Real user pain |
| p99 | Rage-quit territory |

---

### 4. 📊 Total Usage (Last 30 Days) — *Separate the Useful from the Undead*

Distinguish the services that matter from the ones that just exist and cost money.

```promql
sum by (service) (increase(http_requests_total[30d]))
```

**What it helps you do:**
- Prioritize engineering effort
- Identify dead services prime for deletion

---

### 5. 🧠 CPU Usage (per Pod/Service) — *Busy or Panicking?*

High CPU either means your service is doing real work, or it's having a very quiet breakdown.

```promql
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)
```

**Action:**
- Consistently high CPU → scale out or optimize
- CPU pegged at limit → you're about to have a bad time

---

### 6. 💾 Memory Usage — *The Silent Killer*

Memory creep leads to OOM, which leads to CrashLoopBackOff, which leads to 2am incidents.

```promql
container_memory_usage_bytes
```

**Compare usage against configured limits:**

| Scenario | Implication |
|----------|-------------|
| Near the limit | Expect crashes soon |
| Far below the limit | You're overpaying for unused capacity |

---

### 7. 🔁 Pod Restarts — *Pods Should Not Behave Like Windows XP*

A pod restarting once is fine. A pod restarting constantly is a cry for help.

```promql
increase(kube_pod_container_status_restarts_total[5m])
```

**Common causes to investigate:**
- OOM kill
- Application crash
- Bad deployment / misconfiguration

---

### 8. 📦 Pod Health & Availability — *Are You Even Running?*

Before debugging performance, verify your service actually exists in a running state.

```promql
kube_pod_status_phase{phase="Running"}
```

**Track the full pod lifecycle:**
- `Running` — healthy
- `Pending` — something is blocking scheduling
- `Failed` — investigate immediately

---

### 9. ⚖️ Autoscaling Behavior (HPA) — *Smart Scaling or Thrashing?*

HPA can be your best friend or a hyperactive intern that can't make decisions.

```promql
kube_horizontalpodautoscaler_status_current_replicas
```

**Red flags to watch:**
- Constant scale-up/scale-down cycles (thrashing) — tune your thresholds
- No scaling when load is clearly high — your HPA is asleep on the job

---

### 10. 🌐 Node Health — *Sometimes the Cluster Is Betraying You*

Not every problem is your application's fault. Sometimes the underlying infrastructure is quietly failing.

```promql
node_cpu_seconds_total
node_memory_MemAvailable_bytes
```

**Monitor at the infrastructure level:**
- Node CPU saturation
- Disk pressure
- Memory starvation
- Network issues

---

## 💸 Bonus: Cost vs. Usage Reality Check

Combine request volume with CPU and memory usage to find the answer to the most important question in infrastructure:

> **"Which service is expensive AND useless?"**

Those are your prime deletion candidates. No survivors.

---

## Start Here: The Survival Tier List

If you're overwhelmed, begin with these four. They'll surface 80% of your problems:

1. **Request Rate** — Is traffic normal?
2. **Error Rate** — Are requests succeeding?
3. **Latency** — Are responses fast enough?
4. **Pod Restarts** — Is anything crashing?

Everything else answers *why* those four look bad.

---

## The Brutal Truth

```
Most teams:

  ✅ Monitor CPU
  ❌ Ignore error rate
  ❌ Ignore latency  
  ❌ Ignore usage trends

Then act surprised when users complain.
```

You now have no excuse.

---

*Stack: GKE + Prometheus + Grafana*
