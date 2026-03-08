#!/bin/bash
set -e

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
# Use server-side apply to avoid oversized last-applied annotations on CRDs.
kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deployment/argocd-server --timeout=180s
kubectl apply -f argocd/java-cicd-demo-app.yaml

echo "Argo CD installed and application manifest applied."
