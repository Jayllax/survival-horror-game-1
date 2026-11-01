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

Player/NPC/enemy frames share padded 32×40 canvases. The current player sheet is **entirely drawn by the designer**, imported directly from `player_redesign_1.pixil`. Every one of its 84 cells is preserved unchanged: no redraw, recolouring, resizing or pose substitution. Its simple shading and character details remain the reference for future NPC art; retain NPC gestures and enemy face effects when adapting those sheets.

The game's `art/pixel/player_motion.png` is the exact PNG stored in the uploaded drawing layer. The current editable master, `art/pixlart/player_animation/player_motion.pixil`, uses that file's single **Background** layer and palette. Only its malformed global thumbnail was replaced with the valid embedded frame preview. `player_redesign_1.pixil` beside it archives the original upload byte-for-byte. Earlier reference documents remain historical. `art/templates/characters/player_authored_frames.png` holds the full finished sheet for preservation checks, and `player_style_reference.png` holds its first cell.

All 14 animations now read their six cells in sheet order. The old shuffled crouch-idle mapping and reused walk-column reference were corrected; FPS and per-frame durations are retained. Body-centre, shoulder and flashlight points are calibrated against the actual belt, shirt and hands. The artwork stays fixed; these attachment coordinates fit weapons and lights to it.

Use the [actual game renders and exported animation previews](../previews/refined_cast/README.md) when reviewing artwork. The player master is now the uploaded single-layer document. NPC/enemy masters under `art/pixlart/cast_animation/` keep their existing **REFINED CAST - DRAW HERE** layers; their artwork is unchanged by this import.

See the [looping cast comparisons](../previews/refined_cast/README.md). The active Jax scene uses `art/pixel/npc_jax_,motion.png`. The older `player.png`/`enemy.png` strips are legacy assets; current actors use the motion sheets listed above.

See [CHARACTER_GUIDE.md](CHARACTER_GUIDE.md) for exact atlas rows, aiming arms and animation replacement. See [FENCE_GUIDE.md](FENCE_GUIDE.md) for fence placement and saved route openings, and [HOUSE_VARIANTS.md](HOUSE_VARIANTS.md) for houses.

Lighting and fog intentionally use separate smooth Godot 2D light textures. They can create additional screen colors without adding colors to the PNG artwork. Font files and their required OFL license remain in `art/fonts/`.

The unused legacy shelf, sign, drain and pipe PNGs, their import files, and the unused shelf scene have been removed. Interior bookcases and cabinets remain available in their existing folders. Asset paths, native canvas sizes, ground anchors, collisions and placed level geometry are retained. The house/tree drawing outlines now come from the approved artwork, not the old silhouette masks.
