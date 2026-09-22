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

        stage('Start Database') {
            steps {
                sh 'docker compose up -d postgres'
                sh 'sleep 10'
            }
        }

        stage('Test') {
            steps {
                sh 'DATABASE_URL=postgresql://task_user:password@localhost:5432/task_manager .venv/bin/pytest'
            }
        }
    }

    post {
        always {
            sh 'docker compose down -v || true'
        }

        success {
            echo 'Cloud-Native Task Manager CI pipeline completed successfully!'
        }

        failure {
            echo 'Cloud-Native Task Manager CI pipeline failed!'
        }
    }
}
