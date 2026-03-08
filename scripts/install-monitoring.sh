#!/bin/bash
set -e

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install monitoring-prometheus prometheus-community/prometheus \
  --namespace monitoring \
  -f monitoring/prometheus-values.yaml

helm upgrade --install monitoring-grafana grafana/grafana \
  --namespace monitoring \
  -f monitoring/grafana-values.yaml

kubectl get pods -n monitoring
echo "Prometheus and Grafana installed in monitoring namespace."
