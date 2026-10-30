# Ignotum / designer guide

For reusable wire/solid fences in broad and end views, see [FENCE_GUIDE.md](docs/guides/FENCE_GUIDE.md). Try `tests/fixtures/fence_sandbox.tscn` with F6.

For sleeping enemies, crouch bypasses, directional sight/hearing, patrol/search behaviour, and the attack animation/hitbox, see [ENEMY_AI_GUIDE.md](docs/guides/ENEMY_AI_GUIDE.md).

For player/enemy SpriteFrames, crouch, sprint, short dodge, and gun-only combat, see [CHARACTER_GUIDE.md](docs/guides/CHARACTER_GUIDE.md). Open `tests/fixtures/combat_sandbox.tscn` with F6 to try them.

For editable environmental notes, colored speakers, and NPC conversations, see [NARRATIVE_GUIDE.md](docs/guides/NARRATIVE_GUIDE.md). Open `tests/fixtures/story_sandbox.tscn` and press F6 to try the framework without changing your town.

## Your starting point

Import `project.godot` with Godot 4.7.2 Standard, open `scenes/levels/town_01.tscn`, choose **2D**, and press **F6** to test. **F5** starts the main menu. Stop with F8 before editing. The game has no story progression requirement or ending. You own the writing and campaign structure.

The supplied first street links to a small ground-floor interior and service alley to demonstrate entrances. Your uploaded alley is a blockout; use the separate combat/stealth sandbox scenes to test enemies, then place them where your levels need them. All objects are visible in the editor, including every destination and spawn marker.

## Move and duplicate

Click a scene-tree node and drag it in the 2D view. **Ctrl+D** duplicates. Drag reusable `.tscn` files from FileSystem to place objects. Move an instance's **root**, not just its sprite, to keep its visuals and collision together.

| Branch | Contents |
| --- | --- |
| Buildings | Background façades and alley-mouth polygons |
| Geometry | Ground, visible paving, curb, boundaries |
| Props | Lamps, benches, pipes, drains, bins, bollards |
| Interactables | Entrances and pickups |
| Actors | One player and optional enemies |
| Spawns | Named Marker2D entry points |
| HUD | One reusable interface scene |

Decorative façades and most street props do not block movement. Platforms, physical gates, boundaries, and ground do. Use **Debug → Visible Collision Shapes** when testing. `scenes/objects/platform.tscn` exposes **Platform Size**, which updates its existing art/collision/shadow nodes in the editor. Keep jump steps roughly 40–60 world pixels with default movement settings.

## Add a door or alley entrance

1. Drag `scenes/objects/entrance.tscn` into `Interactables`.
2. Select its root. Set **Action Label**, such as “Enter”.
3. Set **Destination Scene** with the file picker, such as `scenes/levels/house_01.tscn`.
4. Set **Destination Spawn** to a Marker2D name in that location's `Spawns` branch, such as `from_street`.
5. Keep **Required Key** empty and **Requires Power** off for an unlocked entrance.
6. In the destination, place a return entrance that targets the original scene and a different return marker.
7. Test both directions. Place return markers roughly 100–140 pixels beside the entrance rather than directly on top of another interactable.

The player presses **E** within Interaction Radius. The scene fades to black, loads the destination, places the player at the named marker, and fades back in. Input is locked throughout. It never walks the character along an invisible depth axis. There is no end-of-level trigger.

For an alley, enable **Editable Children** on the entrance instance and hide its `Facade` sprite. Put a dark, visible gap in the buildings behind it. The supplied `AlleyEntrance` demonstrates this. Its Area2D rectangle helps selection in the editor; interaction is based on proximity. Avoid placing accessible triggers on opposite sides of a thin wall because the proximity system does not check line of sight.

For a key lock, set Required Key to a pickup's **Item Id**, such as `workshop_key`. The key’s **Use Behavior → Remove After Use** checkbox controls consumption. Successfully unlocked entrances stay unlocked for backtracking even when their key is spent. An entrance is a background transition; `door.tscn` is a physical sliding gate on the same side-scrolling plane. See the [item-use guide](docs/guides/ITEM_USE_GUIDE.md) for both key/tool variants and the legacy Consume Key override.

## Make another location

