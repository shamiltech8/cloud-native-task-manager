#!/bin/bash

set -e

# -----------------------------
# Configuration
# -----------------------------
LOG_FILE="git-auto.log"
EXPECTED_BRANCH="main"

# -----------------------------
# Colors
# -----------------------------
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

# -----------------------------
# Logging Function
# -----------------------------
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# -----------------------------
# Validate Commit Message
# -----------------------------
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Commit message is required.${NC}"
    echo "Usage: ./git-auto.sh \"Your commit message\""
    exit 1
fi

COMMIT_MESSAGE="$1"

# -----------------------------
# Check Current Branch
# -----------------------------
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" != "$EXPECTED_BRANCH" ]; then
    echo -e "${RED}Error: You are on branch '$CURRENT_BRANCH'.${NC}"
    echo -e "${YELLOW}Please switch to '$EXPECTED_BRANCH' before pushing.${NC}"
    exit 1
fi

# -----------------------------
# Check for Changes
# -----------------------------
if git diff --quiet && git diff --cached --quiet; then
    echo -e "${YELLOW}No changes to commit.${NC}"
    exit 0
fi

# -----------------------------
# Show Git Status
# -----------------------------
echo -e "${BLUE}========== Git Status ==========${NC}"
git status
echo

# -----------------------------
# Add Files
# -----------------------------
echo -e "${YELLOW}Adding files...${NC}"
git add .
log "Files added"

# -----------------------------
# Commit
# -----------------------------
echo -e "${YELLOW}Creating commit...${NC}"
git commit -m "$COMMIT_MESSAGE"
log "Commit created: $COMMIT_MESSAGE"

# -----------------------------
# Confirmation
# -----------------------------
echo
read -p "Push changes to GitHub? (y/n): " answer

if [ "$answer" != "y" ]; then
    echo -e "${YELLOW}Push cancelled.${NC}"
    log "Push cancelled by user"
    exit 0
fi

# -----------------------------
# Push
# -----------------------------
echo -e "${YELLOW}Pushing to GitHub...${NC}"
git push origin "$EXPECTED_BRANCH"
log "Changes pushed to GitHub"

# -----------------------------
# Show Latest Commit
# -----------------------------
echo
echo -e "${BLUE}========== Latest Commit ==========${NC}"
git log --oneline -1

# -----------------------------
# Success
# -----------------------------
echo
echo -e "${GREEN}Git automation completed successfully!${NC}"
log "Git automation completed successfully"
