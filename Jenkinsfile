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
          docker.image('maven:3.9.9-eclipse-temurin-11').inside('--network cicd-network') {
            withSonarQubeEnv('sonarqube') {
              sh '''
                mvn -B sonar:sonar \
                  -Dsonar.projectKey=java-cicd-demo \
                  -Dsonar.projectName=java-cicd-demo \
                  -Dsonar.host.url=http://sonarqube:9000
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
              sed "s|DOCKER_HUB_USERNAME|${DOCKER_USER}|g" k8s/deployment.yaml | kubectl apply -f -
              kubectl rollout status deployment/java-cicd-demo
            '''
          }
        }
      }
    }
  }
}
