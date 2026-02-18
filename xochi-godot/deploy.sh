#!/bin/bash
# Build and deploy Xochi to GitHub Pages
# Usage: ./deploy.sh [commit message]
# Example: ./deploy.sh "Add one-way platforms to upscroller levels"

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_DIR="$REPO_ROOT/xochi-godot"
BUILD_DIR="$GODOT_DIR/build/web"
GODOT="/opt/homebrew/bin/godot"
BRANCH="xochi-2.0"
DEPLOY_MSG="${1:-deploy: update web build}"

echo "=== Xochi Deploy ==="
echo ""

# 1. Verify we're on the right branch
cd "$REPO_ROOT"
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    echo "ERROR: Expected branch '$BRANCH', on '$CURRENT_BRANCH'"
    exit 1
fi

# 2. Check for uncommitted changes in xochi-godot
if ! git diff --quiet -- xochi-godot/; then
    echo "ERROR: Uncommitted changes in xochi-godot/. Commit first."
    git diff --name-only -- xochi-godot/
    exit 1
fi

# 3. Export web build
echo "[1/5] Building web export..."
"$GODOT" --headless --path "$GODOT_DIR" --export-release "Web" "$BUILD_DIR/index.html" 2>&1 | tail -3

# 4. Verify build output
if [ ! -f "$BUILD_DIR/index.pck" ]; then
    echo "ERROR: Build failed — index.pck not found"
    exit 1
fi

PCK_SIZE=$(du -m "$BUILD_DIR/index.pck" | cut -f1)
echo "[2/5] Build OK — index.pck is ${PCK_SIZE}MB"

if [ "$PCK_SIZE" -gt 50 ]; then
    echo "WARNING: index.pck exceeds 50MB GitHub recommendation ($PCK_SIZE MB)"
fi

# 5. Switch to gh-pages and deploy
echo "[3/5] Switching to gh-pages..."
git stash --quiet 2>/dev/null || true
git checkout gh-pages --quiet

echo "[4/5] Copying build files..."
cp "$BUILD_DIR"/index.html .
cp "$BUILD_DIR"/index.js .
cp "$BUILD_DIR"/index.wasm .
cp "$BUILD_DIR"/index.pck .
cp "$BUILD_DIR"/index.png .
cp "$BUILD_DIR"/index.icon.png .
cp "$BUILD_DIR"/index.apple-touch-icon.png .
cp "$BUILD_DIR"/index.audio.worklet.js .
cp "$BUILD_DIR"/index.audio.position.worklet.js .

# Check if anything actually changed
if git diff --quiet -- index.*; then
    echo "No changes to deploy. Build matches current gh-pages."
    git checkout "$BRANCH" --quiet
    git stash pop --quiet 2>/dev/null || true
    exit 0
fi

git add index.html index.js index.wasm index.pck index.png index.icon.png \
       index.apple-touch-icon.png index.audio.worklet.js index.audio.position.worklet.js
git commit -m "$DEPLOY_MSG" --quiet

echo "[5/5] Pushing to gh-pages..."
git push origin gh-pages

# 6. Switch back
git checkout "$BRANCH" --quiet
git stash pop --quiet 2>/dev/null || true

echo ""
echo "=== Deployed! ==="
echo "Site will update in ~1 min. Hard-refresh (Cmd+Shift+R) to bypass cache."
