# Deploy Xochi to GitHub Pages

Build-verify and deploy the Godot web export of Xochi.

## Input
$ARGUMENTS

## Steps

1. **Pre-flight checks**:
   - Verify the repo is on branch `xochi-2.0`
   - Check that `deploy.sh` exists and is executable
   - Verify the Godot export preset `Web` exists in `export_presets.cfg`
   - Verify all audio files referenced in code exist in `assets/audio/`
   - Verify all sprite files referenced in code exist in `assets/sprites/`

2. **Build validation**:
   - Run the Godot web export into `build/web/`
   - Verify `build/web/index.html`, `index.js`, `index.wasm`, and `index.pck` all exist
   - Check every level ID (1-11) maps to valid level data in LevelData
   - Check every world (1-6) maps to valid music track in AudioManager
   - Check world selector covers all 6 worlds with correct level ranges
   - Verify no `test_level` references remain in production code paths

3. **Asset completeness**:
   - List all `preload()` and `load()` calls in all .gd files
   - Verify each referenced path exists as an actual file
   - Flag any missing assets with their referencing file and line number

4. **Commit and push**:
   - Run `./deploy.sh "deploy: [summary of changes]"`
   - Confirm the script exported from `xochi-godot/build/web`
   - Confirm it copied the export to `gh-pages` and pushed successfully

5. **Post-deploy**:
   - Report the GitHub Pages URL
   - Report the deployed `gh-pages` commit hash
   - List all files that were changed in this deployment
   - Note any warnings found during validation

## Important
- Do NOT deploy if any validation step fails — report all issues first
- Do NOT bundle/minify unless explicitly asked (Godot export handles this differently)
- Always check `git status` before committing to avoid including unintended files
- Do NOT rely on `xochi-web/`; the legacy Phaser code has been removed from the active repo
