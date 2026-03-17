```bash
# Identity & project
gcloud beta container \
  --project "piyush-gcp" \
  clusters create "standard-cluster-private-1" \

# Location & version
  --region "us-central1" \
  --cluster-version "1.34.4-gke.1047000" \
  --release-channel "regular" \

# Node machine config
  --machine-type "e2-custom-2-5120" \
  --image-type "COS_CONTAINERD" \
  --disk-type "pd-standard" \
  --disk-size "20" \
  --spot \
  --num-nodes "0" \
  --max-pods-per-node "110" \
  --default-max-pods-per-node "110" \

# Auth & service account
  --no-enable-basic-auth \
  --service-account "default" \
  --scopes "https://www.googleapis.com/auth/cloud-platform" \
  --metadata disable-legacy-endpoints=true \

# Networking
  --enable-private-nodes \
  --enable-ip-alias \
  --enable-ip-access \
  --enable-dataplane-v2 \
  --disable-default-snat \
  --no-enable-intra-node-visibility \
  --no-enable-google-cloud-access \
  --network "projects/piyush-gcp/global/networks/default" \
  --subnetwork "projects/piyush-gcp/regions/us-central1/subnetworks/default" \

# Node locations (HA across zones)
  --node-locations "us-central1-a","us-central1-b","us-central1-c" \

# Observability
  --logging=SYSTEM,WORKLOAD \
  --monitoring=SYSTEM,STORAGE,POD,DEPLOYMENT,STATEFULSET,DAEMONSET,HPA,JOBSET,CADVISOR,KUBELET,DCGM \
  --enable-managed-prometheus \

# Security
  --enable-shielded-nodes \
  --shielded-integrity-monitoring \
  --no-shielded-secure-boot \
  --security-posture=standard \
  --workload-vulnerability-scanning=disabled \
  --workload-pool "piyush-gcp.svc.id.goog" \
  --binauthz-evaluation-mode=DISABLED \

# Addons
  --addons HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS,GcePersistentDiskCsiDriver,GcpFilestoreCsiDriver \

# Upgrade policy
  --enable-autoupgrade \
  --enable-autorepair \
  --max-surge-upgrade 1 \
  --max-unavailable-upgrade 0
```



# GKE Private Cluster — `standard-cluster-private-1`

