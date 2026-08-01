#!/bin/bash

set -e

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

LOG_FILE="git-auto.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check commit message
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Commit message is required.${NC}"
    echo "Usage: ./git-auto.sh \"Your commit message\""
    exit 1
fi

COMMIT_MESSAGE="$1"

echo -e "${YELLOW}Adding files...${NC}"
git add .
log "Files added"

echo -e "${YELLOW}Creating commit...${NC}"
git commit -m "$COMMIT_MESSAGE"
log "Commit created: $COMMIT_MESSAGE"

echo -e "${YELLOW}Pushing to GitHub...${NC}"
git push origin main
log "Changes pushed"

echo -e "${GREEN}Git automation completed successfully!${NC}"
log "Git automation completed"
