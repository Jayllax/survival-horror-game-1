# Ignotum — a guide for level designers

## 1. Open and play your project

Use the **standard edition of Godot 4.4 or newer**. This project uses GDScript, so you do not need the .NET edition. It was validated with Godot 4.6.3.

In Godot's Project Manager, choose **Import**, select `project.godot`, and choose **Import & Edit**. Let the artwork import. Press **F5** and choose **Enter the square**. All controls are printed on the menu and at the bottom of the game.

For level editing, double-click `scenes/levels/town.tscn` in the FileSystem dock and select the **2D** workspace. Press **F6** to test this scene directly. Press **F8** to stop testing before editing again. The game uses a fresh run when launched; restarting the square also clears your inventory and objective.

## 2. Understand the editor

- **Scene tree, left:** the objects in your current level. Click a name to select it.
- **2D viewport, middle:** the visual layout. Drag the selected object to move it. W selects the move tool; F frames the selection.
- **Inspector, right:** settings for the selected object. Exported gameplay settings appear near the top, under its script.
- **FileSystem dock:** reusable scene files and artwork. Drag a `.tscn` from here into the viewport to place another instance.

The finished level is already laid out. Its buildings, walls, ground, platforms, player, enemy, items, doors, lights, benches, and crates all exist as nodes in `town.tscn` or its instanced scenes. The editor view is the actual playable geometry. Shooting tracers and damage flashes are temporary effects; they do not build the environment.

The level's useful groups are:

| Scene tree branch | What to edit |
| --- | --- |
| `Buildings` | Individual house and station sprites, with their labels |
| `Geometry` | Street collision, boundaries, and jumpable platforms |
| `Props` | Lamps, benches, and solid crates |
| `Interactables` | Notice, fuse, ammunition, switchboard, gate |
| `Actors` | Player spawn and enemy |
| `Fog` | Transparent fog sprites, drawn in front of the world |
| `HUD` | An instance of the interface scene |

**Decorative buildings and benches have no collision.** Crates, platforms, the street, boundaries, and the closed gate do. Use **Debug → Visible Collision Shapes** while testing to see solid surfaces.

## 3. Rearrange the square

1. Select `Actors/Player` and drag it to change the starting position. Keep its feet above a solid surface. Its origin is approximately at the body's center, about 32 pixels above its feet.
2. Select any object under `Interactables` and move it. Items have a small gold diamond above them. This is their visible interaction marker, not collision.
3. Select a lamp under `Props` and move it. The post and warm light move together.
4. Move platforms or crates to make a jump route. With default tuning the jump rises about **72 pixels**. Steps of 40–60 pixels and horizontal gaps below roughly 120 pixels are comfortable. Test every route.
5. Save with **Ctrl+S**, then test with F6.

Select the **root of an instance**, such as `StationStep`, instead of just its child sprite. Moving only the art leaves collision behind. To tune a child in a scene instance, right-click the instance and choose **Editable Children**. Editing the original reusable scene changes all its instances; editing an instance's exported settings overrides only that instance.

## 4. Place reusable objects

Drag these scenes from FileSystem into your level. Then select the new root and change its Inspector settings:

| Scene | Designer settings |
| --- | --- |
| `scenes/actors/player.tscn` | Move Speed, Jump Velocity, Gravity, Magazine Size, Bullet Damage, Shot Interval, Reload Seconds, Melee Damage, Melee Reach, Dodge Speed |
| `scenes/actors/enemy.tscn` | Max Health, Speed, Detection Radius, Damage, Attack Interval, Patrol Width |
| `scenes/objects/platform.tscn` | Platform Size: width and thickness; visual, collision, and light shadow resize together in the editor |
| `scenes/objects/ammo.tscn` | Item Id, Quantity, Prompt Text, Interaction Radius |
| `scenes/objects/key.tscn` | Pickup settings; default Item Id is `gate_key` |
| `scenes/objects/fuse.tscn` | Same pickup settings; default Item Id is `fuse` |
| `scenes/objects/clue.tscn` | Description (multiline text), Prompt Text, Interaction Radius |
| `scenes/objects/switchboard.tscn` | Puzzle Solution (three numbers, each 1–3), Prompt Text, Interaction Radius |
| `scenes/objects/door.tscn` | Required Key, Requires Power, Escape Door, Door Animation Seconds, Prompt Text, Interaction Radius |
| `scenes/objects/streetlamp.tscn` | Move the root; edit `WarmLight` for color, Texture Scale, Emergency Energy, and Powered Energy |

