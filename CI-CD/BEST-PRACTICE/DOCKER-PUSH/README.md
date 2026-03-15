# Jenkins Pipeline — Image Tagging with `GIT_COMMIT` (Fix for `latest` Anti-pattern)

## Problem

Using `latest` as a Docker image tag is an anti-pattern:

- If a push fails mid-way, GAR still serves the **old** `latest`
- Every image in GAR looks identical — **no traceability**
- Rollback is impossible — you don't know what "latest" actually was
- You can't link a running container back to a git commit

---

## Solution — Use `BUILD_NUMBER` + `GIT_COMMIT` as the tag

```groovy
env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT[0..6]}"
```

### Breaking it down

| Part | Example | Meaning |
|------|---------|---------|
| `env.BUILD_NUMBER` | `42` | Jenkins auto-incremented build number |
| `env.GIT_COMMIT[0..6]` | `a3f9c1d` | First 7 chars of the git commit SHA |
| Combined | `42-a3f9c1d` | Final image tag |

#### `env.BUILD_NUMBER`
- Jenkins increments this automatically on every run
- Tells you **which Jenkins build** produced this image

#### `env.GIT_COMMIT[0..6]`
- `[0..6]` is **Groovy slice syntax** — extracts characters at index 0 through 6 (7 chars total)
- Shortens the full 40-char SHA: `a3f9c1d8e2b4f6789...` → `a3f9c1d`
- 7 characters is the **git industry standard** for short SHAs — unique enough in any repo

---

## Why Set It AFTER Checkout (Critical!)

```groovy
// ❌ WRONG — environment{} block runs BEFORE any stage
environment {
    IMAGE_TAG = "${env.GIT_COMMIT[0..6]}"  // GIT_COMMIT is null here → tag = "42-null"
}

// ✅ CORRECT — set inside the checkout stage, after git has populated GIT_COMMIT
stage("Git: Code Checkout") {
    steps {
        script {
            code_checkout(...)           // git runs → GIT_COMMIT is now set
            env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT[0..6]}"
        }
    }
}
```

The `environment {}` block evaluates at **pipeline startup**, before any git operation.
`GIT_COMMIT` is `null` at that point → your tag becomes `42-null`.

---

## Full Pipeline Flow

```
Jenkins starts build
       ↓
Stage 2: code_checkout() runs
       ↓
Jenkins sets GIT_COMMIT = "a3f9c1d8e2b4..."
       ↓
env.IMAGE_TAG = "42-a3f9c1d"   ← safe to read now
       ↓
Stage 5: docker_build(..., "42-a3f9c1d", ...)
       ↓
Stage 6: docker_push(...,  "42-a3f9c1d", ...)
       ↓
GAR stores: wanderlust-backend-beta:42-a3f9c1d
```

---

## Real-World Traceability

GAR now shows:
```
wanderlust-backend-beta:42-a3f9c1d   ← currently deployed
wanderlust-backend-beta:41-b7e2f9a
wanderlust-backend-beta:40-c1d3e8b
```

You immediately know:
- `42` → Jenkins build #42 deployed this
- `a3f9c1d` → exact git commit that introduced this code

Trace it:
```bash
git show a3f9c1d
# Shows author, date, and full diff for that commit
```

---

## Note on SHA Digest vs IMAGE_TAG

Both are used in this pipeline — they serve **different purposes**:

| | Purpose | Used by |
|---|---------|---------|
| `IMAGE_TAG` (`42-a3f9c1d`) | Human-readable traceability | Developers, GAR UI |
| `SHA Digest` (`sha256:abc...`) | Immutable image pinning | Helm `values.yaml` |

The tag can be re-pushed and overwritten (in theory). The SHA digest is **content-addressable** and immutable — it's what Helm uses to deploy the exact same bytes every time.
