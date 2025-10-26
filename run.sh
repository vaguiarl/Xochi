#!/bin/bash

echo "🐸 Starting Xochi Side Scroller..."
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.9+ first."
    exit 1
fi

# Check if dependencies are installed
python3 -c "import pygame, scipy" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "📦 Installing dependencies..."
    pip3 install -r requirements.txt
fi

echo "🎮 Launching game..."
echo ""
python3 main.py
