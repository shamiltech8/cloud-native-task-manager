#!/bin/bash

echo "================================"
echo " Cloud-Native Task Manager"
echo " Application Rollback"
echo "================================"

IMAGE_NAME="cloud-native-task-manager"
IMAGE_TAG="v1"
CONTAINER_NAME="task-manager"

echo ""
echo "Checking rollback image..."

if docker image inspect "$IMAGE_NAME:$IMAGE_TAG" > /dev/null 2>&1
then
    echo "✓ Rollback image found: $IMAGE_NAME:$IMAGE_TAG"
else
    echo "✗ Rollback image not found"
    exit 1
fi

echo ""
echo "Stopping current container..."

if docker ps -q -f name="^${CONTAINER_NAME}$" | grep -q .
then
    docker stop "$CONTAINER_NAME"
    echo "✓ Current container stopped"
else
    echo "No running container found"
fi

echo ""
echo "Removing old container..."

if docker ps -aq -f name="^${CONTAINER_NAME}$" | grep -q .
then
    docker rm "$CONTAINER_NAME"
    echo "✓ Old container removed"
fi

echo ""
echo "Starting rollback version..."

docker run -d \
    --name "$CONTAINER_NAME" \
    -p 5000:5000 \
    "$IMAGE_NAME:$IMAGE_TAG"

if [ $? -eq 0 ]
then
    echo "✓ Rollback completed successfully"
else
    echo "✗ Rollback failed"
    exit 1
fi

echo ""
echo "Running health check..."

sleep 3

if curl -f http://localhost:5000 > /dev/null 2>&1
then
    echo "✓ Application is healthy"
else
    echo "✗ Application health check failed"
    exit 1
fi

echo ""
echo "================================"
echo " Rollback Successful"
echo "================================"
