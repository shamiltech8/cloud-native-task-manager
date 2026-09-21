#!/bin/bash

echo "=========================================="
echo " Cloud-Native Task Manager"
echo " Automated Deployment"
echo "=========================================="

# -------------------------------
# Configuration
# -------------------------------

AWS_REGION="ap-south-1"
AWS_ACCOUNT_ID="148908330969"

ECR_REPOSITORY="cloud-native-task-manager"
IMAGE_NAME="cloud-native-task-manager"
IMAGE_TAG=$(git rev-parse --short HEAD)

EC2_INSTANCE_ID="i-0b44a5d32e4241f7b"
EC2_USER="ubuntu"

SSH_KEY="$HOME/.ssh/id_ed25519"

ECR_IMAGE="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG"

# -------------------------------
# Step 1: Check dependencies
# -------------------------------

echo ""
echo "Step 1: Checking required tools..."

if ! command -v docker > /dev/null 2>&1
then
    echo "✗ Docker is not installed"
    exit 1
fi

if ! command -v aws > /dev/null 2>&1
then
    echo "✗ AWS CLI is not installed"
    exit 1
fi

if [ ! -f "$SSH_KEY" ]
then
    echo "✗ SSH key not found: $SSH_KEY"
    exit 1
fi

echo "✓ Docker found"
echo "✓ AWS CLI found"
echo "✓ SSH key found"

# -------------------------------
# Step 2: Check AWS credentials
# -------------------------------

echo ""
echo "Step 2: Checking AWS credentials..."

if ! aws sts get-caller-identity > /dev/null 2>&1
then
    echo "✗ AWS credentials are not working"
    exit 1
fi

echo "✓ AWS credentials verified"

# -------------------------------
# Step 3: Get EC2 public IP
# -------------------------------

echo ""
echo "Step 3: Getting EC2 public IP..."

EC2_IP=$(aws ec2 describe-instances \
    --instance-ids "$EC2_INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

if [ "$EC2_IP" = "None" ] || [ -z "$EC2_IP" ]
then
    echo "✗ Could not find EC2 public IP"
    exit 1
fi

echo "✓ EC2 IP: $EC2_IP"

# -------------------------------
# Step 4: Build Docker image
# -------------------------------

echo ""
echo "Step 4: Building Docker image..."

docker build \
    -t "$IMAGE_NAME:$IMAGE_TAG" \
    .

if [ $? -ne 0 ]
then
    echo "✗ Docker build failed"
    exit 1
fi

echo "✓ Docker image built"

# -------------------------------
# Step 5: Tag image for ECR
# -------------------------------

echo ""
echo "Step 5: Tagging image for ECR..."

docker tag \
    "$IMAGE_NAME:$IMAGE_TAG" \
    "$ECR_IMAGE"

if [ $? -ne 0 ]
then
    echo "✗ Docker tag failed"
    exit 1
fi

echo "✓ Image tagged:"
echo "$ECR_IMAGE"

# -------------------------------
# Step 6: Login to ECR
# -------------------------------

echo ""
echo "Step 6: Logging into Amazon ECR..."

aws ecr get-login-password \
    --region "$AWS_REGION" \
    | docker login \
    --username AWS \
    --password-stdin \
    "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

if [ $? -ne 0 ]
then
    echo "✗ ECR login failed"
    exit 1
fi

echo "✓ ECR login successful"

# -------------------------------
# Step 7: Push image
# -------------------------------

echo ""
echo "Step 7: Pushing image to ECR..."

docker push "$ECR_IMAGE"

if [ $? -ne 0 ]
then
    echo "✗ Docker push failed"
    exit 1
fi

echo "✓ Image pushed successfully"

# -------------------------------
# Step 8: Deploy to EC2
# -------------------------------

echo ""
echo "Step 8: Connecting to EC2..."

ssh -i "$SSH_KEY" \
    -o StrictHostKeyChecking=no \
    "$EC2_USER@$EC2_IP" << EOF

echo "Connected to EC2"

echo ""
echo "Logging into ECR..."

aws ecr get-login-password \
    --region "$AWS_REGION" \
    | docker login \
    --username AWS \
    --password-stdin \
    "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo ""
echo "Pulling new image..."

docker pull "$ECR_IMAGE"

echo ""
echo "Stopping old container..."

if docker ps -q -f name="^task-manager$" | grep -q .
then
    docker stop task-manager
fi

echo ""
echo "Removing old container..."

if docker ps -aq -f name="^task-manager$" | grep -q .
then
    docker rm task-manager
fi

echo ""
echo "Starting new container..."

docker run -d \
    --name task-manager \
    -p 5000:5000 \
    "$ECR_IMAGE"

echo ""
echo "Deployment completed on EC2"

EOF

if [ $? -ne 0 ]
then
    echo "✗ EC2 deployment failed"
    exit 1
fi

# -------------------------------
# Step 9: Health check
# -------------------------------

echo ""
echo "Step 9: Checking application..."

sleep 5

if curl -f http://"$EC2_IP":5000 > /dev/null 2>&1
then
    echo "✓ Application is responding"
else
    echo "⚠ Application health check failed"
    echo "Check: http://$EC2_IP:5000"
fi

echo ""
echo "=========================================="
echo " Deployment Successful"
echo "=========================================="
