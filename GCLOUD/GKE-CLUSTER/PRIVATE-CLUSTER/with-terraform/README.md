# GKE Private Cluster + Jenkins CI/CD on GCP

**Author:** piyush-gcp
**Purpose:** Practice / demo infrastructure for a private GKE cluster with a Jenkins bastion VM, Cloud NAT, Workload Identity, and a hardened node service account.

---

## Overview

This project provisions a secure, production-style Google Kubernetes Engine (GKE) environment on Google Cloud Platform (GCP). It is designed as a learning and demo setup for running a private GKE cluster with Jenkins as the CI/CD entry point.

The architecture includes:

* A custom VPC and subnet with secondary IP ranges for GKE
* Cloud Router and Cloud NAT for outbound internet access from private nodes
* Dedicated service accounts for GKE nodes and Jenkins
* A Jenkins bastion VM with a static external IP
* Firewall rules for Jenkins UI, SonarQube, and SSH via IAP only
* A private, VPC-native GKE cluster with Workload Identity and Dataplane v2

---

## Architecture

### 1. Locals

Centralized configuration for:

* Project ID
* Region and zone
* CIDR blocks for subnet, pods, services, and control plane
* IAP CIDR range
* Jenkins ingress CIDR list

### 2. Networking

* **VPC:** Custom network with manual subnet control
* **Subnet:** Primary subnet plus secondary ranges for pods and services
* **Cloud Router:** Required for Cloud NAT
* **Cloud NAT:** Lets private GKE nodes pull images and reach external services without public IPs

### 3. IAM

* **GKE Node Service Account:** Minimal permissions for node operation
* **Jenkins Service Account:** Permissions required for Jenkins to manage GKE resources

### 4. Compute

* **Jenkins Bastion VM:** Debian 12 VM used for Jenkins access and cluster administration
* **Static IP:** Reserved for stable access and firewall control

### 5. Firewall

* Jenkins UI and SonarQube accessible on ports **8080** and **9000**
* SSH allowed **only via Google IAP**

### 6. GKE Cluster

* Private nodes with no external IPs
* VPC-native networking
* Workload Identity enabled
* Dataplane v2 enabled
* Managed logging and monitoring
* Add-ons for HTTP load balancing, HPA, DNS cache, Persistent Disk CSI, and Filestore CSI

---

## Key Features

* **Private cluster:** Nodes are isolated from the public internet
* **Cloud NAT:** Enables outbound connectivity without public node IPs
* **Workload Identity:** Avoids service account key files in pods
* **Shielded nodes:** Improves node security with secure boot and integrity monitoring
* **Spot nodes:** Reduces cost for demo and non-production workloads
* **IAP-only SSH:** Prevents direct SSH exposure to the internet
* **Terraform lifecycle safeguards:** Reduces unnecessary recreation during upgrades

---

## Repository Layout

A typical layout for this project may look like:

```text
.
├── main.tf
├── variables.tf
├── locals.tf
├── outputs.tf
├── terraform.tfvars
└── README.md
```

You may keep everything in a single Terraform file for a demo, or split it into multiple files for readability.

---

## Prerequisites

Before deploying, make sure you have:

* A GCP project
* Billing enabled on the project
* Terraform installed
* `gcloud` CLI installed and authenticated
* Required Google Cloud APIs enabled:

  * Compute Engine API
  * Kubernetes Engine API
  * IAM API
  * Cloud Logging API
  * Cloud Monitoring API

---

## Deployment Steps

### 1. Authenticate with GCP

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project piyush-gcp
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the execution plan

```bash
terraform plan
```

### 4. Apply the infrastructure

```bash
terraform apply
```

---

## Accessing Jenkins

After the VM is created, Jenkins can be reached through the reserved static IP on port **8080**.

For security, SSH access is restricted to **Google IAP** rather than direct internet access.

---

## Security Notes

This configuration is intentionally hardened compared to a basic demo setup:

* Private GKE nodes have no public IPs
* SSH is allowed only through IAP
* Node permissions are scoped to required roles only
* Legacy metadata endpoints are disabled on the VM
* Shielded VM settings are enabled
* Workload Identity replaces credential files

A few settings are intentionally relaxed for demo purposes:

* Jenkins UI ingress is open to `0.0.0.0/0`
* Private endpoint is disabled on the cluster
* Spot nodes are enabled
* Binary Authorization and Security Posture are disabled

These should be tightened for production use.

---

## Important Terraform Notes

* `deletion_protection` is set to `false`, so the cluster can be destroyed when needed.
* The default node pool is not fully removed in this configuration because `remove_default_node_pool = false` is set.
* `depends_on` ensures Cloud NAT and node IAM roles are ready before cluster creation.
* `master_authorized_networks_config` allows access to the Kubernetes API from the internal subnet.

---

## Suggested Next Steps

* Add a proper `variables.tf` file for reusability
* Move sensitive or environment-specific values into `terraform.tfvars`
* Replace open Jenkins ingress with office/VPN CIDR ranges
* Enable private endpoint for stricter cluster access
* Add Kubernetes manifests or Helm charts for Jenkins, SonarQube, and sample workloads
* Enable Binary Authorization and Security Posture for production

---

## Troubleshooting

### Cluster creation fails

Check that:

* Cloud NAT is created successfully
* The node service account has the required IAM roles
* Secondary IP ranges do not overlap
* The master CIDR block is a valid `/28`

### Nodes cannot pull images

This usually means:

* Cloud NAT is missing or misconfigured
* Artifact Registry permissions are incomplete
* Network routing or firewall rules are blocking egress

### SSH to VM does not work

Remember:

* SSH is allowed only through IAP
* Your user must have the correct IAP and OS Login permissions

---

## Cleanup

To remove the infrastructure:

```bash
terraform destroy
```

If deletion protection is enabled on the cluster in the future, set it to `false` before destroying.

---

## License

This project is intended for practice and demonstration use.
