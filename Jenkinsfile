// =============================================================================
// RISE Application - Jenkins Pipeline
// =============================================================================
// This file must be placed in the ROOT of your RISE fork repository as 'Jenkinsfile':
//   https://github.com/DzhanerHalil/2526-dotnet-template/Jenkinsfile
//
// Prerequisites:
//   - Jenkins has Docker installed and jenkins user is in docker group
//   - Jenkins has Ansible installed
//   - Credentials configured: 'github-token', 'ghcr-credentials'
//   - Ansible playbooks available at /var/lib/jenkins/ansible/
// =============================================================================

pipeline {
    agent any

    environment {
        DOTNET_CLI_TELEMETRY_OPTOUT = '1'
        DOCKER_IMAGE = "ghcr.io/dzhanerhalil/rise-app"
        GIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        ANSIBLE_DIR = "/var/lib/jenkins/ansible"
    }

    stages {
        stage('Static Analysis') {
            steps {
                echo 'Running static analysis (dotnet format)...'
                sh 'dotnet format --verify-no-changes --verbosity diagnostic || true'
            }
        }

        stage('Build') {
            steps {
                echo 'Building RISE application...'
                sh 'dotnet build --configuration Release'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'dotnet test --configuration Release --logger trx --results-directory TestResults'
            }
            post {
                always {
                    // Archive test results
                    archiveArtifacts artifacts: 'TestResults/**/*.trx', allowEmptyArchive: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                echo "Building Docker image: ${DOCKER_IMAGE}:${GIT_SHA}"
                sh "docker build -t ${DOCKER_IMAGE}:${GIT_SHA} -t ${DOCKER_IMAGE}:latest ."
            }
        }

        stage('Docker Push') {
            steps {
                echo 'Pushing Docker image to GitHub Container Registry...'
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr-credentials',
                    usernameVariable: 'GHCR_USER',
                    passwordVariable: 'GHCR_TOKEN'
                )]) {
                    sh '''
                        echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USER}" --password-stdin
                        docker push ${DOCKER_IMAGE}:${GIT_SHA}
                        docker push ${DOCKER_IMAGE}:latest
                    '''
                }
            }
        }

        stage('Deploy Local') {
            steps {
                echo 'Deploying to local appserver via Ansible...'
                sh """
                    cd ${ANSIBLE_DIR}
                    ansible-playbook -i inventory/local deploy.yml \
                        -e deploy_tag=${GIT_SHA} \
                        --private-key ~/.ssh/ansible_ed25519
                """
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check the logs for details.'
        }
    }
}