Use **Ctrl+D** to duplicate a selected instance. Do not duplicate the player or HUD: keep exactly one of each per playable scene. Enemies can be duplicated.

For an enemy that stays close to its spawn, reduce Patrol Width. Increasing Detection Radius makes it notice you sooner. The enemy only navigates along the ground; it does not jump gaps or climb stairs. Keep patrol routes flat and accessible. The default enemy has 78 health, so three handgun hits kill it.

**Platform Size** is safe to change per instance: the scene's collision and shadow resources are local to that instance. Avoid scaling a physics body to resize it. For the street, enable Editable Children, select its CollisionShape2D, and change the rectangle's Size; then adjust the Asphalt and Curb polygons with the polygon edit tool so their visible edges match. Make a shape resource unique before editing it if you duplicated a plain physics node that shares its resource.

Keep tuning numbers positive, except Jump Velocity, which must be **negative** to jump upward. The gun begins with six loaded rounds, clamped to your Magazine Size. The starting reserve is 12. The dodge's invulnerability is deliberately fixed at **0.5 seconds**; Dodge Speed changes its distance, not that duration.

## 5. Items, pockets, and interactions

There are exactly eight pockets. Each pocket holds one item stack. Ammunition stacks to 24 rounds; keys and puzzle objects occupy one pocket each. There is no drag-and-drop inventory management or discard action. Reloading consumes reserve ammunition and can free pockets.

The flashlight is equipment, not an inventory item. F toggles a real Godot PointLight2D attached to the aiming arm. Point the mouse to aim both the gun and flashlight. LightOccluder2D nodes on crates and platforms cast shadows.

To make another pickup without coding:

1. Duplicate an ammunition or fuse scene instance.
2. Set **Kind** to **Pickup**.
3. Enter its **Item Id** and **Quantity**.
4. Change **Prompt Text**.
5. Enable Editable Children and replace `Sprite2D`'s Texture by dragging a different image into the Texture field.

Supported gameplay identifiers are `ammo`, `fuse`, and `gate_key`. Other names are accepted as collectible puzzle objects or custom keys, but they do not gain a use automatically. A door can require any matching Item Id. For example, put `cellar_key` on a pickup and on a door's Required Key. Use Quantity 1 for keys.

A full inventory refuses a pickup and leaves it in the world. It never silently deletes items. The nearest available interactable within its **Interaction Radius** gets the E prompt. Avoid placing different objects on top of each other. Radius measures distance from object origin to player center; about 84 pixels works for small items and 130 for tall doors. Interactions use proximity, not line of sight; keep objects separated from walls where appropriate.

To create a readable prop, duplicate a notice. **Kind = Clue** marks the station clue as read; **Kind = Examine** displays the Description without advancing that clue flag. Use Examine for optional notes and environmental descriptions. Keep descriptions short enough to fit the note panel (about nine lines at its default font size), or enlarge that panel in `scenes/ui/hud.tscn`.

## 6. Design the clue, puzzle, and exit

The included sequence is:

1. Read the notice by the station. It describes the bells: **3, 1, 2**, west to east.
2. Pick up the **ceramic fuse** beside the stacked crates.
3. At the switchboard, click each of the three dials to set **3 / 1 / 2**. Choose **Insert fuse & restore power**.
4. This consumes the fuse, restores the streetlamps, and gives you a **brass gate key**.
5. At the eastern gate, press E. The key is consumed, the gate slides open, collision clears, and the ending appears.

The switchboard checks that you read the clue, have a fuse, and selected the correct code. A wrong answer costs nothing. Using the fuse frees its pocket for the key, so solving the puzzle works even with all eight pockets filled.

To change the answer, select your switchboard and change **Puzzle Solution** in the Inspector. Each number must be 1, 2, or 3. Then edit the notice's Description to provide the new answer. Change both together.

Doors have these useful configurations:

- **Locked exit:** Required Key = `gate_key`, Requires Power = On, Escape Door = On.
- **Ordinary locked passage:** set Required Key to your pickup's Item Id, Requires Power = Off, Escape Door = Off. The door opens without ending the level.
- **Unlocked passage:** leave Required Key empty, Requires Power = Off, Escape Door = Off.

A door opens permanently for that run. A key is consumed on use, so supply one pickup for every locked door that needs it. The door's origin is its center, about 85 pixels above the ground.

