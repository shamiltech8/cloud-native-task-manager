#!/bin/bash

echo "================================"
echo " Cloud-Native Task Manager"
echo " Docker Cleanup"
echo "================================"

CONTAINER_NAME="task-manager"

echo ""
echo "Checking container..."

if docker ps -aq -f name="^${CONTAINER_NAME}$" | grep -q .
then
    echo "Removing container: $CONTAINER_NAME"

    docker stop "$CONTAINER_NAME" 2>/dev/null
    docker rm "$CONTAINER_NAME"

    echo "✓ Container removed"
else
    echo "No task-manager container found"
fi

echo ""
echo "Removing dangling Docker images..."

docker image prune -f

echo ""
echo "Removing unused Docker containers..."

docker container prune -f

echo ""
echo "================================"
echo " Cleanup Completed"
echo "================================"
