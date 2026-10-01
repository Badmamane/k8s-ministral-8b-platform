#!/usr/bin/env bash
set -euo pipefail

cluster="${PROJECT:-k8s-ministral-8b}-${ENV:-dev}"
region="${AWS_REGION:-us-east-1}"

aws eks update-kubeconfig --name "$cluster" --region "$region" >/dev/null
kubectl get nodes -o wide
echo "[test] cluster reachable"
