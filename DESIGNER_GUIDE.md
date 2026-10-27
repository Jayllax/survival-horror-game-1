# Ignotum / designer guide

## Your starting point

Import `project.godot` with Godot 4.4+ Standard, open `scenes/levels/town.tscn`, choose **2D**, and press **F6** to test. **F5** starts the main menu. Stop with F8 before editing. The game has no story progression requirement or ending. You own the writing and campaign structure.

The supplied first street links to a small ground-floor interior and service alley to demonstrate entrances. The alley includes one enemy for testing combat; delete its instance if you want a peaceful blockout. All objects are visible in the editor, including every destination and spawn marker.

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
3. Set **Destination Scene** with the file picker, such as `scenes/levels/interior.tscn`.
4. Set **Destination Spawn** to a Marker2D name in that location's `Spawns` branch, such as `from_street`.
5. Keep **Required Key** empty and **Requires Power** off for an unlocked entrance.
6. In the destination, place a return entrance that targets the original scene and a different return marker.
7. Test both directions. Place return markers roughly 100–140 pixels beside the entrance rather than directly on top of another interactable.

The player presses **E** within Interaction Radius. The scene fades to black, loads the destination, places the player at the named marker, and fades back in. Input is locked throughout. It never walks the character along an invisible depth axis. There is no end-of-level trigger.

For an alley, enable **Editable Children** on the entrance instance and hide its `Facade` sprite. Put a dark, visible gap in the buildings behind it. The supplied `AlleyEntrance` demonstrates this. Its Area2D rectangle helps selection in the editor; interaction is based on proximity. Avoid placing accessible triggers on opposite sides of a thin wall because the proximity system does not check line of sight.

For a key lock, set Required Key to a pickup's **Item Id**, such as `workshop_key`. The key is reusable. An entrance is a background transition; `door.tscn` is a physical sliding gate that opens on the same side-scrolling plane. Physical gates support **Consume Key** if you deliberately want a one-use key.

## Make another location

1. Open a similar location and choose **Scene → Save As** under `scenes/levels/`.
2. Keep the root's `location.gd` script. Set its **Display Name** and **Camera Bounds** in the Inspector.
3. Keep exactly one Player and one HUD. Keep ground and boundaries, adjusting their positions and shapes for the new width.
4. Keep a `Spawns` Node2D with a Marker2D called `default`. Add named return markers as needed.
5. Rearrange art, props, pickups, enemies, and entrances. Link it from another entrance with the file picker.
6. Test F6, then test entering it from the actual source location. F6 begins with fresh state; Load game restores a manual save instead.

New Game loads `town.tscn`. To replace the starting location without programming, keep a backup and save your final start layout over that file. Do not add a second Player or HUD. There is no need for a separate Git worktree; edit this checkout.

## Tune movement and combat

Select Player for Move Speed, Acceleration, Jump Velocity, Gravity, Coyote Seconds, Jump Buffer Seconds, Magazine Size, Bullet Damage, Shot Interval, Reload Seconds, Melee Damage, Melee Reach, and Dodge Speed.

Jump Velocity must be negative; other tuning values should be positive. Dodge invulnerability stays exactly **0.5 seconds**, with a 1.05-second reuse interval. The gun starts with six loaded rounds, clamped to Magazine Size, plus twelve reserve rounds. Character walk frames advance automatically. Movement accelerates smoothly; a short coyote window and jump buffer make platforming forgiving.

The flashlight is `Player/Aim/Gun/Flashlight`. It inherits aim and gun recoil. **Offset = (256, 0)** places its beam in front of the barrel. Energy/Color/Texture Scale change its illumination. Do not use `texture_offset`; that is not a Godot PointLight2D property. F toggles it, and its state persists between locations. It never occupies an inventory slot.

Enemies expose Max Health, Speed, Detection Radius, Damage, Attack Interval, Patrol Width. They walk and chase on flat ground, do not navigate jumps, and disappear persistently after defeat. The default enemy takes three handgun hits. Place them on reachable flat surfaces. Their live partial health is not persisted across scene changes.

