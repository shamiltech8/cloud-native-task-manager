# Module 10 — Jenkins CI/CD

## Cloud-Native Task Management Application

This module integrates **Jenkins, Docker, Amazon ECR, and Kubernetes** to create an automated CI/CD pipeline for the Cloud-Native Task Management Application.

The pipeline automates the complete workflow:

```text
Developer Push
      ↓
    GitHub
      ↓
    Jenkins
      ↓
  Run Tests
      ↓
 Build Docker Image
      ↓
 Amazon ECR
      ↓
 Kubernetes Deployment
      ↓
 Rollout Verification
```

---

## 1. Module Objective

The objective of Module 10 is to implement a Jenkins-based CI/CD pipeline that automatically:

* Retrieves application code from GitHub
* Creates a Python virtual environment
* Installs project dependencies
* Starts a PostgreSQL database for CI testing
* Runs automated tests
* Builds the Docker image
* Pushes the image to Amazon ECR
* Deploys the new image to Kubernetes
* Verifies the Kubernetes rollout
* Cleans up temporary CI resources

This changes the project from a manually deployed application into an automated CI/CD workflow.

---

# 2. Technologies Used

| Technology     | Purpose                  |
| -------------- | ------------------------ |
| GitHub         | Source code management   |
| Jenkins        | CI/CD automation         |
| Python         | Application and testing  |
| Pytest         | Automated testing        |
| PostgreSQL     | Application database     |
| Docker         | Containerization         |
| Docker Compose | CI database environment  |
| Amazon ECR     | Docker image registry    |
| Kubernetes     | Container orchestration  |
| Minikube       | Local Kubernetes cluster |
| AWS CLI        | AWS integration          |
| Git            | Version control          |

---

# 3. CI/CD Architecture

The implemented architecture is:

```text
                    ┌──────────────┐
                    │    GitHub    │
                    │ Source Code  │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   Jenkins    │
                    │   Pipeline   │
                    └──────┬───────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
       Install Dependencies       Start PostgreSQL
              │                         │
              └────────────┬────────────┘
                           ▼
                    ┌──────────────┐
                    │    Pytest    │
                    │ 4 Tests Pass │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ Docker Build │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │  Amazon ECR  │
                    │ Image Registry│
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │  Kubernetes  │
                    │   Minikube   │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │  Rollout     │
                    │ Verification │
                    └──────────────┘
```

---

# 4. Jenkins Pipeline Flow

The Jenkins pipeline follows this sequence:

```text
Checkout
   ↓
Project Check
   ↓
Install Dependencies
   ↓
Start CI Database
   ↓
Run Tests
   ↓
Build Docker Image
   ↓
Push Image to Amazon ECR
   ↓
Deploy to Kubernetes
   ↓
Verify Rollout
   ↓
Cleanup
```

Each stage performs one specific responsibility.

---

# 5. Jenkins Pipeline Stages

## 5.1 Checkout

Jenkins retrieves the project source code from GitHub.

```groovy
stage('Checkout') {
    steps {
        checkout scm
    }
}
```

The pipeline works with the repository:

```text
cloud-native-task-manager
```

---

## 5.2 Project Check

This stage verifies the Jenkins workspace and displays the project files.

```groovy
stage('Project Check') {
    steps {
        sh 'pwd'
        sh 'ls -la'
    }
}
```

This is useful for troubleshooting because it confirms that Jenkins checked out the expected project.

---

## 5.3 Install Dependencies

A Python virtual environment is created and project dependencies are installed.

```groovy
stage('Install Dependencies') {
    steps {
        sh 'python3 -m venv .venv'
        sh '.venv/bin/python -m pip install -r requirements.txt'
    }
}
```

The dependencies are defined in:

```text
requirements.txt
```

The pipeline therefore uses the same dependency definition as the application.

---

# 6. CI PostgreSQL Database

The tests require PostgreSQL.

Instead of depending on an external database, Jenkins starts a temporary PostgreSQL container using Docker Compose.

```groovy
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
```

The CI environment uses:

```text
docker-compose.ci.yml
```

The PostgreSQL container is exposed to Jenkins through the configured CI port.

The test database connection used by Jenkins is:

```text
postgresql://task_user:password@localhost:5433/task_manager
```

The CI database is temporary and is removed after the pipeline finishes.

---

# 7. Automated Testing

The `Test` stage executes the project's Pytest test suite.

