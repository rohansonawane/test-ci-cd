pipeline {
  agent any

  environment {
    IMAGE_NAME = 'DOCKER_HUB_USERNAME/java-cicd-demo:latest'
  }

  stages {
    stage('Checkout Code') {
      steps {
        checkout scm
      }
    }

    stage('Helm Chart Lint') {
      steps {
        sh 'docker run --rm -v "$PWD":/work -w /work alpine/helm:3.14.4 lint helm/java-cicd-demo'
      }
    }

    stage('Build with Java 17') {
      steps {
        script {
          docker.image('maven:3.9.9-eclipse-temurin-17').inside('--network cicd-network') {
            sh 'mvn -B clean package -DskipTests'
          }
        }
      }
    }

    stage('Run Tests with Java 11') {
      steps {
        script {
          docker.image('maven:3.9.9-eclipse-temurin-11').inside('--network cicd-network') {
            sh 'mvn -B test'
          }
        }
      }
    }

    stage('Static Analysis (Sonar on Java 11)') {
      steps {
        script {
          withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
            docker.image('maven:3.9.9-eclipse-temurin-11').inside('--network cicd-network') {
              sh '''
                mvn -B sonar:sonar \
                  -Dsonar.projectKey=java-cicd-demo \
                  -Dsonar.projectName=java-cicd-demo \
                  -Dsonar.host.url=http://sonarqube:9000 \
                  -Dsonar.login=${SONAR_TOKEN}
              '''
            }
          }
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          withCredentials([usernamePassword(
            credentialsId: 'docker-hub-credentials',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )]) {
            def builtImageName = IMAGE_NAME.replace('DOCKER_HUB_USERNAME', DOCKER_USER)
            env.BUILT_IMAGE_NAME = builtImageName
            sh "docker build -t ${builtImageName} ."
          }
        }
      }
    }

    stage('Trivy Security Scan') {
      steps {
        script {
          sh '''
            docker run --rm \
              -v /var/run/docker.sock:/var/run/docker.sock \
              aquasec/trivy:0.58.1 image \
              --severity HIGH,CRITICAL \
              --ignore-unfixed \
              --exit-code 0 \
              "${BUILT_IMAGE_NAME}"
          '''
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
            sh 'echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin'
            sh 'docker push "${BUILT_IMAGE_NAME}"'
          }
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        script {
          withCredentials([usernamePassword(
            credentialsId: 'docker-hub-credentials',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )]) {
            sh '''
              sed "s|DOCKER_HUB_USERNAME|${DOCKER_USER}|g" k8s/deployment.yaml | docker exec -i minikube /var/lib/minikube/binaries/v1.35.1/kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f -
              docker exec minikube /var/lib/minikube/binaries/v1.35.1/kubectl --kubeconfig=/etc/kubernetes/admin.conf rollout status deployment/java-cicd-demo
            '''
          }
        }
      }
    }
  }
}
