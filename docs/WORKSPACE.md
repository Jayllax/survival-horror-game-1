# Workspace layout

| Folder/file | Contents |
| --- | --- |
| `project.godot` | Open this in Godot 4.7.2 Standard |
| `DESIGNER_GUIDE.md` | Beginner level-building entry point |
| `scenes/levels/` | Your authored levels and separate demonstration scenes |
| `scenes/actors/` | Player, enemy, NPC and reusable aiming-arm component |
| `scenes/objects/` | Drag-and-drop props, entrances, fences, pickups and bicycle |
| `scenes/ui/` | Menus, inventory, dialogue, fades and saves |
| `scripts/` | Gameplay behavior; you can design through the exported Inspector fields |
| `data/` | Editable item definitions, inventory settings, SpriteFrames and narrative resources |
| `art/pixel/` | Game PNGs; new motion atlases and fences are single native files |
| `art/pixel/source/` | Preserved older native source drawings, including the original character reference |
| `art/pixlart/` | Your editable `.pixil` working files |
| `art/templates/characters/` | Blank layered Pixilart animation templates, excluded from runtime import |
| `docs/downloads/` | Blank templates and completed editable player/NPC/enemy animation packs |
| `art/pixel/ignotum.gpl` | Current Sparkle's palette from your house source |
| `audio/` | Sound files |
| `docs/guides/` | Focused art, characters, fences, AI, narrative and house guides |
| `docs/previews/` | Reference screenshots; docs are excluded from Godot importing |
| `tests/` | Development checks, separate from normal game scenes |
| `tools/check.sh` | Optional automated validation runner |

## This cleanup

The detailed guides were grouped under `docs/guides/`, with links updated. README and DESIGNER_GUIDE remain easy to find at the root.

Removed the obsolete generated redesign illustration (about 1.4 MB), its old production contact sheet/metadata, the old asset and bicycle generators, and their obsolete checker. Those tools used historical art/palettes and could overwrite later hand edits. Superseded exploration/inventory/save-menu screenshots were replaced with current aiming/strike previews. Documentation image-import sidecars were removed and `docs/.gdignore` prevents Godot importing documentation as game assets. Duplicate palette files were consolidated into the current `art/pixel/ignotum.gpl`.

Your editable PNG sources, `.pixil` files, scenery/prop kit, audio, levels and font license remain. The original six-frame character PNGs remain as references alongside their native sources; current player/enemy scenes use the new `*_motion.png` atlases. Old source/export pairs for other assets were retained because existing scenes/item resources use those exports and you may still edit their sources. This is not a blanket deletion of assets that happen to be absent from today's town.

Godot's `.png.import`, `.tres`, `.tscn`, and `.gd.uid` files are useful project metadata/resources, not duplicate artwork. Keep them with the associated files. `.godot/` is an ignored generated cache and is not committed. Removed historical generated references remain recoverable from Git history.

The current completed player artwork and untouched uploaded reference are in [art/pixlart/player_animation](../art/pixlart/player_animation/README.md). The [editable animation pack](downloads/Ignotum-completed-player-animations.zip) includes all fourteen player clips.

NPC and enemy editable sources are in [art/pixlart/cast_animation](../art/pixlart/cast_animation/README.md), using the same native character design. [Download their animation pack](downloads/Ignotum-NPC-enemy-animations.zip).

The [interior kit](guides/INTERIOR_KIT_GUIDE.md) keeps native furniture PNGs under `art/pixel/interiors/`, matching reusable scenes under `scenes/objects/interiors/`, and editor controls under `scripts/interiors/`. The latest designer snapshot removes its separate showroom/catalog scenes, while retaining the reusable kit.

The [forest kit](guides/FOREST_KIT_GUIDE.md) keeps 63 native textures in `art/pixel/forest/`, 21 reusable props in `scenes/objects/forest/` and its palette labels in `scripts/forest/`. It shares the interior color/collision controls. Removed old gameplay sandboxes survive only as development fixtures under `tests/fixtures/`, preserving your removal from `scenes/levels/`.

The [weapon and upgrade guide](guides/WEAPONS_AND_UPGRADES.md) covers `data/items/`, `data/upgrades/`, new native artwork in `art/pixel/equipment/` and reusable pickups in `scenes/objects/equipment/`. The authored equipment test room lives in `tests/fixtures/`, outside your gameplay levels.

The [item-use guide](guides/ITEM_USE_GUIDE.md) explains the shared Remove After Use checkbox and disposable tool variants. The single-use cutters reuse the original cutter artwork; no duplicate PNG is needed.

Four-digit locks are split into an invisible reusable interaction scene under `scenes/objects/puzzles/`, an editor-authored panel at `scenes/ui/code_lock_ui.tscn`, and scripts under `scripts/puzzles/`. The [code-lock guide](guides/CODE_LOCK_GUIDE.md) explains placement and optional opening effects. Automated instances stay in `tests/code_lock.gd`; your playable levels have no added puzzle examples.

