# Completed player redesign

The first five rows of the latest uploaded **`player_redesign.pixil`** are the designer's finished idle, walk, sprint, crouch-idle and crouch-walk animations. All **30 authored cells are preserved pixel-for-pixel**. The remaining 54 cells now complete jump, fall, dodge and the six armed movement variants using the same native parts and palette.

## Actual exported motion

This inspection GIF shows the designer's reference alongside the completed jump, fall and dodge frames. It is slowed for review and shows air poses at a fixed origin; gameplay supplies the player's vertical jump movement. Every frame comes from the production `art/pixel/player_motion.png`.

![Designer reference beside the completed jump, fall and dodge poses](player-new-motions.gif)

The following image loads the actual `player.tscn` in Godot, including calibrated weapon arms, under neutral lighting. The first three poses use the designer's own cells. Level lighting affects the colours during gameplay.

![Actual player scene in Godot](player-godot.png)

[Open the complete 192×560 sheet enlarged 4×](player-sheet.png).

The existing authored movements are also previewed directly from the production atlas:

![Authored walk](player-walk.gif)

![Authored sprint](player-sprint.gif)

![Authored crouch walk](player-crouch.gif)

## Editable files and preservation

- `art/pixlart/player_animation/player_motion.pixil`: current completed game master. The visible **REFINED CAST - DRAW HERE** layer and both embedded previews exactly match the game PNG. Earlier author/guide layers remain hidden underneath.
- `art/pixlart/player_animation/player_redesign_reference.pixil`: the latest uploaded document, unchanged byte-for-byte.
- `art/templates/characters/player_authored_frames.png`: exact native first five rows, used to guard the 30 authored cells against accidental edits.
- `art/templates/characters/player_style_reference.png`: exact first reference frame, also enlarged in [this actual PNG preview](player-native.png).

The atlas remains **6×14 cells of 32×40**, with its existing playback order, frame durations and animation names. All finished poses use colours already present in the 30 drawn cells. Heads, collars, sleeves, belt details and boots reuse the native drawn parts; no independent concept illustration, new gradients or moving wrinkle pattern is introduced. Armed variants omit dangling hands so the weapon rig supplies the aiming hands. Body-centre, shoulder and flashlight points follow the completed artwork without moving the physics body or collision shape.

Opening the documents inside the Pixilart application could not be tested here. Their JSON, embedded PNGs, dimensions and active layers/previews are validated. Earlier preview pages and animation download packs document older artwork; Jax/enemy sheets and authored face effects are unchanged in this player update.

## Verification

Godot 4.7.2 passes **78 character/aiming checks**, covering exact preservation of all 30 authored cells, no added colours, unchanged head pixels across all 84 cells, armless aiming artwork, both weapon grips and per-frame flashlight/shoulder alignment facing both ways. All 151 reusable/fixture scenes, 39 data resources and 24 entrance links resolve; all 12 designer levels start and clean up. Native art validation passes. The designer's kit, shotgun and shell PNGs remain unchanged.