```groovy
stage('Test') {
    steps {
        sh '''
            DATABASE_URL=postgresql://task_user:password@localhost:5433/task_manager \
            .venv/bin/pytest -v
        '''
    }
}
```

The database URL is supplied through the `DATABASE_URL` environment variable.

The successful pipeline verified four tests:

```text
relationship_test.py::test_user_tasks_relationship
test_db.py::test_database_connection
test_relationship.py::test_user_task_relationship
test_user.py::test_create_user
```

Result:

```text
4 passed
```

Testing occurs **before** the Docker image is built and deployed.

This prevents a failed test from continuing to the deployment stages.

---

# 8. Docker Image Build

After the tests pass, Jenkins builds the Docker image.

```groovy
stage('Build Docker Image') {
    steps {
        sh '''
            docker build \
            -t cloud-task-manager:${BUILD_NUMBER} .
        '''
    }
}
```

Jenkins uses the build number as the Docker image tag.

For example:

```text
Build #31
```

creates:

```text
cloud-task-manager:31
```

Using the Jenkins build number makes individual builds easy to identify.

---

# 9. Amazon ECR

Amazon Elastic Container Registry (ECR) is used as the Docker image registry.

The project repository is:

```text
cloud-native-task-manager
```

The ECR registry is located in:

```text
ap-south-1
```

The Docker image follows this format:

```text
<registry>/cloud-native-task-manager:<BUILD_NUMBER>
```

Example:

```text
148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:31
```

---

# 10. Jenkins → AWS Authentication

AWS credentials are stored in Jenkins Credentials instead of being written directly into the Jenkinsfile.

The Jenkins credential ID used by the pipeline is:

```text
aws-ecr
```

The pipeline accesses the credentials using:

```groovy
withCredentials([
    usernamePassword(
        credentialsId: 'aws-ecr',
        usernameVariable: 'AWS_ACCESS_KEY_ID',
        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
    )
])
```

This allows Jenkins to authenticate with AWS during the pipeline.

AWS credentials should **never be committed to GitHub**.

---

# 11. ECR Login

Jenkins authenticates Docker with Amazon ECR:

```bash
aws ecr get-login-password \
    --region ap-south-1 | \
    docker login \
    --username AWS \
    --password-stdin \
    148908330969.dkr.ecr.ap-south-1.amazonaws.com
```

The AWS CLI generates a temporary authentication token.

Docker then uses this token to authenticate with ECR.

---

# 12. Tagging the Docker Image

The locally built image is tagged with the ECR repository:

```bash
docker tag \
cloud-task-manager:${BUILD_NUMBER} \
148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:${BUILD_NUMBER}
```

For Build #31:

```text
cloud-task-manager:31
```

becomes:

```text
148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:31
```

---

# 13. Push Docker Image to ECR

The image is pushed to ECR:

```bash
docker push \
148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:${BUILD_NUMBER}
```

The successful Build #31 pushed image:

```text
cloud-native-task-manager:31
```

to Amazon ECR.

The push produced the image digest:

```text
sha256:c0d8...d205a86d
```

The full digest is recorded in the Jenkins build output.

---

# 14. ECR Push Reliability

During development, ECR pushes occasionally failed because of intermittent network connection problems.

Examples included:

```text
connection reset by peer
```

and:

```text
timeout awaiting response headers
```

The ECR endpoint itself was reachable, and AWS authentication and repository access were verified.

To make the pipeline more resilient, the ECR push operation was wrapped in:

```groovy
retry(3) {
    sh '''
        ...
    '''
}
```

This allows Jenkins to retry the ECR operation when a temporary network failure occurs.

The retry mechanism successfully allowed a later attempt to complete an ECR push during testing.

---

# 15. Kubernetes Deployment

After the image is successfully pushed to ECR, Jenkins deploys the new image to Kubernetes.

The pipeline uses:

```bash
kubectl set image deployment/flask \
    flask=148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:${BUILD_NUMBER}
```

For Build #31:

```text
deployment/flask
        ↓
ECR image :31
```

Kubernetes then creates a new ReplicaSet and replaces the old application pods according to the Deployment strategy.

---

# 16. Kubernetes Cluster

The project uses Minikube as the Kubernetes environment.

The Jenkins deployment stage verifies the cluster before deployment:

```bash
export KUBECONFIG=/var/lib/jenkins/.kube/config

kubectl config current-context
kubectl get nodes
```