1. Open a similar location and choose **Scene → Save As** under `scenes/levels/`.
2. Keep the root's `location.gd` script. Set its **Display Name** and **Camera Bounds** in the Inspector.
3. Keep exactly one Player and one HUD. Keep ground and boundaries, adjusting their positions and shapes for the new width.
4. Keep a `Spawns` Node2D with a Marker2D called `default`. Add named return markers as needed.
5. Rearrange art, props, pickups, enemies, and entrances. Link it from another entrance with the file picker.
6. Test F6, then test entering it from the actual source location. F6 begins with fresh state; Load game restores a manual save instead.

New Game loads `town.tscn`. To replace the starting location without programming, keep a backup and save your final start layout over that file. Do not add a second Player or HUD. There is no need for a separate Git worktree; edit this checkout.

## Tune movement and combat

Select Player for movement, sprint/crouch, and short dodge settings. Firearm stats come from the equipped weapon definition. See docs/guides/CHARACTER_GUIDE.md for all animation names and Inspector defaults.

Jump Velocity must be negative; other tuning values should be positive. The short grounded dodge defaults to **0.18 seconds of motion** and **0.12 seconds of invulnerability**, with a 0.65-second cooldown between starts. All three values are exported. The gun starts with six loaded rounds, clamped to Magazine Size; reserve ammunition comes from your inventory settings. Character states play named SpriteFrames animations automatically. Movement accelerates smoothly; a short coyote window and jump buffer make platforming forgiving.

The flashlight is `Player/Aim/Gun/Flashlight`. It follows the cursor only while right mouse is held; otherwise it points in the last walking direction. The gun is holstered when right mouse is released. The Gun node stays active so its light children keep working. Its origin follows the animated hand when holstered, or the pistol barrel and recoil when drawn. Select **Player/WeaponArms → Attachment Profile** for per-frame hand/chest points; see [the character guide](docs/guides/CHARACTER_GUIDE.md). It still points horizontally in facing direction without held aim. **Offset = (256, 0)** places its beam in front of the barrel. **Transform → Scale (0.85,1.25)** gives the current slightly shorter, broader beam. Increase Y for a wider cone or X for longer reach; Energy/Color/Texture Scale change its illumination. Keep Offset (256,0) when using the supplied beam texture so the apex remains attached. Do not use `texture_offset`; that is not a Godot PointLight2D property. F toggles it, and its state persists between locations. It never occupies an inventory slot.

Enemies expose Max Health, Speed, Detection Radius, Damage, Attack Interval, Patrol Width. They sleep or guard/patrol, hear noisy actions, use directional vision, investigate/search, react to hits, and perform committed attacks with an editable hitbox. They move on flat ground and do not navigate jumps. They play a death animation before removal. Their defeat is persistent. The default enemy takes three handgun hits. Place them on reachable flat surfaces. Their live partial health is not persisted across scene changes.

## Quiet interface and inspectable items

The world view has no permanent HUD bars, location/title labels, controls strip, pickup names, or floating item markers. A nearby object's generic action appears above it: Take, Examine, Use, Open, Enter, Read, or Talk, without a keyboard hint. Override **Action Label** for a different short verb, without revealing item identity. **Prompt Offset** positions the prompt relative to the object in world pixels; Interaction Radius controls proximity. Saving is manual and only available at placed bicycles.

Health appears briefly after damage, staying visible only at critical health. Select the HUD root to tune Health Feedback Seconds, Pickup Hint Seconds, Message Seconds, or turn Show Pickup Hint off. Select Player to tune Combat Feedback Seconds and Aiming Move Multiplier. Holding right mouse enables careful aiming movement and a small crosshair/ammo readout. Left click fires only while right mouse is held. Recent shots and reloading also show ammunition temporarily; the crosshair disappears as soon as right mouse is released. Inspect exact condition and weapon status in the inventory. The flashlight remains equipped outside the inventory. In-game control legends and key hints have been removed for your tutorial.

Open I and click an item icon, or move focus with arrow keys. Its name, large artwork, category, quantity, and description appear beside the grid. **Use** applies compatible supplies, **Combine** asks for a second item, and selection itself examines the item. Use is disabled at full health for medical items. A failed combination or an output that cannot fit consumes nothing. Drag items within the grid to move them. See the grid inventory section below for rotation and equipment. Discarding items is not implemented.

### Create an item without programming

1. Duplicate a definition in `data/items/` from Godot's FileSystem dock. Open the `.tres` in the Inspector.
2. Give it a unique stable **Id**, **Display Name**, **Category**, **Description**, **Icon**, and **Max Stack**. **Heal Amount** greater than zero makes it usable medicine.
3. Open `data/catalog.tres`. Add the definition to its **Items** array. This makes names/icons/descriptions available even before revisiting a pickup's scene after loading.
4. Duplicate a pickup scene and assign your definition to **Item Definition**. Set **Quantity**, put the matching image on its Sprite2D so it is visible in the editor, and place it. At runtime, the definition's Icon is applied to the pickup too.
5. Play, collect, and inspect it in the inventory. The world will not label it with its name.

