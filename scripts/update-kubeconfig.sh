#!/bin/bash

CLUSTER_NAME=$1

aws eks update-kubeconfig \
  --region ap-south-1 \
  --name $CLUSTER_NAME