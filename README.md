# Midterm CI/CD Assignment Project

This project is a complete submission-ready setup for:

- Jenkins automation pipeline
- SonarQube static analysis
- Docker container build and push
- Kubernetes deployment using Minikube
- Multi-Java validation (Java 17 build, Java 11 test, Java 8 analysis)

## Project Structure

- `src/main/java/com/rohan/cicd/App.java`: simple Java HTTP app on port `8080`
- `src/test/java/com/rohan/cicd/AppTest.java`: unit test
- `pom.xml`: Maven build config compatible with Java 8+
- `Dockerfile`: image for runtime deployment
- `Jenkinsfile`: complete CI/CD pipeline
- `k8s/deployment.yaml`: Kubernetes deployment + NodePort service
- `setup-cicd-pipeline.sh`: setup script with pre-check and install behavior
- `cleanup-cicd-pipeline.sh`: cleanup/reset script

## What I Completed From Your PDF

1. Checkout stage in Jenkins (`checkout scm`)
2. Java 17 build stage
3. Java 11 unit test stage
4. Java 8 SonarQube analysis stage
5. Docker image build stage
6. Docker Hub push stage
7. Kubernetes deployment stage
8. Docker network and service container setup script
9. Kubernetes deployment manifest (deployment + service)

## Prerequisites (Mac)

- Docker Desktop installed and running
- Homebrew installed
- Jenkins and SonarQube run in Docker
- Docker Hub account

## One-Time Setup

Run:

```bash
chmod +x setup-cicd-pipeline.sh cleanup-cicd-pipeline.sh
./setup-cicd-pipeline.sh
```

The setup script checks tools first and installs missing ones (`kubectl`, `minikube`, `maven`) before moving forward.

## Jenkins UI Configuration

1. Open `http://localhost:8080`
2. Unlock Jenkins:
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Install plugins:
   - Pipeline
   - SonarQube Scanner
   - Docker Pipeline
   - Kubernetes Continuous Deploy
4. Create credentials:
   - **ID**: `docker-hub-credentials` (username/password)
5. Configure SonarQube:
   - Name: `sonarqube`
   - URL: `http://sonarqube:9000`
   - Token from SonarQube (`admin/admin` -> My Account -> Security)

## Create Pipeline Job

1. New Item -> Pipeline
2. Pipeline Definition -> Pipeline script from SCM
3. Repo URL: `https://github.com/rohansonawane/test-ci-cd.git`
4. Script Path: `Jenkinsfile`
5. Save -> Build Now

## Kubernetes Verification

```bash
kubectl get nodes
kubectl get deployment,service,pods
minikube service java-cicd-demo-service
```

## Push This Project to Your GitHub Repo

Your repo is currently empty, so run:

```bash
git init
git add .
git commit -m "Set up complete CI/CD assignment with Jenkins Docker SonarQube and Kubernetes"
git branch -M main
git remote add origin https://github.com/rohansonawane/test-ci-cd.git
git push -u origin main
```

If GitHub asks for auth, use your personal access token as password.
