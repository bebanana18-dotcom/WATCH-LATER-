###############################################################################
# PROJECT: GKE Private Cluster + Jenkins CI/CD on GCP
# AUTHOR : piyush-gcp
# PURPOSE: Practice / Demo — private GKE cluster with Jenkins bastion VM,
#          Cloud NAT, Workload Identity, and a hardened node SA.
#
# LAYOUT:
#   1. Locals & Variables
#   2. Networking  — VPC, Subnet, Router, NAT
#   3. IAM         — GKE Node SA + Jenkins SA (least-privilege)
#   4. Compute     — Jenkins Bastion VM + static IP
#   5. Firewall    — Jenkins UI, SonarQube, SSH-via-IAP
#   6. GKE Cluster — private cluster, VPC-native, Dataplane v2
###############################################################################


###############################################################################
# 1. LOCALS
#    Single place to change project / region — no more grep-and-pray.
###############################################################################

locals {
  project = "piyush-gcp"
  region  = "us-central1"
  zone    = "us-central1-a"

  # CIDR blocks — give them names so the intent is obvious
  subnet_primary  = "10.0.0.0/20"   # GKE nodes
  pods_cidr       = "10.1.0.0/16"   # GKE pods
  services_cidr   = "10.2.0.0/20"   # GKE services
  master_cidr     = "172.16.0.0/28" # GKE control plane (must be /28)
  iap_cidr        = "35.235.240.0/20" # Google IAP proxy range (don't touch)

  # In production, lock this to your office IP. Open /0 is a cry for help.
  jenkins_ingress = ["0.0.0.0/0"]
}


###############################################################################
# 2. NETWORKING
###############################################################################

# ── 2a. VPC ──────────────────────────────────────────────────────────────────
resource "google_compute_network" "vpc_gke" {
  name    = "vpc-gke"
  project = local.project

  # Always false for GKE — you want full control over subnets
  auto_create_subnetworks = false

  # REGIONAL: routes stay within region; GLOBAL allows cross-region routing.
  # Use REGIONAL unless you truly need multi-region pod connectivity.
  routing_mode = "REGIONAL"
}

# ── 2b. Subnet ───────────────────────────────────────────────────────────────
resource "google_compute_subnetwork" "subnet_1" {
  name    = "subnet-1"
  project = local.project
  region  = local.region
  network = google_compute_network.vpc_gke.id

  ip_cidr_range = local.subnet_primary
  stack_type    = "IPV4_ONLY"

  # Secondary ranges are mandatory for VPC-native GKE clusters.
  # Pods and Services get their own dedicated CIDR — no overlap allowed.
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = local.pods_cidr
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = local.services_cidr
  }

  # VPC Flow Logs — cheap observability, priceless when debugging mystery traffic
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# ── 2c. Cloud Router ─────────────────────────────────────────────────────────
# Required backbone for Cloud NAT. The BGP ASN here is only relevant
# if you later add Cloud VPN / Interconnect. For pure NAT, any private ASN works.
resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  project = local.project
  region  = local.region
  network = google_compute_network.vpc_gke.id

  bgp {
    asn = 64514 # Private ASN range: 64512–65534
  }
}

# ── 2d. Cloud NAT ────────────────────────────────────────────────────────────
# Private GKE nodes have no external IPs, so they need NAT to pull images
# from Docker Hub, GitHub, etc. Without this, your pods stay in a beautiful
# but completely useless network timeout loop.
resource "google_compute_router_nat" "nat_config" {
  name    = "nat-config"
  project = local.project
  router  = google_compute_router.nat_router.name
  region  = local.region

  # AUTO_ONLY: Google manages the external IPs. Fine for most workloads.
  # Use MANUAL_ONLY if you need stable egress IPs for allowlisting.
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ALL" # Log both translations and errors
  }
}


###############################################################################
# 3. IAM — SERVICE ACCOUNTS & ROLES
#    Principle: grant only what's needed. "roles/owner" is not a role,
#    it's a future incident report.
###############################################################################

# ── 3a. GKE Node Service Account ─────────────────────────────────────────────
resource "google_service_account" "gke_node_sa" {
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account"
  project      = local.project
}

# Minimum roles required for GKE nodes to function properly
locals {
  gke_node_roles = [
    "roles/logging.logWriter",           # Write logs to Cloud Logging
    "roles/monitoring.metricWriter",     # Push metrics to Cloud Monitoring
    "roles/artifactregistry.reader",     # Pull images from Artifact Registry
    "roles/container.nodeServiceAccount" # Lets nodes register with the control plane
  ]
}