## Quiet interface and inspectable items

The world view has no permanent HUD bars, location/title labels, controls strip, pickup names, or floating item markers. A nearby object's generic action appears above it: Take, Examine, Use, Open, or Enter. Override **Action Label** for a different short verb, without revealing item identity. **Prompt Offset** positions the prompt relative to the object in world pixels; Interaction Radius controls proximity. Saving is manual and only available at placed bicycles.

Health appears briefly after damage, staying visible only at critical health. Select the HUD root to tune Health Feedback Seconds, Pickup Hint Seconds, Message Seconds, or turn Show Pickup Hint off. Select Player to tune Combat Feedback Seconds and Aiming Move Multiplier. Holding right mouse enables careful aiming movement and a small crosshair/ammo readout. Recent shots and reloading also show ammunition temporarily. Inspect exact condition and weapon status in the inventory. The flashlight remains equipped outside the eight pockets. Controls are under Pause → Controls.

Open I and click an item icon, or move focus with arrow keys. Its name, large artwork, category, quantity, and description appear beside the grid. **Use** applies compatible supplies, **Combine** asks for a second item, and selection itself examines the item. Use is disabled at full health for medical items. A failed combination or an output that cannot fit consumes nothing. There is no discard or drag/drop UI.

### Create an item without programming

1. Duplicate a definition in `data/items/` from Godot's FileSystem dock. Open the `.tres` in the Inspector.
2. Give it a unique stable **Id**, **Display Name**, **Category**, **Description**, **Icon**, and **Max Stack**. **Heal Amount** greater than zero makes it usable medicine.
3. Open `data/catalog.tres`. Add the definition to its **Items** array. This makes names/icons/descriptions available even before revisiting a pickup's scene after loading.
4. Duplicate a pickup scene and assign your definition to **Item Definition**. Set **Quantity**, put the matching image on its Sprite2D so it is visible in the editor, and place it. At runtime, the definition's Icon is applied to the pickup too.
5. Play, collect, and inspect it in the inventory. The world will not label it with its name.

When Item Definition is assigned it supplies Item Id; change the definition's Id rather than the legacy Item Id field. For quick generic keys with no definition, clear Item Definition first and set Item Id. Unknown IDs receive a generic inventory icon/description.

### Create a combination recipe

Duplicate `data/recipes/field_dressing.tres`. Set **Input A**, **Input B**, **Output Id**, and **Output Quantity** using item IDs from the catalog. Add it to **Recipes** in `data/catalog.tres`. Input order does not matter. Both inputs are consumed only when the complete result fits; the inventory restores the original items if the result cannot fit. A recipe can require two units of the same item by using the same ID for both inputs.

The included recipe is clean cloth + antiseptic → field dressing. One dressing restores 30 health, capped at 100. Use never wastes it at full health.

### Reusable tool gates

`scenes/objects/chained_gate.tscn` uses **Required Key = bolt_cutters** and **Consume Key = Off**. Required Key can represent a tool as well as a traditional key. Change it to any carried item ID for another gate type. Once opened, the gate's collision and state remain open across scene changes and manual saves.

The supplied building has cloth, antiseptic, and bolt cutters. The alley's chained gate blocks access to a dressing. These are replaceable mechanical examples, not narrative objectives. Remove or rearrange them freely.

## Pickups, notes, and circuits

There are eight pockets. Open/close the inventory with **I or Tab**; Tab does not move focus while the inventory is open. Arrow keys and the mouse still select items. Ammunition stacks to 24. To merge stacks, select the stack you want to fill, press **Combine**, then activate a different matching stack. For example, 20 + 2 becomes 22 and frees a pocket; 20 + 10 becomes 24 + 6. Moving keyboard focus alone never combines items.  Keys and puzzle objects each occupy one pocket. Full inventories leave pickups in place. Reloading consumes reserves; there is no inventory drag/drop or discard UI.