Expected context:

```text
minikube
```

The Kubernetes node must be in the:

```text
Ready
```

state.

---

# 17. Kubernetes ECR Authentication

Kubernetes needs permission to pull the private Docker image from ECR.

The project uses a Kubernetes Docker registry secret:

```text
ecr-secret
```

Jenkins automatically refreshes this secret before deployment:

```bash
kubectl create secret docker-registry ecr-secret \
    --docker-server=148908330969.dkr.ecr.ap-south-1.amazonaws.com \
    --docker-username=AWS \
    --docker-password="$(aws ecr get-login-password --region ap-south-1)" \
    --dry-run=client \
    -o yaml | kubectl apply -f -
```

This is important because ECR authentication tokens are temporary.

The deployment therefore does not depend on an old ECR token remaining valid.

---

# 18. Kubernetes Image Pull Secret

The Flask Deployment references the secret:

```yaml
spec:
  imagePullSecrets:
    - name: ecr-secret
```

This allows Kubernetes to authenticate with ECR when pulling the private application image.

The workflow is:

```text
Jenkins
   ↓
AWS ECR authentication
   ↓
Refresh ecr-secret
   ↓
Kubernetes
   ↓
Pull private ECR image
```

---

# 19. Kubernetes Rollout Verification

After changing the image, Jenkins waits for Kubernetes to complete the rollout.

```bash
kubectl rollout status \
    deployment/flask \
    --timeout=120s
```

This prevents Jenkins from reporting a successful deployment before Kubernetes has actually completed the rollout.

The pipeline then displays the Deployment:

```bash
kubectl get deployment flask
```

and the Flask pods:

```bash
kubectl get pods -l app=flask
```

---

# 20. Successful Deployment

The successful Build #31 deployment produced:

```text
flask   3/3   3   3
```

The new Flask pods were:

```text
1/1 Running
```

with:

```text
0 restarts
```

This confirms that the new application image was successfully deployed to the Kubernetes cluster.

---

# 21. Kubernetes Manifests

The Kubernetes configuration is stored under:

```text
k8s/
```

Current project manifests include:

```text
k8s/
├── flask-configmap.yaml
├── flask-deployment.yaml
├── flask-service.yaml
├── postgres-deployment.yaml
├── postgres-pvc.yaml
├── postgres-secret.yaml
└── postgres-service.yaml
```

### Flask

The Flask application is deployed through:

```text
flask-deployment.yaml
```

and exposed through:

```text
flask-service.yaml
```

The Flask service uses:

```text
NodePort: 30080
```

### PostgreSQL

PostgreSQL is deployed through:

```text
postgres-deployment.yaml
```

and exposed internally through:

```text
postgres-service.yaml
```

Persistent storage is configured through:

```text
postgres-pvc.yaml
```

Database configuration is provided through:

```text
postgres-secret.yaml
```

and:

```text
flask-configmap.yaml
```

---

# 22. Complete Jenkinsfile

The CI/CD pipeline is defined in the root-level:

```text
Jenkinsfile
```

The pipeline performs:

```text
Checkout
→ Project Check
→ Install Dependencies
→ Start CI Database
→ Test
→ Build Docker Image
→ Push Image to ECR
→ Deploy to Kubernetes
→ Rollout Verification
→ Cleanup
```

The Jenkinsfile is version-controlled together with the application source code.

---

# 23. Pipeline Cleanup

The temporary CI database is removed after every build.

```groovy
post {
    always {
        sh '''
            docker compose \
            -f docker-compose.ci.yml \
            -p cloud-task-manager-ci \
            down -v || true
        '''
    }
}
```

The `always` block means cleanup is attempted whether the build succeeds or fails.

This prevents temporary PostgreSQL containers and volumes from accumulating on the Jenkins machine.

---

# 24. Jenkins Post Actions

The pipeline also reports whether the build succeeded or failed.

### Successful build

```groovy
success {
    echo 'Cloud-Native Task Manager CI/CD pipeline completed successfully!'
}
```

### Failed build

```groovy
failure {
    echo 'Cloud-Native Task Manager CI/CD pipeline failed!'
}
```

This provides a clear final status in the Jenkins console.

---

# 25. Real Troubleshooting During Module 10

This module included several real CI/CD troubleshooting situations.

## 25.1 PostgreSQL hostname problem

Initially, tests attempted to use:

```text
postgres
```