When Item Definition is assigned it supplies Item Id; change the definition's Id rather than the legacy Item Id field. For quick generic keys with no definition, clear Item Definition first and set Item Id. Unknown IDs receive a generic inventory icon/description.

### Create a combination recipe

Duplicate `data/recipes/field_dressing.tres`. Set **Input A**, **Input B**, **Output Id**, and **Output Quantity** using item IDs from the catalog. Add it to **Recipes** in `data/catalog.tres`. Input order does not matter. Each input follows its own **Remove After Use** checkbox, and the complete result must fit before any change is committed. A recipe can require two units of the same item by using the same ID for both inputs.

The included recipe is clean cloth + antiseptic → field dressing. One dressing restores 30 health, capped at 100. Use never wastes it at full health.

### Reusable tool gates

`scenes/objects/chained_gate.tscn` is an alias to the cuttable fence and uses **Required Tool = bolt_cutters**. Tool/key requirements can accept matching variants through their **Use As Item Id**. Change it to any carried item ID for another gate type. Once opened, the gate's collision and state remain open across scene changes and manual saves.

The supplied building has cloth, antiseptic, and bolt cutters. The alley's chained gate blocks access to a dressing. These are replaceable mechanical examples, not narrative objectives. Remove or rearrange them freely.

## Pickups, notes, and circuits

The starting inventory is an **8-column × 4-row grid (32 cells)**. Press **I or Tab** to open/close it. Tab is reserved for toggling while inventory is open; it still navigates the other menus. Current 9mm and buckshot ammunition stack to 12 per item instance; change Max Stack in their item definitions. The handgun occupies **2×1 cells**, and each handgun is a separate item with its own loaded rounds. Most existing supplies, keys and puzzle objects use one cell until you change their footprint. Full or fragmented grids leave pickups in the world.

### Move, rotate and combine

- **Left-drag** an item to a clear area and release to place it. Grab any occupied cell of a large item.
- Press **R while dragging** to rotate the preview by 90°. Red means it cannot fit; an invalid drop leaves the original item completely unchanged.
- Select an item and press **R**, or click **Rotate**, to rotate in place when there is room.
- **Escape** cancels an active drag first. Escape again closes the inventory; I/Tab also close it and cancel the drag.
- Drag an ammo stack onto another matching stack to merge. **20 + 2 becomes 22**, freeing a cell. **20 + 10 becomes 24 + 6**. Overflow is never discarded.
- The **Combine** button still supports recipes: select the first material, press Combine, then click the second. Moving focus never consumes items.
- For keyboard placement, focus the grid, use **arrow keys** to move the cell cursor, and **Enter/Space** to pick up or place an item. R rotates the held preview.

### Equip weapons

Select the handgun and click **Unequip** to put it away; select it and click **Equip** to use it again. Equipped weapons still occupy their grid cells. An **E** marker on the item identifies the equipped weapon. Unequipped weapons cannot fire or reload, and aiming feedback is hidden. Switching weapons cancels an unfinished reload; loaded rounds stay in their original weapon. Player melee is removed. The flashlight stays available while unarmed and consumes no cells.

### Configure capacity and item sizes

Open **`data/inventory_settings.tres`** in the Inspector. **Columns/Rows** set the starting grid, **Starting Weapon** sets its item ID (empty means start unarmed), and **Starting Ammo** sets the reserve. Existing save slots retain their saved capacity. The UI fits supported grids from **4×2 to 12×8**. No existing inventory is silently shrunk or repacked.

Open any item definition `.tres` and edit **Inventory Footprint → Grid Size**: X is columns, Y is rows. For example, use **(3, 2)** for a large puzzle object or **(4, 1)** for a long weapon. **Can Rotate** controls rotation. Keep dimensions positive and no larger than the supported grid. Change **Max Stack** independently; a whole stack uses that item's footprint. Automatic pickups try the natural orientation, then the rotated orientation, without moving existing items.

Size upgrades now shrink individual compatible items instead of growing the grid. See [Weapons and item upgrades](docs/guides/WEAPONS_AND_UPGRADES.md). The older `Game.expand_inventory` hook remains for compatibility, but no capacity-upgrade pickup is supplied.

