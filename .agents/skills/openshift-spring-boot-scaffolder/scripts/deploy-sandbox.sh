#!/usr/bin/env bash
set -euo pipefail

# Deployment automation script for Red Hat OpenShift Sandbox
# Usage: ./deploy-sandbox.sh [APP_NAME] [BUILDER_IMAGE]

APP_NAME="${1:-org-jugph-svc}"
BUILDER_IMAGE="${2:-registry.access.redhat.com/ubi9/openjdk-21}"

echo "==> 1. Validating active OpenShift project context..."
CURRENT_PROJECT=$(oc project -q 2>/dev/null || true)
if [ -z "${CURRENT_PROJECT}" ]; then
    echo "ERROR: Not logged in or no active project found. Run 'oc login' first."
    exit 1
fi
echo "Active OpenShift project: ${CURRENT_PROJECT}"

echo "==> 2. Ensuring S2I binary build configuration exists..."
if ! oc get bc "${APP_NAME}" &>/dev/null; then
    echo "Creating new binary build configuration for ${APP_NAME}..."
    oc new-build "${BUILDER_IMAGE}" --binary=true --name="${APP_NAME}"
fi

echo "==> 3. Uploading local source directory to trigger S2I build..."
oc start-build "${APP_NAME}" --from-dir=. --follow

echo "==> 4. Applying declarative manifests from k8s/..."
oc apply -f k8s/

echo "==> 5. Linking deployment container image to newly built ImageStream..."
IMAGE_REPO=$(oc get is "${APP_NAME}" -o jsonpath='{.status.dockerImageRepository}')
oc set image "deployment/${APP_NAME}" "${APP_NAME}=${IMAGE_REPO}:latest"

echo "==> 6. Awaiting rollout completion..."
oc rollout status "deployment/${APP_NAME}" --timeout=180s

echo "==> 7. Fetching Route URL..."
ROUTE_HOST=$(oc get route "${APP_NAME}-route" -o jsonpath='{.spec.host}' 2>/dev/null || oc get route -l "app=${APP_NAME}" -o jsonpath='{.items[0].spec.host}')
echo "=========================================================="
echo "Deployment successful!"
echo "Public URL: https://${ROUTE_HOST}"
echo "Health:     https://${ROUTE_HOST}/actuator/health"
echo "=========================================================="
