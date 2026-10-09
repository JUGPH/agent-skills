---
name: openshift-spring-boot-scaffolding
description: >-
  Trigger this skill whenever asked to generate, scaffold, initialize, or bootstrap a brand new Spring Boot microservice for Red Hat OpenShift Sandbox using the Source-to-Image (S2I) strategy. It interacts with the Spring Initializr API and enforces S2I-ready architectures using the org.jugph namespace.
metadata:
  version: "1.0.0"
  author: "Tristan Mahinay"
  framework: "Spring Boot 4.x (4.1.1) / Java 21 / OpenShift Sandbox / S2I"
---

# Enterprise Spring Boot & OpenShift S2I Scaffolding Skill

You are an expert Solutions Architect. When tasked with creating a new microservice for OpenShift using S2I, you will use the official Spring Initializr API to generate a safe baseline, unzip it, and prepare the repository structure so the Red Hat OpenShift builder images can automatically detect and compile it.

## Workflow Steps

### Step 1: Parameter Gathering & Strategy
Before executing any shell commands, determine the following from the user's prompt:
* `artifactId` (Defaults to `org.jugph` prefixed or substituted domain, e.g., `org.jugph.service`)
* `description` (e.g., "Handles core transaction processing engine")
* Required Spring Boot modules (e.g., `web`, `data-jpa`, `h2`, `actuator`)

If the user does not specify, default to:
* **Java Version:** 21
* **Build Tool:** Gradle (Kotlin DSL) or Maven. (Note: OpenShift S2I detects the build tool automatically by looking for `pom.xml` or `build.gradle` in the root).
* **Group ID:** `org.jugph`
* **Base Dependencies:** `web, data-jpa, h2, actuator, validation`

### Step 2: The API Generation Phase
Construct and execute a `curl` command to the Spring Initializr API, piping the output to an archive, and extracting it into the workspace. Use the **Initializr API Blueprint** below.

### Step 3: The Architecture Mutation Phase
Once the vanilla Spring Boot structure is extracted, you must enforce the S2I-ready layout:
1. Establish the standard layered package structure (`controller`, `service`, `repository`, `dto`, `exception`) within the `src/main/java/org/jugph/...` directory.
2. Add a standard `application.yml` replacing the default `application.properties`. Ensure server port is set to `8080`.
3. Generate the OpenShift manifests in the `k8s/` directory (`deployment.yaml`, `service.yaml`, `route.yaml`) and provide the `oc` deployment instructions.

### Step 4: Verification Loop
Execute `./gradlew build` or `mvn clean install` locally to ensure the generated artifact compiles cleanly before it is pushed to the OpenShift Sandbox for S2I execution.

---

## Technical Blueprints

### 1. Spring Initializr API Command
Use this exact pattern to download the baseline. Adjust the `-d` parameters based on the gathered requirements.

```bash
# Example generation for an S2I-ready service
curl -G https://start.spring.io/starter.zip \
    -d type=gradle-project-kotlin \
    -d language=java \
    -d bootVersion=4.1.1 \
    -d baseDir=org.jugph \
    -d groupId=org.jugph \
    -d artifactId=org.jugph \
    -d name=org.jugph \
    -d description="Core enterprise platform service" \
    -d packageName=org.jugph \
    -d packaging=jar \
    -d javaVersion=21 \
    -d dependencies=web,data-jpa,h2,validation,actuator \
    -o org.jugph.zip

# Unzip and cleanup
unzip org.jugph.zip -d .
rm org.jugph.zip
```

### 2. Architecture Mutation (Layered Structure & Config)
Transform the flat structure into a layered architecture and establish the production configuration baseline.

```bash
# Create standard package structure
mkdir -p src/main/java/org/jugph/web/controller src/main/java/org/jugph/service src/main/java/org/jugph/repository src/main/java/org/jugph/dto src/main/java/org/jugph/exception

# Configure application.yml with server port 8080 and H2 console
cat <<EOF > src/main/resources/application.yml
server:
  port: 8080

spring:
  application:
    name: org-jugph-svc
  datasource:
    url: jdbc:h2:mem:testdb
    driverClassName: org.h2.Driver
    username: sa
    password: ""
  h2:
    console:
      enabled: true
      path: /h2-console
  jpa:
    database-platform: org.hibernate.dialect.H2Dialect
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        format_sql: true
EOF
```

### 3. OpenShift Deployment Manifests
Generate the necessary OpenShift manifests in a dedicated `k8s/` directory for S2I deployment, ensuring the application is exposed via an edge-terminated `Route`.

```bash
# Create k8s directory for deployment manifests
mkdir -p k8s

# 1. Deployment manifest (Kubernetes apps/v1)
cat <<EOF > k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: org-jugph-svc
spec:
  replicas: 1
  selector:
    matchLabels:
      app: org-jugph-svc
  template:
    metadata:
      labels:
        app: org-jugph-svc
    spec:
      containers:
      - name: org-jugph-svc
        image: placeholder:latest # Will be updated by S2I build or image stream
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
EOF

# 2. Service manifest
cat <<EOF > k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: org-jugph-svc
spec:
  selector:
    app: org-jugph-svc
  ports:
    - port: 80
      targetPort: 8080
EOF

# 3. OpenShift Route manifest
cat <<EOF > k8s/route.yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: org-jugph-route
spec:
  to:
    kind: Service
    name: org-jugph-svc
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF
```

### 4. OpenShift Deployment Commands
Provide the user with the command sequence to deploy the scaffolded service to OpenShift Sandbox:

```bash
# 1. Login & set project namespace
oc project <your-namespace>

# 2. Trigger binary S2I build from local source
oc new-build registry.access.redhat.com/ubi9/openjdk-21 --binary=true --name=org-jugph-svc
oc start-build org-jugph-svc --from-dir=. --follow

# 3. Apply the declarative manifests
oc apply -f k8s/

# 4. Verify deployment and get route URL
oc get pods -w
oc get route org-jugph-route -o jsonpath='https://{.spec.host}{"\n"}'
```

---

## Helper Scripts & Architecture References

* **Automation Scripts:**
  * Bash Scaffolder: [`scripts/scaffold.sh`](file:///c:/Users/rjtma/Documents/agent-skills/.agents/skills/openshift-spring-boot-scaffolding/scripts/scaffold.sh)
  * PowerShell Scaffolder: [`scripts/scaffold.ps1`](file:///c:/Users/rjtma/Documents/agent-skills/.agents/skills/openshift-spring-boot-scaffolding/scripts/scaffold.ps1)
  * OpenShift Sandbox Deployer: [`scripts/deploy-sandbox.sh`](file:///c:/Users/rjtma/Documents/agent-skills/.agents/skills/openshift-spring-boot-scaffolding/scripts/deploy-sandbox.sh)
* **Architecture Reference:**
  * S2I Lifecycle, Builder Images, and Quotas: [`references/s2i-architecture.md`](file:///c:/Users/rjtma/Documents/agent-skills/.agents/skills/openshift-spring-boot-scaffolding/references/s2i-architecture.md)


