# Pixel art workflow

One native art pixel covers **2×2 world pixels**. Use nearest-neighbor filtering, hard transparency, flat palette colors and simple shapes. Keep façades and fence panels horizontally symmetrical. Single left/right house chimneys are the deliberate exception requested for those variants.

The current artist palette is **Sparkle's palette**, extracted from your `art/pixlart/house.pixil`; import `art/pixel/ignotum.gpl` into your pixel editor. The previous kit palette and obsolete generators have been replaced/removed so they cannot accidentally overwrite your revisions. Existing scenery, items and editable `.pixil` files are retained.

## Files to edit

| Asset | Editable PNG | Display |
| --- | --- | --- |
| Player motion | `art/pixel/player_motion.png`, 192×240, 6×6 cells of 32×40 | Body scale 2× |
| Enemy motion | `art/pixel/enemy_motion.png`, same layout | Body scale 2× |
| Broad fences | `art/pixel/fence_cuttable.png`, `fence_reinforced.png`, 48×32 each | Sprite scale 2× |
| End-view fences | `art/pixel/fence_cuttable_side.png`, `fence_reinforced_side.png`, 6×32 each | Sprite scale 2× |
| Houses | `art/pixel/house_variants/house_*.png`, 96×128 | Sprite scale 2× |
| Bicycle | `art/pixel/bicycle.png`, 32×28 | Sprite scale 2× |
| Older scenery/items | `art/pixel/source/name.png` native drawing; `art/pixel/name.png` existing enlarged export | Export already 2×; Sprite scale 1× |

**New characters and fences have only one PNG each.** Edit that native file directly; do not enlarge it before saving. The older source/export pairs remain because your placed scenes and item resources use those exports. Keep both files in step if you edit them. Your `.pixil` working files remain under `art/pixlart/`.

Player/enemy frames deliberately share the same padded canvas, feet at its bottom. Crouch and death drawings are shorter poses inside that canvas, rather than squashed sprites. The player has brown hair, a flat face without a protruding nose, a plain brown shirt, blue-grey trousers and dark shoes. The matching enemy has muted green skin, dark hair and a burgundy shirt, without extra monster detailing.

See [CHARACTER_GUIDE.md](CHARACTER_GUIDE.md) for exact atlas rows, aiming arms and animation replacement. See [FENCE_GUIDE.md](FENCE_GUIDE.md) for fence placement and saved route openings, and [HOUSE_VARIANTS.md](HOUSE_VARIANTS.md) for houses.

Lighting and fog intentionally use separate smooth Godot 2D light textures. They can create additional screen colors without adding colors to the PNG artwork. Font files and their required OFL license remain in `art/fonts/`.
