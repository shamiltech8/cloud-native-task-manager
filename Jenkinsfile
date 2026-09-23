pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Project Check') {
            steps {
                sh 'pwd'
                sh 'ls -la'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'python3 -m venv .venv'
                sh '.venv/bin/python -m pip install -r requirements.txt'
            }
        }

        stage('Start CI Database') {
            steps {
                sh '''
                    docker compose \
                    -f docker-compose.ci.yml \
                    -p cloud-task-manager-ci \
                    up -d

                    sleep 10
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    DATABASE_URL=postgresql://task_user:password@localhost:5433/task_manager \
                    .venv/bin/pytest -v
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                    -t cloud-task-manager:${BUILD_NUMBER} .
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

                    retry(3) {

                        sh '''
                            echo "Logging in to Amazon ECR..."

                            aws ecr get-login-password \
                            --region ap-south-1 | \
                            docker login \
                            --username AWS \
                            --password-stdin \
                            148908330969.dkr.ecr.ap-south-1.amazonaws.com

                            echo "Tagging Docker image..."

                            docker tag \
                            cloud-task-manager:${BUILD_NUMBER} \
                            148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:${BUILD_NUMBER}

                            echo "Pushing Docker image to ECR..."

                            docker push \
                            148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:${BUILD_NUMBER}

                            echo "ECR push completed successfully."
                        '''
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    export KUBECONFIG=/var/lib/jenkins/.kube/config

                    echo "Checking Kubernetes cluster..."

                    kubectl config current-context
                    kubectl get nodes

                    echo "Deploying image..."

                    kubectl set image deployment/flask \
                    flask=148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:${BUILD_NUMBER}

                    echo "Waiting for rollout..."

                    kubectl rollout status \
                    deployment/flask \
                    --timeout=120s

                    echo "Deployment status:"

                    kubectl get deployment flask

                    echo "Pod status:"

                    kubectl get pods -l app=flask
                '''
            }

            post {
                failure {
                    sh '''
                        echo "Kubernetes deployment failed."

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
                -p cloud-task-manager-ci \
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

