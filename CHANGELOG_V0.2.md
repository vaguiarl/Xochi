# Xochi v0.2 Changelog

## Release: v0.2 - "Bird Enemies & Transparency Fix"

### Date: Current

## Changes

### 🎨 Visual Updates
- **Character Sprites**: Updated Xochi to use new `xochi_characters_v2.png` spritesheet
- **Enemy Sprites**: 
  - Goombas now appear as **birds/gulls**
  - Koopas now appear as **herons**
  - All enemy sprites loaded from `birds_enemies.png`

### 🐛 Bug Fixes
- **Transparency Fixed**: Resolved black box issue on Xochi sprites
  - Updated `classes/Spritesheet.py` to use `pygame.SRCALPHA` for proper alpha channel support
  - Removed forced black color key that was causing transparency issues
  - Sprites now render with full transparency support

### 📦 Assets Added
- `img/xochi_characters_v2.png` - Updated character sprites
- `img/birds_enemies.png` - Bird enemy sprites  
- `img/xochi_tiles.png` - Tile assets (ready for future integration)
- `img/xochi_fx.png` - Effect assets (ready for future integration)
- `img/xochi_items.png` - Item assets (ready for future integration)
- `img/xochi_parallax.png` - Parallax background (ready for future integration)

### 🔧 Technical Changes
- Updated `sprites/Mario.json` to reference new character spritesheet
- Updated `sprites/Goomba.json` to use bird sprites
- Updated `sprites/Koopa.json` to use heron sprites with proper sizing (17x32)
- Modified `classes/Spritesheet.py` for improved transparency handling

## Known Issues
- Tile/background/effects assets are prepared but not yet integrated due to JSON format differences
- Requires engine updates for full v0.2 asset integration

## Testing
✅ Game launches successfully
✅ Character sprites display with transparency
✅ Enemy sprites display correctly
✅ All animations work as expected
✅ No crashes or errors

## Next Steps (v0.3)
- Integrate remaining tile/background assets
- Update level data to use new tiles
- Add new visual effects
- Polish animations
