#!/bin/bash

echo "=========================================="
echo " Cloud-Native Task Manager"
echo " Docker Cleanup"
echo "=========================================="

AWS_REGION="ap-south-1"
EC2_INSTANCE_ID="i-0b44a5d32e4241f7b"
EC2_USER="ubuntu"

SSH_KEY="$HOME/.ssh/id_ed25519"


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
# Get EC2 public IP
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
# Connect to EC2
# --------------------------------

echo ""
echo "Connecting to EC2..."

ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" <<'EOF'

echo ""
echo "================================"
echo " Docker Disk Usage - Before"
echo "================================"

docker system df

echo ""
echo "Removing stopped containers..."

docker container prune -f

echo ""
echo "Removing dangling images..."

docker image prune -f

echo ""
echo "Removing unused build cache..."

docker builder prune -f

echo ""
echo "================================"
echo " Docker Disk Usage - After"
echo "================================"

docker system df

echo ""
echo "================================"
echo " Cleanup Completed"
echo "================================"

EOF

if [ $? -ne 0 ]
then
    echo ""
    echo "✗ Cleanup failed"
    exit 1
fi

echo ""
echo "✓ Remote Docker cleanup completed"