as the database hostname.

This hostname works inside the Docker Compose network, but the Jenkins test process runs outside that network.

The CI configuration was therefore changed so Jenkins tests connect through:

```text
localhost:5433
```

using:

```text
DATABASE_URL=postgresql://task_user:password@localhost:5433/task_manager
```

---

## 25.2 ECR connection failures

Some Jenkins builds experienced:

```text
connection reset by peer
```

or:

```text
timeout awaiting response headers
```

during Docker image pushes.

AWS CLI access, ECR repository access, DNS resolution, and endpoint connectivity were tested.

A retry mechanism was added:

```groovy
retry(3) {
    sh '''
        ...
    '''
}
```

This improved resilience against temporary network failures.

---

## 25.3 Expired ECR Kubernetes token

A Kubernetes rollout once failed with:

```text
ImagePullBackOff
```

The pod description showed:

```text
403 Forbidden
```

with an expired ECR authorization token.

The ECR pull secret was refreshed:

```bash
kubectl create secret docker-registry ecr-secret ...
```

After refreshing the secret and replacing the failed pod, the new pod successfully pulled the image and started.

This led to an important improvement in the final pipeline:

```text
Refresh ECR secret automatically before deployment
```

---

## 25.4 Minikube unavailable

A deployment can fail if Minikube is stopped.

The pipeline therefore checks Kubernetes before attempting the deployment:

```bash
kubectl config current-context
kubectl get nodes
```

The node must be available and ready before the deployment can succeed.

---

# 26. Security Considerations

The CI/CD pipeline uses several security practices.

### AWS credentials

AWS credentials are stored in Jenkins Credentials:

```text
aws-ecr
```

They are not hard-coded into the Jenkinsfile.

### Kubernetes ECR authentication

The ECR pull secret is refreshed automatically instead of relying on an expired authentication token.

### GitHub secrets

The following information must never be committed to GitHub:

```text
AWS Access Key
AWS Secret Access Key
ECR passwords/tokens
Database passwords
Private SSH keys
Jenkins credentials
```

### Important project improvement

The current Flask Kubernetes Deployment contains a database URL with a password directly in the manifest.

For stronger security, the database password should eventually be moved completely into a Kubernetes Secret and injected into the application rather than keeping the password directly in the Deployment YAML.

---

# 27. Important Jenkins Commands

Check Jenkins service:

```bash
sudo systemctl status jenkins
```

Restart Jenkins:

```bash
sudo systemctl restart jenkins
```

Check Jenkins logs:

```bash
sudo journalctl -u jenkins -f
```

---

# 28. Important Docker Commands

Check Docker:

```bash
docker --version
```

Build an image:

```bash
docker build -t cloud-task-manager:test .
```

List images:

```bash
docker images
```

Check Docker Compose:

```bash
docker compose ps
```

Stop the CI database:

```bash
docker compose \
-f docker-compose.ci.yml \
-p cloud-task-manager-ci \
down -v
```

---

# 29. Important AWS ECR Commands

Authenticate with ECR:

```bash
aws ecr get-login-password \
--region ap-south-1 | \
docker login \
--username AWS \
--password-stdin \
148908330969.dkr.ecr.ap-south-1.amazonaws.com
```

List repositories:

```bash
aws ecr describe-repositories \
--region ap-south-1
```

List images:

```bash
aws ecr list-images \
--repository-name cloud-native-task-manager \
--region ap-south-1
```

---

# 30. Important Kubernetes Commands

Check cluster:

```bash
kubectl get nodes
```

Check all resources:

```bash
kubectl get all
```

Check Flask Deployment:

```bash
kubectl get deployment flask
```

Check Flask pods:

```bash
kubectl get pods -l app=flask
```

Check services:

```bash
kubectl get services
```

Check rollout:

```bash
kubectl rollout status deployment/flask
```

Check Deployment history:

```bash
kubectl rollout history deployment/flask
```

Check pod details:

```bash
kubectl describe pod <pod-name>
```

Check logs:

```bash
kubectl logs <pod-name>
```

---

# 31. Final CI/CD Workflow

The complete workflow implemented in this project is:

