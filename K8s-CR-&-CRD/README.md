# 📘 CRD + CR + Controller (Student Example)

Built on Kubernetes

---

# 🎯 What we’re building

A system where:

* You define a **Student resource**
* Each Student creates **N pods (replicas)**
* A simple controller enforces it

---

# 🧩 Step 1: Create CRD (Student)

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: students.demo.com   # <plural>.<group>
spec:
  group: demo.com
  names:
    kind: Student
    plural: students
    singular: student
    shortNames:
      - stu
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                name:
                  type: string
                course:
                  type: string
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 5
```

👉 Apply:

```bash
kubectl apply -f crd.yaml
```

---

# 📦 Step 2: Create CR (Student instance)

```yaml
apiVersion: demo.com/v1
kind: Student
metadata:
  name: vicky
spec:
  name: Vicky
  course: DevOps
  replicas: 2
```

👉 Apply:

```bash
kubectl apply -f student.yaml
```

---

# 🤖 Step 3: Controller (controller.sh)

This acts like a **mini operator**

### ✅ Handles:

* Create pods
* Scale pods (based on replicas)
* Delete extra pods

---

## 🧠 controller.sh

```bash
#!/bin/bash

while true; do
  students=$(kubectl get students -o jsonpath='{.items[*].metadata.name}')

  for stu in $students; do
    replicas=$(kubectl get student $stu -o jsonpath='{.spec.replicas}')
    image="nginx"

    # Current pods
    current=$(kubectl get pods -l student=$stu --no-headers 2>/dev/null | wc -l)

    # 🟢 Scale UP
    if [ "$current" -lt "$replicas" ]; then
      diff=$((replicas - current))
      echo "Scaling UP $stu by $diff"

      for i in $(seq 1 $diff); do
        kubectl run ${stu}-pod-$RANDOM \
          --image=$image \
          --labels="student=$stu"
      done
    fi

    # 🔴 Scale DOWN
    if [ "$current" -gt "$replicas" ]; then
      diff=$((current - replicas))
      echo "Scaling DOWN $stu by $diff"

      pods=$(kubectl get pods -l student=$stu -o jsonpath='{.items[*].metadata.name}')

      count=0
      for pod in $pods; do
        kubectl delete pod $pod
        count=$((count + 1))
        [ $count -eq $diff ] && break
      done
    fi
  done

  sleep 5
done
```

---

# ▶️ Step 4: Run controller

```bash
chmod +x controller.sh
./controller.sh
```

---

# 🔍 Step 5: Test it

### Check students

```bash
kubectl get students
```

### Check pods

```bash
kubectl get pods
```

---

# 🧪 Try this (IMPORTANT)

## 🔼 Scale up

```bash
kubectl edit student vicky
```

Change:

```yaml
replicas: 4
```

👉 Pods increase automatically

---

## 🔽 Scale down

```yaml
replicas: 1
```

👉 Extra pods deleted

---

# 🧠 What you learned

| Component  | Role                     |
| ---------- | ------------------------ |
| CRD        | Defines Student resource |
| CR         | Defines desired state    |
| Controller | Enforces replicas        |
| Kubernetes | Runs pods                |

---

# 🔁 Core Loop (remember this)

```text
Desired (CR) vs Actual (Cluster)
→ Controller fixes difference
```

---

# 💀 Honest summary

You just built:

> A budget Kubernetes Operator powered by bash and determination

---

# 🚀 Next step (if you want to level up)

* Add **status field**
* Replace bash with Go (real operator)
* Use kubebuilder

---
