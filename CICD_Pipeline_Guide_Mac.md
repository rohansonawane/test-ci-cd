# CI/CD Pipeline Setup Guide for Mac
## Midterm Assignment: Docker, Kubernetes, Jenkins, and SonarQube

---

## Table of Contents
1. [Prerequisites & Installation](#prerequisites--installation)
2. [Part 1: Infrastructure Setup](#part-1-infrastructure-setup)
3. [Part 2: Docker Configuration](#part-2-docker-configuration)
4. [Part 3: Kubernetes Setup](#part-3-kubernetes-setup)
5. [Part 4: Jenkins Pipeline](#part-4-jenkins-pipeline)
6. [Part 5: Testing & Verification](#part-5-testing--verification)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites & Installation

### Step 1: Install Homebrew (if not already installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Install Docker Desktop for Mac
1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop
2. Install and start Docker Desktop
3. Verify installation:
```bash
docker --version
docker-compose --version
```

### Step 3: Install Minikube
```bash
brew install minikube
```

### Step 4: Install kubectl
```bash
brew install kubectl
```

### Step 5: Verify all installations
```bash
docker --version
minikube version
kubectl version --client
```

---

## Part 1: Infrastructure Setup

### Step 1.1: Create Custom Docker Network
```bash
docker network create ci_network
```

Verify the network:
```bash
docker network ls | grep ci_network
```

---

## Part 2: Docker Configuration

### Step 2.1: Run Jenkins Container

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  --network ci_network \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts
```

**Wait for Jenkins to start (about 1-2 minutes)**

### Step 2.2: Unlock Jenkins

Get the initial admin password:
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Copy this password - you'll need it shortly.

### Step 2.3: Access Jenkins
1. Open browser: http://localhost:8080
2. Paste the initial admin password
3. Click "Install suggested plugins"
4. Create your admin user account
5. Click "Save and Finish"

### Step 2.4: Install Required Jenkins Plugins

1. Go to: **Manage Jenkins → Manage Plugins → Available**
2. Search and install:
   - Pipeline
   - SonarQube Scanner
   - Docker Pipeline
   - Kubernetes Continuous Deploy
3. Click "Install without restart"
4. Check "Restart Jenkins when installation is complete"

### Step 2.5: Run SonarQube Container

```bash
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  --network ci_network \
  sonarqube:lts
```

**Wait for SonarQube to start (about 2-3 minutes)**

### Step 2.6: Access and Configure SonarQube

1. Open browser: http://localhost:9000
2. Login with:
   - Username: `admin`
   - Password: `admin`
3. Change password when prompted
4. Create a SonarQube token:
   - Click on your profile (top right)
   - My Account → Security → Generate Token
   - Name: `jenkins-token`
   - Click "Generate"
   - **COPY THIS TOKEN - YOU'LL NEED IT LATER**

### Step 2.7: Create Java Environment Containers

**Java 17 Build Container:**
```bash
docker run -dit \
  --name java17-builder \
  --network ci_network \
  openjdk:17-jdk
```

**Java 11 Test Container:**
```bash
docker run -dit \
  --name java11-tester \
  --network ci_network \
  openjdk:11-jdk
```

**Java 8 Analysis Container:**
```bash
docker run -dit \
  --name java8-analyzer \
  --network ci_network \
  openjdk:8-jdk
```

### Step 2.8: Verify All Containers

```bash
docker ps
```

You should see 5 running containers:
- jenkins
- sonarqube
- java17-builder
- java11-tester
- java8-analyzer

---

## Part 3: Kubernetes Setup

### Step 3.1: Start Minikube

```bash
minikube start
```

This may take 3-5 minutes on first run.

### Step 3.2: Verify Kubernetes Cluster

```bash
kubectl get nodes
```

Expected output:
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.xx.x
```

### Step 3.3: Create Kubernetes Deployment File

Create a file called `deployment.yaml`:

```bash
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: java-app
  template:
    metadata:
      labels:
        app: java-app
    spec:
      containers:
      - name: java-app
        image: YOUR_DOCKER_HUB_USERNAME/java-app:latest
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: java-app-service
spec:
  type: NodePort
  selector:
    app: java-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
    nodePort: 30007
EOF
```

**Important:** Replace `YOUR_DOCKER_HUB_USERNAME` with your actual Docker Hub username.

---

## Part 4: Jenkins Pipeline

### Step 4.1: Create a Sample Java Project

For this assignment, we'll use the Spring PetClinic project mentioned in the Jenkinsfile.

### Step 4.2: Set Up Docker Hub Credentials in Jenkins

1. Log into Jenkins (http://localhost:8080)
2. Go to: **Manage Jenkins → Manage Credentials**
3. Click on "(global)" domain
4. Click "Add Credentials"
5. Fill in:
   - Kind: Username with password
   - Username: Your Docker Hub username
   - Password: Your Docker Hub password
   - ID: `docker-hub-credentials`
   - Description: Docker Hub Credentials
6. Click "OK"

### Step 4.3: Configure SonarQube in Jenkins

1. Go to: **Manage Jenkins → Configure System**
2. Scroll to "SonarQube servers"
3. Click "Add SonarQube"
4. Fill in:
   - Name: `sonarqube`
   - Server URL: `http://sonarqube:9000`
   - Server authentication token: Click "Add" → Jenkins
     - Kind: Secret text
     - Secret: [paste your SonarQube token from Step 2.6]
     - ID: `sonarqube-token`
     - Click "Add"
   - Select the token you just created
5. Click "Save"

### Step 4.4: Create Jenkinsfile

Create a file called `Jenkinsfile`:

```bash
cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    
    environment {
        SONARQUBE_SERVER = 'http://sonarqube:9000'
        DOCKER_IMAGE = 'YOUR_DOCKER_HUB_USERNAME/java-app:latest'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/spring-projects/spring-petclinic.git'
            }
        }
        
        stage('Build') {
            steps {
                script {
                    docker.image('openjdk:17-jdk').inside {
                        sh 'chmod +x ./mvnw'
                        sh './mvnw clean package -DskipTests'
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    docker.image('openjdk:11-jdk').inside {
                        sh 'chmod +x ./mvnw'
                        sh './mvnw test'
                    }
                }
            }
        }
        
        stage('Static Code Analysis') {
            steps {
                script {
                    docker.image('openjdk:8-jdk').inside {
                        withSonarQubeEnv('sonarqube') {
                            sh 'chmod +x ./mvnw'
                            sh "./mvnw sonar:sonar -Dsonar.host.url=${SONARQUBE_SERVER}"
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t ${DOCKER_IMAGE} .'
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh 'docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}'
                        sh 'docker push ${DOCKER_IMAGE}'
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh 'kubectl apply -f deployment.yaml'
                }
            }
        }
    }
}
EOF
```

**Important:** Replace `YOUR_DOCKER_HUB_USERNAME` with your actual Docker Hub username.

### Step 4.5: Create Dockerfile for the Java Application

```bash
cat > Dockerfile << 'EOF'
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
```

### Step 4.6: Create Jenkins Pipeline Job

1. In Jenkins, click "New Item"
2. Enter name: `java-app-pipeline`
3. Select "Pipeline"
4. Click "OK"
5. Under "Pipeline" section:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your GitHub repository URL (or use the Spring PetClinic repo)
   - If using local files, select "Pipeline script" and paste the Jenkinsfile content
6. Click "Save"

---

## Part 5: Testing & Verification

### Step 5.1: Run the Pipeline

1. In Jenkins, open your `java-app-pipeline` job
2. Click "Build Now"
3. Watch the pipeline execute (this may take 10-15 minutes on first run)

### Step 5.2: Verify Each Stage

Monitor the Console Output to ensure:
- ✅ Checkout completes
- ✅ Build completes
- ✅ Tests pass
- ✅ SonarQube analysis completes
- ✅ Docker image builds
- ✅ Image pushes to Docker Hub
- ✅ Deployment to Kubernetes succeeds

### Step 5.3: Check Kubernetes Deployment

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

### Step 5.4: Access the Application

```bash
minikube service java-app-service
```

This will open the application in your browser.

### Step 5.5: Verify SonarQube Analysis

1. Go to http://localhost:9000
2. Click on "Projects"
3. You should see your project with code quality metrics

---

## Troubleshooting

### Issue: Jenkins can't connect to Docker

**Solution:**
```bash
# Give Jenkins access to Docker socket
docker exec -u root jenkins chmod 666 /var/run/docker.sock
```

Or restart Jenkins container with Docker socket mounted:
```bash
docker stop jenkins
docker rm jenkins

docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  --network ci_network \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

### Issue: Minikube won't start

**Solution:**
```bash
# Delete and restart
minikube delete
minikube start --driver=docker
```

### Issue: Port already in use

**Solution:**
```bash
# Find what's using the port
lsof -i :8080
# Kill the process or change the port
```

### Issue: SonarQube container exits

**Solution:**
```bash
# Check logs
docker logs sonarqube

# Increase Docker memory (Docker Desktop → Preferences → Resources)
# Set Memory to at least 4GB
```

### Issue: kubectl can't connect to cluster

**Solution:**
```bash
# Get Minikube IP and configure kubectl
minikube status
kubectl config use-context minikube
```

---

## Quick Reference Commands

### Docker Commands
```bash
# List all containers
docker ps -a

# View container logs
docker logs <container_name>

# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all networks
docker network prune
```

### Kubernetes Commands
```bash
# Get all resources
kubectl get all

# Describe a pod
kubectl describe pod <pod_name>

# View pod logs
kubectl logs <pod_name>

# Delete deployment
kubectl delete deployment java-app

# Delete service
kubectl delete service java-app-service
```

### Minikube Commands
```bash
# Start Minikube
minikube start

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete

# SSH into Minikube
minikube ssh

# Open Kubernetes dashboard
minikube dashboard
```

---

## Assignment Checklist

Before submitting, ensure:

- ✅ Docker network `ci_network` is created
- ✅ Jenkins is running and accessible at http://localhost:8080
- ✅ SonarQube is running and accessible at http://localhost:9000
- ✅ Three Java containers (8, 11, 17) are running
- ✅ Minikube cluster is running
- ✅ Jenkinsfile is created and configured
- ✅ deployment.yaml is created
- ✅ Pipeline runs successfully through all stages
- ✅ Application is deployed to Kubernetes
- ✅ Application is accessible via Minikube service
- ✅ SonarQube shows code analysis results
- ✅ Docker image is pushed to Docker Hub

---

## Additional Notes for Mac Users

1. **Docker Desktop Settings:**
   - Recommended: 4 CPUs, 8GB RAM
   - Enable Kubernetes in Docker Desktop (optional, but helpful)

2. **File Sharing:**
   - Ensure `/tmp` is added to File Sharing in Docker Desktop preferences

3. **Network Issues:**
   - If containers can't communicate, check if Docker Desktop is running
   - Verify firewall settings

4. **Performance:**
   - Close unnecessary applications
   - Monitor Activity Monitor during builds

---

## Next Steps: Real Industry Improvements

After completing the basic assignment, consider adding:

1. **Helm Charts for Kubernetes**
   ```bash
   brew install helm
   ```

2. **GitOps using Argo CD**
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

3. **Security Scanning using Trivy**
   ```bash
   brew install trivy
   ```

4. **Monitoring via Prometheus and Grafana**
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm install prometheus prometheus-community/kube-prometheus-stack
   ```

---

## Support Resources

- **Docker Documentation:** https://docs.docker.com/
- **Jenkins Documentation:** https://www.jenkins.io/doc/
- **Kubernetes Documentation:** https://kubernetes.io/docs/
- **SonarQube Documentation:** https://docs.sonarqube.org/
- **Minikube Documentation:** https://minikube.sigs.k8s.io/docs/

---

**Good luck with your assignment! 🚀**
