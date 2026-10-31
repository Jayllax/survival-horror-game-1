# Refined cast animation comparisons

Original artwork is on the left; the approved refinement is on the right. These GIFs use the existing animation frame order and durations, rounded to GIF timing precision. Open a GIF directly if your viewer displays only its first frame.

![Player walking in the brown polo](player-walk.gif)

![Jax talking](jax-talking.gif)

![Enemy face distortion](enemy-distortion.gif)

![Enemy attack](enemy-attack.gif)

The game keeps the existing 32×40 frame canvases, poses, skin, hair, authored face effects and effect transparency. Only clothing receives shading; the enemy's death row remains unchanged. The player's crouch-idle attachment points now follow the designer's existing frame order so the flashlight stays on the drawn hand.

Edit the current PNGs under `art/pixel/`. Updated Pixilart masters retain the original author layers underneath the visible **REFINED CAST - DRAW HERE** layer. See [the art guide](../../guides/ART_STYLE_GUIDE.md) for file locations and export scale.

## Verification

Checked with Godot 4.7.2: 151 scenes, 39 data resources and 24 destination links resolve; all 12 designer levels start. The character/attachment, aiming, interior/stair and forest suites pass 305 checks. Environment texture dimensions, alpha silhouettes, source/export scale and expected symmetry are verified against the designer snapshot. Level layouts, dialogue, item settings and SpriteFrames timing data are retained.

The Pixilart JSON and embedded PNGs are validated, and the active layers exactly match the game PNGs. Reopening the documents in the Pixilart application could not be tested here.
