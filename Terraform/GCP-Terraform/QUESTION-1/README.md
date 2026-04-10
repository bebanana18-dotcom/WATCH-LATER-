# TERRAFORM QUESTION

Q. Explain **Terraform state** in your own words and why it is critical.

→

> Terraform state is a JSON file that keeps track of the mapping between the Terraform configuration and real-world infrastructure. It stores resource IDs and metadata so Terraform knows what it is managing.
It is critical because it allows Terraform to perform incremental changes instead of recreating everything, ensuring efficient and accurate infrastructure updates.
> 

### 💀 Killer one-liner (if they push you):

> “Without state, Terraform wouldn’t know what exists and would try to recreate all resources.”
> 

---

---

Q. Why is a **remote backend (like GCS)** preferred over a local state file?

> A remote backend like GCS is preferred because it provides a single source of truth for the Terraform state, enabling team collaboration. It also supports state locking to prevent concurrent modifications and reduces the risk of conflicts. Additionally, features like versioning help in recovering from accidental changes or corruption.
> 

### 💀 Strong one-liner add-on:

> “Local state doesn’t scale in teams — it leads to conflicts, duplication, and potential infrastructure damage.”
> 

---

---

---

Q. What is the difference between **modules and workspaces** in Terraform?

→ 

> Modules and workspaces serve different purposes in Terraform.
> 
> 
> Modules are used for code reusability and organization. They allow you to define infrastructure once and reuse it across multiple environments.
> 
> Workspaces, on the other hand, are used to manage multiple state files for the same configuration, typically to separate environments like dev, staging, and prod.
> 
> However, in production, teams often prefer separate directories or root modules per environment instead of workspaces, because workspaces can increase the risk of applying changes in the wrong environment.
> 

### 💀 Strong closer (this is what impresses interviewers):

> “Modules solve code reuse, while workspaces solve state isolation — they address completely different problems.”
> 

---

---

---

Q. You changed a Terraform resource, and the plan shows:

```
-/+ resource "google_compute_instance" "vm"
```

**Why is Terraform recreating the resource instead of updating it?**

→

> Terraform recreates the resource because certain attributes are immutable and cannot be updated in place. When such fields are changed, Terraform has no option but to destroy and recreate the resource to apply the new configuration.
> 

### 💀 Stronger version (say this → interviewer nods immediately):

> “This happens when we modify immutable attributes defined by the provider, such as machine type or disk configuration in a VM, which require resource replacement instead of in-place updates.”
> 

### ⚡ Example (if they push you):

- Changing:
    - machine type (sometimes)
    - boot disk
    - region/zone
    👉 triggers recreation

---

---

---

Q.  A resource exists in GCP, but it is **not in Terraform state**.

What will Terraform do if you run `terraform apply`, and how would you fix this properly?

→

> If a resource exists in GCP but is not in Terraform state, Terraform will treat it as new and attempt to create it during `apply`, which can lead to conflicts or errors if the resource already exists.
> 
> 
> The correct approach is to import the existing resource into Terraform state using the `terraform import` command. After importing, we update the configuration to match the actual resource and run `terraform plan` until there is no drift.
> 

### 💀 Strong version (this hits hard in interviews):

> “Terraform only manages what’s in its state. If a resource isn’t in state, it assumes it doesn’t exist.”
> 

### ⚡ Bonus (your answer already included this — nice):

Steps:

1. Write minimal resource block
2. `terraform import`
3. `terraform state show`
4. Align `.tf` with real infra
5. Run plan → zero drift

---

---

---

Q. What is the difference between `count` and `for_each`, and **why is `for_each` generally preferred in production?**

→

> The main difference is that `count` uses index-based resource creation, while `for_each` uses key-based mapping.
> 
> 
> `for_each` is preferred in production because it provides stable resource identification, preventing unintended resource destruction when the configuration changes.
> 

## 💀 Killer one-liner:

> “count is fragile because index changes can recreate resources, while for_each is stable because it uses unique keys.”
> 

## ⚡ When to use what

- Use `count` → simple, identical resources
- Use `for_each` → anything dynamic, production, or important

---

---

---

Q. Why are **provisioners discouraged** in Terraform, and what should you use instead?

→

> Provisioners are discouraged because they are not  `idempotent`  and operate outside Terraform’s state management, making deployments unreliable and hard to maintain.
> 
> 
> Instead, we should use approaches like startup scripts, cloud-init, or configuration management tools to handle instance configuration in a more predictable and scalable way.
> 

## 💀 Killer one-liner:

> “Provisioners introduce imperative behavior into a declarative system, which makes infrastructure unpredictable.”
> 

FOLLOW-UP 

Q. WHAT IS `idempotent`  ??

→ 

IT’S A PROCESS WHICH EVEN EXECUTE MULTIPLE TIMES PRODUCE THE SAME RESULT AS IT PRODUCE FOR SINGLE TIME  EXECUTION

EXAMPLE : 

HTTP METHOD : PUT AND PATCH ARE IDEMPOTENT 

BUT POST METHOD IS NOT IDEMPOTENT 

---

---

---
