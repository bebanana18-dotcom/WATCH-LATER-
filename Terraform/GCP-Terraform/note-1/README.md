# Terraform on GCP — STAR Notes

## 1) Terraform Basics

### Situation
You want to define infrastructure as code instead of clicking around in the console like it is 2009.

### Task
Understand Terraform file structure, syntax, and the basic workflow.

### Action
Terraform configuration is written in `.tf` files.

General syntax:

```hcl
<BLOCK> "<TYPE>" "<NAME>" {
  <ARGUMENTS>
}
```

The most common blocks are:

- `resource` → create infrastructure
- `provider` → configure a provider
- `variable` → declare input values
- `output` → print values after apply
- `data` → read existing infrastructure
- `terraform` → Terraform settings, including required providers and backend config

### Result
You can describe infrastructure in code, validate it, plan changes, apply them, and destroy them safely.

---

## 2) Terraform Workflow

### Situation
You need to create infrastructure and verify it before applying.

### Task
Run Terraform in the correct order.

### Action
Typical command flow:

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

Useful flags:

```bash
terraform apply -auto-approve
terraform destroy -auto-approve
```

### Result
Terraform downloads providers, checks syntax, previews changes, applies them, and later removes them.

---

## 3) Resources and Providers

### Situation
You want Terraform to create something, such as a file, VM, or GCS bucket.

### Task
Understand the difference between provider, resource type, and resource name.

### Action
Example:

```hcl
resource "local_file" "my_file" {
  filename = "main.txt"
  content  = "this is cool file"
}
```

Breakdown:

- `resource` → block type
- `local` → provider
- `file` → resource type
- `my_file` → Terraform resource name / identifier

The resource name is Terraform's pointer to the real object. It helps Terraform track, update, and destroy the right thing.

### Result
Terraform knows what to create, how to track it, and what to delete later without becoming a menace to unrelated resources.

---

## 4) Installing and Configuring Providers

### Situation
You need a cloud provider such as Google Cloud.

### Task
Install and configure the provider inside Terraform.

### Action
Example `terraform.tf` or `versions.tf`:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.25.0"
    }
  }
}

provider "google" {
  project = "my-gcp-project"
  region  = "us-central1"
}
```

After `terraform init`, Terraform downloads the provider into `.terraform/providers/...`.

### Result
Terraform can talk to GCP and manage real cloud resources.

---

## 5) Creating a GCS Bucket with Terraform

### Situation
You want to create a Google Cloud Storage bucket.

### Task
Define a bucket resource in Terraform.

### Action
```hcl
resource "google_storage_bucket" "terra_bucket" {
  name                        = "my-bucket-xyz"
  location                    = "US"
  uniform_bucket_level_access = true
}
```

### Result
Terraform creates a bucket in GCP with IAM-based access control enabled.

---

## 6) Creating a Compute Engine VM

### Situation
You want to provision a VM on GCP with a firewall, service account, startup script, and outputs.

### Task
Build the VM using reusable Terraform blocks.

### Action

#### Variables
```hcl
variable "google_compute_instance_machine_type" {
  default = "e2-micro"
  type    = string
}

variable "vm_root_storage_size" {
  default = 10
  type    = number
}

