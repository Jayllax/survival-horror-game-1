# Ignotum

Editable Godot **4.7.2 Standard** 2D survival-horror foundation. Import `project.godot` in Godot, then press **F5** for the main menu and your town. All level geometry, props, characters and interactables are authored scene nodes.

Your October 28 upload's alley, interiors, player speed/jump, camera, lighting and input changes are preserved. This iteration adds matching simple player/enemy pixel animations, hands that hold the equipped pistol while aiming, and reusable cuttable/permanent fences in both broad and end views. Your story and main level design remain yours to build.

## Start here

Drawing your own animations? Use the [Pixilart templates and instructions](art/templates/characters/README.md), or [download the template pack](docs/downloads/Ignotum-animation-templates.zip). These are blank authoring files; current game artwork is unchanged.

- [DESIGNER_GUIDE.md](DESIGNER_GUIDE.md): build levels, connect entrances, place items, puzzles and bicycle saves.
- [Character guide](docs/guides/CHARACTER_GUIDE.md): native atlas rows, animation names, aiming arms and movement settings.
- [Fence guide](docs/guides/FENCE_GUIDE.md): tool-gated paths, permanent barriers, both viewpoints and saved openings.
- [Enemy AI guide](docs/guides/ENEMY_AI_GUIDE.md): sleeping enemies, quiet crouch bypasses, sight/hearing, searching and timed attacks.
- [Narrative guide](docs/guides/NARRATIVE_GUIDE.md): notes, NPCs, colored speakers and conversations.
- [Art guide](docs/guides/ART_STYLE_GUIDE.md) and [house variants](docs/guides/HOUSE_VARIANTS.md): palette, pixel size and editing assets.
- [Workspace layout](docs/WORKSPACE.md): where things live and what was cleaned up.
- [Inspiration notes](docs/guides/INSPIRATION_NOTES.md): sources and implementation choices; no copied game assets or authored campaign.

## Test scenes

Open a scene and press **F6**:

| Scene under `scenes/levels/` | Try |
| --- | --- |
| `fence_sandbox.tscn` | Cutters, bicycle save, broad/end-view wire fences, permanent fences |
| `combat_sandbox.tscn` | Movement, aim, crouch clearance, short dodge, enemy reactions |
| `stealth_sandbox.tscn` | Sleeping enemies, quiet bypasses, noisy actions, pursuit |
| `story_sandbox.tscn` | Note reader and NPC dialogue |

These are separate demonstrations; they do not overwrite your levels. New fence roots sit on the floor, for example Y=620. New character/fence PNGs are native resolution displayed at 2×; edit those PNGs directly.

## Existing systems

Hold right mouse to draw and aim an equipped gun; release to holster. The independent flashlight follows aim while held, and walking direction otherwise. The arms follow the grip points in both standing and crouched aim. Frame-specific attachments keep the handheld flashlight aligned during walk/run/crouch poses and place it at the barrel during armed aim; body frame alignment keeps the hips over the collider. Gunshots stop at fences/walls even if the barrel visually extends past a thin obstruction.

The 8×4 inventory supports dragging, rotation, stacking, equipping and per-weapon magazines. Larger item footprints and future inventory upgrades are supported. Starting item quantities and definitions retain your settings. UI stays quiet; world pickups show only a nearby generic action, and item identity is read in the inventory. No control legends were added to the game.

Four bicycle-only save slots independently store inventory/layout/equipment, ammunition, health, flashlight state, completed puzzles, collected items, opened fences/doors and defeated enemies. New Game leaves saves intact. Active enemy alertness, partial enemy health and unfinished animations are transient. Version-2 bicycle saves remain readable; current saves use version 3.

## Validation

```sh
GODOT_BIN=/path/to/godot-4.7.2 bash tools/check.sh aiming narrative combat stealth fences character_art
```

This imports the project and runs six suites against your current settings, with isolated user-data folders. They cover UI/aim, notes/dialogue, movement/combat, stealth, independently saved fence routes, pixel animation states, phased enemy strikes and both hands staying on gun grips across aim angles.

The older five suites (`smoke`, `interface`, `assets`, `manual_saves`, `grid_inventory`) assume historical item names, quantities and example level layouts. Your later designer revisions intentionally differ. The script's no-argument mode includes all eleven suites; select the six current suites above for this snapshot. Never change your designer data to satisfy historical fixtures.

Graphical checks used Linux software OpenGL. Standalone exports, other operating systems and physical audio output have not been tested. Required font license files remain in `art/fonts/`.

Interior furniture, working lamps and walkable stairs are ready to place from `scenes/objects/interiors/`. See the [interior kit guide](docs/guides/INTERIOR_KIT_GUIDE.md) and [color catalog](docs/previews/interior-kit-catalog.png). Open `scenes/levels/interior_kit_showroom.tscn` with F6 to try them without changing your existing levels.
