pipeline {
  agent any

  tools {
    maven 'maven3'
    jdk 'jdk-17'
  }

  environment {
    SCANNER_HOME = tool 'sonar-scanner'
    IMAGE_REPO = 'pankajdhapade1998/ekart'
    IMAGE_TAG = "${env.BUILD_NUMBER}"
  }

  options {
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  stages {

    stage('Clean Workspace') {
      steps {
        cleanWs()
      }
    }

    stage('Checkout Code') {
      steps {
        git branch: 'master', url: 'https://github.com/PankajDhapade1998/Ekart.git'
      }
    }

    stage('Compile') {
      steps {
        sh 'mvn compile'
      }
    }

    stage('Unit Tests') {
      steps {
        sh 'mvn test'
      }
      post {
        always {
          junit '**/target/surefire-reports/*.xml'
        }
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('sonar') {
          sh """${SCANNER_HOME}/bin/sonar-scanner \
            -Dsonar.projectKey=EKART \
            -Dsonar.projectName=EKART \
            -Dsonar.java.binaries=target/classes"""
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 1, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('OWASP Dependency Check') {
      steps {
        dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'DC'
        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
      }
    }

    stage('Build & Deploy to Nexus') {
      steps {
        withMaven(globalMavenSettingsConfig: 'global-maven', jdk: 'jdk-17', maven: 'maven3') {
          sh 'mvn package deploy -DskipTests=true'
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          sh "docker build -t ${IMAGE_REPO}:${IMAGE_TAG} -f docker/Dockerfile ."
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh """
            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
            docker push ${IMAGE_REPO}:${IMAGE_TAG}
          """
        }
      }
    }

    stage('Configure kubectl for EKS') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-eks-creds']]) {
          sh 'aws eks update-kubeconfig --region ap-south-1 --name pankaj-cluster'
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh "kubectl apply -f deploymentservice.yml"
        sh "kubectl rollout status deployment/ekart-deployment"
      }
    }
  }

  post {
    success {
      echo "✅ Build #${env.BUILD_NUMBER} completed successfully."
    }
    failure {
      mail to: 'team@example.com',
           subject: "🚨 Jenkins Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
           body: "Check console logs at ${env.BUILD_URL}"
    }
    always {
      cleanWs()
    }
  }
}
