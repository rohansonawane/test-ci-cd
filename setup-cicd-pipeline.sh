#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
  echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
  echo -e "${YELLOW}[INFO]${NC} $1"
}

require_or_install_brew_pkg() {
  local cmd="$1"
  local brew_pkg="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    print_success "$cmd already installed"
  else
    print_info "$cmd not found. Installing $brew_pkg with Homebrew..."
    brew install "$brew_pkg"
    print_success "Installed $brew_pkg"
  fi
}

echo "CI/CD pipeline environment setup"
echo "================================"

if ! command -v brew >/dev/null 2>&1; then
  print_error "Homebrew is required. Install it first: https://brew.sh/"
  exit 1
fi

require_or_install_brew_pkg kubectl kubernetes-cli
require_or_install_brew_pkg minikube minikube
require_or_install_brew_pkg mvn maven

if ! command -v docker >/dev/null 2>&1; then
  print_error "Docker CLI not found. Install Docker Desktop first."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  print_error "Docker daemon is not running. Start Docker Desktop and rerun this script."
  exit 1
fi
print_success "Docker daemon is running"

echo ""
echo "Step 1: create Docker network"
echo "-----------------------------"
if docker network inspect cicd-network >/dev/null 2>&1; then
  print_info "Network cicd-network already exists"
else
  docker network create cicd-network
  print_success "Network cicd-network created"
fi

echo ""
echo "Step 2: Jenkins container"
echo "-------------------------"
if docker ps -a --format '{{.Names}}' | grep -q '^jenkins$'; then
  if docker ps --format '{{.Names}}' | grep -q '^jenkins$'; then
    print_info "Jenkins is already running"
  else
    docker start jenkins
    print_success "Jenkins container started"
  fi
else
  docker run -d \
    --name jenkins \
    -p 8080:8080 \
    -p 50000:50000 \
    --network cicd-network \
    -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
    -v jenkins_home:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    jenkins/jenkins:lts
  print_success "Jenkins container created"
fi

echo ""
echo "Step 3: SonarQube container"
echo "---------------------------"
if docker ps -a --format '{{.Names}}' | grep -q '^sonarqube$'; then
  if docker ps --format '{{.Names}}' | grep -q '^sonarqube$'; then
    print_info "SonarQube is already running"
  else
    docker start sonarqube
    print_success "SonarQube container started"
  fi
else
  docker run -d \
    --name sonarqube \
    -p 9000:9000 \
    --network cicd-network \
    sonarqube:lts
  print_success "SonarQube container created"
fi

echo ""
echo "Step 4: Java environment containers"
echo "-----------------------------------"
for name in java17-builder java11-tester java8-analyzer; do
  if docker ps -a --format '{{.Names}}' | grep -q "^${name}$"; then
    if docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
      print_info "$name already running"
    else
      docker start "$name"
      print_success "$name started"
    fi
  else
    case "$name" in
      java17-builder) image='eclipse-temurin:17-jdk' ;;
      java11-tester) image='eclipse-temurin:11-jdk' ;;
      java8-analyzer) image='eclipse-temurin:8-jdk' ;;
    esac
    docker run -dit --name "$name" --network cicd-network "$image"
    print_success "$name created"
  fi
done

echo ""
echo "Step 5: Minikube"
echo "----------------"
if minikube status >/dev/null 2>&1; then
  print_info "Minikube appears to be available. Starting (or ensuring) cluster..."
else
  print_info "Initializing Minikube..."
fi
minikube start --driver=docker
print_success "Minikube ready"

echo ""
echo "Setup completed."
echo ""
echo "Next steps:"
echo "1) Jenkins: http://localhost:8080"
echo "   Password: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
echo "2) SonarQube: http://localhost:9000 (admin/admin)"
echo "3) Verify Kubernetes: kubectl get nodes"
echo "4) Follow project README for Jenkins credentials and pipeline run"
