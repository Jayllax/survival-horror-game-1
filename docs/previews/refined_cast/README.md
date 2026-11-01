# Refined cast animation comparisons

Previous shading is on the left; stable clothing shading is on the right. These GIFs use the existing animation frame order and durations, rounded to GIF timing precision. Open a GIF directly if your viewer displays only its first frame.

![Player walking in the brown polo](player-walk.gif)

![Jax talking](jax-talking.gif)

![Enemy face distortion](enemy-distortion.gif)

![Enemy attack](enemy-attack.gif)

The game keeps the existing 32×40 frame canvases, poses, skin, hair, authored face effects and effect transparency. Each character reuses one fixed garment pattern across its poses; there are no independently shaded crease patterns or changing trouser highlights. The polo collar and Jax's center seam remain part of their designs. The enemy's death row remains unchanged, and the flashlight still follows the existing attachment points.

Edit the current PNGs under `art/pixel/`. Updated Pixilart masters retain the original author layers underneath the visible **REFINED CAST - DRAW HERE** layer. See [the art guide](../../guides/ART_STYLE_GUIDE.md) for file locations and export scale.

## Verification

Checked with Godot 4.7.2: 151 scenes, 39 data resources and 24 destination links resolve; all 12 designer levels start. The character/attachment, aiming and forest suites pass 186 checks. All 150 character cells retain their dimensions and alpha; clothing texture samples remain identical at matching torso coordinates across the poses. Building/tree exports retain native canvas dimensions, ground anchors and source/export scale; their new drawing outlines and shading come from the approved artwork. Level layouts, dialogue, item settings and SpriteFrames timing data are retained.

The designer's November 1 kit, shotgun and shotgun-shell PNGs are included byte-for-byte from the newest ZIP. The other files in that ZIP match the previous project, apart from leftover copies of the four already-retired props.

The Pixilart JSON and embedded PNGs are validated, and the active layers exactly match the game PNGs. Reopening the documents in the Pixilart application could not be tested here.