resource "google_project_iam_member" "gke_node_roles" {
  for_each = toset(local.gke_node_roles)

  project = local.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

# ── 3b. Jenkins Service Account ───────────────────────────────────────────────
resource "google_service_account" "jenkins_master_sa" {
  account_id   = "jenkins-master-sa"
  display_name = "Jenkins Master Service Account"
  project      = local.project
}

# container.admin allows Jenkins to authenticate to GKE and run kubectl.
# Scope this to a specific cluster with a binding on the cluster resource
# if you ever move past demo territory.
resource "google_project_iam_member" "jenkins_container_admin" {
  project = local.project
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.jenkins_master_sa.email}"
}


###############################################################################
# 4. COMPUTE — JENKINS BASTION VM
###############################################################################

# ── 4a. Reserve a static external IP ─────────────────────────────────────────
# Ephemeral IPs rotate on VM restart — your DNS and firewall rules will hate you.
resource "google_compute_address" "jenkins_ip" {
  name    = "jenkins-master-ip"
  region  = local.region
  project = local.project
}

# ── 4b. Jenkins VM ───────────────────────────────────────────────────────────
resource "google_compute_instance" "jenkins_master_vm" {
  name         = "jenkins-master-vm"
  project      = local.project
  zone         = local.zone
  machine_type = "e2-standard-2" # 2 vCPU / 8 GB — comfortable for Jenkins

  # Network tag used by firewall rules below to target this VM specifically
  tags = ["jenkins-master"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      # Consider bumping disk_size_gb in production — Jenkins loves eating disk
    }
  }

  network_interface {
    network    = google_compute_network.vpc_gke.id
    subnetwork = google_compute_subnetwork.subnet_1.id

    # Attach the reserved static IP as the external (NAT) address
    access_config {
      nat_ip = google_compute_address.jenkins_ip.address
    }
  }

  service_account {
    email = google_service_account.jenkins_master_sa.email
    # cloud-platform scope + a scoped SA is the correct GCP pattern.
    # Do NOT use "compute-ro" or other legacy shorthand scopes.
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    # OS Login replaces SSH key management — highly recommended over raw keys
    enable-oslogin = "TRUE"
  }
}


###############################################################################
# 5. FIREWALL RULES
#    Tag-based targeting: rules apply only to VMs with the matching network tag.
#    Much safer than subnet-wide or VPC-wide rules.
###############################################################################

# ── 5a. Jenkins UI (8080) + SonarQube (9000) ─────────────────────────────────
# ⚠️  source_ranges = ["0.0.0.0/0"] is fine for a demo.
#     In production, replace with your office/VPN CIDR and sleep better.
resource "google_compute_firewall" "allow_jenkins_ui" {
  name    = "allow-jenkins-ui"
  project = local.project
  network = google_compute_network.vpc_gke.name

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = local.jenkins_ingress
  target_tags   = ["jenkins-master"]

  allow {
    protocol = "tcp"
    ports    = ["8080", "9000"]
  }

  description = "Allow HTTP access to Jenkins and SonarQube UIs"
}

