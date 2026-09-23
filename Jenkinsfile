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
                sh 'docker compose -f docker-compose.ci.yml -p cloud-task-manager-ci up -d'
                sh 'sleep 10'
            }
        }

        stage('Test') {
            steps {
                sh 'DATABASE_URL=postgresql://task_user:password@localhost:5433/task_manager .venv/bin/pytest -v'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t cloud-task-manager:${BUILD_NUMBER} .'
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
                        aws ecr get-login-password --region ap-south-1 | \
                        docker login --username AWS --password-stdin \
                        148908330969.dkr.ecr.ap-south-1.amazonaws.com

                        docker tag cloud-task-manager:${BUILD_NUMBER} \
                        148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:${BUILD_NUMBER}

                        docker push \
                        148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    export KUBECIONFIG=/var/lib/jenkins/.kube/config

                    kubectl config current-context
                    kubectl get nodes


                    kubectl set image deployment/flask \
                    flask=148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:${BUILD_NUMBER}

                    kubectl rollout status deployment/flask
                '''
            }
        }
    }

    post {

        always {
            sh 'docker compose -f docker-compose.ci.yml -p cloud-task-manager-ci down -v || true'
        }

        success {
            echo 'Cloud-Native Task Manager CI pipeline completed successfully!'
        }

        failure {
            echo 'Cloud-Native Task Manager CI pipeline failed!'
        }
    }
}

