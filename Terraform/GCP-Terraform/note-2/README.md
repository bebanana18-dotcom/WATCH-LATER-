# 🏗️ Terraform — Complete Notes (TWS)
> **STAR Method**: **S**ituation → **T**ask → **A**ction → **R**esult  
> Every concept explained as: *Why does this exist? What problem does it solve? How do you use it? What do you get?*

---

## 📋 Table of Contents
1. [Core Syntax](#1-core-syntax)
2. [Providers](#2-providers)
3. [Main Commands](#3-main-commands)
4. [Variables & tfvars](#4-variables--tfvars)
5. [Outputs](#5-outputs)
6. [Data Block](#6-data-block)
7. [count & for_each](#7-count--for_each)
8. [depends_on](#8-depends_on)
9. [Conditional Expressions](#9-conditional-expressions)
10. [Terraform State](#10-terraform-state)
11. [Terraform Import](#11-terraform-import)
12. [Remote Backend & State Locking (GCS)](#12-remote-backend--state-locking-gcs)
13. [Modules](#13-modules)
14. [Workspaces & Environment Management](#14-workspaces--environment-management)
15. [Full GCP VM Example](#15-full-gcp-vm-example)
16. [.gitignore Cheatsheet](#16-gitignore-cheatsheet)
17. [Master Command Cheatsheet](#17-master-command-cheatsheet)

---

## 1. Core Syntax

### ⭐ STAR
| | |
|---|---|
| **Situation** | You need to define cloud infrastructure in a repeatable, automated way |
| **Task** | Write a `.tf` file that describes what resources you want |
| **Action** | Use Terraform's block-based HCL syntax |
| **Result** | Terraform reads your `.tf` files and creates/manages the real infrastructure |

### Syntax Structure

```hcl
<BLOCK> <PARAMETERS> {
  <argument> = <value>
  <argument> = <value>
}
```

### Block Types — Quick Reference

| Block | Purpose | When to Use |
|-------|---------|-------------|
| `resource` | Create/manage infrastructure | Creating a VM, bucket, firewall |
| `output` | Print values to CLI | Showing IP addresses after apply |
| `variable` | Store reusable input values | Machine type, region, image name |
| `provider` | Configure the cloud platform | Setting GCP project, region |
| `terraform` | Configure Terraform itself | Pinning provider versions, backend |
| `data` | Read existing resources (read-only) | Reference a VPC you didn't create |
| `module` | Call reusable module folders | Reusing VM config across projects |
| `locals` | Store computed/derived values | Combining workspace + variable name |

### Example — Create a Local File

```hcl
resource "local_file" "my_file" {
  filename = "main.txt"
  content  = "this is cool file"
}
```

**Anatomy breakdown:**
```
resource   "local_file"   "my_file"   {
  ^BLOCK    ^PROVIDER_TYPE  ^RESOURCE-IDENTITY (pointer/label)
```

> ⚠️ **Resource Identity** (`my_file`) is Terraform's internal pointer.  
> The actual filename (`main.txt`) can be different.  
> This is how `terraform destroy` knows *which* resource to delete — without it, it might nuke files it never created.

---

## 2. Providers

### ⭐ STAR
| | |
|---|---|
| **Situation** | Terraform needs to talk to a cloud API (GCP, AWS, Azure) |
| **Task** | Install and configure the correct provider plugin |
| **Action** | Declare `required_providers` in a `terraform {}` block, then run `terraform init` |
| **Result** | Terraform downloads the plugin and can now create resources on that platform |

### Understanding Provider Naming

```
local_file       →   local  = provider,  file       = resource type
aws_s3_bucket    →   aws    = provider,  s3_bucket  = resource type
google_compute_instance → google = provider, compute_instance = resource type
```

### Default vs External Providers

- `local` — **built-in**, no installation needed
- `aws`, `google`, `azurerm` — must be declared and installed via `terraform init`

### Installing Google Cloud Provider

**`terraform.tf`** (suggested filename for provider config):

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.25.0"   # Always pin versions — "latest" = "breaks eventually"
    }
  }
}

provider "google" {
  project = "your-gcp-project-id"
  region  = "us-central1"
  # Note: zone is NOT set here — set per-resource
}
```

Then run:
```bash
terraform init
```

### Verify Provider Was Installed

```bash
ls .terraform/providers/registry.terraform.io/hashicorp/
# Should show: local  google
```

---

## 3. Main Commands

### ⭐ STAR
| | |
|---|---|
| **Situation** | You have written your `.tf` files and need to turn them into real infrastructure |
| **Task** | Run Terraform commands in the correct order |
| **Action** | Follow the init → validate → plan → apply lifecycle |
| **Result** | Infrastructure is created, modified, or destroyed safely |

### The Lifecycle (in order)

```bash
# Step 1 — One time per project (downloads providers, sets up backend)
terraform init

# Step 2 — Write your .tf files (this is on you)

# Step 3 — Check syntax is valid
terraform validate

# Step 4 — Dry run: see what WILL happen, nothing is created yet
terraform plan

# Step 5 — Actually create/update the infrastructure
terraform apply                   # Asks for confirmation
terraform apply -auto-approve     # Skips confirmation (use in CI/CD)

# Step 6 — Tear it all down
terraform destroy                 # Asks for confirmation
terraform destroy -auto-approve   # Skips confirmation
```

### Useful Extras

```bash
terraform show                    # Full state dump — see everything Terraform knows
terraform output                  # Print all output values
terraform state list              # List all resources Terraform is tracking
terraform fmt                     # Auto-format your .tf files (run this often)
```

---

## 4. Variables & tfvars

### ⭐ STAR
| | |
|---|---|
| **Situation** | Hardcoding values (machine type, image name) makes configs inflexible and environment-specific |
| **Task** | Extract values into variables so the same code works for dev and prod |
| **Action** | Declare variables in `variable.tf`, assign values in `.tfvars` files |
| **Result** | Same infrastructure code, different environments — no copy-paste, no hardcoding |

### Declaring Variables (`variable.tf`)

```hcl
# With default value
variable "machine_type" {
  description = "GCP machine type for the VM"
  type        = string
  default     = "e2-micro"
}

# Without default (must be provided externally)
variable "vm_storage_size" {
  description = "Root disk size in GB"
  type        = number
}

variable "os_image" {
  description = "OS image for the VM"
  type        = string
}
```

### Using Variables in Resources

```hcl
resource "google_compute_instance" "vm" {
  machine_type = var.machine_type   # Reference with var.<name>

  boot_disk {
    initialize_params {
      image = var.os_image
      size  = var.vm_storage_size
    }
  }
}
```

### Assigning Values — `.tfvars` Files

**`terraform.tfvars`** (auto-loaded by Terraform):
```hcl
machine_type    = "e2-micro"
vm_storage_size = 10
os_image        = "debian-cloud/debian-11"
```

**`dev.tfvars`** (manual, for dev environment):
```hcl
machine_type    = "e2-micro"
vm_storage_size = 10
```

**`prod.tfvars`** (manual, for production):
```hcl
machine_type    = "e2-standard-4"
vm_storage_size = 50
```

Apply with specific var file:
```bash
terraform apply -var-file="dev.tfvars"
terraform apply -var-file="prod.tfvars"
```

### Variable Priority (Highest → Lowest)

```
1. CLI flag:        terraform apply -var="machine_type=e2-medium"
2. -var-file flag:  terraform apply -var-file="prod.tfvars"
3. terraform.tfvars (auto-loaded)
4. default in variables.tf
```

### Types of `.tfvars` Files

| Type | Files | Behaviour |
|------|-------|-----------|
| Auto-loaded | `terraform.tfvars`, `terraform.tfvars.json`, `*.auto.tfvars` | Loaded automatically every time |
| Manual | `dev.tfvars`, `prod.tfvars`, any custom name | Must pass `-var-file=` explicitly |

### ⚠️ Golden Rules for `.tfvars`

```
✅ DO:   Use for environment-specific values
✅ DO:   Add to .gitignore if it contains real values
✅ DO:   Commit a .tfvars.example with blank/placeholder values

❌ DON'T: Commit real secrets to Git
❌ DON'T: Store API keys or passwords here — use Secret Manager or env vars
❌ DON'T: Assume all .tfvars files auto-load — only terraform.tfvars does
```

---

## 5. Outputs

### ⭐ STAR
| | |
|---|---|
| **Situation** | After `terraform apply`, you need to know the VM's IP address or other generated values |
| **Task** | Extract and display resource attributes after creation |
| **Action** | Define `output` blocks referencing resource attributes |
| **Result** | Values are printed to the terminal after apply, and accessible via `terraform output` |

```hcl
# output.tf

output "vm_public_ip" {
  value = google_compute_instance.vm-1.network_interface[0].access_config[0].nat_ip
}

output "vm_private_ip" {
  value = google_compute_instance.vm-1.network_interface[0].network_ip
}

output "vm_instance_id" {
  value = google_compute_instance.vm-1.instance_id
}
```

> 📝 `network_interface[0]` — index `[0]` because a VM can theoretically have multiple NICs. In practice you'll almost never see more than one, but Terraform requires the index.

---

## 6. Data Block

### ⭐ STAR
| | |
|---|---|
| **Situation** | You want to use an existing resource (like the default VPC) without recreating it |
| **Task** | Reference it in Terraform without managing its lifecycle |
| **Action** | Use a `data` block to do a read-only lookup |
| **Result** | Terraform fetches the resource's attributes so you can reference them — it creates nothing |

```hcl
# Fetch the existing default VPC
data "google_compute_network" "default" {
  name = "default"
}

# Use it in a resource
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = data.google_compute_network.default.name  # ← reference via data.<type>.<name>.<attribute>
}
```

**Key distinction:**

| `resource` block | `data` block |
|-----------------|-------------|
| Creates/manages the resource | Only reads/references it |
| `terraform destroy` will delete it | `terraform destroy` ignores it |
| You own its lifecycle | It existed before Terraform |

---

## 7. count & for_each

### ⭐ STAR
| | |
|---|---|
| **Situation** | You need multiple identical (or similar) resources without copy-pasting blocks |
| **Task** | Create N resources using a loop construct |
| **Action** | Use `count` for identical resources, `for_each` for distinct configurations |
| **Result** | Clean, DRY code that creates multiple resources from a single block |

### `count` — When all resources are identical

```hcl
resource "google_compute_instance" "vm" {
  count        = 3
  name         = "my-vm-${count.index + 1}"   # my-vm-1, my-vm-2, my-vm-3
  machine_type = "e2-micro"
}
```

**Output all IPs with splat expression `[*]`:**
```hcl
output "all_vm_ips" {
  value = google_compute_instance.vm[*].network_interface[0].access_config[0].nat_ip
}
```

> ⚠️ **count gotcha:** If you delete the middle resource (index 1 of 3), Terraform re-indexes and **destroys + recreates** resources 1 and 2 unnecessarily. Use `for_each` to avoid this.

### `for_each` — When resources need distinct configs (preferred)

```hcl
resource "google_compute_instance" "vm" {
  for_each = tomap({
    vm-small  = "e2-micro"
    vm-medium = "e2-medium"
  })

  name         = each.key    # "vm-small" or "vm-medium"
  machine_type = each.value  # "e2-micro" or "e2-medium"
}
```

**Output with `for` expression:**
```hcl
# Map output (most common)
output "vm_names_map" {
  value = { for k, vm in google_compute_instance.vm : k => vm.name }
}

# List output
output "vm_names_list" {
  value = [for vm in google_compute_instance.vm : vm.name]
}
```

### When to Use What

| Use | When |
|-----|------|
| `count` | Resources are truly identical, simple numbered copies |
| `for_each` | Resources need distinct names or different configs (prefer this in real-world) |
| `[*]` splat | Getting a list of attributes from `count`-based resources |

---

## 8. depends_on

### ⭐ STAR
| | |
|---|---|
| **Situation** | Terraform builds a dependency graph automatically — but sometimes it can't infer a dependency |
| **Task** | Explicitly tell Terraform "create resource B only after resource A exists" |
| **Action** | Add `depends_on` meta-argument to the dependent resource |
| **Result** | Terraform enforces creation order, preventing race conditions |

```hcl
resource "google_compute_instance" "vm" {
  name = "my-vm"
  # ...

  depends_on = [
    google_compute_network.vpc,
    google_compute_firewall.allow_http
  ]
}
```

**When to use `depends_on`:**
- Hidden dependencies (resource B needs A to exist, but doesn't directly reference it)
- Ordering issues Terraform can't infer from the config
- Preventing race conditions at provisioning time

---

## 9. Conditional Expressions

### ⭐ STAR
| | |
|---|---|
| **Situation** | Dev needs a 10 GB disk, prod needs 50 GB — hardcoding either breaks the other environment |
| **Task** | Assign different values based on a condition (environment, workspace, etc.) |
| **Action** | Use the ternary operator: `condition ? value_if_true : value_if_false` |
| **Result** | One codebase that behaves differently per environment automatically |

```hcl
# Syntax
condition ? value_if_true : value_if_false

# Real example — disk size based on environment
volume_size = var.env == "prod" ? 50 : var.default_storage_size

# Real example — machine type based on workspace
machine_type = terraform.workspace == "prod" ? "n2-standard-4" : "e2-micro"
```

| Environment | Result |
|-------------|--------|
| `var.env = "prod"` | 50 GB disk |
| `var.env = "dev"` | Uses `var.default_storage_size` |

---

## 10. Terraform State

### ⭐ STAR
| | |
|---|---|
| **Situation** | Terraform needs to know what infrastructure currently exists to plan future changes |
| **Task** | Maintain a record of all resources managed by Terraform |
| **Action** | Terraform automatically manages `terraform.tfstate` — a JSON file mapping your config to real resources |
| **Result** | Terraform can detect drift, plan updates, and destroy the right resources |

### The Problem State Solves

Without state, Terraform wouldn't know:
- Which cloud VM corresponds to which `resource` block
- Whether to create, update, or skip a resource
- What to delete on `terraform destroy`

### When State Goes Stale

```
You create VMs via Terraform
→ You manually stop them from GCP Console (ClickOps 😔)
→ terraform.tfstate still shows them as "RUNNING"
→ Terraform is now living in a fantasy
```

**Fix:**
```bash
# Sync state with real infrastructure
terraform refresh

# Or just run apply — it refreshes too AND is actually useful
terraform apply
```

> `terraform refresh` alone is mostly unnecessary. `terraform apply` handles it and does useful things on top.

### State Management Commands

```bash
# List all resources Terraform is tracking
terraform state list

# Show full details of one specific resource
terraform state show google_compute_instance.vm

# Remove a resource from state WITHOUT destroying the real resource
# Use when: you want to keep the resource alive but stop managing it with Terraform
terraform state rm google_service_account.terra-vm-sa
```

> ⚠️ After `terraform state rm`, running `terraform destroy` will **not** touch that resource. It's been orphaned intentionally.

---

## 11. Terraform Import

### ⭐ STAR
| | |
|---|---|
| **Situation** | Someone created infrastructure manually in the GCP console (ClickOps) and now you want Terraform to manage it |
| **Task** | Bring an existing resource under Terraform's control |
| **Action** | Write the `.tf` block first, then run `terraform import` with the resource's cloud ID |
| **Result** | Terraform adds the resource to state — you then fix your `.tf` until `terraform plan` shows no changes |

### What Import Does (and Doesn't Do)

| Action | Result |
|--------|--------|
| ✅ Adds resource to `terraform.tfstate` | Yes |
| ❌ Creates `.tf` config code for you | No — that's your job |
| ❌ Modifies the real infrastructure | No — read-only operation |

### Step-by-Step Workflow

```bash
# Step 1: Write the .tf block FIRST (non-negotiable — no block = instant error)
resource "google_compute_instance" "my_vm" {
  name = "my-vm"
  zone = "us-central1-a"
}

# Step 2: Run the import with the GCP resource ID
terraform import google_compute_instance.my_vm \
  projects/my-project/zones/us-central1-a/instances/my-vm

# Step 3: See what Terraform actually sees (copy this into your .tf file)
terraform state show google_compute_instance.my_vm

# Step 4: Run plan and fix drift until you see:
terraform plan
# → "No changes. Infrastructure is up-to-date."
```

### GCP Resource ID Formats

| Resource | ID Format |
|----------|-----------|
| VM Instance | `projects/<project>/zones/<zone>/instances/<name>` |
| Firewall Rule | `projects/<project>/global/firewalls/<name>` |
| Service Account | `projects/<project>/serviceAccounts/<email>` |
| GCS Bucket | `<bucket-name>` |

### Common Mistakes

```bash
# ❌ Mistake 1: No resource block
terraform import google_compute_instance.my_vm ...
# Error: resource block doesn't exist in .tf
# Fix: Write the block FIRST. Always. Forever.

# ❌ Mistake 2: Name mismatch
# .tf file has:   resource "google_compute_instance" "vm"
# import command: terraform import google_compute_instance.my_vm ...
# Error: "vm" ≠ "my_vm" — they must match exactly

# ❌ Mistake 3: Expecting import to generate .tf code
# It doesn't. It never will. Use `terraform state show` to copy the config.
```

### When to Use Import

```
✅ Use when:
   - Resources were manually created in the GCP console
   - Migrating existing infra to Terraform
   - Previous team didn't believe in IaC (bless their soul)

❌ Don't use when:
   - You can recreate the resource from scratch with Terraform
   - Starting a fresh project
```

---

## 12. Remote Backend & State Locking (GCS)

### ⭐ STAR
| | |
|---|---|
| **Situation** | Two engineers are working on the same infrastructure. Both have local `terraform.tfstate` files. Both think they're the source of truth. Neither is. |
| **Task** | Centralize state storage and prevent simultaneous applies from corrupting it |
| **Action** | Store state in a GCS bucket (Remote Backend) and enable state locking |
| **Result** | One source of truth, concurrent apply protection, full version history for rollbacks |

### The Problem Visualized

```
Engineer A                    Engineer B
terraform init                terraform init
(local tfstate A)             (local tfstate B)
terraform apply  ←── Both apply simultaneously ──→  terraform apply
         💥 A's changes overwrite B's (or vice versa) 💥
```

### The Naive (Wrong) Fix

> "Let's commit `terraform.tfstate` to GitHub!"

The `terraform.tfstate` file contains:
- Resource IDs and metadata
- **Sensitive values** (passwords, keys, connection strings)
- Enough information to ruin your week if it leaks

Treat it **exactly like an API key** — you wouldn't commit that to GitHub either.

### The Right Fix: GCS Remote Backend

```
Problem                          Solution
────────────────────────────────────────────────────────────
Multiple conflicting state files → Single centralized state in GCS
State file leaking on GitHub     → Private, access-controlled bucket
No rollback on bad applies       → Versioning enables state history
```

### How State Locking Works

When `terraform apply` starts:
1. Terraform **writes** a lock object → `gs://your-bucket/prefix/default.tflock`
2. All other `apply` requests are **rejected** while locked
3. Operation completes → lock object is **deleted**

The `.tflock` file:
```json
{
  "ID": "abc-123-xyz",
  "Operation": "OperationTypeApply",
  "Who": "engineer-a@machine",
  "Created": "2024-01-01T00:00:00Z"
}
```

### GCP vs AWS: State Locking Comparison

| Feature | AWS (S3 + DynamoDB) | GCP (GCS) |
|---------|--------------------|-----------| 
| State Storage | S3 Bucket | GCS Bucket |
| Lock Mechanism | DynamoDB Table | GCS Object (`.tflock`) |
| Extra infrastructure needed? | ✅ Yes (spin up DynamoDB) | ❌ No |
| Native support | ❌ Bolted on | ✅ Built-in |
| Additional cost | DynamoDB charges extra | Just GCS storage |

```
AWS → State lock = S3 (storage) + DynamoDB (lock) = 2 services
GCP → State lock = GCS (storage) + GCS API  (lock) = 1 service
```

### Step-by-Step: Setting Up GCS Remote Backend

```bash
# 1. Create the GCS bucket
gcloud storage buckets create gs://your-terraform-state \
  --project=your-gcp-project \
  --location=us-central1 \
  --uniform-bucket-level-access

# 2. Enable versioning (for rollbacks)
gcloud storage buckets update gs://your-terraform-state --versioning

# 3. Enforce public access prevention
gcloud storage buckets update gs://your-terraform-state --pap

# 4. Verify
gcloud storage buckets describe gs://your-terraform-state
```

**Add backend config to `terraform.tf`:**

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

Then run `terraform init` — Terraform migrates local state to GCS automatically.

### Testing That Locking Works

Open two terminals. Run `terraform apply` in both simultaneously:

```
Terminal 1: Acquiring state lock. This may take a few moments...
Terminal 2: Error: Error acquiring the state lock
            Error message: writing "gs://your-bucket/.../default.tflock" failed:
            googleapi: Error 412: At least one of the pre-conditions you specified did not hold.
```

Lock acquired. Chaos averted.

### Force Unlock (Emergency Use Only)

```bash
terraform force-unlock <LOCK_ID>
```

> ⚠️ Use ONLY when you are **certain** the previous operation is dead — not just slow. Using this while someone is actively applying is the infrastructure equivalent of pulling the emergency brake on a moving train.

---

## 13. Modules

### ⭐ STAR
| | |
|---|---|
| **Situation** | You're copy-pasting the same VM config across 3 different projects. Something breaks in one, now you have to fix 3 places. |
| **Task** | Extract reusable infrastructure logic into a module |
| **Action** | Create a folder with `.tf` files, call it from a root `main.tf` using a `module` block |
| **Result** | One definition, used everywhere. Fix it once, fixed everywhere. |

### What is a Module?

A module is just **a folder with `.tf` files**.

- The folder you run `terraform apply` from = **root module**
- Any folder you call from the root = **child module**

Think of it as a function: inputs (variables) → work → outputs.

### Project Structure

```
april-07/
├── main.tf                  ← Root module (orchestrates everything)
├── terraform.tf             ← Provider + backend config
└── modules/
    └── ce_vm/
        ├── main.tf          ← Actual GCP resource definitions
        ├── variable.tf      ← Module's input variables
        └── output.tf        ← What the module exposes back
```

### How It Works — The Three Files

**Root `main.tf` — calls the module:**
```hcl
module "ce_vm" {
  source = "./modules/ce_vm"    # Where to find the module

  # Passing values into the module's variables
  network_vpc_name   = "default"
  machine_type_value = "e2-micro"
  image_name         = "debian-cloud/debian-12"
}

# Accessing the module's output
output "vm_public_ip" {
  value = module.ce_vm.vm_public_ip
}
```

**Module `variable.tf` — declares accepted inputs:**
```hcl
variable "machine_type_value" {
  description = "GCP machine type for the VM"
  type        = string
}

variable "image_name" {
  description = "OS image for the VM"
  type        = string
}

variable "network_vpc_name" {
  description = "VPC network name"
  type        = string
}
```

**Module `output.tf` — exposes values back to root:**
```hcl
output "vm_public_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}
```

### Module Source Options

```hcl
# Local folder
source = "./modules/ce_vm"

# GitHub public repo (subdirectory via //)
source = "github.com/your-org/terraform-modules//ce_vm"

# GitHub with pinned tag (recommended for stability)
source = "github.com/your-org/terraform-modules//ce_vm?ref=v1.2.0"

# GitHub private repo via SSH
source = "git@github.com:your-org/terraform-modules.git//ce_vm?ref=main"

# Terraform Registry
source  = "terraform-google-modules/vm/google"
version = "~> 10.0"
```

> 📌 "Latest" is just "works until it doesn't." Always pin versions with `?ref=v1.x.x`.

### Best Practice: `main.tf.example` Pattern

Same idea as `.env` / `.env.example`:

```
What you COMMIT → main.tf.example    (blank placeholder values, safe to share)
What you DON'T COMMIT → main.tf      (real values, add to .gitignore)
```

**`main.tf.example`:**
```hcl
module "ce_vm" {
  source = "github.com/your-org/terraform-modules//ce_vm?ref=v1.0.0"

  network_vpc_name   = ""  # e.g. "default"
  machine_type_value = ""  # e.g. "e2-micro"
  image_name         = ""  # e.g. "debian-cloud/debian-12"
}
```

**Onboarding a new developer:**
```bash
git clone github.com/your-org/your-infra-repo
cd your-infra-repo
cp main.tf.example main.tf
# Edit main.tf with real values
terraform init && terraform plan
```

### Files — What to Commit vs Not

| File | Commit? | Reason |
|------|---------|--------|
| `modules/*/main.tf` | ✅ Yes | Reusable logic |
| `modules/*/variable.tf` | ✅ Yes | Input declarations |
| `modules/*/output.tf` | ✅ Yes | Output definitions |
| `main.tf.example` | ✅ Yes | Blank template |
| `main.tf` | ❌ No | Contains real values |
| `terraform.tfvars` | ❌ No | Contains real values |
| `*.tfstate` | ❌ No | Contains secrets |
| `.terraform/` | ❌ No | Local provider cache |

---

## 14. Workspaces & Environment Management

### ⭐ STAR
| | |
|---|---|
| **Situation** | You need dev, staging, and prod environments from the same Terraform code |
| **Task** | Isolate state between environments without duplicating `.tf` files |
| **Action** | Use workspaces (simple) or directory separation (production-grade) |
| **Result** | Same code creates different infrastructure per environment |

### What Workspaces Actually Do

Workspaces are **separate state files sharing the same code**.

```
Same .tf files
    ├── default workspace  →  terraform.tfstate
    ├── dev workspace      →  terraform.tfstate.d/dev/terraform.tfstate
    └── prod workspace     →  terraform.tfstate.d/prod/terraform.tfstate
```

> ⚠️ **Critical misunderstanding**: Workspaces do NOT magically create environments. If your code doesn't change behaviour per workspace, you'll just create identical infrastructure multiple times — by accident.

### Workspace Commands

```bash
terraform workspace list              # List all workspaces
terraform workspace show              # Show current workspace
terraform workspace new dev           # Create and switch to 'dev'
terraform workspace select prod       # Switch to 'prod'
terraform workspace delete dev        # Delete 'dev' (must not be current)
```

### Making Code Workspace-Aware

```hcl
# Reference current workspace name
locals {
  env = terraform.workspace
}

# Use it in resource names (prevents naming conflicts)
resource "google_compute_instance" "vm" {
  name         = "${var.instance_name}-${terraform.workspace}"
  machine_type = local.env == "prod" ? "n2-standard-4" : "e2-micro"
}
```

Without workspace-aware naming, your "dev" workspace's `terraform apply` will conflict with or overwrite your "prod" resources.

### Real-World Example

```bash
terraform workspace new dev
terraform apply
# Creates: terraform-demo-server-dev

terraform workspace new prod
terraform apply
# Creates: terraform-demo-server-prod
# Same code. Different outcomes. No copy-paste.
```

### Workspaces — When to Use / Avoid

```
✅ USE workspaces when:
   - Same infrastructure, different scale per environment
   - Dev / staging / prod clones
   - Quick testing environments

❌ AVOID workspaces when:
   - Completely different architectures per environment
   - Different teams / ownership
   - High-risk production systems
   - Anything needing strict, bulletproof isolation
```

---

### 🏆 Production-Grade: Directory Separation (Industry Standard)

The actual gold standard used by serious DevOps teams.

```
terraform/
├── modules/
│   ├── compute/         ← Reusable VM module
│   └── network/         ← Reusable network module
│
└── environments/
    ├── dev/
    │   ├── main.tf      ← Calls modules with dev values
    │   ├── backend.tf   ← Points to dev-state GCS bucket
    │   └── terraform.tfvars
    ├── staging/
    │   ├── main.tf
    │   ├── backend.tf
    │   └── terraform.tfvars
    └── prod/
        ├── main.tf
        ├── backend.tf
        └── terraform.tfvars
```

**Why this beats workspaces:**

| | Workspaces | Directory Separation |
|--|-----------|---------------------|
| State isolation | Shared backend | Separate backend per env |
| Human error risk | High (easy to apply in wrong workspace) | Low (you're physically in the folder) |
| IAM/access control | Hard to restrict | Restrict by folder/backend |
| Code changes | Affect all workspaces | Explicitly per environment |

**Mental model:**
```
Workspaces = "Same blueprint, multiple copies with separate memory" (convenient, not bulletproof)
Directory Separation = "Completely separate projects that share reusable modules" (bulletproof)
```

---

## 15. Full GCP VM Example

A complete, production-style GCP Compute Engine VM with firewall rules, service account, SSH access, and nginx startup script.

### `terraform.tf` — Provider + Backend Config

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.25.0"
    }
  }

  # Uncomment after creating your GCS bucket
  # backend "gcs" {
  #   bucket = "your-terraform-state"
  #   prefix = "state/terraform"
  # }
}

provider "google" {
  project = "your-gcp-project"
  region  = "us-central1"
  # Note: zone is set per-resource, not here
}
```

### `variable.tf`

```hcl
variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-micro"
}

variable "vm_storage_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 10
}

variable "os_image" {
  description = "OS image"
  type        = string
  default     = "debian-cloud/debian-11"
}
```

### `google_instance.tf`

```hcl
# Reference existing default VPC (read-only, creates nothing)
data "google_compute_network" "default" {
  name = "default"
}

# Firewall rule — HTTP + HTTPS
resource "google_compute_firewall" "allow_http" {
  name    = "terra-allow-http"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  target_tags   = ["terra-http"]
  source_ranges = ["0.0.0.0/0"]
}

# Firewall rule — SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "terra-allow-ssh"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["terra-ssh"]
  source_ranges = ["0.0.0.0/0"]   # ✅ Correct — was "0.0.0.0/22" in original (bug!)
}

# Custom Service Account for the VM
resource "google_service_account" "vm_sa" {
  account_id   = "terra-vm-sa"
  display_name = "Custom SA for Compute Engine VM"
}

# The VM itself
resource "google_compute_instance" "vm" {
  name         = "my-vm"
  machine_type = var.machine_type
  zone         = "us-central1-b"
  tags         = ["terra-ssh", "terra-http"]

  boot_disk {
    initialize_params {
      image = var.os_image
      size  = var.vm_storage_size
    }
  }

  network_interface {
    network = data.google_compute_network.default.name
    access_config {}   # Empty block = GCP assigns ephemeral public IP
                       # Remove entirely = private-only VM
  }

  # Runs once on first boot — installs nginx
  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "<h1>Deployed with Terraform</h1>" | sudo tee /var/www/html/index.html
  EOF

  # Inject your SSH public key at provisioning time
  metadata = {
    ssh-keys = file("./terrakey-my-vm1.pub")
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }
}
```

### `output.tf`

```hcl
output "vm_public_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "vm_private_ip" {
  value = google_compute_instance.vm.network_interface[0].network_ip
}

output "vm_instance_id" {
  value = google_compute_instance.vm.instance_id
}
```

### Resource Dependency Flow

```
variable.tf
     ↓
data block (default VPC)
     ↓
Firewall rules + Service Account
     ↓            ↓
         Compute VM
              ↓
           Outputs
```

Terraform resolves this graph automatically — you don't manually order resources. Use `depends_on` only when the dependency isn't directly referenced in code.

---

## 16. `.gitignore` Cheatsheet

```gitignore
# Root module config (contains real values — never commit)
main.tf
terraform.tfvars

# Terraform state (contains sensitive data — NEVER commit)
*.tfstate
*.tfstate.backup

# Terraform internals
.terraform/
.terraform.lock.hcl

# Crash logs
crash.log
crash.*.log
```

---

## 17. Master Command Cheatsheet

```bash
# ─── SETUP ────────────────────────────────────────────────────────
terraform init                          # Initialize, download providers
terraform validate                      # Check syntax
terraform fmt                           # Auto-format .tf files

# ─── PLANNING ─────────────────────────────────────────────────────
terraform plan                          # Dry run — what will happen
terraform plan -var-file="prod.tfvars"  # Plan with specific var file

# ─── APPLYING ─────────────────────────────────────────────────────
terraform apply                         # Apply (asks confirmation)
terraform apply -auto-approve           # Apply (no confirmation)
terraform apply -var-file="dev.tfvars"  # Apply with specific var file
terraform apply -var="machine_type=e2-medium"  # Override single var

# ─── DESTROYING ───────────────────────────────────────────────────
terraform destroy                       # Destroy all (asks confirmation)
terraform destroy -auto-approve         # Destroy all (no confirmation)
terraform destroy --target=google_compute_instance.vm  # Destroy ONE resource

# ─── STATE MANAGEMENT ─────────────────────────────────────────────
terraform state list                    # List all tracked resources
terraform state show <resource>         # Show resource details
terraform state rm <resource>           # Remove from state (keeps real resource)
terraform refresh                       # Sync state with real infra
terraform show                          # Full state dump
terraform output                        # Print all outputs

# ─── IMPORT ───────────────────────────────────────────────────────
terraform import <type>.<name> <id>     # Import existing resource into state
terraform state show <resource>         # View imported config (copy to .tf file)

# ─── WORKSPACES ───────────────────────────────────────────────────
terraform workspace list                # List workspaces
terraform workspace show                # Show current workspace
terraform workspace new dev             # Create and switch to 'dev'
terraform workspace select prod         # Switch to existing workspace
terraform workspace delete dev          # Delete workspace

# ─── LOCKING ──────────────────────────────────────────────────────
terraform force-unlock <LOCK_ID>        # ⚠️ Emergency only — use with extreme caution

# ─── GCS BUCKET SETUP ─────────────────────────────────────────────
gcloud storage buckets create gs://your-bucket --location=us-central1 --uniform-bucket-level-access
gcloud storage buckets update gs://your-bucket --versioning
gcloud storage buckets update gs://your-bucket --pap
gcloud storage buckets list
```

---

## ⚡ Quick Reference — Mental Models

```
resource  = "create this thing"
data      = "look up this existing thing (read-only)"
variable  = "here's an input I accept"
output    = "here's a value I expose"
module    = "run that folder's code with these inputs"
locals    = "here's a computed value I'll reuse internally"
provider  = "here's how to talk to the cloud"
terraform = "here's how to configure Terraform itself"

count     = use when resources are identical
for_each  = use when resources differ (preferred)
[*]       = get all values from count-based resources
depends_on = explicit ordering when Terraform can't infer it

.tfvars      → values (never commit if real)
.tf          → infrastructure logic (commit)
.tfstate     → Terraform's memory (never commit)
.tflock      → distributed lock object in GCS (auto-managed)
```

---

*Notes from TWS Terraform Course | File: `TERRAFORM_NOTES.md`*


---
---
---
# FEW EXTRA THINGS 
## 🧠 1. Dependency Handling (Implicit vs Explicit)

### ✅ Concept:

Terraform automatically determines dependencies through **resource references**.

---

### 💻 Example (Implicit dependency):

```hcl
resource "google_compute_network" "vpc" {
  name = "my-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.0.0/24"
}
```

👉 No `depends_on` needed.

---

### ⚠️ When to use `depends_on`:

```hcl
resource "google_project_iam_member" "binding" {
  member = "serviceAccount:my-sa@project.iam.gserviceaccount.com"

  depends_on = [google_service_account.sa]
}
```

---

### 🧠 Rule:

> Prefer references over `depends_on`

---

# 🧠 2. `terraform state rm`

### ✅ Concept:

Removes a resource **from state only**, without deleting actual infrastructure.

---

### 💻 Example:

```bash
terraform state rm google_compute_instance.vm
```

👉 Resource still exists in GCP
👉 Terraform stops managing it

---

### ⚠️ Compare:

* `state rm` → forget resource
* `taint` → recreate resource

---

# 🧠 3. Terraform Plan Symbol `-/+`

### ✅ Concept:

`-/+` means **resource will be destroyed and recreated**

---

### 💻 Example plan:

```
-/+ resource "google_compute_instance" "vm"
```

---

### 🧠 Meaning:

* `-` → destroy
* `+` → create

👉 Replacement (not update)

---

# 🧠 4. Resource Attribute Navigation

### ✅ Concept:

Attributes must be accessed **exactly**, not guessed.

---

### 💻 Example:

```hcl
# Network
network = google_compute_instance.vm.network_interface[0].network

# Internal IP
internal_ip = google_compute_instance.vm.network_interface[0].network_ip

# External IP
external_ip = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
```

---

### 🧠 Rule:

> Read provider docs—don’t assume attribute names

---

# 🧠 5. Provisioners Usage

### ✅ Concept:

Use provisioners **only as a last resort**

---

### ❌ Not recommended:

```hcl
provisioner "remote-exec" {
  command = "install nginx"
}
```

---

### ✅ Better approach (GCP startup script):

```hcl
resource "google_compute_instance" "vm" {
  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt update
    apt install -y nginx
  EOT
}
```

---

### 🧠 Rule:

> Prefer cloud-native solutions over provisioners

---

# 🧠 6. Sensitive Variables

### ✅ Concept:

Mark variables as sensitive to hide them in output

---

### 💻 Example:

```hcl
variable "password" {
  type      = string
  sensitive = true
}
```

---

### ⚠️ Important:

* Hides in CLI output
* Does NOT encrypt state

---

# 🧠 7. `null_resource`

### ✅ Concept:

Used to run provisioners without creating real infrastructure

---

### 💻 Example:

```hcl
resource "null_resource" "example" {
  provisioner "local-exec" {
    command = "echo Hello"
  }
}
```

---

### 💻 With trigger:

```hcl
resource "null_resource" "always_run" {
  triggers = {
    run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo Running again"
  }
}
```

---

### 🧠 Rule:

> Useful, but don’t overuse

---

# 🧠 8. `locals`

### ✅ Concept:

Reusable values within a module

---

### 💻 Example:

```hcl
locals {
  env         = "dev"
  name_prefix = "myapp-${local.env}"
}
```

---

### Usage:

```hcl
resource "google_compute_instance" "vm" {
  name = "${local.name_prefix}-vm"
}
```

---

### 🧠 Rule:

* `variable` → input
* `local` → internal logic

---
---
---


