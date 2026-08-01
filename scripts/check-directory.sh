#!/bin/bash

read -p "Enter directory name: " DIR

if [ -d "$DIR" ]; then
    echo "Directory exists."
    exit 0
else
    echo "Directory not found."
    exit 1
fi
