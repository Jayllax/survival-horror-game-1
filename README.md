# Ignotum / development foundation 04

A desktop Godot 4 side-view survival-horror foundation with original pixel art. No authored story, forced quest, campaign ending, or victory screen. Start on a street, enter a building or alley with E, and return through matching entrances. These small connected spaces demonstrate the reusable location system; they are not a campaign.

## Open and play

Use **Godot 4.4+ Standard edition** (validated on 4.4.1 and 4.6.3). Import `project.godot` and press **F5**. No plugins or .NET installation required.

| Control | Action |
| --- | --- |
| A/D or arrows | Move |
| Space | Jump (buffered, with coyote time) |
| Right mouse / left click | Held aim / fire |
| R / Q / Shift | Reload / melee / dodge |
| E | Collect, examine, operate, or enter |
| F | Gun-mounted flashlight |
| I / Esc | Eight-slot inventory / pause |

**Main menu:** New game, Continue, Options (volume/fullscreen), Quit. A new game asks before replacing an existing checkpoint. Entrances automatically save a checkpoint; Pause → Save checkpoint updates it manually. Loading restores the last entrance spawn, health, ammunition, inventory, circuit states, collected pickups, opened doors, and defeated enemies. Partial enemy health and active animations are not saved.

## Simplified sprite replacement

The redesign is implemented as **29 individual production sprite PNGs**: 28 scenery/prop/item/enemy replacements at their existing paths, plus a new cream-house variant. Player and ammo PNGs are preserved. Buildings have smaller native dimensions and simpler surfaces; scene positions, door selection shapes, and light offsets have been adjusted accordingly.

`art/pixel/STYLE_SHEET.png` shows the actual assets now used by the project. See [ART_STYLE_GUIDE.md](ART_STYLE_GUIDE.md) for native sizes and the exact 2× pixel workflow. The earlier illustrated sheet is only an art reference.

## Exploration and inventory

Exploration has no fixed HUD panels, logo, controls strip, or permanent crosshair. Health briefly appears after damage (and remains subtly visible when critical). Ammo/crosshair appear only during aiming, recent firing, or reload. Hold right mouse to aim and move carefully. Controls are available from Pause → Controls.

Pickups are just their artwork. A nearby **[E] Take** prompt identifies an action, not the item. Collecting does not announce its name. Open I, select an icon with the mouse or keyboard, and read its name, description, category, quantity, and artwork. Medical supplies can be **Used**; select **Combine** on a material, then select its partner. Cloth + antiseptic creates a field dressing that heals 30. Full-health use and failed combinations waste nothing.

The building contains bolt cutters. Carry them to the alley's chained gate to permanently open access to a medical supply. All additions are authored scene instances with editable item resources and recipe resources, not a mandatory quest. No story or ending is attached.

Sources and the specific design adaptations are documented in [INSPIRATION_NOTES.md](INSPIRATION_NOTES.md).

## Design your own game

- **[DESIGNER_GUIDE.md](DESIGNER_GUIDE.md):** edit locations and link door/alley destinations without programming.
- **[ART_STYLE_GUIDE.md](ART_STYLE_GUIDE.md):** dimensions, palette, pixel rules, replacement workflow.
- **`art/pixel/STYLE_SHEET.png`:** labeled visual asset sheet.
- **`art/pixel/source/`:** native-resolution PNGs to edit in your pixel editor.
- **`art/pixel/ignotum.gpl`:** importable 16-color palette.

All environments, characters, props, entrances, and colliders are authored editor-visible nodes. Every source image has a ready-to-use 2× PNG, and character sheets include six walk frames. Smooth lighting gradients are intentionally separate from pixel art.

## Previews

Exploration:

![Unobstructed exploration](docs/previews/exploration.png)

Inventory inspection:

![Icon inventory and item actions](docs/previews/inventory.png)

## Validation

```sh
./tools/check.sh
```

This imports the project and runs integration tests in an isolated checkpoint data directory. It exercises movement, jump, flashlight attachment and beam offset, exact 0.5-second dodge, combat, inventory, independent power circuits, animated doors, round-trip scene transitions, named spawns, persistent pickups/enemies, checkpoints, death/retry, and menu controls. A second suite covers quiet HUD visibility, proximity prompts, inventory inspection, medical use, combination rollback, and tool-gated persistence. All three suites must complete: `IGNOTUM: … checks, 0 failures`, `IGNOTUM INTERFACE: … checks, 0 failures`, and `IGNOTUM ASSETS: … checks, 0 failures`; script errors are failures even if Godot returns zero.

With a graphical display, `godot --path . res://tests/capture.tscn` writes screenshots to `/tmp/ignotum-*.png`. Rendering has been inspected using software OpenGL. Physical audio output, standalone exports, and other operating systems have not been tested. The Silkscreen UI font is distributed under its included OFL license in `art/fonts/`; game artwork and sounds were created for this project.
