#!/usr/bin/env bash
set -euo pipefail

# Enterprise Spring Boot & OpenShift S2I Scaffolder Script
# Generates a Java 21 / Spring Boot 4.x service in org.jugph namespace with H2 database and k8s manifests

APP_NAME="${1:-org.jugph.service}"
GROUP_ID="${2:-org.jugph}"
BOOT_VERSION="${3:-4.1.1}"
JAVA_VERSION="${4:-21}"
DEPENDENCIES="${5:-web,data-jpa,h2,validation,actuator}"

echo "==> 1. Downloading Spring Boot project from Initializr API..."
curl -s -G https://start.spring.io/starter.zip \
    -d type=gradle-project-kotlin \
    -d language=java \
    -d bootVersion="${BOOT_VERSION}" \
    -d baseDir="${APP_NAME}" \
    -d groupId="${GROUP_ID}" \
    -d artifactId="${APP_NAME}" \
    -d name="${APP_NAME}" \
    -d description="Core enterprise platform service" \
    -d packageName="${GROUP_ID}" \
    -d packaging=jar \
    -d javaVersion="${JAVA_VERSION}" \
    -d dependencies="${DEPENDENCIES}" \
    -o "${APP_NAME}.zip"

echo "==> 2. Extracting archive..."
unzip -q "${APP_NAME}.zip" -d .
rm -f "${APP_NAME}.zip"

cd "${APP_NAME}"

echo "==> 3. Establishing layered package architecture..."
mkdir -p src/main/java/org/jugph/web/controller \
         src/main/java/org/jugph/service \
         src/main/java/org/jugph/repository \
         src/main/java/org/jugph/dto \
         src/main/java/org/jugph/exception

echo "==> 4. Generating application.yml with H2 in-memory DB and console..."
cat <<EOF > src/main/resources/application.yml
server:
  port: 8080

spring:
  application:
    name: ${APP_NAME}
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

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  endpoint:
    health:
      show-details: always
      probes:
        enabled: true
EOF

echo "==> 5. Creating OpenShift / Kubernetes manifests in k8s/..."
mkdir -p k8s

cat <<EOF > k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${APP_NAME}
  template:
    metadata:
      labels:
        app: ${APP_NAME}
    spec:
      containers:
      - name: ${APP_NAME}
        image: placeholder:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 20
          periodSeconds: 15
EOF

cat <<EOF > k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}
spec:
  selector:
    app: ${APP_NAME}
  ports:
    - port: 80
      targetPort: 8080
EOF

cat <<EOF > k8s/route.yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${APP_NAME}-route
spec:
  to:
    kind: Service
    name: ${APP_NAME}
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF

echo "==> Scaffolding complete for ${APP_NAME}."