This template has one shared station clue flag, one switchboard power flag, and one ending. Multiple switchboards would share that same progression. You can rearrange or replace this puzzle through the Inspector, but separate independent puzzle chains would require extending the scripts in a future programming task.

## 7. Make your own level without starting from nothing

The easiest path is to duplicate the authored town:

1. Open `town.tscn`, choose **Scene → Save As**, and save as `scenes/levels/my_town.tscn`.
2. Keep one Player, one HUD, street collision, and the boundaries.
3. Delete or rearrange buildings and props. Drag more reusable scenes into the level.
4. Keep a reachable notice, fuse, switchboard, and escape door if using the built-in objective.
5. Test the scene with F6, including a full playthrough from spawn.
6. For a longer level, select the Player, enable Editable Children, select Camera2D, and adjust **Limit → Right / Bottom**. Move the end boundary, extend the street collision and visuals, sky polygon, and fog. The supplied level is 3100 × 720 pixels.

To keep your new level as the menu's destination **without editing code**, leave your saved custom copy as a backup and save the final playable version over `scenes/levels/town.tscn`. The menu's Start and Restart buttons intentionally load that path. Setting another scene as Project → Project Settings → Application → Run → Main Scene starts it directly; it does not change the menu's destination.

## 8. Change the atmosphere

- **AmbientTint:** change CanvasModulate's color. Darker colors make the unlit world darker. Avoid pure black until you have tested flashlight-off navigation.
- **Street lamps:** WarmLight's texture is an original radial gradient. Texture Scale changes its reach. Emergency Energy is the dim starting state; Powered Energy is the brighter state after the puzzle.
- **Flashlight:** in `player.tscn`, select Aim/Flashlight. Energy, Color, Texture Scale, and Shadow Enabled control the beam. Texture Offset places the cone ahead of its light source; leave its existing offset unless intentionally reshaping the beam.
- **Fog:** move, duplicate, or scale the fog sprites. Modulate controls their tint and opacity. They are static transparent layers, with no hidden gameplay behavior.
- **Artwork:** replace Sprite2D Texture resources with your own PNG/SVG files. The included SVGs are editable original placeholders. Godot does not render SVG text reliably, so building names use actual Label nodes.
- **Sound:** replace AmbientSound's Stream with a WAV. It loops when finished. Adjust Volume dB. ShotSound and HurtSound are inside the player scene. The included audio was synthesized for this project.
- **Interface:** edit `scenes/ui/hud.tscn` for text, colors, spacing, and panels. Shared button and label styling lives in `art/ui_theme.tres`.

## 9. Check a change before sharing

Play from the menu and make sure you can finish the level without teleporting or skipping a required item. Try shooting until empty, reloading, melee, dodging an enemy attack, toggling the light, pausing, opening pockets, reading the clue again, a wrong puzzle answer, and restarting after death.

For automated checks, open a terminal in the project folder and run:

```sh
./tools/check.sh
```

On Windows, run the equivalent commands from README with the path to your Godot executable. The tests use the original town's node names and reference puzzle answer; update tests if you intentionally rename those nodes or change the answer. A test failure after such an intentional design change does not necessarily mean the game is broken, but always test the actual new route.

The smoke suite checks the complete gameplay chain with real scene resources and physics. It also verifies the exact 0.5-second dodge boundary and stack limits. `tests/capture.tscn` is an optional screenshot helper for a graphical session on Linux; screenshots go to `/tmp`, not into the project.

If the game does not start, inspect the red errors in Godot's **Debugger** panel. A missing resource usually means a file was moved outside Godot: use Godot's FileSystem dock to move or rename resources so scene references update.

## 10. Project map and scope

```text
project.godot          Project settings, controls, Game autoload, menu entry
art/                  Original SVG placeholders and UI theme
audio/                Original WAV effects and ambience
scenes/actors/        Reusable player and enemy
scenes/objects/       Pickups, clues, puzzle, doors, platforms, lamps
scenes/levels/        Visually authored town
scenes/ui/            Main menu and HUD panels
scripts/              Small reusable gameplay scripts
tests/                Integration and rendering helper scenes
tools/check.sh        Reproducible validation command
```

No plugins, network services, secret keys, or code-generated level data are required. The template has no persistent save/load, gamepad controls, or independent multi-level quest system. Those are future extensions, not requirements for editing and playing this level.
