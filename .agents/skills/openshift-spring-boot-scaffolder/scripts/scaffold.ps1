<#
.SYNOPSIS
    Enterprise Spring Boot & OpenShift S2I Scaffolder Script (PowerShell)
    Generates a Java 21 / Spring Boot 4.x service in org.jugph namespace with H2 database and k8s manifests.
#>
param (
    [string]$AppName = "org.jugph.service",
    [string]$GroupId = "org.jugph",
    [string]$BootVersion = "4.1.1",
    [string]$JavaVersion = "21",
    [string]$Dependencies = "web,data-jpa,h2,validation,actuator"
)

$ErrorActionPreference = "Stop"

Write-Host "==> 1. Downloading Spring Boot project from Initializr API..." -ForegroundColor Cyan
$url = "https://start.spring.io/starter.zip?type=gradle-project-kotlin&language=java&bootVersion=$BootVersion&baseDir=$AppName&groupId=$GroupId&artifactId=$AppName&name=$AppName&description=Core+enterprise+platform+service&packageName=$GroupId&packaging=jar&javaVersion=$JavaVersion&dependencies=$Dependencies"
$zipFile = "$AppName.zip"

Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing

Write-Host "==> 2. Extracting archive..." -ForegroundColor Cyan
Expand-Archive -Path $zipFile -DestinationPath "." -Force
Remove-Item -Path $zipFile -Force

Push-Location -Path $AppName

Write-Host "==> 3. Establishing layered package architecture..." -ForegroundColor Cyan
$packageDirs = @(
    "src/main/java/org/jugph/web/controller",
    "src/main/java/org/jugph/service",
    "src/main/java/org/jugph/repository",
    "src/main/java/org/jugph/dto",
    "src/main/java/org/jugph/exception"
)
foreach ($dir in $packageDirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

Write-Host "==> 4. Generating application.yml with H2 in-memory DB and console..." -ForegroundColor Cyan
$appYml = @"
server:
  port: 8080

spring:
  application:
    name: $AppName
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
"@
Set-Content -Path "src/main/resources/application.yml" -Value $appYml -Encoding UTF8

Write-Host "==> 5. Creating OpenShift / Kubernetes manifests in k8s/..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "k8s" -Force | Out-Null

$deploymentYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $AppName
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $AppName
  template:
    metadata:
      labels:
        app: $AppName
    spec:
      containers:
      - name: $AppName
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
"@
Set-Content -Path "k8s/deployment.yaml" -Value $deploymentYaml -Encoding UTF8

$serviceYaml = @"
apiVersion: v1
kind: Service
metadata:
  name: $AppName
spec:
  selector:
    app: $AppName
  ports:
    - port: 80
      targetPort: 8080
"@
Set-Content -Path "k8s/service.yaml" -Value $serviceYaml -Encoding UTF8

$routeYaml = @"
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: $AppName-route
spec:
  to:
    kind: Service
    name: $AppName
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
"@
Set-Content -Path "k8s/route.yaml" -Value $routeYaml -Encoding UTF8

Pop-Location
Write-Host "==> Scaffolding complete for $AppName." -ForegroundColor Green
