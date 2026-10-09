# Red Hat OpenShift Source-to-Image (S2I) Architecture Reference

This reference outlines the internal mechanics of Red Hat OpenShift Source-to-Image (S2I), image builders, sandbox environment constraints, and network routing policies for Spring Boot services.

---

## 1. S2I Build Lifecycle

Source-to-Image (S2I) is a reproducible framework that produces ready-to-run container images by injecting application source code into a container image and letting an assemble script build the artifacts:

```text
Local Source Code (or Git Repository)
               │
               ▼
┌──────────────────────────────────────────────┐
│ Red Hat OpenJDK 21 S2I Builder Image         │
│ (ubi9/openjdk-21)                            │
│  1. Ingests source code via .s2i/bin/assemble│
│  2. Detects build tool (Gradle / Maven)      │
│  3. Compiles executable JAR                  │
│  4. Configures run script (.s2i/bin/run)     │
└──────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Output ImageStream                           │
│ (image-registry.../<namespace>/<app>:latest) │
└──────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Kubernetes Deployment / Pods                 │
└──────────────────────────────────────────────┘
```

---

## 2. Recommended Builder Images

For modern Java 21 LTS workloads on OpenShift:

| Builder Image | Registry Path | Notes |
| :--- | :--- | :--- |
| **UBI 9 OpenJDK 21** | `registry.access.redhat.com/ubi9/openjdk-21` | **Default / Recommended.** Hardened Universal Base Image 9 with OpenJDK 21. |
| **UBI 8 OpenJDK 21** | `registry.access.redhat.com/ubi8/openjdk-21` | Compatible with OpenShift 4.12+ legacy clusters. |

---

## 3. Red Hat OpenShift Sandbox Environment Constraints

The Developer Sandbox on OpenShift has strict resource quotas per developer account:

* **Namespaces:** A single `-dev` namespace (e.g. `user1-dev`).
* **Memory Quota:** Typically capped at **7Gi** total across all pods.
* **CPU Quota:** Typically capped at **2 cores** burstable.
* **Idle Sleep:** Sandbox pods spin down after inactive periods; applications should have rapid startup times.
* **Storage:** Ephemeral by default; persistent volumes (PVC) are limited to 5GB (ReadWriteOnce).

### Recommended Resource Sizing for Java Pods:
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

---

## 4. OpenShift Network Routing Architecture

OpenShift utilizes an HAProxy-backed **Router** to provide external DNS hostnames for internal cluster services:

```text
Public Request (https://org-jugph-svc-user-dev.apps.sandbox.openshift.com)
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │ OpenShift Ingress Router│ (Edge TLS Termination)
                    └─────────────────────────┘
                                 │
                     (Cleartext HTTP / 8080)
                                 ▼
                    ┌─────────────────────────┐
                    │ Service (port 80:8080)  │
                    └─────────────────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │ Spring Boot Pod (8080)  │
                    └─────────────────────────┘
```

### Route TLS Policies:
* **`edge` (Recommended for Spring Boot):** TLS is terminated at the OpenShift Router. Traffic from the router to the pod is plaintext HTTP on port `8080`.
* **`insecureEdgeTerminationPolicy: Redirect`:** Automatically converts unencrypted `http://` incoming traffic to `https://`.
