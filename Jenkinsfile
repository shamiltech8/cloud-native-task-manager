pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '148908330969.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'cloud-native-task-manager'
        CI_COMPOSE_PROJECT = "cloud-task-manager-ci-${BUILD_NUMBER}"
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.IMAGE_TAG = "build-${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
                    echo "Docker image tag: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Project Check') {
            steps {
                sh '''
                    set -eu
                    echo "Checking project files..."
                    pwd
                    ls -la
                    test -f Dockerfile
                    test -f requirements.txt
                    test -f docker-compose.ci.yml
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -eu
                    python3 -m venv .venv
                    .venv/bin/python -m pip install --upgrade pip
                    .venv/bin/python -m pip install -r requirements.txt
                    .venv/bin/python -m pip install pytest
                '''
            }
        }

        stage('Start CI Database') {
            steps {
                sh '''
                    set -eu

                    docker compose \
                        -f docker-compose.ci.yml \
                        -p "$CI_COMPOSE_PROJECT" \
                        up -d --wait --wait-timeout 60

                    docker compose \
                        -f docker-compose.ci.yml \
                        -p "$CI_COMPOSE_PROJECT" \
                        ps
                '''
            }
        }

        stage('Test') {
            steps {
                withEnv([
                    'SECRET_KEY=jenkins-ci-test-only-secret',
                    'DATABASE_URL=postgresql://task_user:password@localhost:5433/task_manager'
                ]) {
                    sh '''
                        set -eu
                        .venv/bin/python -m pytest -v
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu
                    docker build \
                        -t "$ECR_REPOSITORY:$IMAGE_TAG" .
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        set -eu
                        export AWS_DEFAULT_REGION="$AWS_REGION"

                        echo "Logging in to Amazon ECR..."

                        aws ecr get-login-password \
                            --region "$AWS_REGION" |
                        docker login \
                            --username AWS \
                            --password-stdin "$ECR_REGISTRY"

                        echo "Tagging Docker image..."

                        docker tag \
                            "$ECR_REPOSITORY:$IMAGE_TAG" \
                            "$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"

                        echo "Pushing Docker image to ECR..."

                        docker push \
                            "$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"

                        echo "ECR push completed successfully."
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    def previousImage = ''

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'aws-ecr',
                            usernameVariable: 'AWS_ACCESS_KEY_ID',
                            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                        )
                    ]) {
                        try {
                            sh '''
                                set -eu
                                export AWS_DEFAULT_REGION="$AWS_REGION"

                                echo "Checking Kubernetes cluster..."
                                kubectl config current-context
                                kubectl get nodes

                                echo "Refreshing ECR pull secret..."
                                kubectl create secret docker-registry ecr-secret \
                                    --docker-server="$ECR_REGISTRY" \
                                    --docker-username=AWS \
                                    --docker-password="$(aws ecr get-login-password --region "$AWS_REGION")" \
                                    --dry-run=client -o yaml |
                                kubectl apply -f -
                            '''

                            previousImage = sh(
                                script: '''
                                    kubectl get deployment flask \
                                        -o jsonpath='{.spec.template.spec.containers[?(@.name=="flask")].image}'
                                ''',
                                returnStdout: true
                            ).trim()

                            if (!previousImage) {
                                error('Could not determine the previous Flask image. Deployment stopped.')
                            }

                            echo "Previous Flask image recorded."

                            sh '''
                                set -eu

                                echo "Deploying the new image..."

                                kubectl set image deployment/flask \
                                    flask="$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"

                                kubectl rollout status \
                                    deployment/flask \
                                    --timeout=120s

                                echo "Deployment status:"
                                kubectl get deployment flask

                                echo "Pod status:"
                                kubectl get pods -l app=flask
                            '''
                        } catch (err) {
                            echo "Deployment failed: ${err}"

                            if (previousImage) {
                                echo "Attempting to restore the previous Flask image..."

                                withEnv(["PREVIOUS_IMAGE=${previousImage}"]) {
                                    sh '''
                                        set -eu
                                        kubectl set image deployment/flask \
                                            flask="$PREVIOUS_IMAGE"
                                        kubectl rollout status deployment/flask \
                                            --timeout=120s
                                    '''
                                }
                            }

                            throw err
                        }
                    }
                }
            }

            post {
                failure {
                    sh '''
                        kubectl get pods -l app=flask || true
                        kubectl describe deployment flask || true
                    '''
                }
            }
        }
    }

    post {
        always {
            sh '''
                docker compose \
                    -f docker-compose.ci.yml \
                    -p "$CI_COMPOSE_PROJECT" \
                    down -v || true
            '''
        }

        success {
            echo 'Cloud-Native Task Manager CI/CD pipeline completed successfully!'
        }

        failure {
            echo 'Cloud-Native Task Manager CI/CD pipeline failed!'
        }
    }
}