variable "os-image" {
  default = "debian-cloud/debian-11"
  type    = string
}
```

#### Read existing VPC
```hcl
data "google_compute_network" "default" {
  name = "default"
}
```

#### Firewall rules
```hcl
resource "google_compute_firewall" "terra_allow_http" {
  name    = "terra-allow-http"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  target_tags   = ["terra-http"]
  source_ranges = ["0.0.0.0/0"]
}
```

```hcl
resource "google_compute_firewall" "terra_allow_ssh" {
  name    = "terra-allow-ssh"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["terra-ssh"]
  source_ranges = ["0.0.0.0/0"]
}
```

#### Service account
```hcl
resource "google_service_account" "terra_vm_sa" {
  account_id   = "terra-vm-sa"
  display_name = "custom sa for compute engine vm"
}
```

#### VM instance
```hcl
resource "google_compute_instance" "vm_1" {
  name         = "my-vm"
  machine_type = var.google_compute_instance_machine_type
  zone         = "us-central1-b"
  tags         = ["terra-ssh", "terra-http"]

  boot_disk {
    initialize_params {
      image = var.os-image
      size  = var.vm_root_storage_size
    }
  }

  network_interface {
    network = data.google_compute_network.default.name
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "<h1>welcome to nginx</h1>" | sudo tee /var/www/html/index.html
  EOF

  metadata = {
    ssh-keys = file("./terrakey-my-vm1.pub")
  }

  service_account {
    email  = google_service_account.terra_vm_sa.email
    scopes = ["cloud-platform"]
  }
}
```

#### Outputs
```hcl
output "vm_public_ip" {
  value = google_compute_instance.vm_1.network_interface[0].access_config[0].nat_ip
}

output "vm_private_ip" {
  value = google_compute_instance.vm_1.network_interface[0].network_ip
}

output "vm_instance_id" {
  value = google_compute_instance.vm_1.instance_id
}
```

### Result
You get a VM with network access, nginx installed on boot, SSH access via key, and outputs for the IPs and instance ID.

---

## 7) Variables and `.tfvars`

### Situation
You want the same Terraform code to work for multiple environments.

### Task
Separate code from values.

### Action
Define variables:

```hcl
variable "region" {}
variable "instance_type" {}
```

Provide values in `terraform.tfvars`:

```hcl
region        = "us-central1"
instance_type = "e2-medium"
```

For environment-specific values:

```hcl
# dev.tfvars
instance_type = "e2-micro"
```

```hcl
# prod.tfvars
instance_type = "e2-standard-4"
```

Use it with:

```bash
terraform apply -var-file="dev.tfvars"
```

Important priority order:

1. CLI `-var`
2. `-var-file`
3. `.tfvars`
4. default values in `.tf` files

### Result
You can reuse the same Terraform code across environments without editing infrastructure logic every time.

---

## 8) `count`, `for_each`, and `depends_on`

### Situation
You need to create multiple similar resources, or control ordering.

### Task
Choose the right meta-argument.

### Action

#### Use `count` for identical resources
```hcl
resource "google_compute_instance" "my_vm" {
  count        = 2
  name         = "my-vm-${count.index + 1}"
  machine_type = "e2-micro"
}
```

#### Use `for_each` for distinct resources
```hcl
resource "google_compute_instance" "my_vm" {
  for_each = tomap({
    "my-vm-micro"  = "e2-micro"
    "my-vm-medium"  = "e2-medium"
  })

  name         = each.key
  machine_type = each.value
}
```

#### Use `depends_on` when Terraform cannot infer ordering
```hcl
resource "google_compute_instance" "my_vm" {
  depends_on = [google_compute_network.vpc]
}
```

### Result
`count` helps when resources are identical, `for_each` is better for distinct items, and `depends_on` fixes hidden ordering issues.

---

## 9) Conditional Expressions

### Situation
You want different values for dev and prod.

### Task
Use a Terraform conditional expression.

### Action
Syntax:

```hcl
condition ? value_if_true : value_if_false
```

Example:

```hcl
volume_size = var.env == "prd" ? 50 : var.ec2_default_root_storage_size
```

### Result
Terraform can assign values dynamically based on the environment.

---

## 10) Terraform State

### Situation
Terraform must remember what it created.

### Task
Understand state and why it matters.

### Action
Terraform stores resource metadata in `terraform.tfstate`. This file tracks the real-world infrastructure Terraform believes exists.

Useful commands:

```bash
terraform state list
terraform state show google_service_account.terra_vm_sa
terraform state rm google_service_account.terra_vm_sa
terraform refresh
```

### Result
Terraform can compare code to real infrastructure and decide what to create, change, or destroy.

---

## 11) Remote Backend on GCS

### Situation
Local state becomes unsafe when more than one person works on the same infrastructure.

### Task
Store state centrally and lock it during operations.

### Action
Use a GCS backend:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.25.0"
    }
  }

  backend "gcs" {
    bucket = "your-terraform-state"
    prefix = "state/terraform"
  }
}
```

Create and configure the bucket:

```bash
gcloud storage buckets create gs://your-terraform-state   --project=your-gcp-project   --location=us-central1   --uniform-bucket-level-access

gcloud storage buckets update gs://your-terraform-state --versioning
gcloud storage buckets update gs://your-terraform-state --pap
```

### Result
State is stored remotely, versioned, and protected from accidental local damage.

---

## 12) State Locking

### Situation
Two people should not run `terraform apply` on the same state at the same time.

### Task
Prevent concurrent state corruption.

### Action
GCS creates a lock object during an apply, usually with a `.tflock` entry.

If Terraform gets stuck:

```bash
terraform force-unlock <LOCK_ID>
```

Use this only when you are sure the old operation is dead.

### Result
Terraform avoids split-brain state and bad concurrent writes.

---

## 13) Importing Existing Resources

### Situation
A resource already exists in GCP, but Terraform does not know about it.

### Task
Bring it under Terraform management.

### Action
Write the resource block first:

```hcl
resource "google_compute_instance" "my_vm" {
  name = "my-vm"
  zone = "us-central1-a"
}
```

Then import:

```bash
terraform import google_compute_instance.my_vm   projects/my-project/zones/us-central1-a/instances/my-vm
```

Then inspect and align configuration:

```bash
terraform state show google_compute_instance.my_vm
terraform plan
```

### Result
Terraform adds the resource to state, and you then adjust the config until plan shows no drift.

---

## 14) Modules

### Situation
You want reusable Terraform code.

### Task
Package infrastructure into modules.

### Action
A module is just a folder with `.tf` files.

Example structure:

```text
april-07/
├── main.tf
├── terraform.tfstate
└── modules/
    └── ce_vm/
        ├── main.tf
        ├── variable.tf
        └── output.tf
```

Root module usage:

```hcl
module "ce_vm" {
  source = "./modules/ce_vm"

  network_vpc_name   = "default"
  machine_type_value = "e2-micro"
  image_name         = "debian-cloud/debian-12"
}
```

Output usage:

```hcl
output "vm_public_ip" {
  value = module.ce_vm.vm_public_ip
}
```

### Result
You can reuse infrastructure logic across projects and environments without copy-pasting the same code everywhere.

---

## 15) Workspaces

### Situation
You want multiple state files using the same code.

### Task
Understand what workspaces really do.

### Action
Workspaces isolate state, not code.

Examples:

- `default` → one state
- `dev` → another state
- `prod` → another state

Use workspace-aware naming:

```hcl
instance_name = "${var.instance_name}-${terraform.workspace}"
```

Create a workspace:

```bash
terraform workspace new dev
terraform apply
```

### Result
You can manage separate state snapshots for the same codebase, but workspaces are not full environment isolation.

---

## 16) Better Production Pattern

### Situation
Workspaces are convenient, but production usually needs stronger separation.

### Task
Use directory separation.

### Action
Recommended structure:

```text
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── backend.tf
│       └── terraform.tfvars
└── modules/
    ├── compute/
    └── network/
```

### Result
Each environment has its own code path and backend, which reduces accidental cross-environment damage.

---

## 17) Quick Cheat Sheet

### Situation
You need the important commands and patterns in one place.

### Task
Keep a compact reference.

### Action

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
terraform output
terraform show
terraform state list
terraform state show <resource>
terraform import <type>.<name> <id>
terraform force-unlock <LOCK_ID>
```

### Result
You can work faster and make fewer mistakes.

---

## 18) Common Mistakes to Avoid

### Situation
Terraform can be unforgiving in the most entertaining way.

### Task
Avoid the usual traps.

### Action
- Do not commit `terraform.tfstate` to Git.
- Do not forget `terraform init`.
- Do not assume `.tfvars` auto-load in every case.
- Do not use the wrong `source_ranges` for firewall rules.
- Do not confuse resource name with the real cloud resource name.
- Do not use workspaces as a replacement for proper environment separation.

### Result
Less chaos, fewer late-night incidents, and fewer conversations that start with “Terraform said it was safe.”
