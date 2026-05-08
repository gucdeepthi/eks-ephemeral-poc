#!/bin/bash

set -e

CLUSTER_NAME=$1

if [ -z "$CLUSTER_NAME" ]; then
  echo "ERROR: Cluster name not provided"
  exit 1
fi

echo "Updating kubeconfig for cluster: $CLUSTER_NAME"

aws eks update-kubeconfig \
  --region ap-south-1 \
  --name $CLUSTER_NAME

echo "✅ kubeconfig updated successfully"