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

        stage('Test') {
            steps {
                sh '.venv/bin/python --version'
                sh '.venv/bin/pytest'
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