```text
                    Developer
                       │
                       ▼
                    GitHub
                       │
                       ▼
                   Jenkins
                       │
                       ▼
              Checkout Source Code
                       │
                       ▼
             Install Dependencies
                       │
                       ▼
              Start PostgreSQL
                       │
                       ▼
                  Run Pytest
                       │
                ┌──────┴──────┐
                │             │
             Failed        Passed
                │             │
                ▼             ▼
             Stop        Build Docker
             Build           Image
                              │
                              ▼
                         Push to ECR
                              │
                              ▼
                    Refresh ECR Secret
                              │
                              ▼
                    Update Kubernetes
                              │
                              ▼
                    Rollout Verification
                              │
                              ▼
                       Running Pods
                              │
                              ▼
                           Cleanup
```

---

# 32. Final Result

The Module 10 CI/CD implementation successfully connected:

```text
GitHub
   ↓
Jenkins
   ↓
Pytest
   ↓
Docker
   ↓
Amazon ECR
   ↓
Kubernetes
```

The final successful Jenkins build demonstrated:

* Source code checkout succeeded
* Python dependencies installed
* CI PostgreSQL started
* **4/4 tests passed**
* Docker image built successfully
* Docker image pushed to Amazon ECR
* ECR authentication refreshed
* Kubernetes deployment updated
* Kubernetes rollout completed successfully
* **3/3 Flask replicas running**
* CI resources cleaned up

This completes the practical CI/CD implementation for the Cloud-Native Task Management Application.

---

# 33. Project Files Related to Module 10

The main Module 10 files are:

```text
cloud-native-task-manager/
│
├── Jenkinsfile
├── docker-compose.ci.yml
├── requirements.txt
│
├── k8s/
│   ├── flask-configmap.yaml
│   ├── flask-deployment.yaml
│   ├── flask-service.yaml
│   ├── postgres-deployment.yaml
│   ├── postgres-pvc.yaml
│   ├── postgres-secret.yaml
│   └── postgres-service.yaml
│
├── tests/
│   ├── relationship_test.py
│   ├── test_db.py
│   ├── test_relationship.py
│   └── test_user.py
│
└── docs/
    └── module-10-jenkins-cicd.md
```

---

# 34. Interview Explanation

### Question: Explain the CI/CD pipeline you implemented.

**Answer:**

> I implemented a Jenkins CI/CD pipeline for my Cloud-Native Task Management Application. Jenkins checks out the code from GitHub, creates a Python environment, starts a temporary PostgreSQL database, and runs the Pytest test suite. If the tests pass, Jenkins builds the Docker image and pushes it to Amazon ECR. It then refreshes the Kubernetes ECR pull secret, updates the Flask Deployment with the new image, and waits for the Kubernetes rollout to complete. Finally, it verifies the running pods and cleans up the temporary CI database.

### Pipeline architecture:

```text
GitHub
   ↓
Jenkins
   ↓
Test
   ↓
Docker Build
   ↓
Amazon ECR
   ↓
Kubernetes
   ↓
Rollout Verification
```

---

# 35. Key Lessons Learned

Through this module, the project demonstrated practical understanding of:

* Jenkins Declarative Pipeline
* CI/CD pipeline design
* Jenkins credentials
* Automated testing
* PostgreSQL CI environments
* Docker image automation
* Amazon ECR authentication
* Docker image tagging
* Kubernetes deployment automation
* Kubernetes rollout verification
* ECR pull-secret management
* CI cleanup
* Pipeline troubleshooting
* Retry strategies for transient failures

The most important concept is that every stage has a specific responsibility:

```text
GitHub       → Source Code
Jenkins      → Automation
Pytest       → Quality Check
Docker       → Packaging
ECR          → Image Storage
Kubernetes   → Deployment
```

---

# 36. Module 10 Status

**Status: Completed**

```text
GitHub Integration        ✅
Jenkins Pipeline          ✅
Automated Testing         ✅
PostgreSQL CI             ✅
Docker Build              ✅
Amazon ECR                ✅
Kubernetes Deployment     ✅
ECR Secret Refresh        ✅
Rollout Verification      ✅
Pipeline Cleanup          ✅
Troubleshooting           ✅
```

---

## Final Architecture

```text
┌─────────────┐
│   GitHub    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Jenkins   │
│    CI/CD    │
└──────┬──────┘
       │
       ├──────────────► PostgreSQL CI
       │
       ▼
┌─────────────┐
│    Pytest   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Docker   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Amazon ECR │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Kubernetes  │
│  Minikube   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Flask Pods  │
│    3/3      │
└─────────────┘
```

**Module 10 — Jenkins CI/CD completed successfully.**
