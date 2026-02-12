# Deploy Xochi to GitHub Pages

Build-verify and deploy the web version of Xochi.

## Input
$ARGUMENTS

## Steps

1. **Pre-flight checks**:
   - Verify the xochi-web directory exists at `../xochi-web/`
   - Check that `game.js` exists and is not empty
   - Check that `index.html` references all required JS and CSS files
   - Verify all audio files referenced in code exist in `assets/audio/`
   - Verify all sprite files referenced in code exist in `assets/sprites/`

2. **Build validation**:
   - Check every level ID (1-11) maps to valid level data in LevelData
   - Check every world (1-6) maps to valid music track in AudioManager
   - Check world selector covers all 6 worlds with correct level ranges
   - Verify no `test_level` references remain in production code paths

3. **Asset completeness**:
   - List all `preload()` and `load()` calls in all .gd files
   - Verify each referenced path exists as an actual file
   - Flag any missing assets with their referencing file and line number

4. **Commit and push**:
   - Stage all changes
   - Create commit with message: "deploy: [summary of changes]"
   - Push to the appropriate branch

5. **Post-deploy**:
   - Report the GitHub Pages URL
   - List all files that were changed in this deployment
   - Note any warnings found during validation

## Important
- Do NOT deploy if any validation step fails — report all issues first
- Do NOT bundle/minify unless explicitly asked (Godot export handles this differently)
- Always check `git status` before committing to avoid including unintended files
