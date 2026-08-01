#!/bin/bash

set -e

IMAGE="cloud-native-task-manager-flask2"
TAG="latest"
LOG_FILE="deploy.log"

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

echo -e "${YELLOW}Starting deployment...${NC}"
log "Deployment started"

echo -e "${YELLOW}Building Docker image...${NC}"

docker build -t $IMAGE:$TAG ..

log "Docker image built"

echo -e "${GREEN}Deployment completed successfully.${NC}"

log "Deployment completed"
