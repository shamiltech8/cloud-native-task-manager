#!/bin/bash

LOG_FILE="demo.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

echo "Running demo..."

log "Demo started"

sleep 2

log "Demo finished"

echo "Check demo.log"