### Add future weapons without changing player code

1. Duplicate **`data/items/pistol.tres`**, giving it a new file name and unique **Id**.
2. Set **Display Name**, **Description**, **Icon**, and **Grid Size**; set **Category = Weapon**, **Is Weapon = On**, **Max Stack = 1**.
3. Under **Weapon**, assign **Weapon Texture**, **Ammunition Id**, **Magazine Size**, **Bullet Damage**, **Shot Interval**, and **Reload Seconds**.
4. Add the resource to **Items** in `data/catalog.tres`.
5. Duplicate a pickup scene and assign the new **Item Definition**; update its child Sprite2D texture for the editor preview. Place it where you want the weapon to be discovered.
6. Collect it, arrange it, and select **Equip**. Multiple weapons, including duplicate weapons of the same type, have independent magazines and stable instance IDs. New weapon pickups start unloaded; the starting weapon begins loaded.

These definitions drive **hitscan firearms**, including shotgun pellet count, spread, range, shell-by-shell reload and per-weapon hand/muzzle offsets. Alternate fire modes and distinct weapon animations would require further additions. Five or six definitions do not require five or six player scripts. Define a new ammunition item and match its ID for a different ammunition type. Existing Player movement and dodge settings remain on the Player; firearm stats now come from the equipped definition.

Reuse `ammo.tscn`, `fuse.tscn`, or `key.tscn`. Assign **Item Definition**, set **Quantity** and optional **Action Label**, and update child Sprite2D Texture for the editor preview. Arbitrary item IDs work as keys or circuit inputs; names default to a readable capitalization. Built-ins have friendlier labels.

`clue.tscn` is a neutral reference-card example. Set **Description** to your own text. **Kind = Examine** shows it without marking a puzzle reference; **Kind = Clue** records a reference for its Power Channel. Keep text to about nine lines or enlarge the note panel.

`switchboard.tscn` is an optional reusable three-dial puzzle; it is not placed in the starting street. Set:

- **Puzzle Solution:** each of three values must be 1–3.
- **Puzzle Input Item:** a required item; its Remove After Use setting controls consumption. Leave empty for no requirement.
- **Puzzle Reward Item:** item awarded; leave empty for no reward.
- **Require Reference:** optionally require a Clue with the same Power Channel first.
- **Power Channel:** a unique circuit name, such as `workshop`.

Doors, entrances, and streetlamp `WarmLight` nodes can use that same Power Channel. Different channels are independent and persist in manual saves. Street lamps expose Emergency Energy and Powered Energy. For a permanently lit lamp, make those values equal. Keep clues and puzzle answers consistent yourself; no narrative is supplied.

## Bicycle save stations and four manual save slots

Saving is **manual**. Entering rooms, collecting objects, opening gates, pausing, dying, and starting a new game do not write or erase save slots. World progress remains in memory while you travel; progress after your last bicycle save is lost when you load or quit.

### Place a save bicycle without programming

1. Drag **`scenes/objects/save_bicycle.tscn`** into your location's **Interactables** node.
2. Move its root to the floor: for the supplied scenes, **Y = 620**. Keep the root scale at **(1, 1)**.
3. Select its root and set **Station Name** (used in save-slot details), **Interaction Radius**, **Prompt Offset**, and optional **Action Label**.
4. Right-click the instance → **Editable Children**. Move **SaveSpawn**, its `Marker2D`, to a safe standing position beside the bike. The supplied offset is **(-56, -32)**, appropriate for this player's capsule and floor. Keep it clear of walls and entrances. Enable **View Helpers** in the 2D editor if needed to see markers.
5. Test with F5. Approach the bicycle and press **E**. The original bell rings; the **Save your game** menu opens and pauses gameplay. Choose one of four slots. An occupied slot asks before being overwritten; Escape cancels the confirmation first, then closes the menu.

An example bicycle is placed at **(200, 620)** on the street. The front-facing artwork is deliberately mirror-symmetric and uses colors sampled from your current player. **Bell/Bicycle** is a normal editor-visible Sprite2D. The native PNG is **32×28** and displayed at **2×** in Godot. Edit `art/pixel/bicycle.png` directly; there is no enlarged duplicate. Replace **BellSound → Stream** to use another sound. Bell Animation Seconds controls the small visual bob before opening the menu. No inventory item, key, story text, or consumable is required.

### What each slot remembers