# ── 5b. SSH via Google IAP only ───────────────────────────────────────────────
# 35.235.240.0/20 is Google's IAP TCP forwarding proxy range.
# This means: no direct SSH from the internet — you must go through IAP.
# Which means: audit trails, no exposed port 22, and a much calmer security team.
resource "google_compute_firewall" "allow_jenkins_ssh_iap" {
  name    = "allow-jenkins-ssh-iap"
  project = local.project
  network = google_compute_network.vpc_gke.name

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = [local.iap_cidr]
  target_tags   = ["jenkins-master"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  description = "Allow SSH only via Google Identity-Aware Proxy (IAP)"
}


###############################################################################
# 6. GKE PRIVATE CLUSTER
#    Private nodes: no external IPs on nodes (good).
#    Private endpoint disabled: control plane accessible from authorized CIDRs.
#    VPC-native networking with secondary ranges defined above.
###############################################################################

resource "google_container_cluster" "primary" {
  deletion_protection = false
  name     = "standard-cluster-private-1"
  project  = local.project
  location = local.region # Regional cluster = control plane across 3 zones

  network    = google_compute_network.vpc_gke.id
  subnetwork = google_compute_subnetwork.subnet_1.id

  # Best practice: destroy the default node pool immediately and manage your
  # own via google_container_node_pool. Gives you full lifecycle control.
  remove_default_node_pool = false
  initial_node_count       = 3 # Required placeholder; overridden by node pool

  # REGULAR channel: tested releases, ~2 minor versions behind RAPID.
  # Good balance between stability and staying reasonably current.
  release_channel {
    channel = "REGULAR"
  }

  # VPC_NATIVE enables alias IP addresses — required for private clusters
  # and essential for proper network policy enforcement.
  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"     # Must match subnet secondary range name
    services_secondary_range_name = "gke-services"
  }

  # ── Private Cluster Config ─────────────────────────────────────────────────
  private_cluster_config {
    enable_private_nodes = true  # Nodes get only internal IPs

    # false = control plane is reachable from master_authorized_networks CIDRs.
    # true  = control plane is fully private (kubectl only from inside VPC).
    # Keeping false for demo — flip to true in production + set up bastion tunnel.
    enable_private_endpoint = false

    # /28 is the only allowed size. Must not overlap any existing subnet in the VPC.
    master_ipv4_cidr_block = local.master_cidr
  }

  # Only these CIDRs can reach the API server.
  # subnet_primary covers Jenkins VM → can run kubectl against the cluster.
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = local.subnet_primary
      display_name = "internal-subnet-access"
    }
  }

  # ── Workload Identity ──────────────────────────────────────────────────────
  # Allows pods to impersonate GCP service accounts via Kubernetes SA annotations.
  # The secure, modern alternative to mounting JSON key files into pods.
  workload_identity_config {
    workload_pool = "${local.project}.svc.id.goog"
  }

  # ── Dataplane v2 ───────────────────────────────────────────────────────────
  # eBPF-based dataplane: better network policy, lower overhead, built-in
  # visibility. Choose this over the legacy iptables dataplane for all new clusters.
  datapath_provider = "ADVANCED_DATAPATH"

  # ── Observability ─────────────────────────────────────────────────────────
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true # Google-managed Prometheus — no Prometheus operator needed
    }
  }

  # ── Add-ons ────────────────────────────────────────────────────────────────
  addons_config {
    # HTTP LB: required for Ingress resources backed by GCP Load Balancers
    http_load_balancing {
      disabled = false
    }

    # HPA: enables horizontal pod autoscaling (almost always want this)
    horizontal_pod_autoscaling {
      disabled = false
    }

    # NodeLocal DNSCache: caches DNS at node level — reduces kube-dns load
    # and cuts latency on DNS-heavy workloads considerably
    dns_cache_config {
      enabled = true
    }

    # CSI driver for Persistent Disks (replaces legacy in-tree PD driver)
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }

    # CSI driver for Filestore (NFS-backed ReadWriteMany volumes)
    gcp_filestore_csi_driver_config {
      enabled = true
    }
  }

  # ── Security ──────────────────────────────────────────────────────────────
  # Binary Authorization: DISABLED for demo. In production, use PROJECT_SINGLETON_POLICY_ENFORCE
  # to ensure only signed, attested images are deployed.
  binary_authorization {
    evaluation_mode = "DISABLED"
  }

  # Security Posture: scans workloads for known vulnerabilities and misconfigs
  security_posture_config {
    mode = "DISABLED"
  }

  # ── Default Node Config ────────────────────────────────────────────────────
  # NOTE: This block applies to the placeholder default node pool that is
  # immediately deleted. Your real node config lives in google_container_node_pool.
  node_config {
    machine_type = "e2-custom-2-5120" # 2 vCPU / 5 GB — tight but workable for demo
    image_type   = "COS_CONTAINERD"   # Container-Optimized OS; hardened, minimal
    disk_type    = "pd-standard"
    disk_size_gb = 20

    service_account = google_service_account.gke_node_sa.email

    # Spot VMs: up to 91% cheaper, but preemptible. Perfect for demo/dev.
    # Do NOT use spot=true for stateful or latency-sensitive production workloads.
    spot = true

    metadata = {
      # Disables the legacy instance metadata API (v1) — a known attack vector
      disable-legacy-endpoints = "true"
    }

    shielded_instance_config {
      enable_secure_boot          = true # Prevents boot-level rootkits
      enable_integrity_monitoring = true # Detects runtime tampering
    }

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # Spread nodes across 3 zones for HA. If us-central1-a has a bad day,
  # your workloads won't know (or care).
  node_locations = [
    "us-central1-a",
    "us-central1-b",
    "us-central1-c",
  ]

  lifecycle {
    # GKE auto-applies resource labels to nodes during upgrades.
    # Ignoring prevents Terraform from treating that as a diff and
    # trying to re-create nodes every plan. Trust me, learn from this one.
    ignore_changes = [
      node_config[0].resource_labels,
    ]
  }

  # Cluster creation will fail silently in mysterious ways if NAT isn't ready
  # or if the node SA doesn't have container.nodeServiceAccount yet.
  depends_on = [
    google_compute_router_nat.nat_config,
    google_project_iam_member.gke_node_roles,
  ]
}
