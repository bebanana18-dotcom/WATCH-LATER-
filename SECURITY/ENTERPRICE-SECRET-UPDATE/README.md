# 🔐 Enterprise Secret Management & Rotation with GKE, CI/CD & Secret Manager

---

## 🧠 1. Architecture Overview

This setup is designed for **large-scale, security-first environments** where:

* Multiple teams and services exist
* Secrets must be centrally managed
* Human access is minimized
* Systems are resilient even if CI/CD is compromised

### Core Components:

* Google Secret Manager → Central secret storage
* Google Kubernetes Engine → Runs applications
* Secrets Store CSI Driver → Mounts secrets into pods
* Jenkins / GitLab CI/CD → Secret rotation pipelines

---

## 🔐 2. Separation of Responsibilities

### CI/CD Pipelines

* **Deployment Pipeline**

  * Builds and deploys applications
  * Runs frequently

* **Secret Management Pipeline**

  * Handles secret creation & rotation
  * Runs:

    * On schedule (e.g., every 30 days)
    * Or manually (security-triggered)

👉 This separation reduces risk and enforces strict access control.

---

## 🔄 3. Secret Rotation Strategy

### Rotation Frequency

* Database passwords → every 30–90 days
* API keys → every 60–180 days
* Tokens → short-lived

---

### Rotation Flow

1. Fetch current secret from Secret Manager
2. Generate a strong random password
3. Update external system (e.g., DB) using old password
4. Store new password as a **new version** in Secret Manager
5. Applications automatically consume updated secret

---

### Example Logic (Pipeline)

```bash
OLD_PASSWORD=$(gcloud secrets versions access latest --secret=db-password)
NEW_PASSWORD=$(openssl rand -base64 32)

# Update DB
mysql -h $DB_HOST -u admin -p$OLD_PASSWORD \
  -e "ALTER USER 'admin' IDENTIFIED BY '${NEW_PASSWORD}';"

# Store new version
echo -n "$NEW_PASSWORD" | gcloud secrets versions add db-password --data-file=-
```

---

## 🔐 4. No Secrets Stored in CI/CD

* CI/CD systems **do not persist secrets**
* Secrets are:

  * fetched at runtime
  * used temporarily
  * never logged

👉 This ensures:

* reduced blast radius
* no long-term exposure

---

## ⚠️ 5. Security Assumption (Critical)

The system assumes:

> “CI/CD (e.g., Jenkins) can be compromised”

### Mitigation:

* Jenkins runs with **GSA (Google Service Account)**
* Uses:

  * least privilege IAM
  * short-lived credentials
* No secret persistence

---

## 🔐 6. Access Control (IAM)

* Each service gets **minimal access**
* Example:

  * Payments service → only payments secrets
  * Auth service → only auth secrets

### Roles:

* `roles/secretmanager.secretAccessor` → read
* `roles/secretmanager.secretVersionAdder` → write

---

## 📦 7. Secret Consumption in GKE (CSI Driver)

Using Secrets Store CSI Driver with GKE add-on.

---

### How It Works

1. Pod uses **Kubernetes Service Account (KSA)**
2. KSA is mapped to **Google Service Account (GSA)** via Workload Identity
3. CSI driver fetches secrets from Secret Manager
4. Secrets are mounted as files inside the container

---

### SecretProviderClass Example

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: app-secrets
spec:
  provider: gke
  parameters:
    secrets: |
      - resourceName: "projects/PROJECT_ID/secrets/db-password/versions/latest"
        path: "db.txt"
```

---

### Pod Configuration

```yaml
volumeMounts:
  - mountPath: "/var/secrets"
    name: mysecret

volumes:
  - name: mysecret
    csi:
      driver: secrets-store-gke.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "app-secrets"
```

---

### Result Inside Container

```bash
/var/secrets/db.txt
```

👉 Application reads secret like a file
👉 No SDK, no API calls

---

## 🔄 8. Secret Auto-Rotation in GKE

* GKE Secret Manager add-on supports **auto-refresh of mounted secrets**
* When a new version is added:

  * file updates automatically
  * no pod restart required

---

## 🔐 9. Third-Party Secrets (PAT Tokens)

* Some services require **Personal Access Tokens (PATs)**
* Characteristics:

  * created manually
  * protected by MFA
  * visible only once

### Handling:

* stored in Secret Manager
* accessed by apps via CSI driver
* rotated manually or periodically

---

## 📊 10. Auditing & Monitoring

Using Google Secret Manager:

* Logs every:

  * access
  * modification
  * rotation

👉 Acts as a **“black box”** for:

* incident investigation
* compliance
* anomaly detection

---

## 🧨 11. Common Pitfalls

* Storing secrets in Terraform state
* Hardcoding secrets in code or YAML
* Giving broad IAM roles
* Not rotating secrets
* Logging secrets in CI/CD

---

## 🧠 12. Key Principles

* Zero or minimal human access
* Centralized secret storage
* Versioned secrets
* Automated rotation
* Identity-based access (Workload Identity)
* Assume breach → limit damage

---

## 💬 Final Summary

Secrets are:

* **centrally stored** in Secret Manager
* **securely injected** via CI/CD pipelines
* **automatically rotated**
* **mounted into GKE pods using CSI driver**

The system ensures:

* no secret persistence in CI/CD
* minimal human exposure
* strong auditability
* resilience even under compromise

---
