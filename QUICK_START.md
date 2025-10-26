# Quick Start Guide - Xochi Side Scroller

## 🚀 Run the Game in 3 Seconds

### Option 1: Use the Launch Script (Easiest)

**macOS/Linux:**
```bash
./run.sh
```

**Windows:**
```bash
run.bat
```

### Option 2: Manual Launch

```bash
# Install dependencies (one time)
pip install -r requirements.txt

# Run the game
python main.py
```

## 🎮 Controls

| Action | Keys |
|--------|------|
| Move Left | ← or H |
| Move Right | → or L |
| Jump | ↑ or Space or K |
| Run Faster | Left Shift |
| Pause | Esc or F5 |

## 🐸 What You'll See

- **Main Menu** - Press any key to start (or wait on the title screen)
- **Xochi the Axolotl** - Your playable character in the game world
- **Enemies** - Goombas and Koopas (original Mario enemies)
- **Coins** - Collect for points
- **Mushrooms** - Power up to become bigger
- **Platforms** - Jump and explore the side-scrolling world

## 🎯 Gameplay Tips

1. Run and jump to explore the level
2. Avoid or stomp on enemies
3. Collect coins for points
4. Find mushrooms to grow bigger
5. Try right-clicking to spawn enemies (debug mode)
6. Try left-clicking to spawn coins (debug mode)

## 🐛 Troubleshooting

**Game won't start:**
- Make sure Python 3.9+ is installed: `python3 --version`
- Install dependencies: `pip install -r requirements.txt`

**Sprite appears as black box:**
- Xochi sprite sheet is loading from `img/xochi_sheet.png`
- Check that file exists and is valid PNG

**Sound issues:**
- Sound files are in the `sfx/` directory
- No sound doesn't prevent gameplay

## 📝 Version Info

- **Version**: 0.1 (Sprite-swap MVP)
- **Character**: Xochi replaces Mario sprites
- **Gameplay**: Original Mario mechanics
- **Levels**: Original level design

Enjoy playing as Xochi! 🎮