A production-ready private GKE cluster on Google Cloud Platform with VPC-native networking, Workload Identity, managed observability, and zero-disruption upgrade policy.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Cluster Specifications](#cluster-specifications)
- [Command](#command)
- [Configuration Reference](#configuration-reference)
  - [Identity & Project](#identity--project)
  - [Location & Version](#location--version)
  - [Node Configuration](#node-configuration)
  - [Networking](#networking)
  - [Observability](#observability)
  - [Security](#security)
  - [Addons](#addons)
  - [Upgrade Policy](#upgrade-policy)
- [Post-Creation Steps](#post-creation-steps)
- [Workload Considerations](#workload-considerations)
- [Cost Notes](#cost-notes)
- [Known Limitations](#known-limitations)

---

## Overview

This cluster is configured as a **regional private cluster** in `us-central1`, spread across three availability zones for high availability. Nodes have no public IP addresses. All workloads communicate through VPC-native pod networking (Dataplane v2 / eBPF). Identity for pods is managed via Workload Identity — no service account key files required.

| Property | Value |
|---|---|
| Cluster name | `standard-cluster-private-1` |
| Project | `piyush-gcp` |
| Region | `us-central1` |
| Zones | `us-central1-a`, `us-central1-b`, `us-central1-c` |
| Kubernetes version | `1.34.4-gke.1047000` |
| Release channel | `regular` |
| Node type | Spot (preemptible) |
| Networking | VPC-native, private nodes, Dataplane v2 |

---

## Prerequisites

Before running the creation command, ensure the following are in place.

**Tools**

- `gcloud` CLI installed and authenticated (`gcloud auth login`)
- `gcloud` beta components installed:
  ```bash
  gcloud components install beta
  ```
- `kubectl` installed for post-creation cluster access

**GCP APIs enabled** on project `piyush-gcp`:

```bash
gcloud services enable container.googleapis.com \
  compute.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  --project piyush-gcp
```

**IAM permissions required** to run this command:

- `roles/container.admin` on the project
- `roles/iam.serviceAccountUser` on the node service account

**VPC & Subnet**

The command uses the `default` VPC and subnet in `us-central1`. Ensure they exist and have sufficient secondary IP ranges for pod and service CIDRs. If using a custom VPC, update `--network` and `--subnetwork` accordingly.

---

## Cluster Specifications

| Category | Detail |
|---|---|
| Machine type | `e2-custom-2-5120` (2 vCPU, 5 GB RAM) |
| Boot disk | 20 GB `pd-standard` |
| OS image | `COS_CONTAINERD` (Container-Optimized OS) |
| Node pricing | Spot (preemptible, up to 91% cheaper) |
| Initial node count | 0 (autoscaler provisions on demand) |
| Max pods per node | 110 |
| Node service account | `default` compute SA |

---

## Command

```bash
gcloud beta container \
  --project "piyush-gcp" \
  clusters create "standard-cluster-private-1" \

  # Location & version
  --region "us-central1" \
  --cluster-version "1.34.4-gke.1047000" \
  --release-channel "regular" \

  # Node machine config
  --machine-type "e2-custom-2-5120" \
  --image-type "COS_CONTAINERD" \
  --disk-type "pd-standard" \
  --disk-size "20" \
  --spot \
  --num-nodes "0" \
  --max-pods-per-node "110" \
  --default-max-pods-per-node "110" \

  # Auth & service account
  --no-enable-basic-auth \
  --service-account "default" \
  --scopes "https://www.googleapis.com/auth/cloud-platform" \
  --metadata disable-legacy-endpoints=true \

  # Networking
  --enable-private-nodes \
  --enable-ip-alias \
  --enable-ip-access \
  --enable-dataplane-v2 \
  --disable-default-snat \
  --no-enable-intra-node-visibility \
  --no-enable-google-cloud-access \
  --network "projects/piyush-gcp/global/networks/default" \
  --subnetwork "projects/piyush-gcp/regions/us-central1/subnetworks/default" \

  # Node locations (HA across zones)
  --node-locations "us-central1-a","us-central1-b","us-central1-c" \

  # Observability
  --logging=SYSTEM,WORKLOAD \
  --monitoring=SYSTEM,STORAGE,POD,DEPLOYMENT,STATEFULSET,DAEMONSET,HPA,JOBSET,CADVISOR,KUBELET,DCGM \
  --enable-managed-prometheus \

  # Security
  --enable-shielded-nodes \
  --shielded-integrity-monitoring \
  --no-shielded-secure-boot \
  --security-posture=standard \
  --workload-vulnerability-scanning=disabled \
  --workload-pool "piyush-gcp.svc.id.goog" \
  --binauthz-evaluation-mode=DISABLED \

  # Addons
  --addons HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS,GcePersistentDiskCsiDriver,GcpFilestoreCsiDriver \

  # Upgrade policy
  --enable-autoupgrade \
  --enable-autorepair \
  --max-surge-upgrade 1 \
  --max-unavailable-upgrade 0
```

> **Estimated provisioning time:** 8–15 minutes for a regional cluster.

---

## Configuration Reference

### Identity & Project

| Flag | Value | Purpose |
|---|---|---|
| `--project` | `piyush-gcp` | GCP project to create the cluster in |

### Location & Version

| Flag | Value | Purpose |
|---|---|---|
| `--region` | `us-central1` | Regional cluster — control plane spans multiple zones |
| `--cluster-version` | `1.34.4-gke.1047000` | Pinned Kubernetes version |
| `--release-channel` | `regular` | Stable, tested releases (not bleeding edge) |
| `--node-locations` | `us-central1-a,b,c` | Distributes node pools across three zones for HA |

### Node Configuration

| Flag | Value | Purpose |
|---|---|---|
| `--machine-type` | `e2-custom-2-5120` | 2 vCPU, 5 GB RAM custom machine |
| `--image-type` | `COS_CONTAINERD` | Hardened container-optimized OS with containerd runtime |
| `--disk-type` | `pd-standard` | Standard HDD boot disk |
| `--disk-size` | `20` GB | Boot disk size — increase if pulling large images |
| `--spot` | — | Preemptible nodes — significantly cheaper, can be reclaimed by GCP |
| `--num-nodes` | `0` | Node pool starts empty; relies on Cluster Autoscaler |
| `--max-pods-per-node` | `110` | Kubernetes default maximum |
| `--metadata` | `disable-legacy-endpoints=true` | Blocks access to deprecated GCE metadata API from pods |

### Networking

| Flag | Purpose |
|---|---|
| `--enable-private-nodes` | Nodes have no external IP addresses |
| `--enable-ip-alias` | VPC-native networking — pods get first-class VPC IPs |
| `--enable-ip-access` | Allows authorized external access to the Kubernetes API (kubectl) |
| `--enable-dataplane-v2` | Uses eBPF (Cilium) for pod networking — enables `NetworkPolicy`, better observability |
| `--disable-default-snat` | Disables GKE's automatic SNAT — required when you manage NAT manually or use Cloud NAT |
| `--no-enable-intra-node-visibility` | Pod-to-pod traffic on the same node bypasses VPC flow logs (lower cost, less visibility) |
| `--no-enable-google-cloud-access` | Prevents GCP services from accessing the control plane directly |

> **Important:** With `--enable-private-nodes`, nodes cannot reach the internet by default. You must configure [Cloud NAT](https://cloud.google.com/nat/docs/overview) on the VPC to allow outbound internet access (e.g., pulling images from Docker Hub).

### Observability

| Flag | Value | Purpose |
|---|---|---|
| `--logging` | `SYSTEM,WORKLOAD` | Ships cluster system logs and application (stdout/stderr) logs to Cloud Logging |
| `--monitoring` | `SYSTEM,STORAGE,POD,DEPLOYMENT,...` | Full workload metrics suite — pods, deployments, HPA, cAdvisor, Kubelet |
| `--enable-managed-prometheus` | — | Google-managed Prometheus scraping — expose `/metrics` from your apps and it just works |

All metrics and logs are visible in **Cloud Monitoring** and **Cloud Logging** dashboards automatically.

### Security

| Flag | Value | Purpose |
|---|---|---|
| `--no-enable-basic-auth` | — | Disables username/password authentication to the API server |
| `--enable-shielded-nodes` | — | Nodes use Secure Boot, vTPM, and integrity monitoring |
| `--shielded-integrity-monitoring` | — | Runtime boot integrity measured and reported |
| `--no-shielded-secure-boot` | — | Secure Boot is **disabled** — enable this in stricter environments |
| `--security-posture` | `standard` | GKE baseline workload misconfiguration scanning |
| `--workload-vulnerability-scanning` | `disabled` | Container image CVE scanning is off — consider enabling in production |
| `--workload-pool` | `piyush-gcp.svc.id.goog` | Enables Workload Identity — pods can authenticate to GCP APIs without key files |
| `--binauthz-evaluation-mode` | `DISABLED` | Binary Authorization is off — any image can deploy |

### Addons

| Addon | Purpose |
|---|---|
| `HorizontalPodAutoscaling` | Enables HPA — scale deployments based on CPU, memory, or custom metrics |
| `HttpLoadBalancing` | Enables GKE Ingress controller for external HTTP/S load balancers |
| `NodeLocalDNS` | DNS caching per node — reduces DNS latency for service discovery |
| `GcePersistentDiskCsiDriver` | PVC support backed by GCP Persistent Disks (ReadWriteOnce) |
| `GcpFilestoreCsiDriver` | PVC support backed by Cloud Filestore (ReadWriteMany / NFS) |

### Upgrade Policy

| Flag | Value | Purpose |
|---|---|---|
| `--enable-autoupgrade` | — | Nodes automatically upgrade when new versions are available |
| `--enable-autorepair` | — | Unhealthy nodes are automatically drained and recreated |
| `--max-surge-upgrade` | `1` | One extra node is provisioned during an upgrade (surge node) |
| `--max-unavailable-upgrade` | `0` | Zero nodes taken offline simultaneously — zero-disruption upgrades |

---

## Post-Creation Steps

**1. Configure kubectl**

```bash
gcloud container clusters get-credentials standard-cluster-private-1 \
  --region us-central1 \
  --project piyush-gcp
```

**2. Set up Cloud NAT** (required for private nodes to pull images / reach the internet)

```bash
gcloud compute routers create nat-router \
  --network default \
  --region us-central1 \
  --project piyush-gcp

gcloud compute routers nats create nat-config \
  --router nat-router \
  --region us-central1 \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges \
  --project piyush-gcp
```

**3. Configure Workload Identity for your apps**

```bash
# Create a GCP service account for your workload
gcloud iam service-accounts create my-app-sa \
  --project piyush-gcp

# Bind it to a Kubernetes ServiceAccount
gcloud iam service-accounts add-iam-policy-binding \
  my-app-sa@piyush-gcp.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:piyush-gcp.svc.id.goog[NAMESPACE/KSA_NAME]"
```

**4. Configure a node pool autoscaler** (since `--num-nodes=0`)

```bash
gcloud container clusters update standard-cluster-private-1 \
  --enable-autoscaling \
  --min-nodes 0 \
  --max-nodes 10 \
  --region us-central1 \
  --project piyush-gcp
```

**5. Verify cluster health**

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

---

## Workload Considerations

**Spot nodes and eviction tolerance**

Nodes are preemptible (`--spot`). Workloads must:
- Handle `SIGTERM` and shut down gracefully within the termination grace period
- Use `PodDisruptionBudgets` to maintain availability during evictions
- Set appropriate `priorityClass` if mixing spot and on-demand pools in future

**No nodes on startup**

The cluster starts with zero nodes (`--num-nodes=0`). First pod deployments will trigger Cluster Autoscaler to provision nodes, adding ~2–4 minutes of cold-start latency. For latency-sensitive workloads, consider setting `--min-nodes 1`.

**DNS performance**

`NodeLocalDNS` caches DNS on each node. Ensure your app's DNS TTLs and retry logic are compatible with local caching behavior.

**Persistent storage**

- Use `GcePersistentDiskCsiDriver` for `ReadWriteOnce` volumes (stateful apps, databases)
- Use `GcpFilestoreCsiDriver` for `ReadWriteMany` volumes (shared filesystems)
- Note: 20 GB boot disk fills quickly with large container images — monitor node disk usage

---

## Cost Notes

| Component | Cost impact |
|---|---|
| Spot nodes | Up to 91% cheaper vs on-demand — but subject to preemption |
| Zero initial nodes | No compute cost until workloads are scheduled |
| Managed Prometheus | Ingestion costs apply based on metric volume |
| Cloud Logging (WORKLOAD) | Log ingestion billed beyond free tier |
| Cloud NAT | Billed per GB of outbound traffic processed |
| Regional cluster | Control plane billed at regional rate (higher than zonal) |

---

## Known Limitations

- **No public node IPs** — pods cannot be reached directly from the internet without a load balancer or ingress.
- **Secure Boot disabled** — `--no-shielded-secure-boot` means the full shielded node guarantee is not in effect. Enable in stricter compliance environments.
- **Vulnerability scanning disabled** — `--workload-vulnerability-scanning=disabled` means container image CVEs will not be reported. Enable for production security posture.
- **Default service account** — `--service-account "default"` uses the Compute Engine default SA, which may have broader permissions than needed. Replace with a least-privilege custom SA for production.
- **Binary Authorization disabled** — any container image can be deployed without attestation. Enable `--binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE` for supply chain security.

---

## References

- [GKE Private Clusters documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept)
- [Workload Identity documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Dataplane V2 documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2)
- [GKE Managed Prometheus](https://cloud.google.com/stackdriver/docs/managed-prometheus)
- [Cloud NAT with GKE](https://cloud.google.com/nat/docs/gke-example)
- [`gcloud container clusters create` reference](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)