The [light-switch guide](guides/LIGHT_SWITCH_GUIDE.md) covers the reusable `scenes/objects/lighting/light_switch.tscn` and `scripts/lighting/light_switch.gd`. Its simple plate and rocker are editor-visible shapes using the project palette. The interior lamp script exposes a small control method so switches can keep its actual light and Inspector property synchronized. No light-switch instances are added to your levels.

The [loot-container guide](guides/LOOT_CONTAINER_GUIDE.md) covers the invisible `scenes/objects/loot/loot_container.tscn`, the interaction script and the exported `LootEntry` resource under `scripts/loot/`. Contents are configured directly on placed container instances; an empty array makes an intentionally empty drawer. No duplicate item artwork or gameplay examples are added.

Five native side-view paper sprites are grouped in `art/pixel/notes/`; matching inherited note scenes are in `scenes/objects/notes/`. The [note-variant guide](guides/NOTE_VARIANTS_GUIDE.md) explains placement and editing. The default note scene uses the flat profile; documents and reading logic remain shared. The enlarged preview is kept only under `docs/previews/`.

Native blood textures are grouped in `art/pixel/blood/`, and script-free Sprite2D scenes in `scenes/objects/blood/`. The [overlay guide](guides/BLOOD_OVERLAY_GUIDE.md) explains furniture masking, scale and depth. The checkerboard/context preview is documentation only; game PNGs are transparent and no stains are automatically added to levels.

The child pushable component lives at `scenes/objects/physics/pushable_body.tscn`, with its controller under `scripts/physics/` and a fitted nightstand variant beside it. It moves its furniture parent and records positions through existing world saves. The [pushable guide](guides/PUSHABLE_GUIDE.md) explains per-instance collision sizing and travel limits. Its editor-authored development room stays under `tests/fixtures/`; no campaign furniture is converted automatically.

## Fonts

`art/fonts/` contains the uploaded fonts and four new open-license families, with notices and editable FontVariation presets under `styles/`. The [font guide](guides/FONT_GUIDE.md) lists each UI node and the per-note override controls. The newest uploaded levels, items, Jax art and project/window settings are preserved.

## Conversation choices

`DialogueChoice` resources belong to the Choices array on a DialogueLine. Conditional world targets use `scenes/objects/story/world_flag_condition.tscn`. Choice buttons are a reusable authored UI scene; additional response buttons are instanced only as UI. All level targets remain editor-placed. See the [choice guide](guides/DIALOGUE_CHOICES_GUIDE.md). The separate `tests/fixtures/dialogue_choices_sandbox.tscn` is not linked to the campaign.

### Verification notes for this iteration

The focused narrative/choice and modal suites validate the new UI and saved consequences. Legacy code-lock and loot checks now read the designer's key resource ID instead of assuming `gate_key`; the light-switch test places the player inside the edited Interaction Radius. These are fixture changes only. The separate headless aiming suite reports one left-mirroring assertion failure in both the untouched October 30 22-42 upload and this branch. Aiming behavior and character/weapon attachment resources were not changed in this iteration.

## Inventory bounds and complete interface font pass

The October 30 23-28 upload changes seven level scenes; all seven are imported byte-for-byte. `inventory_grid_control.gd` now limits GUI hits and keyboard focus to real cells, cancels drops outside the grid without changing item data, and adapts its bounds to current inventory dimensions. Its 21 native GUI checks cover outside clicks, valid dragging/rotation, stack merging and resized grids.

All general interface text, including code-drawn inventory counts, uses `art/fonts/styles/ui_text.tres` (Marcellus). Save-slot records use the Special Elite preset. The only retained old interface face is Lakeside Castle in note contents, as requested. A runtime audit checked 105 font roles across menus, popups and the HUD with exactly that one exception and no failures. Transparent note panels and authored layouts are retained.

## Scene-contained item saves

`Game._saved_catalog` accepts typed InventoryItemDefinition resources stored either externally or inside a scene/resource. It loads and holds the owning resource before resolving embedded IDs in a fresh process; it never instantiates the owning level. The previous `.tres` filename-only check rejected the designer's embedded `house_03_key` and `gate_key`, even after visiting their locations without collecting them. Save format 4, slot isolation, atomic writes and malformed-data validation remain unchanged.

`tests/embedded_item_saves.tscn` exercises the real alley, house and town bicycle menu, both custom keys, independent inventory/health/progress snapshots and malformed-data rejection. `tools/check.sh embedded_item_saves` automatically launches a second Godot process to verify the same files load without previously visited scenes in memory. The latest supplied ZIP differs only in UI-theme property ordering; that exact uploaded file is preserved, along with all levels and assets.
