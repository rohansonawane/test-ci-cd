#!/bin/bash

# CI/CD Pipeline Cleanup Script
# Use this to remove all containers and reset the environment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo "🧹 CI/CD Pipeline Cleanup Script"
echo "=================================="
echo ""

print_warning "This will remove all CI/CD containers and data!"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Stopping and removing containers..."

# Stop and remove Jenkins
if docker ps -a --format '{{.Names}}' | grep -q "^jenkins$"; then
    docker stop jenkins
    docker rm jenkins
    print_success "Jenkins container removed"
fi

# Stop and remove SonarQube
if docker ps -a --format '{{.Names}}' | grep -q "^sonarqube$"; then
    docker stop sonarqube
    docker rm sonarqube
    print_success "SonarQube container removed"
fi

# Stop and remove Java containers
for container in java17-builder java11-tester java8-analyzer; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker stop $container
        docker rm $container
        print_success "$container container removed"
    fi
done

# Remove Docker network
if docker network inspect cicd-network >/dev/null 2>&1; then
    docker network rm cicd-network
    print_success "Docker network cicd-network removed"
fi

# Ask about Minikube
echo ""
read -p "Do you want to delete the Minikube cluster? (yes/no): " minikube_confirm

if [ "$minikube_confirm" = "yes" ]; then
    minikube delete
    print_success "Minikube cluster deleted"
fi

# Ask about volumes
echo ""
read -p "Do you want to remove Docker volumes (this will delete all data)? (yes/no): " volume_confirm

if [ "$volume_confirm" = "yes" ]; then
    docker volume rm jenkins_home 2>/dev/null || true
    print_success "Docker volumes removed"
fi

echo ""
print_success "Cleanup complete!"
echo ""
echo "To start fresh, run: ./setup-cicd-pipeline.sh"
