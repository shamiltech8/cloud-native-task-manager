# Troubleshooting Log

During development I hit several infrastructure, CI/CD, monitoring, and application deployment issues. Working through them showed me how real DevOps environments behave and how to resolve failures systematically.

**My approach:** identify the failure → investigate logs and events → find the root cause → apply a controlled fix → verify the result.

---

## 1. Kubernetes ImagePullBackOff: expired AWS ECR authentication

**Problem:** Pods went into `ImagePullBackOff` because the Amazon ECR token used by the Kubernetes image-pull secret (`ecr-secret`) had expired. The image was in ECR, but Kubernetes could no longer authenticate to pull it.

**Root cause:** ECR authorization tokens are temporary credentials, and the secret was not refreshed automatically after the token expired.

**Solution:**
- Inspected pod events with `kubectl describe pod`.
- Verified AWS identity and ECR authentication.
- Automated the refresh of the `ecr-secret`.
- Added the ECR authentication refresh to the deployment workflow.
- Verified that Kubernetes could pull the image and complete the deployment.

**Result:** Jenkins build #31 completed the ECR publish and Kubernetes deployment, and all three Flask replicas became available.

**Tools:** AWS ECR, AWS CLI, Docker, Kubernetes, Jenkins.

---

## 2. Jenkins pipeline failure: incorrect declarative pipeline structure

**Problem:** The pipeline failed with `Undefined section "stage"`. The Docker image build stage had been placed outside the required `stages` block.

**Root cause:** Declarative pipelines require stages to be defined inside the correct pipeline structure, so Jenkins rejected the configuration.

**Solution:**
- Read the Jenkins console output.
- Found the misplaced `Build Docker Image` stage.
- Moved it inside the `stages` block.
- Re-ran the pipeline to verify the fix.

**Result:** The pipeline was accepted and the Docker image build stage ran successfully.

**Tools:** Jenkins, Groovy, Jenkinsfile, Docker.

---

## 3. PostgreSQL connectivity: local tests could not resolve the database hostname

**Problem:** The local pytest suite failed with `could not translate host name "postgres" to address: Name or service not known`. The application defaults to the hostname `postgres`, which resolves inside the cluster or Docker network but not from the host machine running the tests.

**Root cause:** The test process ran outside the network where the service name exists.

**Solution:**
- Inspected the Flask database configuration and environment variables.
- Verified that the PostgreSQL pod and service were healthy.
- Exposed PostgreSQL locally (port-forward in Kubernetes, the published port in Docker Compose).
- Created a separate `task_manager_test` database to protect the main database.
- Overrode `DATABASE_HOST`, `DATABASE_PORT`, and `DATABASE_NAME` when running the tests.

**Result:** The local test environment connected to PostgreSQL without changing the deployment configuration. The suite passes: **3 passed**.

**Tools:** Python, Flask, SQLAlchemy, PostgreSQL, pytest, Kubernetes, kubectl.

---

## 4. Prometheus target down: Flask unreachable after adding Nginx

**Problem:** The `flask` scrape job showed DOWN with `connection refused` on `localhost:5000`.

**Root cause:** In Docker Compose the Flask containers only exposed port 5000 inside the Docker network, and only Nginx published a port (80).

**Solution:**
- Read the error on the Prometheus targets page and tested each endpoint with `curl`.
- Published each Flask container on its own localhost-only port (`127.0.0.1:5001` to `5003`).
- Updated the scrape config to the three targets instead of scraping through the load balancer, which would hit a random instance on every scrape.

**Result:** All Prometheus targets are UP.

**Tools:** Prometheus, Docker Compose, Nginx, curl.

---

## 5. Alerts that could not fire

**Problem:** Stopping a Flask container did not trigger any alert.

**Root cause:** None of the five existing rules watched the Docker Flask containers. `NodeExporterDown` covers only the node job, and `FlaskReplicaMismatch` covers only the Kubernetes deployment, which is a separate system.

**Solution:**
- Added the `FlaskInstanceDown` rule (`up{job="flask"} == 0` for 1 minute).
- Validated the rules with `promtool`.
- Stopped a Flask container and watched the alert go from pending to firing, then restored the container.

**Result:** The Flask-down alert is verified to fire. Notification delivery through Alertmanager is not configured yet.

**Tools:** Prometheus, promtool, Docker.