Each independent file records the location, bicycle's return position, the grid dimensions, every item instance (ID, quantity, coordinates, rotation and installed upgrades), equipped weapon, health, each weapon’s loaded magazine, flashlight state, circuit/reference flags, collected pickups, opened gates, defeated enemies, and elapsed play time. The slot menu shows location, station name, local save date/time, played hours/minutes, and health. Saving does not heal the player or refill ammunition. Partly injured living enemies, their patrol positions, and active animations reset when a scene reloads.

**Main menu → Load game** and **Pause → Load game** both open the four-slot picker. The death menu also loads a selected file. Loading returns to the recorded **SaveSpawn position**, not the last entrance. **New game** starts fresh in memory and preserves all four files. A player can later overwrite a slot only by saving at a bicycle and confirming.

The scene must use `scripts/location.gd`, as the supplied locations do. Keep its Player and HUD, and keep the save marker above usable collision. Your fixed cameras and light settings are preserved. The marker's coordinates are captured when saving: if you later move a bicycle, older saves still return to the previously recorded position.

State IDs default to `scene file path + node path`. Renaming a persistent object changes its identity. Give interactables a unique **Persistent Id** before release if you intend to rename them. Do not duplicate explicit IDs. Enemy identities currently use their scene/node paths. Back up saves before changing scene paths, item IDs, or geometry around saved return positions.

In Godot, choose **Project → Open User Data Folder** to find **`save_1.json` through `save_4.json`**, plus `settings.cfg`. Files are written to a temporary file first, then committed. Save previews include the stored item count, grid capacity and whether a weapon is equipped. Loading validates the entire snapshot before changing scenes and applies it as one state change; it never merges the loaded inventory or progress with the current run. Every slot reads its own file; opening another slot’s preview does not change the run. Unavailable/corrupt saves are marked in the picker and cannot be loaded; they can be replaced after confirmation. The old `checkpoint.json` remains unused. Previous **version-2 bicycle saves** are read without rewriting them: the eight pockets are placed in an 8×4 grid and the formerly implicit handgun becomes an equipped 2-cell item with its saved ammunition. Saving at a bicycle writes the new version-4 format, including installed item upgrades, only to the chosen slot.

## Art and interface

See [the art guide](docs/guides/ART_STYLE_GUIDE.md) for native sizes and palette rules. New player/enemy atlases, houses, bicycle and fences use single native PNGs at Sprite scale 2×. Older scenery/item source/export pairs remain in place. The current palette is `art/pixel/ignotum.gpl`; editable `.pixil` files remain in `art/pixlart/`. Place reusable scenery under `scenes/objects/` and keep its native pixel scale.

CanvasModulate sets ambient darkness. Lamps and the flashlight add real light. Fog sprites are authored transparent layers. The scene's ambient audio loops; replace its Stream with your own WAV. The pause and inventory panels are laid out in `scenes/ui/hud.tscn`; its `Grid` Control draws the saved item footprints; button styles are shared through `art/ui_theme.tres`. Menu Options changes volume/fullscreen and stores settings.

## Test before sharing

Play from New Game, enter the building, collect ammo, return, revisit, and confirm it stays collected. Enter the alley, test combat, return to the bicycle, save to a slot, go to the menu, choose Load game, and verify state. Try the other slots and cancel an overwrite. Save A, collect several items and finish a puzzle, save B, then repeatedly load A/B and check the differences. Try moving, rotating and unequipping the handgun before saving. Try an empty magazine, full pockets, a wrong puzzle answer, locked entrances, death, and retry. Physical sound and standalone exports still need testing on your computer.

`bash tools/check.sh` imports resources and runs gameplay, interface, asset, manual-save, grid-input, aiming, narrative, combat, and stealth integration suites. Each suite uses a separate test data directory so your normal saves are not overwritten. `bash tools/check.sh aiming narrative combat stealth` selects the newer feature suites, which work with your current item settings. Older tests still assert original example item values and layouts; intentional designer changes can require updating those test expectations. `tests/capture.tscn` is an optional graphical screenshot helper for Linux. Tests reference the supplied scene/node names, so update the tests if your intentional design changes rename them.

## Interior furniture and stairs

Start with [INTERIOR_KIT_GUIDE.md](docs/guides/INTERIOR_KIT_GUIDE.md). Drag scenes from `scenes/objects/interiors/` into a room and choose Color Variant in the Inspector. The kit includes 24 furniture/lamp objects in three colors, plus walkable full/half stairs in both directions. Your latest snapshot removes the separate showroom/catalog scenes; the guide and PNG preview remain available.

