#!/bin/bash
set -e

###############################################################################
# install-istio-microk8s.sh
#
# This script automates the setup of Istio, Ingress, and DNS on MicroK8s,
# labels a namespace for Istio sidecar injection, deploys the Istio Bookinfo
# sample application, applies the Bookinfo Gateway, retrieves the ingress IP,
# and tests the Bookinfo app via curl.
#
# Usage:
#   bash install-istio-microk8s.sh
#
# Prerequisites:
#   - MicroK8s installed and running
#   - User has permissions to run microk8s commands (may require sudo)
#   - Internet access to fetch Istio sample manifests
###############################################################################

# Function to print error and exit
error_exit() {
  echo "[ERROR] $1" >&2
  exit 1
}

# Ensure 'istio-system' namespace exists
if ! microk8s kubectl get namespace istio-system >/dev/null 2>&1; then
  echo "[INFO] 'istio-system' namespace does not exist. Creating it..."
  microk8s kubectl create namespace istio-system || error_exit "Failed to create 'istio-system' namespace."
else
  echo "[INFO] 'istio-system' namespace already exists."
fi

# 1. Enable Istio, Ingress, and DNS in MicroK8s
# These are required for service mesh, external access, and service discovery.
echo "[INFO] Enabling Istio, Ingress, and DNS in MicroK8s..."
microk8s enable community || error_exit "Failed to enable required MicroK8s community addons."
microk8s enable dns ingress istio || error_exit "Failed to enable required MicroK8s addons."

echo "[INFO] Waiting for Istio control plane and ingress gateway to be ready..."
# Wait for Istio control plane (istiod) to be available
microk8s kubectl wait --for=condition=Available --timeout=180s deployment/istiod -n istio-system || \
  error_exit "istiod did not become available in time."
# Wait for Istio ingress gateway to be available
microk8s kubectl wait --for=condition=Available --timeout=180s deployment/istio-ingressgateway -n istio-system || \
  error_exit "istio-ingressgateway did not become available in time."

# Show all pods for verification
echo "[INFO] Current pod status:"
microk8s kubectl get pods -A

echo "[INFO] All required components are enabled and running."

# 2. Label the 'default' namespace for automatic Istio sidecar injection
# This ensures that pods in the namespace get the Envoy sidecar automatically.
echo "[INFO] Labeling 'default' namespace for Istio sidecar injection..."
microk8s kubectl label namespace default istio-injection=enabled --overwrite || \
  error_exit "Failed to label namespace for sidecar injection."

echo "[INFO] Namespace 'default' labeled for Istio sidecar injection."

# 3. Deploy the Istio Bookinfo sample app
# This is a microservices demo app provided by Istio.
BOOKINFO_URL="https://raw.githubusercontent.com/istio/istio/release-1.20/samples/bookinfo/platform/kube/bookinfo.yaml"
echo "[INFO] Deploying Bookinfo sample app from $BOOKINFO_URL ..."
microk8s kubectl apply -f "$BOOKINFO_URL" || \
  error_exit "Failed to deploy Bookinfo sample app."

echo "[INFO] Bookinfo sample app deployed."

# 4. Apply the Bookinfo Gateway
# This exposes the Bookinfo app via Istio ingress.
GATEWAY_URL="https://raw.githubusercontent.com/istio/istio/release-1.20/samples/bookinfo/networking/bookinfo-gateway.yaml"
echo "[INFO] Applying Bookinfo Gateway from $GATEWAY_URL ..."
microk8s kubectl apply -f "$GATEWAY_URL" || \
  error_exit "Failed to apply Bookinfo Gateway."

echo "[INFO] Bookinfo Gateway applied."

# 5. Get the Ingress IP and Port
# Try to get the external IP, fallback to ClusterIP if not available (common in local setups)
echo "[INFO] Retrieving Istio ingress gateway IP and port..."
INGRESS_HOST=$(microk8s kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$INGRESS_HOST" ]; then
  # Fallback to ClusterIP for local environments
  INGRESS_HOST=$(microk8s kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.clusterIP}')
  if [ -z "$INGRESS_HOST" ]; then
    error_exit "Could not determine ingress IP."
  fi
fi
# Get the port for HTTP traffic (named 'http2')
INGRESS_PORT=$(microk8s kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
if [ -z "$INGRESS_PORT" ]; then
  error_exit "Could not determine ingress port."
fi

echo "[INFO] Ingress IP: $INGRESS_HOST"
echo "[INFO] Ingress Port: $INGRESS_PORT"

# 6. Test the Ingress IP with curl
# This checks if the Bookinfo productpage is accessible via the gateway.
GATEWAY_URL="http://$INGRESS_HOST:$INGRESS_PORT/productpage"
echo "[INFO] Testing Bookinfo app at: $GATEWAY_URL"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL")
if [ "$HTTP_STATUS" = "200" ]; then
  echo "[SUCCESS] Bookinfo app is accessible at $GATEWAY_URL (HTTP 200)"
else
  echo "[WARNING] Bookinfo app test returned HTTP $HTTP_STATUS. Check deployment and logs."
fi 