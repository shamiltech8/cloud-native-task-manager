#!/bin/bash

greet() {
    echo "Hello, $@!"
    echo "Welcome to the Cloud-Native Task Manager project."
}

if [ $# -eq 0 ]; then
    echo "Usage: ./greet.sh <name>"
    exit 1
fi

greet "$1"