## Forest scenery

See the [FOREST_KIT_GUIDE.md](docs/guides/FOREST_KIT_GUIDE.md) for trees, logs, stumps, bushes, ferns, rocks and smaller ground props. Drag scenes from `scenes/objects/forest/`, choose one of three color variants, and enable Solid only where you want to block the player. Your latest snapshot removes the separate showroom/catalog scenes; compare the colors in the guide’s PNG preview.

## Weapons and per-item upgrades

See [WEAPONS_AND_UPGRADES.md](docs/guides/WEAPONS_AND_UPGRADES.md) for the buckshot shotgun, separate ammunition, compact saw and damage kit. All five pickup scenes are under `scenes/objects/equipment/`, including a handgun to place in your town. New games start unarmed; change Starting Weapon in `data/inventory_settings.tres` to configure another loadout. Test the equipment separately with `tests/fixtures/weapon_workbench.tscn` and F6.

## Remove items after use

Open an item `.tres` under `data/items/`, expand **Use Behavior**, and set **Remove After Use**. See [ITEM_USE_GUIDE.md](docs/guides/ITEM_USE_GUIDE.md) for healing, crafting, upgrades, puzzles, doors and fences. Use the ready-made `scenes/objects/equipment/bolt_cutters_single_use.tscn` for disposable cutters; the existing bolt cutter pickup remains reusable. Both work with the same fences.

## Square alleyway lighting

Place `scenes/objects/lighting/alley_light.tscn` for a square light, or assign `art/lights/square_beam.tres` to an existing PointLight2D. Texture Scale controls overall size; Transform Scale X/Y makes it rectangular. See the [alley light guide](docs/guides/ALLEY_LIGHT_GUIDE.md).

## Four-digit code locks

Place `scenes/objects/puzzles/code_lock.tscn` beside or under your furniture. Set **Correct Code** and a unique **Persistent Id** in the Inspector. Optionally assign **Reward Item**, closed/open artwork, a barrier collision shape or an opening animation. Your existing HUD opens the four-dial panel and the bicycle save slots remember completion and unsolved dial positions. See [CODE_LOCK_GUIDE.md](docs/guides/CODE_LOCK_GUIDE.md) for the setup steps. No lock, clue or puzzle content has been placed in your levels.

## Room light switches

Place `scenes/objects/lighting/light_switch.tscn`, assign lights or interior lamp roots in **Connected Lights**, and set **Starting On** and a **Persistent Id**. E toggles those lights. Optional **Reveal When Off** nodes let you show your own clue artwork when the circuit is off. Bicycle saves remember each circuit; matching IDs can link two switches. See [LIGHT_SWITCH_GUIDE.md](docs/guides/LIGHT_SWITCH_GUIDE.md) for setup and dark-room visibility settings.

## Searchable furniture and empty drawers

Place `scenes/objects/loot/loot_container.tscn` beside or under your furniture and give it a unique **Persistent Id**. Leave **Contents** size **0** to show **Empty** once and remove the Search interaction. To add loot, create a **LootEntry** for each item type inside Contents, then assign its **Item** and **Quantity**. All contents must fit before anything is taken. Empty and filled containers keep their searched state in bicycle saves. See [LOOT_CONTAINER_GUIDE.md](docs/guides/LOOT_CONTAINER_GUIDE.md) for Inspector steps and optional opening artwork/animations.

## Side-view note artwork

Choose one of five reusable scenes in `scenes/objects/notes/`: flat, folded, crumpled, creased or a small stack. Assign your Document on the root and place the root on a tabletop/shelf/floor. The default Note now uses the flat profile. Native editable PNGs are in `art/pixel/notes/`; all share a 20×12 canvas and 2× display scale. See [NOTE_VARIANTS_GUIDE.md](docs/guides/NOTE_VARIANTS_GUIDE.md) for changing existing note artwork while keeping saved read IDs.

## Blood overlays

Place scenes from `scenes/objects/blood/` over your floors or furniture. The native transparent PNGs are under `art/pixel/blood/`; opacity is editable using **Self Modulate → Alpha**. For a stain clipped to furniture, set the furniture's Artwork Sprite2D to **Clip Children → Clip + Draw**, make the stain its child, and set the stain's local Scale to **(1,1)** when that Artwork already uses 2× scale. See [BLOOD_OVERLAY_GUIDE.md](docs/guides/BLOOD_OVERLAY_GUIDE.md) for placement, depth and masking.
