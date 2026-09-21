#!/bin/bash

echo "================================"
echo " Cloud-Native Task Manager"
echo " Docker Build"
echo "================================"

IMAGE_NAME="cloud-native-task-manager"
IMAGE_TAG="v1"

echo ""
echo "Building Docker image..."

docker build \
    -t "$IMAGE_NAME:$IMAGE_TAG" \
    ..

if [ $? -eq 0 ]
then
    echo "✓ Docker image built successfully"
else
    echo "✗ Docker build failed"
    exit 1
fi

echo ""
echo "Checking image..."

docker images "$IMAGE_NAME:$IMAGE_TAG"

echo ""
echo "Build completed successfully."


