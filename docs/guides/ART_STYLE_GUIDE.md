# Pixel art workflow

One native art pixel covers **2×2 world pixels**. Use nearest-neighbor filtering, hard transparency, flat palette colors and simple shapes. Keep façades and fence panels horizontally symmetrical. Single left/right house chimneys are the deliberate exception requested for those variants.

The base artist swatches are **Sparkle's palette**; import `art/pixel/ignotum.gpl` into your pixel editor. Approved house/tree artwork retains its source colours and intermediate shades. Player artwork uses the designer’s native pixel reference and its colours. `art/pixel/STYLE_SHEET.png` is a contact sheet made from the current game sprites at 2× native size.

Buildings keep the approved window/door recesses, roof seams and mostly uniform walls. Trees keep the approved leaf planes and bark shading. Their source artwork is exported directly with a single nearest-neighbor size conversion. Old internal colour masks, hard shade reduction and mirrored RGB shading must not be reapplied: those operations change the approved design. Tree outlines remain symmetric; directional shading is retained.

See [the actual Godot render and approved source artwork](../previews/approved_world/README.md). These are separate from a concept illustration: the Godot image loads the same textures and reusable scenes as the game.

The legacy `tools/build_simple_assets.py` draws an earlier prototype and does **not** reproduce the current artwork. Edit the current PNGs and Pixilart masters rather than running that generator over your work. Plain plaster, existing tile-edge colors and authored character distortion colors are deliberately retained.

## Files to edit

| Asset | Editable PNG | Display |
| --- | --- | --- |
| Player motion | `art/pixel/player_motion.png`, 192×560, 6×14 cells of 32×40 | Body scale 2× |
| Enemy motion | `art/pixel/enemy_motion.png`, 192×280, 6×7 cells of 32×40 | Body scale 2× |
| NPC motion | `art/pixel/npc_motion.png`, 192×80, 6×2 cells of 32×40 | Body scale 2× |
| Broad fences | `art/pixel/fence_cuttable.png`, `fence_reinforced.png`, 48×32 each | Sprite scale 2× |
| End-view fences | `art/pixel/fence_cuttable_side.png`, `fence_reinforced_side.png`, 6×32 each | Sprite scale 2× |
| Houses | `art/pixel/house_variants/house_*.png`, 96×128 | Sprite scale 2× |
| Bicycle | `art/pixel/bicycle.png`, 32×28 | Sprite scale 2× |
| Older scenery/items | `art/pixel/source/name.png` native drawing; `art/pixel/name.png` existing enlarged export | Export already 2×; Sprite scale 1× |

**New characters and fences have only one PNG each.** Edit that native file directly; do not enlarge it before saving. The older source/export pairs remain because your placed scenes and item resources use those exports. Keep both files in step if you edit them. Your `.pixil` working files remain under `art/pixlart/`.

Player/NPC/enemy frames share padded 32×40 canvases. Crouch and death are shorter drawn poses. The player's detail standard is now the designer's top-left frame from the uploaded `player.pixil`: dark brown hair with a simple rim, blank tan face, plain brown long sleeves, pale grey neckline, grey belt buckle, slate trousers with dark edges and dark shoes. This native reference is the visual standard for future NPC artwork too; preserve existing NPC gestures and enemy face effects when adapting their sheets.

`art/templates/characters/player_style_reference.png` is the exact original 32×40 frame. The original uploaded document is archived unchanged as `art/pixlart/player_animation/player_style_reference.pixil`. The player atlas keeps that top-left cell pixel-for-pixel unchanged. All 84 cells reuse its exact unscaled head, copied collar and belt details, flat clothing colours and existing motion silhouettes. No colours are added beyond those already in the reference. Keep shading consistent between frames; do not add gradients, independent crease patterns, antialiasing or resampled high-resolution concept art. The atlas stays 192×560, feet retain their original baselines and playback timing is unchanged.

Use the [actual exported animations and Godot render](../previews/refined_cast/README.md) to review changes. Previews must be made from the production PNG, rather than an independently generated illustration.

Current editable masters are under `art/pixlart/player_animation/` and `art/pixlart/cast_animation/`. The updated masters have a visible **REFINED CAST - DRAW HERE** layer; the original author layers are retained underneath and hidden. Keep guides and old layers hidden when exporting the current sprite sheet. `animations-human-made.pixil` remains the original source. Each 32×40 cell is one game animation frame; the `.pixil` documents contain the full sheets.

See the [looping cast comparisons](../previews/refined_cast/README.md). The active Jax scene uses `art/pixel/npc_jax_,motion.png`. The older `player.png`/`enemy.png` strips are legacy assets; current actors use the motion sheets listed above.

See [CHARACTER_GUIDE.md](CHARACTER_GUIDE.md) for exact atlas rows, aiming arms and animation replacement. See [FENCE_GUIDE.md](FENCE_GUIDE.md) for fence placement and saved route openings, and [HOUSE_VARIANTS.md](HOUSE_VARIANTS.md) for houses.

Lighting and fog intentionally use separate smooth Godot 2D light textures. They can create additional screen colors without adding colors to the PNG artwork. Font files and their required OFL license remain in `art/fonts/`.

The unused legacy shelf, sign, drain and pipe PNGs, their import files, and the unused shelf scene have been removed. Interior bookcases and cabinets remain available in their existing folders. Asset paths, native canvas sizes, ground anchors, collisions and placed level geometry are retained. The house/tree drawing outlines now come from the approved artwork, not the old silhouette masks.
