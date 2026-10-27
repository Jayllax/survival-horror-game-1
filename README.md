# Ignotum / development foundation 02

A desktop Godot 4 side-view survival-horror foundation with original pixel art. No authored story, forced quest, campaign ending, or victory screen. Start on a street, enter a building or alley with E, and return through matching entrances. These small connected spaces demonstrate the reusable location system; they are not a campaign.

## Open and play

Use **Godot 4.4+ Standard edition** (validated on 4.4.1 and 4.6.3). Import `project.godot` and press **F5**. No plugins or .NET installation required.

| Control | Action |
| --- | --- |
| A/D or arrows | Move |
| Space | Jump (buffered, with coyote time) |
| Mouse / left click | Aim / fire |
| R / Q / Shift | Reload / melee / dodge |
| E | Collect, examine, operate, or enter |
| F | Gun-mounted flashlight |
| I / Esc | Eight-slot inventory / pause |

**Main menu:** New game, Continue, Options (volume/fullscreen), Quit. A new game asks before replacing an existing checkpoint. Entrances automatically save a checkpoint; Pause → Save checkpoint updates it manually. Loading restores the last entrance spawn, health, ammunition, inventory, circuit states, collected pickups, opened doors, and defeated enemies. Partial enemy health and active animations are not saved.

## Design your own game

- **[DESIGNER_GUIDE.md](DESIGNER_GUIDE.md):** edit locations and link door/alley destinations without programming.
- **[ART_STYLE_GUIDE.md](ART_STYLE_GUIDE.md):** dimensions, palette, pixel rules, replacement workflow.
- **`art/pixel/STYLE_SHEET.png`:** labeled visual asset sheet.
- **`art/pixel/source/`:** native-resolution PNGs to edit in your pixel editor.
- **`art/pixel/ignotum.gpl`:** importable 16-color palette.

All environments, characters, props, entrances, and colliders are authored editor-visible nodes. Every source image has a ready-to-use 2× PNG, and character sheets include six walk frames. Smooth lighting gradients are intentionally separate from pixel art.

## Validation

```sh
./tools/check.sh
```

This imports the project and runs integration tests in an isolated checkpoint data directory. It exercises movement, jump, flashlight attachment and beam offset, exact 0.5-second dodge, combat, inventory, independent power circuits, animated doors, round-trip scene transitions, named spawns, persistent pickups/enemies, checkpoints, death/retry, and menu controls. Require the final `IGNOTUM: … checks, 0 failures` line; script errors are failures even if Godot returns zero.

With a graphical display, `godot --path . res://tests/capture.tscn` writes screenshots to `/tmp/ignotum-*.png`. Rendering has been inspected using software OpenGL. Physical audio output, standalone exports, and other operating systems have not been tested. The Silkscreen UI font is distributed under its included OFL license in `art/fonts/`; game artwork and sounds were created for this project.
