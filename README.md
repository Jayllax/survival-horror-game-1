# Ignotum

Editable Godot **4.7.2 Standard** 2D survival-horror foundation. Import `project.godot` in Godot, then press **F5** for your configured introduction scene. The reusable main menu is `scenes/ui/main_menu.tscn`. All level geometry, props, characters and interactables are authored scene nodes.

Your October 29 upload's levels, movement, camera, Z ordering, interaction ranges and startup scene are preserved. New games now start unarmed, as requested. This iteration adds a buckshot shotgun and consumable per-item size/damage upgrades. The grid stays at your chosen capacity; your story and level design remain yours to build.

## Start here

Drawing your own animations? Use the [Pixilart templates and instructions](art/templates/characters/README.md), or [download the template pack](docs/downloads/Ignotum-animation-templates.zip). These are blank authoring files; current game artwork is unchanged.

- [DESIGNER_GUIDE.md](DESIGNER_GUIDE.md): build levels, connect entrances, place items, puzzles and bicycle saves.
- [Reusable/single-use items](docs/guides/ITEM_USE_GUIDE.md): Remove After Use, tool variants and consumption on successful actions.
- [Weapons and upgrades](docs/guides/WEAPONS_AND_UPGRADES.md): shotgun, buckshot, compact/damage kits, starting loadout and Inspector settings.
- [Character guide](docs/guides/CHARACTER_GUIDE.md): native atlas rows, animation names, aiming arms and movement settings.
- [Fence guide](docs/guides/FENCE_GUIDE.md): tool-gated paths, permanent barriers, both viewpoints and saved openings.
- [Enemy AI guide](docs/guides/ENEMY_AI_GUIDE.md): sleeping enemies, quiet crouch bypasses, sight/hearing, searching and timed attacks.
- [Narrative guide](docs/guides/NARRATIVE_GUIDE.md): notes, NPCs, colored speakers and conversations.
- [Square alleyway light](docs/guides/ALLEY_LIGHT_GUIDE.md): an editable square/rectangular Godot light for openings.
- [Interior kit](docs/guides/INTERIOR_KIT_GUIDE.md): furniture, lamps and walkable stairs in three colors.
- [Forest kit](docs/guides/FOREST_KIT_GUIDE.md): 21 matching objects in three colors, with optional collision.
- [Art guide](docs/guides/ART_STYLE_GUIDE.md) and [house variants](docs/guides/HOUSE_VARIANTS.md): palette, pixel size and editing assets.
- [Workspace layout](docs/WORKSPACE.md): where things live and what was cleaned up.
- [Inspiration notes](docs/guides/INSPIRATION_NOTES.md): sources and implementation choices; no copied game assets or authored campaign.

## Test scenes

Open a scene and press **F6**:

| Scene | Try |
| --- | --- |
| `tests/fixtures/weapon_workbench.tscn` | New weapon/ammo/upgrade pickups, bicycle and a durable test enemy |
| `tests/fixtures/fence_sandbox.tscn` | Cutters, bicycle save, broad/end-view wire fences, permanent fences |
| `tests/fixtures/combat_sandbox.tscn` | Movement, aim, crouch clearance, short dodge, enemy reactions |
| `tests/fixtures/stealth_sandbox.tscn` | Sleeping enemies, quiet bypasses, noisy actions, pursuit |
| `tests/fixtures/story_sandbox.tscn` | Note reader and NPC dialogue |

These older demonstrations are regression fixtures under `tests/fixtures/`; they remain removed from your gameplay level folder. Your latest upload also removes the interior/forest showroom and catalog scenes from `scenes/levels/`; those removals are preserved. The reusable assets remain available. New fence roots sit on the floor, for example Y=620. New character/fence PNGs are native resolution displayed at 2×; edit those PNGs directly.

## Existing systems

Hold right mouse to draw and aim an equipped gun; release to holster. The independent flashlight follows aim while held, and walking direction otherwise. The arms follow the grip points in both standing and crouched aim. Frame-specific attachments keep the handheld flashlight aligned during walk/run/crouch poses and place it at the barrel during armed aim; body frame alignment keeps the hips over the collider. Gunshots stop at fences/walls even if the barrel visually extends past a thin obstruction.

The 8×4 inventory supports dragging, rotation, stacking, equipping and per-weapon magazines. Larger item footprints and per-instance compact/damage upgrades are supported. The handgun shrinks from 2 to 1 cell, the shotgun from 3 to 2, and bolt cutters from 3 to 2. Kits are consumed once per effect and leave other item instances unchanged. UI stays quiet; world pickups show only a nearby generic action, and item identity is read in the inventory. No control legends were added to the game.

Four bicycle-only save slots independently store inventory/layout/equipment, ammunition, health, flashlight state, completed puzzles, collected items, opened fences/doors and defeated enemies. New Game leaves saves intact. Active enemy alertness, partial enemy health and unfinished animations are transient. Version-2 and version-3 bicycle saves remain readable; current saves use version 4 and include installed upgrades.

## Validation

```sh
GODOT_BIN=/path/to/godot-4.7.2 bash tools/check.sh item_use equipment grid_inventory aiming narrative combat stealth fences character_art interiors forest
```

This imports the project and runs eleven suites against your current settings, with isolated user-data folders. They cover item upgrades, independent upgraded saves, shotgun spread/reloads, grid manipulation, UI/aim, notes/dialogue, movement/combat, stealth, independently saved fence routes, pixel animation states, phased enemy strikes and both hands staying on gun grips across aim angles.

The older four suites (`smoke`, `interface`, `assets`, `manual_saves`) assume historical item names, quantities and example level layouts. Your later designer revisions intentionally differ. The script's no-argument mode includes all fifteen suites; select the eleven current suites above for this snapshot. Never change your designer data to satisfy historical fixtures.

Graphical checks used Linux software OpenGL. Standalone exports, other operating systems and physical audio output have not been tested. Required font license files remain in `art/fonts/`.

Interior furniture, working lamps and walkable stairs are ready to place from `scenes/objects/interiors/`. See the [interior kit guide](docs/guides/INTERIOR_KIT_GUIDE.md) and [color catalog](docs/previews/interior-kit-catalog.png).

Forest scenery is ready to place from `scenes/objects/forest/`. See the [forest kit guide](docs/guides/FOREST_KIT_GUIDE.md) and [color catalog](docs/previews/forest-kit-catalog.png).

Change **Columns/Rows** and **Starting Weapon** in `data/inventory_settings.tres`. These affect new games; existing slots keep their own saved capacity and loadout. Place the new handgun/shotgun/ammunition/kit scenes from `scenes/objects/equipment/` wherever your levels need them.

Item definitions expose **Use Behavior → Remove After Use**. Existing defaults are retained; a separate disposable cutter pickup is ready under `scenes/objects/equipment/`. Keys, tools and puzzle inputs are removed only when the corresponding action succeeds, and unlocked entrances remain usable for backtracking.
