# Ignotum / simplified production assets

The newer [house variants](HOUSE_VARIANTS.md) use the current house and its embedded **Sparkle's palette**, with exactly mirrored façades, single side chimneys, and three chimney-free options. They each have one native PNG and a reusable scene that applies 2× scale; the older duplicated source/export convention below does not apply to those new files.

The current enemy is a deliberately simple, exact palette swap of the player's six-frame sheet, with sage skin and plum clothing. Its native sheet remains 120×36 and its game export 240×72, matching the player. Do not regenerate it with the older asset generator. Both characters now use editable named SpriteFrames animations; see [CHARACTER_GUIDE.md](CHARACTER_GUIDE.md) for inserting your own animation art and disabling temporary pose compression.

The redesign is now implemented as **individual PNGs used by the game**. `art/pixel/STYLE_SHEET.png` is a contact sheet made from those actual files. The earlier illustration in `art/redesign/` remains a design reference, not the runtime texture atlas.

## Files to edit

- `art/pixel/source/name.png`: native-resolution drawing.
- `art/pixel/name.png`: the same drawing enlarged exactly **2× with nearest-neighbor**. Scenes and inventory resources use this version.
- `art/pixel/ignotum.gpl`: the simplified production palette, ready for import in pixel editors.
- `art/pixel/simple_assets.json`: native/game sizes and color values for this asset pass.

The existing **player and ammunition PNGs are preserved**. The remaining scenery, props, enemy, and item artwork were replaced at their existing paths; a cream-house variant was added. If your own player/ammo edits exist only in your local project, keep those local files when merging the update.

## Pixel scale and drawing rules

One native pixel is always a **2×2 world-pixel block**. Do not resize each sprite independently to fill its old on-screen bounds: this changes apparent pixel size. The sample level's building positions, entrance art/selection shapes, and lamp light positions already account for the new dimensions.

- Large flat wall/roof areas; no masonry grids, roof shingles, random noise, or dither.
- Two or three tones per material, with a few isolated wear clusters on building façades.
- Simple dark windows and broad cream/tan trim.
- Muted maroon and purple roofs, brick reds, cream plaster, sage metalwork, blue-grey glass.
- Hard integer-grid edges and alpha of either 0 or 255. The door, crate, drain, and tiling surfaces naturally fill rectangular canvases.
- Smooth light/fog textures remain separate Godot effects. Their lighting can produce additional screen colors; sprite files themselves use the fixed palette.

The production palette follows the approved redesign direction. Its exact RGB values are in `simple_assets.json` and `ignotum.gpl`. The illustrated concept sheet can contain intermediate colors; it is not the source used for palette validation.

## Native dimensions

| Asset | Native PNG | Game PNG |
| --- | --- | --- |
| Red house / cream house | 96×128 | 192×256 |
| Shop | 128×128 | 256×256 |
| Larger cream building (`station`) | 128×144 | 256×288 |
| Door | 24×44 | 48×88 |
| Gate | 55×85 | 110×170 |
| Lamp | 24×96 | 48×192 |
| Crate | 32×32 | 64×64 |
| Bench | 48×28 | 96×56 |
| Bin | 24×36 | 48×72 |
| Drain | 32×8 | 64×16 |
| Downpipe | 8×100 | 16×200 |
| Sign | 50×22 | 100×44 |
| Shelf / radiator | 64×72 / 44×28 | 128×144 / 88×56 |
| Bollard | 10×26 | 20×52 |
| Paving / plaster (`bricks`) | 32×32 | 64×64 |
| Wooden floor | 32×16 | 64×32 |
| Gun | 17×8 | 34×16 |
| Key | 20×24 | 40×48 |
| Fuse | 18×12 | 36×24 |
| Cloth / antiseptic / dressing / cutters | 24×28 each | 48×56 each |
| Notice / switchboard | 24×30 / 35×50 | 48×60 / 70×100 |
| Enemy sheet | 120×36 (six 20×36 frames) | 240×72 |
| Player sheet (preserved) | 120×36 (six 20×36 frames) | 240×72 |
| Ammo (preserved) | 19×15 | 38×30 |

The old house was 160×170 native pixels. The new 96×128 house has fewer than half as many source pixels, and substantially less surface texture. Its smaller world footprint is reflected in the authored town layout. It is not stretched back to 320×340.

## Replace one sprite with your drawing

1. Open its native PNG in your pixel editor.
2. Keep the canvas dimensions and existing transparent padding if you want a direct swap.
3. Export a second copy at **200%, nearest-neighbor** over the matching game PNG.
4. Let Godot reimport, then test the scene and inventory if the item has an icon.
5. When changing a canvas size, adjust the corresponding scene's sprite placement and any physical collider separately. Do not change a six-frame character sheet into a different frame layout without updating Hframes and animation logic.

Most game sprites are displayed at Sprite2D scale 1 because the PNG is already enlarged 2×. The menu's enlarged façade is a decorative illustration at a different integer native-pixel scale; it is not part of the playable scene's pixel grid.

## Validation and optional build tool

`./tools/check.sh` runs gameplay, interface, and asset-placement checks with Godot. Placement checks confirm resized buildings and doors meet the ground, lamp lights meet their new bulbs, physical gate art still matches the floor, and the player frame layout is valid.

Optional art tooling requires **Python + Pillow**, which are not game runtime dependencies:

```sh
python tools/check_art.py
```

This verifies each generated native/export pair has exact 2× nearest-neighbor pixels, valid dimensions, palette colors, and hard transparency.

`python tools/build_simple_assets.py --write` regenerates the supplied scenery/prop/item/enemy art. **That command overwrites those named PNGs**, so keep your hand edits backed up and do not run it as part of ordinary gameplay or validation. It never overwrites player or ammo. The PNGs are fully usable without the generator.

The optional UI font remains Silkscreen, with its OFL license in `art/fonts/`. All game artwork in this asset kit is original; no Silver Pines artwork is included.

## Bicycle save station (current player palette)

`art/pixel/bicycle.png` is one native **32×28 RGBA PNG**, displayed at **2×** by `save_bicycle.tscn`. There is no second enlarged PNG. Edit this file directly in your pixel editor and retain its dimensions and transparent background. It is a front elevation with exact left/right mirror symmetry, including highlights and pedals. Six colors are sampled from the current player/house assets: `#24222e`, `#344f69`, `#4e6474`, `#8f6c61`, `#ccbb98`, `#b0866c`. Existing art is not recolored.

The optional `godot --headless --path . --script tools/build_bicycle.gd -- --write` rebuilds only the bicycle from exact-grid rectangles. **Do not run it after editing your bicycle unless you intend to replace your edits.** It does not run during gameplay or normal validation. The older asset generator likewise contains the previous kit palette; it should not be run over your revised art.