Reuse `ammo.tscn`, `fuse.tscn`, or `key.tscn`. Assign **Item Definition**, set **Quantity** and optional **Action Label**, and update child Sprite2D Texture for the editor preview. Arbitrary item IDs work as keys or circuit inputs; names default to a readable capitalization. Built-ins have friendlier labels.

`clue.tscn` is a neutral reference-card example. Set **Description** to your own text. **Kind = Examine** shows it without marking a puzzle reference; **Kind = Clue** records a reference for its Power Channel. Keep text to about nine lines or enlarge the note panel.

`switchboard.tscn` is an optional reusable three-dial puzzle; it is not placed in the starting street. Set:

- **Puzzle Solution:** each of three values must be 1–3.
- **Puzzle Input Item:** an item to consume; leave empty for no requirement.
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

Each independent file records the location, bicycle's return position, all eight inventory stacks, health, loaded magazine, flashlight state, circuit/reference flags, collected pickups, opened gates, defeated enemies, and elapsed play time. The slot menu shows location, station name, local save date/time, played hours/minutes, and health. Saving does not heal the player or refill ammunition. Partly injured living enemies, their patrol positions, and active animations reset when a scene reloads.

**Main menu → Load game** and **Pause → Load game** both open the four-slot picker. The death menu also loads a selected file. Loading returns to the recorded **SaveSpawn position**, not the last entrance. **New game** starts fresh in memory and preserves all four files. A player can later overwrite a slot only by saving at a bicycle and confirming.

The scene must use `scripts/location.gd`, as the supplied locations do. Keep its Player and HUD, and keep the save marker above usable collision. Your fixed cameras and light settings are preserved. The marker's coordinates are captured when saving: if you later move a bicycle, older saves still return to the previously recorded position.

State IDs default to `scene file path + node path`. Renaming a persistent object changes its identity. Give interactables a unique **Persistent Id** before release if you intend to rename them. Do not duplicate explicit IDs. Enemy identities currently use their scene/node paths. Back up saves before changing scene paths, item IDs, or geometry around saved return positions.

In Godot, choose **Project → Open User Data Folder** to find **`save_1.json` through `save_4.json`**, plus `settings.cfg`. Files are written to a temporary file first, then committed. Unavailable/corrupt saves are marked in the picker and cannot be loaded; they can be replaced after confirmation. The old `checkpoint.json` is left untouched and is not used by this system. It is not automatically converted into a bicycle save.

## Art and interface

See **ART_STYLE_GUIDE.md** and **art/pixel/STYLE_SHEET.png** for the palette and editable source sizes. Older pixel assets have a native source and a ready-to-use 2× texture. The bicycle uses one native PNG and scales its Sprite2D instead. The new houses are 96×128 native pixels and the shop is 128×128; their placed baselines have already been adjusted. Do not stretch them to the old building bounds. Player and ammo files are preserved. `STYLE_SHEET.png` now shows actual production PNGs, not the earlier illustration. Place `building_house.tscn`, `building_shop.tscn`, or `building_station.tscn`, and decorate with reusable props under `scenes/objects/`.

CanvasModulate sets ambient darkness. Lamps and the flashlight add real light. Fog sprites are authored transparent layers. The scene's ambient audio loops; replace its Stream with your own WAV. The pause panels and eight inventory slots are laid out in `scenes/ui/hud.tscn`; button styles are shared through `art/ui_theme.tres`. Menu Options changes volume/fullscreen and stores settings.

## Test before sharing

Play from New Game, enter the building, collect ammo, return, revisit, and confirm it stays collected. Enter the alley, test combat, return to the bicycle, save to a slot, go to the menu, choose Load game, and verify state. Try the other slots and cancel an overwrite. Try an empty magazine, full pockets, a wrong puzzle answer, locked entrances, death, and retry. Physical sound and standalone exports still need testing on your computer.

`bash tools/check.sh` imports resources and runs gameplay, interface, asset, and manual-save integration suites. Each suite uses a separate test data directory so your normal saves are not overwritten. `tests/capture.tscn` is an optional graphical screenshot helper for Linux. Tests reference the supplied scene/node names, so update the tests if your intentional design changes rename them.
