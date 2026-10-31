# Ignotum

Reusable four-digit dial locks are available in `scenes/objects/puzzles/code_lock.tscn`. Add one beside your own furniture or doors and configure it in the Inspector; see the [code-lock guide](docs/guides/CODE_LOCK_GUIDE.md). No puzzle instances or clues have been added to your levels.

Reusable [room light switches](docs/guides/LIGHT_SWITCH_GUIDE.md) are available in `scenes/objects/lighting/light_switch.tscn`. Assign connected lights in the Inspector, optionally reveal your own clue artwork when off, and preserve each circuit in bicycle save slots.

Searchable furniture uses `scenes/objects/loot/loot_container.tscn`. An empty Contents array shows **Empty** once; filled containers transfer their configured items together and remain searchable if everything cannot fit. See the [loot-container guide](docs/guides/LOOT_CONTAINER_GUIDE.md).

Five [side-view paper notes](docs/guides/NOTE_VARIANTS_GUIDE.md) are available under `scenes/objects/notes/`, with native PNGs in `art/pixel/notes/`. They share the existing note-reading system; the default Note uses the flat paper profile.

Eight [transparent blood overlays](docs/guides/BLOOD_OVERLAY_GUIDE.md) are ready in `scenes/objects/blood/`, with editable native PNGs in `art/pixel/blood/`. They are placed manually and can be clipped to furniture artwork using Godot's Clip Children setting.

The [pushable furniture component](docs/guides/PUSHABLE_GUIDE.md) goes **under your existing furniture as a child**. Resize its collision box, set push speed/optional travel limits, and use it as a solid movable step. Its position is stored in bicycle saves. Scenes are under `scenes/objects/physics/`.

Editable Godot **4.7.2 Standard** 2D survival-horror foundation. Import `project.godot` in Godot, then press **F5** for your configured introduction scene. The reusable main menu is `scenes/ui/main_menu.tscn`. All level geometry, props, characters and interactables are authored scene nodes.

Your latest October 29 upload's renamed town/alley/house scenes, layouts, movement, camera, flashlight brightness, Z ordering, interaction ranges and startup scene are preserved. New games now start unarmed, as requested. This iteration adds a buckshot shotgun and consumable per-item size/damage upgrades. The grid stays at your chosen capacity; your story and level design remain yours to build.

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
GODOT_BIN=/path/to/godot-4.7.2 bash tools/check.sh inventory_bounds pushables aiming narrative dialogue_choices combat stealth interiors
```

This focused movement/interaction command imports the project and uses isolated user-data folders. It covers child-component pushing, the push-and-jump escape route, independent moved-object saves, aiming, notes/dialogue, movement/combat, stealth and the authored stairs.

The runner also contains inventory, upgrades, fence, looting, code-lock, lighting and art suites. Some item fixtures still use earlier item IDs such as `gate_key`; the current designer resource uses `gate_key_01`. The older four suites (`smoke`, `interface`, `assets`, `manual_saves`) also assume historical names, quantities and layouts. The no-argument mode runs all nineteen suites. Select the relevant fixtures and update their setup when changing catalog IDs; keep designer data authoritative.

Graphical checks used Linux software OpenGL. Standalone exports, other operating systems and physical audio output have not been tested. Required font license files remain in `art/fonts/`.

Interior furniture, working lamps and walkable stairs are ready to place from `scenes/objects/interiors/`. See the [interior kit guide](docs/guides/INTERIOR_KIT_GUIDE.md) and [color catalog](docs/previews/interior-kit-catalog.png).

Forest scenery is ready to place from `scenes/objects/forest/`. See the [forest kit guide](docs/guides/FOREST_KIT_GUIDE.md) and [color catalog](docs/previews/forest-kit-catalog.png).

Change **Columns/Rows** and **Starting Weapon** in `data/inventory_settings.tres`. These affect new games; existing slots keep their own saved capacity and loadout. Place the new handgun/shotgun/ammunition/kit scenes from `scenes/objects/equipment/` wherever your levels need them.

Item definitions expose **Use Behavior → Remove After Use**. Existing defaults are retained; a separate disposable cutter pickup is ready under `scenes/objects/equipment/`. Keys, tools and puzzle inputs are removed only when the corresponding action succeeds, and unlocked entrances remain usable for backtracking.

Older town/alley/interior scene paths are redirected to their new names when reading save files, including scene-prefixed collected/opened-object state. Existing files are not rewritten during previews. The uploaded empty animation point lists remain intact; a built-in reference keeps the current character’s attachments aligned when both saved profiles are empty.

Fonts and document appearance: [font guide](docs/guides/FONT_GUIDE.md). Player answers, saved story flags and conditional objects: [dialogue choice guide](docs/guides/DIALOGUE_CHOICES_GUIDE.md).

For scene-contained custom items and bicycle save/load regression checks, run `GODOT_BIN=/path/to/godot bash tools/check.sh embedded_item_saves`. This includes a second Godot process that loads the files written by the first.

Music, ambience, safe-room cues and material footsteps: [AUDIO_GUIDE.md](docs/guides/AUDIO_GUIDE.md). Optional audio/stealth checks: `GODOT_BIN=/path/to/godot bash tools/check.sh audio stealth`.
