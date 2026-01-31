# Axolotl Warrior — Action Frames + Skeleton Template

This pack contains:
- 4 extracted action poses (PNG, white background)
  - walk.png
  - run.png
  - jump.png
  - attack.png
- A convenience spritesheet with those 4 poses in order:
  - axolotl_warrior_actions_sheet.png
- JSON files:
  - animation_manifest.json  (simple frame-based manifest)
  - skeleton_template.json   (engine-agnostic bone hierarchy template)

## Important caveat (so you don't waste time)
These 4 images are *key poses*, not full cycles. For smooth gameplay you usually want:
- WALK: 6–8 frames (or a bone rig)
- RUN: 6–8 frames
- JUMP: 3 phases (start/loop/land)
- ATTACK: 3 phases (windup/hit/recovery)

## If you want fluid skeletal animation
You need the character cut into parts (head/torso/limbs/tail/gills/weapon/shield) and then rigged in:
- Spine (recommended), DragonBones, Unity 2D Animation, or Godot Skeleton2D.

Use `skeleton_template.json` as the starting bone hierarchy:
- root -> hips -> spine -> head
- tail_1/tail_2 for tail sway
- gills_L/gills_R for secondary motion
- weapon is attached to hand_L
- shield is attached to hand_R

## Quick usage (frame-based)
Load `animation_manifest.json`, then play the frames in this order:
walk -> run -> jump -> attack

Example pseudo:
- walk: 120ms
- run: 120ms
- jump: 180ms
- attack: 180ms

## Suggested next upgrade
If you upload a *layered* version (separate PNGs per body part), I can generate:
- a proper bone-weight plan (exact pivots)
- a richer manifest (multiple frames per action)
- naming conventions ready for your engine
