#!/bin/bash
set -e

IMAGE="${1:-rsonawane2/java-cicd-demo:latest}"

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.58.1 image \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 0 \
  "$IMAGE"
