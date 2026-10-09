---
name: openshift-s2i-spring-boot-scaffolder
description: >-
  Trigger this skill whenever asked to generate, scaffold, initialize, or bootstrap a brand new Spring Boot microservice for Red Hat OpenShift Sandbox using the Source-to-Image (S2I) strategy. It interacts with the Spring Initializr API and enforces S2I-ready architectures using the com.rjtmahinay namespace.
metadata:
  version: "1.0.0"
  author: "Tristan Mahinay"
  framework: "Spring Boot 3.x / Java 21 / OpenShift Sandbox / S2I"
---

# Enterprise Spring Boot & OpenShift S2I Scaffolding Skill

You are an expert Solutions Architect. When tasked with creating a new microservice for OpenShift using S2I, you will use the official Spring Initializr API to generate a safe baseline, unzip it, and prepare the repository structure so the Red Hat OpenShift builder images can automatically detect and compile it.

## Workflow Steps

### Step 1: Parameter Gathering & Strategy
Before executing any shell commands, determine the following from the user's prompt:
* `artifactId` (Defaults to `com.rjtmahinay` prefixed or substituted domain, e.g., `com.rjtmahinay.service`)
* `description` (e.g., "Handles core transaction processing engine")
* Required Spring Boot modules (e.g., `web`, `data-jpa`, `actuator`)

If the user does not specify, default to:
* **Java Version:** 21
* **Build Tool:** Gradle (Kotlin DSL) or Maven. (Note: OpenShift S2I detects the build tool automatically by looking for `pom.xml` or `build.gradle` in the root).
* **Group ID:** `com.rjtmahinay`
* **Base Dependencies:** `web, actuator, validation`

### Step 2: The API Generation Phase
Construct and execute a `curl` command to the Spring Initializr API, piping the output to an archive, and extracting it into the workspace. Use the **Initializr API Blueprint** below.

### Step 3: The Architecture Mutation Phase
Once the vanilla Spring Boot structure is extracted, you must enforce the S2I-ready layout:
1. Establish the standard layered package structure (`controller`, `service`, `repository`, `dto`, `exception`) within the `src/main/java/com/rjtmahinay/...` directory.
2. Add a standard `application.yml` replacing the default `application.properties`. Ensure server port is set to `8080`.
3. Generate the `oc` deployment instructions and a Kubernetes `Route` manifest for external exposure.

### Step 4: Verification Loop
Execute `./gradlew build` or `mvn clean install` locally to ensure the generated artifact compiles cleanly before it is pushed to the OpenShift Sandbox for S2I execution.

---

## Technical Blueprints

### 1. Spring Initializr API Command
Use this exact pattern to download the baseline. Adjust the `-d` parameters based on the gathered requirements.

```bash
# Example generation for an S2I-ready service
curl -G [https://start.spring.io/starter.zip](https://start.spring.io/starter.zip) \
    -d type=gradle-project-kotlin \
    -d language=java \
    -d bootVersion=3.3.0 \
    -d baseDir=com.rjtmahinay \
    -d groupId=com.rjtmahinay \
    -d artifactId=com.rjtmahinay \
    -d name=com.rjtmahinay \
    -d description="Core enterprise platform service" \
    -d packageName=com.rjtmahinay \
    -d packaging=jar \
    -d javaVersion=21 \
    -d dependencies=web,data-jpa,postgresql,validation,actuator \
    -o com.rjtmahinay.zip

# Unzip and cleanup
unzip com.rjtmahinay.zip -d .
rm com.rjtmahinay.zip