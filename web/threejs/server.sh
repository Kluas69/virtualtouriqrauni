#!/bin/bash

echo "🚀 Starting Three.js Classroom Viewer Development Server..."
echo

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo "❌ Python not found! Please install Python 3.x"
        echo "   On Ubuntu/Debian: sudo apt install python3"
        echo "   On macOS: brew install python3"
        echo "   On Windows: Download from https://www.python.org/downloads/"
        exit 1
    else
        PYTHON_CMD="python"
    fi
else
    PYTHON_CMD="python3"
fi

# Start the server
echo "📍 Starting server with $PYTHON_CMD..."
$PYTHON_CMD server.py