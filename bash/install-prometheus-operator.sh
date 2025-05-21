#!/bin/bash

# Download the latest bundle.yaml from kube-prometheus and apply it to Kubernetes
BUNDLE_URL="https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/main/manifests/setup/prometheus-operator-0alertmanagerCustomResourceDefinition.yaml"

# You may want to use the full bundle for the stack, but for the operator only, you can use the operator manifest
# For the full stack, see: https://github.com/prometheus-operator/kube-prometheus#quickstart

# Download and apply the operator bundle
curl -sSL -o bundle.yaml "$BUNDLE_URL"
kubectl apply -f bundle.yaml

# Clean up
rm bundle.yaml

echo "Prometheus Operator applied to your Kubernetes cluster." 