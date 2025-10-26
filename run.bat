@echo off
echo Starting Xochi Side Scroller...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed. Please install Python 3.9+ first.
    pause
    exit /b 1
)

REM Check if dependencies are installed
python -c "import pygame, scipy" >nul 2>&1
if errorlevel 1 (
    echo Installing dependencies...
    pip install -r requirements.txt
)

echo Launching game...
echo.
python main.py

pause
