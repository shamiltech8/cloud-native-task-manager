#!/bin/bash

echo "================================"
echo " Cloud-Native Task Manager"
echo " Application Health Check"
echo "================================"

APP_URL="http://localhost:5000"

echo ""
echo "Checking application..."

if curl -f "$APP_URL" > /dev/null 2>&1
then
    echo "✓ Application is running"
    echo "✓ Health check passed"
else
    echo "✗ Application is not responding"
    echo "✗ Health check failed"
    exit 1
fi

