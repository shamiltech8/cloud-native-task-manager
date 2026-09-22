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

        stage('Test') {
            steps {
                sh 'python3 --version'
                sh 'pytest'
            }
        }
    }

    post {
        success {
            echo 'Cloud-Native Task Manager CI pipeline completed successfully!'
        }

        failure {
            echo 'Cloud-Native Task Manager CI pipeline failed!'
        }
    }
}
