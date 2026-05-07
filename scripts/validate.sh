#!/bin/bash

echo "Pods:"
kubectl get pods -A

echo "Services:"
kubectl get svc

echo "Helm:"
helm list