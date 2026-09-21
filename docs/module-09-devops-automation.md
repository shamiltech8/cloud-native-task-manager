# Module 9 — DevOps Automation with Bash & Python

## 1. Module Overview

Module 9 focuses on automating common DevOps tasks using Bash scripting, Docker, AWS ECR, AWS EC2, health checks, rollback automation, and cleanup automation.

The goal was to reduce manual deployment work and create a repeatable deployment workflow for the Cloud-Native Task Management Application.

### Main workflow

```text
Git Repository
      ↓
Git Commit SHA
      ↓
Docker Build
      ↓
AWS ECR
      ↓
AWS EC2
      ↓
Docker Container
      ↓
Health Check
```

---

# 2. DevOps Toolkit

The project contains a dedicated automation directory:

```text
devops-toolkit/
├── build.sh
├── cleanup.sh
├── deploy.sh
├── health-check.sh
└── rollback.sh
```

These scripts automate different parts of the application lifecycle.

---

# 3. Build Automation

The build script automates Docker image creation.

Instead of manually running Docker commands every time, the script provides a repeatable way to build the application image.

### Main responsibilities

* Verify Docker availability
* Build the application image
* Tag the image
* Report build status

Example:

```bash
./devops-toolkit/build.sh
```

---

# 4. Git SHA-Based Image Versioning

A major improvement was replacing a fixed image version with the current Git commit SHA.

The deployment script uses:

```bash
IMAGE_TAG=$(git rev-parse --short HEAD)
```

For example:

```text
dd6a6f7
```

The Docker image becomes:

```text
cloud-native-task-manager:dd6a6f7
```

The ECR image becomes:

```text
148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:dd6a6f7
```

### Why this is useful

Every deployed image can be traced back to a specific Git commit.

```text
Git commit
    ↓
Image tag
    ↓
ECR image
    ↓
EC2 deployment
```

This makes deployments easier to track and rollback.

---

# 5. AWS ECR Integration

The application Docker image is stored in Amazon Elastic Container Registry (ECR).

The repository used by the project is:

```text
cloud-native-task-manager
```

The deployment process:

```text
Docker Build
     ↓
Docker Tag
     ↓
ECR Login
     ↓
Docker Push
```

Example image:

```text
148908330969.dkr.ecr.ap-south-1.amazonaws.com/cloud-native-task-manager:dd6a6f7
```

---

# 6. EC2 Automated Deployment

The `deploy.sh` script automates deployment to the EC2 server.

### Deployment process

```text
1. Check required tools
2. Get current Git commit SHA
3. Build Docker image
4. Tag image for ECR
5. Login to ECR
6. Push image to ECR
7. Get EC2 public IP
8. SSH into EC2
9. Login to ECR from EC2
10. Pull the image
11. Stop the previous container
12. Remove the previous container
13. Start the new container
14. Run health check
```

The application runs on:

```text
Port: 5000
```

Container name:

```text
task-manager
```

---

# 7. Deployment Example

A real deployment was performed using Git commit:

```text
dd6a6f7
```

The resulting image was:

```text
cloud-native-task-manager:dd6a6f7
```

The image was successfully pushed to ECR and deployed to EC2.

The deployed container was successfully started and passed the health check.

---

# 8. Health Check Automation

Health checks verify whether the application is responding after deployment.

The toolkit contains:

```text
health-check.sh
```

The script uses `curl` to verify the application endpoint.

Example:

```bash
curl -f http://localhost:5000
```

The deployment process also performs a remote application health check after starting the new container.

### Purpose

A successful Docker deployment does not necessarily mean the application is working.

The health check verifies that:

```text
Container started
      ↓
Application responding
      ↓
Deployment considered successful
```

---

# 9. Rollback Automation

The project includes:

```text
rollback.sh
```

The script accepts an image tag as an argument.

Example:

```bash
./devops-toolkit/rollback.sh dd6a6f7
```

### Rollback process

```text
Select previous image
       ↓
Login to ECR
       ↓
Pull previous image
       ↓
Stop current container
       ↓
Remove current container
       ↓
Start previous image
       ↓
Health check
```

This allows the application to return to a known image version.

---

# 10. Real Rollback Test

Rollback was tested against the previously deployed image:

```text
dd6a6f7
```

The rollback completed successfully.

Result:

```text
Rollback Successful
Rolled back to: dd6a6f7
```

The application passed the health check after rollback.

This demonstrated that the rollback script works against the real EC2 deployment rather than only being a theoretical script.

---

# 11. Docker Cleanup Automation

The project contains:

```text
cleanup.sh
```

The cleanup script connects to the EC2 server and performs safe Docker cleanup.

It removes:

### Stopped containers

```bash
docker container prune -f
```

### Dangling images

```bash
docker image prune -f
```

### Unused build cache

```bash
docker builder prune -f
```

It does not remove Docker volumes.

---

# 12. Cleanup Verification

Before cleanup, the EC2 Docker storage showed:

```text
Images:        1.837 GB
Containers:    4.792 MB
Volumes:       48.13 MB
Build Cache:   114.8 MB
```

After cleanup:

```text
Images:        1.218 GB
Containers:    4.788 MB
Volumes:       48.13 MB
Build Cache:   114.6 MB
```

