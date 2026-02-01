# Blue Screen Bug Documentation

## Summary
The Xochi game displays a blue screen (empty Phaser canvas) when the `game.js` bundle is incorrectly built.

## Root Cause
The game uses Phaser 3 loaded from a CDN as a global variable. When bundling with esbuild, the `--external:phaser` flag causes the bundler to generate `require("phaser")` calls instead of using the global `Phaser` object.

### The Problematic Command
```bash
npx esbuild src/main.js --bundle --outfile=game.js --format=iife --global-name=XochiGame --external:phaser
```

This produces code like:
```javascript
var __require = /* @__PURE__ */ ((x) => typeof require !== "undefined" ? require : ...);
var import_phaser = __require("phaser");
```

Since `require()` doesn't exist in browsers and Phaser is loaded globally, this fails silently and the game shows only a blue canvas.

## Symptoms
- Blue screen on page load
- No console errors (Phaser initializes but has no scenes)
- The bundled `game.js` file is significantly smaller than expected (~107KB vs ~290KB)

## Solution

### Immediate Fix
Restore from the working backup:
```bash
cp dist/game.js game.js
```

### Proper Build Process
The original `game.js` was built with a different bundler configuration that:
1. Treats `Phaser` as a global (not an external module)
2. Uses `window.Phaser` or assumes `Phaser` is globally available
3. Bundles all game code without trying to import Phaser

### Verification
Check the bundle doesn't contain `require("phaser")`:
```bash
grep -c 'require.*phaser' game.js
# Should return 0
```

Check bundle size is appropriate:
```bash
ls -la game.js
# Should be ~290KB for the full game
```

## Architecture Note

```
index.html
    ├── loads Phaser from CDN (global)
    └── loads game.js (bundled game code)
            └── uses global Phaser object

src/ (development)
    └── Vite dev server (ES modules)
        └── imports Phaser via ES modules
```

The `game.js` bundle must be built to use the global `Phaser` from the CDN, NOT as an ES module import.

## Prevention
- Always test locally before deploying
- Keep `dist/game.js` as a known-good backup
- Document the correct build command when found
- Consider adding a build script to package.json

## Timeline
- **Jan 31, 2026 19:10** - Working game.js in dist/
- **Jan 31, 2026 19:11** - Broken esbuild bundle created
- **Jan 31, 2026 19:14** - Restored from backup

## Related Issues
- Earlier blue screen caused by GitHub Actions workflow conflict (static.yml vs deploy.yml racing)
- That was fixed by removing static.yml
