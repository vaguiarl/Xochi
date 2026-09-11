# Companion encounter art

Created September 11, 2026. The original repository assets were preserved.

## Crowquistador

Final game asset: `crowquistador.png` (1312 × 1199, RGBA).

The character was adapted with the built-in imagegen tool. Identity came from
`xochi-godot/assets/sprites/prerendered/enemies/crowquistador.png`; the existing
`xochi-ios/assets/xochi.png` supplied the soft 3D rendering style. The recognizable
helmet, yellow plume, expressive black crow, breastplate and small sword remain.

The complete initial prompt is preserved in `crowquistador.prompt.txt`.
The initial output had a painted checkerboard and was rejected as a production
sprite. A second built-in imagegen edit removed that background. The complete
correction prompt and generated file paths are in `crowquistador-alpha.prompt.txt`.

Selected tool output:
`/Users/victoraguiar/.codex/generated_images/01a0817d-06fe-77d0-922b-4272d6b3a1d4/exec-ab95ae7a-3808-4cd2-b635-85921418b99f.png`

The selected output was copied to `crowquistador.png` without modifying its pixels.
Source inspection confirmed a real alpha channel ranging from 0 to 255, with
transparent corner pixels. Runtime uses the local project asset, not the generated
image cache. Mipmaps and linear filtering support its smaller on-screen size.

## Calabrija

Final game asset: `calaca.png` (1029 × 805, RGBA).

This is an unchanged copy of the original
`xochi-godot/assets/sprites/enemies/calaca.png`. The original code calls the
character Calaca and describes a flying sugar calavera with a sombrero, glowing
eyes and floating hands. The companion encounter uses the name Calabrija.
No new generation prompt or image edit was used for this asset.

The original sprite entered the repository in commit `d7c0c25` on February 11,
2026. Its original generation prompt was not found in the checked repository.

## Presentation

`scripts/crow_guard.gd` supplies tilt, hover and clear watch/investigate/return
signals. `scripts/calabrija.gd` supplies mood-dependent floating movement. These
actors use the illustrated sprites; procedural marks are limited to readable
attention indicators and the crossing opportunity timer.

## Stone bridge

Final game asset: `bridge.png` (2172 × 724, RGBA).

Created September 11, 2026 with the built-in imagegen tool. The existing
`xochi-ios/assets/garden-quay.png` and `xochi-ios/assets/canal-dawn.png` were
visually inspected for the warm golden Xochimilco masonry, hanging moss,
cinematic dawn lighting, and rich prerendered scene style.

The first generation used those two assets as reference images. Its full prompt
is in `bridge.prompt.txt`. It produced a painted checkerboard background and was
rejected, as were two targeted background-extraction edits. The unsuccessful
edits and their exact input/output paths are preserved in
`bridge-alpha-attempt.prompt.txt` and `bridge-extraction.prompt.txt`.

A fresh generation without an image input produced the selected transparent
bridge. Its complete prompt and tool output path are in
`bridge-final.prompt.txt`. Selected tool output:
`/Users/victoraguiar/.codex/generated_images/01a0817d-06fe-77d0-922b-4272d6b3a1d4/exec-3515ddd6-1968-45ce-a7ce-c1d2f2f55221.png`

This output was copied into `bridge.png` without altering its pixels. Read-only
source inspection confirmed RGBA, alpha values from 0 to 255, all four corners
fully transparent, and fully transparent sample pixels inside the central arch.
The continuous opaque capstone begins at source y=16 across the central width;
the requested draw rectangle `(785, 550, 500, 190)` places this surface at
approximately y=554.2, within one pixel of the y=555 walking collision surface.
The asset contains a single large open arch, warm weathered blocks, hanging moss
and ferns, and restrained floral stone reliefs. There is no railing, water, or
scene backdrop.
