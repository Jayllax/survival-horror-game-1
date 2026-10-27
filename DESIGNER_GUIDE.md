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
2. Select its root. Set **Prompt Text**, such as “Enter” or “Go down alley”.
3. Set **Destination Scene** with the file picker, such as `scenes/levels/interior.tscn`.
4. Set **Destination Spawn** to a Marker2D name in that location's `Spawns` branch, such as `from_street`.
5. Keep **Required Key** empty and **Requires Power** off for an unlocked entrance.
6. In the destination, place a return entrance that targets the original scene and a different return marker.
7. Test both directions. Place return markers roughly 100–140 pixels beside the entrance rather than directly on top of another interactable.

The player presses **E** within Interaction Radius. The scene fades to black, loads the destination, places the player at the named marker, saves a checkpoint, and fades back in. Input is locked throughout. It never walks the character along an invisible depth axis. There is no end-of-level trigger.

For an alley, enable **Editable Children** on the entrance instance and hide its `Facade` sprite. Put a dark, visible gap in the buildings behind it. The supplied `AlleyEntrance` demonstrates this. Its Area2D rectangle helps selection in the editor; interaction is based on proximity. Avoid placing accessible triggers on opposite sides of a thin wall because the proximity system does not check line of sight.

For a key lock, set Required Key to a pickup's **Item Id**, such as `workshop_key`. The key is reusable. An entrance is a background transition; `door.tscn` is a physical sliding gate that opens on the same side-scrolling plane. Physical gates support **Consume Key** if you deliberately want a one-use key.

## Make another location

1. Open a similar location and choose **Scene → Save As** under `scenes/levels/`.
2. Keep the root's `location.gd` script. Set its **Display Name** and **Camera Bounds** in the Inspector.
3. Keep exactly one Player and one HUD. Keep ground and boundaries, adjusting their positions and shapes for the new width.
4. Keep a `Spawns` Node2D with a Marker2D called `default`. Add named return markers as needed.
5. Rearrange art, props, pickups, enemies, and entrances. Link it from another entrance with the file picker.
6. Test F6, then test entering it from the actual source location. F6 begins with fresh state; Continue restores your last checkpoint instead.

New Game loads `town.tscn`. To replace the starting location without programming, keep a backup and save your final start layout over that file. Do not add a second Player or HUD. There is no need for a separate Git worktree; edit this checkout.

## Tune movement and combat

Select Player for Move Speed, Acceleration, Jump Velocity, Gravity, Coyote Seconds, Jump Buffer Seconds, Magazine Size, Bullet Damage, Shot Interval, Reload Seconds, Melee Damage, Melee Reach, and Dodge Speed.

Jump Velocity must be negative; other tuning values should be positive. Dodge invulnerability stays exactly **0.5 seconds**, with a 1.05-second reuse interval. The gun starts with six loaded rounds, clamped to Magazine Size, plus twelve reserve rounds. Character walk frames advance automatically. Movement accelerates smoothly; a short coyote window and jump buffer make platforming forgiving.

The flashlight is `Player/Aim/Gun/Flashlight`. It inherits aim and gun recoil. **Offset = (256, 0)** places its beam in front of the barrel. Energy/Color/Texture Scale change its illumination. Do not use `texture_offset`; that is not a Godot PointLight2D property. F toggles it, and its state persists between locations. It never occupies an inventory slot.

Enemies expose Max Health, Speed, Detection Radius, Damage, Attack Interval, Patrol Width. They walk and chase on flat ground, do not navigate jumps, and disappear persistently after defeat. The default enemy takes three handgun hits. Place them on reachable flat surfaces. Their live partial health is not persisted across scene changes.

## Pickups, notes, and circuits

There are eight pockets. Ammunition stacks to 24. Keys and puzzle objects each occupy one pocket. Full inventories leave pickups in place. Reloading consumes reserves; there is no inventory drag/drop or discard UI.

Reuse `ammo.tscn`, `fuse.tscn`, or `key.tscn`. Change **Item Id**, **Quantity**, **Prompt Text**, and child Sprite2D Texture. Arbitrary item IDs work as keys or circuit inputs; names default to a readable capitalization. Built-ins have friendlier labels.

`clue.tscn` is a neutral reference-card example. Set **Description** to your own text. **Kind = Examine** shows it without marking a puzzle reference; **Kind = Clue** records a reference for its Power Channel. Keep text to about nine lines or enlarge the note panel.

`switchboard.tscn` is an optional reusable three-dial puzzle; it is not placed in the starting street. Set:

- **Puzzle Solution:** each of three values must be 1–3.
- **Puzzle Input Item:** an item to consume; leave empty for no requirement.
- **Puzzle Reward Item:** item awarded; leave empty for no reward.
- **Require Reference:** optionally require a Clue with the same Power Channel first.
- **Power Channel:** a unique circuit name, such as `workshop`.

Doors, entrances, and streetlamp `WarmLight` nodes can use that same Power Channel. Different channels are independent and persist in checkpoints. Street lamps expose Emergency Energy and Powered Energy. For a permanently lit lamp, make those values equal. Keep clues and puzzle answers consistent yourself; no narrative is supplied.

## Persistence and checkpoints

Entering a location automatically saves a single checkpoint. The pause menu also has **Save checkpoint**. It stores the current location and last entrance marker, health, magazine, reserves/inventory, flashlight state, circuit/reference flags, pickups, gate unlocks, and defeated enemies. Loading returns to the entrance marker, not the precise position where you pressed Save. The menu's Continue and the death screen's Load checkpoint restore it. A new game clears run state and replaces that checkpoint after confirmation.

State IDs default to `scene file path + node path`. Renaming an existing scene or persistent object changes its identity. Give interactables a unique **Persistent Id** before releasing a build if you intend to move or rename them. Do not duplicate an existing explicit ID: each physical object needs its own ID. Enemy identities currently use their scene/node paths.

Files live in Godot's **user data folder**, not the project. In the editor choose **Project → Open User Data Folder** to find `checkpoint.json` and `settings.cfg`. Checkpoints are a versioned single-slot foundation, not a multi-slot save manager or a migration system for changing released levels. Corrupt basic formats are rejected; arbitrary modded save files are not supported. Back up saves before changing scene paths or item IDs.

## Art and interface

See **ART_STYLE_GUIDE.md** and **art/pixel/STYLE_SHEET.png** for the palette and editable source sizes. Every pixel asset has a native source and a ready-to-use 2× texture. Place `building_house.tscn`, `building_shop.tscn`, or `building_station.tscn`, and decorate with reusable props under `scenes/objects/`.

CanvasModulate sets ambient darkness. Lamps and the flashlight add real light. Fog sprites are authored transparent layers. The scene's ambient audio loops; replace its Stream with your own WAV. The pause panels and eight inventory slots are laid out in `scenes/ui/hud.tscn`; button styles are shared through `art/ui_theme.tres`. Menu Options changes volume/fullscreen and stores settings.

## Test before sharing

Play from New Game, enter the building, collect ammo, return, revisit, and confirm it stays collected. Enter the alley, test combat, return, save, go to the menu, Continue, and verify state. Try an empty magazine, full pockets, a wrong puzzle answer, locked entrances, death, and retry. Physical sound and standalone exports still need testing on your computer.

`./tools/check.sh` imports resources and runs automated integration checks. It uses a separate test data directory so your normal checkpoint is not overwritten. `tests/capture.tscn` is an optional graphical screenshot helper for Linux. Tests reference the supplied scene/node names, so update the tests if your intentional design changes rename them.
