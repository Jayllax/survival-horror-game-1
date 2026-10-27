# Ignotum

A playable Godot 4 2D survival-horror foundation set in Nørreby, an empty Danish town shaped by distorted memories. Muted original SVG artwork, fog, warm 2D lights, and synthesized ambient sound are included. All level objects are authored nodes in the editor; nothing constructs the level at runtime.

## Play

1. Install **Godot 4.4 or newer, standard edition** (tested with **4.6.3**). No .NET, plugins, downloads, accounts, or external services are required.
2. Import `project.godot` in Godot's Project Manager.
3. Press **F6** to play the currently open scene, or **F5** to start at the main menu. The intended entry point is `scenes/ui/main_menu.tscn`.

| Action | Control |
| --- | --- |
| Move | A / D or left / right arrows |
| Jump | Space |
| Aim / shoot | Mouse / left mouse button |
| Reload | R |
| Melee | Q |
| Dodge | Shift; exactly 0.5 seconds invulnerable, 1.05 seconds between dodges |
| Interact | E |
| Flashlight | F; equipped separately from inventory |
| Eight pockets | I |
| Pause / close panel | Escape |

**Your goal:** Read the station notice, find the ceramic fuse beside the crates, restore power at the switchboard, then unlock the eastern gate. The notice explains the three-dial solution. There is one enemy; ammunition and melee can both kill it. A short ending completes the loop. Restart from pause or the ending to reset the run.

Start with [DESIGNER_GUIDE.md](DESIGNER_GUIDE.md) to rearrange objects, tune mechanics, and build another level without writing scripts.

## Checks

On Linux/macOS with Godot on `PATH`:

```sh
./tools/check.sh
```

Or run these commands from this folder with your Godot executable:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . res://tests/smoke.tscn
```

The integration scene currently passes 53 checks on Godot 4.6.3. It tests the real level, input-driven movement and interactions, traversal over authored obstacles, combat, reload, exact dodge boundary, inventory limits, puzzle prerequisites, door animation, collision release, pause, death, restart, and ending. Menu, town, note, and puzzle screens were also rendered and visually inspected using the Compatibility renderer with software OpenGL. Audio output on physical hardware and exported standalone builds have not been tested. Tests print a count and return a nonzero exit code on failed assertions. If a Godot script error stops the test itself, treat it as a failed run; a successful run must end with `IGNOTUM: … checks, 0 failures`.

To inspect rendering, run `godot --path . res://tests/capture.tscn` **with a graphical display**. It saves menu, town, note, and puzzle screenshots to `/tmp/ignotum-*.png` on Linux and quits. Do not use `--headless` for screenshots. This is a helper, not the game entry point.

This is a compact, single-level template: progression is in memory, there is no save/load system, and doors share the one switchboard's power state. It is intended as an editable foundation, not a finished commercial campaign. Artwork and audio are original placeholders created for this project; there are no external asset packs.
