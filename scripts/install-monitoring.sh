#!/bin/bash
set -e

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitoring/kube-prometheus-values.yaml

kubectl get pods -n monitoring
echo "Prometheus and Grafana installed in monitoring namespace."
