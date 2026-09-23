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
                sh '''
                    echo "Jenkins workspace:"
                    pwd

                    echo "Docker images available to Jenkins:"
                    docker images | head -20
                '''
            }
        }

        stage('Test ECR Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "========================================"
                        echo "Testing AWS credentials..."
                        echo "========================================"

                        aws sts get-caller-identity

                        echo "========================================"
                        echo "Logging into ECR..."
                        echo "========================================"

                        aws ecr get-login-password \
                        --region ap-south-1 | \
                        docker login \
                        --username AWS \
                        --password-stdin \
                        148908330969.dkr.ecr.ap-south-1.amazonaws.com

                        echo "========================================"
                        echo "Checking existing image..."
                        echo "========================================"

                        docker image inspect \
                        148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:21

                        echo "========================================"
                        echo "Pushing image :21 to ECR..."
                        echo "========================================"

                        docker push \
                        148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:21

                        echo "========================================"
                        echo "ECR PUSH TEST COMPLETED"
                        echo "========================================"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'ECR push test succeeded!'
        }

        failure {
            echo 'ECR push test failed!'
        }
    }
}
