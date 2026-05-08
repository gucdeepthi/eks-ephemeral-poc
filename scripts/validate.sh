#!/bin/bash

set -e

echo "==== Validating Kubernetes access ===="

# ✅ Check kubectl connectivity
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "ERROR: Kubernetes cluster not reachable"
  exit 1
fi

# ✅ Wait for nodes to be ready (retry logic)
echo "Waiting for nodes to be ready..."

for i in {1..10}; do
  READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready")

  if [ "$READY_NODES" -gt 0 ]; then
    echo "✅ Nodes are ready"
    break
  fi

  echo "Retry $i: Nodes not ready yet..."
  sleep 15
done

# ✅ Final check
kubectl get nodes

echo "Pods:"
kubectl get pods -A

echo "Services:"
kubectl get svc

echo "Helm:"
helm list

echo "✅ Validation complete"