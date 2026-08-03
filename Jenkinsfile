pipeline {
    agent any

    environment {
        DOTNET_CLI_TELEMETRY_OPTOUT = '1'
        DOTNET_NOLOGO               = '1'
        DOCKER_IMAGE                = 'ghcr.io/dzhanerhalil/rise-app'
        ANSIBLE_DIR                 = '/var/lib/jenkins/ansible'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    // Computed here, not in environment{}, because the
                    // environment block is evaluated before the workspace exists.
                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                }
                echo "Building commit ${env.GIT_SHA}"
            }
        }

        stage('Static Analysis') {
            steps {
                sh 'dotnet format --verify-no-changes --verbosity diagnostic || true'
            }
        }

        stage('Build') {
            steps {
                sh 'dotnet build --configuration Release'
            }
        }

        stage('Test') {
            steps {
                sh 'dotnet test --configuration Release --logger trx --results-directory TestResults'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'TestResults/**/*.trx', allowEmptyArchive: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${env.GIT_SHA} -t ${DOCKER_IMAGE}:latest ."
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr-credentials',
                    usernameVariable: 'GHCR_USER',
                    passwordVariable: 'GHCR_TOKEN'
                )]) {
                    sh '''
                        echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USER}" --password-stdin
                        docker push ${DOCKER_IMAGE}:${GIT_SHA}
                        docker push ${DOCKER_IMAGE}:latest
                        docker logout ghcr.io
                    '''
                }
            }
        }

        stage('Deploy Local') {
            steps {
                sh """
                    cd ${ANSIBLE_DIR}
                    ansible-playbook -i inventory/local deploy.yml -e deploy_tag=${env.GIT_SHA}
                """
            }
        }
    }

    post {
        success {
            echo "Deployed ${DOCKER_IMAGE}:${env.GIT_SHA} to https://192.168.56.20/"
        }
        failure {
            echo 'Pipeline failed — check the stage logs above.'
        }
        cleanup {
            cleanWs()
        }
    }
}