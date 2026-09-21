#!/bin/bash

echo "================================"
echo " Cloud-Native Task Manager"
echo " Application Rollback"
echo "================================"

AWS_REGION="ap-south-1"
AWS_ACCOUNT_ID="148908330969"

ECR_REPOSITORY="cloud-native-task-manager"
CONTAINER_NAME="task-manager"

EC2_INSTANCE_ID="i-0b44a5d32e4241f7b"
EC2_USER="ubuntu"

SSH_KEY="$HOME/.ssh/id_ed25519"

# --------------------------------
# Check rollback version
# --------------------------------

if [ -z "$1" ]
then
    echo ""
    echo "Usage:"
    echo "./devops-toolkit/rollback.sh <image-tag>"
    echo ""
    echo "Example:"
    echo "./devops-toolkit/rollback.sh dd6a6f7"
    exit 1
fi

IMAGE_TAG="$1"

ECR_IMAGE="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG"

echo ""
echo "Rollback version: $IMAGE_TAG"
echo "ECR image:"
echo "$ECR_IMAGE"

# --------------------------------
# Check required tools
# --------------------------------

echo ""
echo "Checking required tools..."

if ! command -v aws > /dev/null 2>&1
then
    echo "✗ AWS CLI not found"
    exit 1
fi

if ! command -v ssh > /dev/null 2>&1
then
    echo "✗ SSH not found"
    exit 1
fi

echo "✓ Required tools found"

# --------------------------------
# Get EC2 IP
# --------------------------------

echo ""
echo "Getting EC2 public IP..."

EC2_IP=$(aws ec2 describe-instances \
    --instance-ids "$EC2_INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region "$AWS_REGION")

if [ -z "$EC2_IP" ] || [ "$EC2_IP" = "None" ]
then
    echo "✗ Could not get EC2 IP"
    exit 1
fi

echo "✓ EC2 IP: $EC2_IP"

# --------------------------------
# Rollback on EC2
# --------------------------------

echo ""
echo "Connecting to EC2..."

ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" <<EOF

echo "Logging into ECR..."

aws ecr get-login-password \
    --region "$AWS_REGION" | \
docker login \
    --username AWS \
    --password-stdin \
    "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

if [ \$? -ne 0 ]
then
    echo "✗ ECR login failed"
    exit 1
fi

echo "✓ ECR login successful"

echo ""
echo "Pulling rollback image..."

docker pull "$ECR_IMAGE"

if [ \$? -ne 0 ]
then
    echo "✗ Failed to pull rollback image"
    exit 1
fi

echo "✓ Rollback image pulled"

echo ""
echo "Stopping current container..."

if docker ps -q -f name="^${CONTAINER_NAME}$" | grep -q .
then
    docker stop "$CONTAINER_NAME"
    echo "✓ Current container stopped"
fi

echo ""
echo "Removing current container..."

if docker ps -aq -f name="^${CONTAINER_NAME}$" | grep -q .
then
    docker rm "$CONTAINER_NAME"
    echo "✓ Current container removed"
fi

echo ""
echo "Starting rollback version..."

docker run -d \
    --name "$CONTAINER_NAME" \
    -p 5000:5000 \
    "$ECR_IMAGE"

if [ \$? -ne 0 ]
then
    echo "✗ Failed to start rollback container"
    exit 1
fi

echo "✓ Rollback container started"

EOF

if [ $? -ne 0 ]
then
    echo ""
    echo "✗ EC2 rollback failed"
    exit 1
fi

# --------------------------------
# Health check
# --------------------------------

echo ""
echo "Checking application..."

sleep 5

if curl -f "http://$EC2_IP:5000" > /dev/null 2>&1
then
    echo "✓ Application is responding"
else
    echo "✗ Application health check failed"
    echo "Check: http://$EC2_IP:5000"
    exit 1
fi

echo ""
echo "================================"
echo " Rollback Successful"
echo "================================"
echo ""
echo "Rolled back to: $IMAGE_TAG"