Approximately **600+ MB** of Docker storage was reclaimed.

Running containers remained active.

---

# 13. EC2 Disk Investigation

After Docker cleanup, the EC2 root filesystem was checked.

Current disk status:

```text
Filesystem      Size  Used  Avail  Use%
/dev/root       6.7G  5.2G  1.5G   79%
```

Before cleanup:

```text
Used:      5.8 GB
Available: 868 MB
Usage:     88%
```

After cleanup:

```text
Used:      5.2 GB
Available: 1.5 GB
Usage:     79%
```

The cleanup recovered roughly 600+ MB.

---

# 14. Disk Usage Investigation

The root filesystem was investigated using:

```bash
sudo du -xhd1 / 2>/dev/null | sort -h
```

The main directories were:

```text
/usr    2.8 GB
/var    2.4 GB
/home   500 KB
```

`/usr` was left untouched because it contains system software.

Further investigation of `/var` showed:

```text
/var/lib     1.9 GB
/var/cache   363 MB
/var/log     164 MB
```

The main `/var/lib` consumers were:

```text
/var/lib/containerd   1.2 GB
/var/lib/snapd        430 MB
/var/lib/apt          148 MB
```

The containerd directory was investigated further.

---

# 15. Containerd Investigation

Containerd storage was approximately:

```text
1.2 GB
```

The main components were:

```text
OverlayFS snapshots: 922 MB
Content blobs:       298 MB
```

The containerd images and containers were inspected using:

```bash
sudo ctr -n moby images ls
```

and:

```bash
sudo ctr -n moby containers ls
```

The running Docker containers were also verified:

```bash
docker ps -a
```

Because the remaining containerd data was associated with active containers, it was not manually deleted.

### Important DevOps principle

Never manually delete files from:

```text
/var/lib/containerd
```

or:

```text
/var/lib/docker
```

without understanding which runtime resources depend on them.

---

# 16. Current EC2 Container Architecture

The EC2 server currently contains:

```text
task-manager
    ↓
Cloud-Native Task Manager application

nginx
    ↓
Nginx web server

flask1
flask2
flask3
    ↓
Previous application containers

postgres
    ↓
PostgreSQL database
```

The current application container exposes:

```text
5000 → 5000
```

Nginx exposes:

```text
80 → 80
```

PostgreSQL currently exposes:

```text
5432 → 5432
```

The older Flask containers expose port 5000 internally but do not publish it to the EC2 host.

---

# 17. Automation Scripts Summary

| Script            | Responsibility                       |
| ----------------- | ------------------------------------ |
| `build.sh`        | Build Docker image                   |
| `deploy.sh`       | Build, push and deploy application   |
| `health-check.sh` | Check application availability       |
| `rollback.sh`     | Restore a previous image version     |
| `cleanup.sh`      | Safely clean unused Docker resources |

---

# 18. Technologies Used

```text
Bash
Docker
Git
GitHub
AWS CLI
Amazon ECR
Amazon EC2
SSH
curl
containerd
Linux
```

---

# 19. DevOps Concepts Learned

Through this module, the following concepts were practiced:

### Infrastructure automation

Automating repetitive infrastructure and deployment operations instead of executing them manually.

### Immutable image versioning

Using Git commit SHAs to identify Docker images.

### Container image registry

Using Amazon ECR to store application images.

### Remote deployment

Using SSH to automate deployment to an EC2 server.

### Health checks

Verifying application availability after deployment.

### Rollback

Returning to a previously known image version when required.

### Resource cleanup

Removing unused Docker resources without deleting active application data.

### Disk troubleshooting

Using Linux tools to identify disk usage before performing cleanup.

---

# 20. Important Commands Learned

### Check Git commit

```bash
git log --oneline
```

### Get current commit SHA

```bash
git rev-parse --short HEAD
```

### Check Docker disk usage

```bash
docker system df
```

### Check running containers

```bash
docker ps
```

### Check all containers

```bash
docker ps -a
```

### Check filesystem usage

```bash
df -h /
```

### Investigate directory usage

```bash
sudo du -xhd1 / 2>/dev/null | sort -h
```

### Check containerd images

```bash
sudo ctr -n moby images ls
```

### Check containerd containers

```bash
sudo ctr -n moby containers ls
```

---

# 21. Module 9 Final Workflow

The complete automation workflow developed during this module is:

```text
Developer
    │
    ▼
Git Commit
    │
    ▼
Git SHA
    │
    ▼
Docker Build
    │
    ▼
Docker Image
    │
    ▼
Amazon ECR
    │
    ▼
EC2
    │
    ▼
Pull Image
    │
    ▼
Stop Previous Container
    │
    ▼
Start New Container
    │
    ▼
Health Check
    │
    ├── Success → Deployment Complete
    │
    └── Failure → Rollback
```

---

# 22. Module 9 Outcome

Module 9 successfully transformed the project from a manually operated deployment into a more automated DevOps workflow.

The project can now:

* Build container images
* Version images using Git commits
* Push images to ECR
* Deploy images to EC2
* Verify application health
* Roll back to previous versions
* Clean unused Docker resources
* Investigate server disk usage

### Status

**Module 9 — DevOps Automation: COMPLETED ✅**
