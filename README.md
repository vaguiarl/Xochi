# Xochi - Side Scroller Game

A Mario-style side-scrolling platformer featuring Xochi the axolotl as the main character.

## Quick Start

### Easy Installation (Recommended)

**On macOS/Linux:**
```bash
./run.sh
```

**On Windows:**
```bash
run.bat
```

The script will automatically install dependencies if needed.

### Manual Installation

1. Ensure you have Python 3.9+ installed
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run the game:
   ```bash
   python main.py
   ```

## Controls

- **Arrow Keys** or **H/L**: Move left/right
- **Space** or **Up Arrow** or **K**: Jump
- **Left Shift**: Run boost
- **Escape** or **F5**: Pause game
- **Right Click**: Add enemies (debug feature)
- **Left Click**: Add coins (debug feature)

## Features

- Classic Mario-style gameplay
- Play as Xochi the axolotl
- Collect coins and mushrooms
- Power-up transformations
- Multiple levels
- Enemies: Goombas and Koopas

## Project Structure

```
Xochi/
├── classes/       # Core game systems (Sprites, Level, Camera, etc.)
├── entities/      # Game entities (Player, Enemies, Items)
├── sprites/       # Sprite definitions (JSON)
├── levels/        # Level data (JSON)
├── img/          # Sprite sheets and images
├── sfx/          # Sound effects
└── main.py       # Entry point
```

## Version 0.1 Notes

This is a sprite-swap version. Only the player character has been replaced with Xochi sprites. All gameplay mechanics and other sprites remain from the original template.

## Requirements

- Python 3.9+
- pygame
- scipy
- numpy

All dependencies are automatically installed when using `run.sh` or `run.bat`
