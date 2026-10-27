# Ignotum / pixel art direction

## Start here

Open `art/pixel/STYLE_SHEET.png` beside your pixel editor. Import `art/pixel/ignotum.gpl` as a palette. Open the matching PNG under **`art/pixel/source/`** to paint at native size. Files immediately inside `art/pixel/` are the game-ready versions, enlarged **exactly 2× using nearest-neighbor**. No smoothing or AI upscaling is needed.

This is an original restrained urban kit: desaturated blue-black shadows, green-grey masonry, worn brown timber, restrained brass, warm cream light. Detail belongs on edges and material seams. Keep the player's silhouette readable against buildings.

## Pixel rules

- Work at native resolution, not the enlarged display size.
- One source pixel becomes a 2×2 world-pixel block. Use integer positions and nearest filtering.
- Use a 16×16 source-pixel architectural grid where possible (32×32 in the game).
- Outline silhouettes with the darkest local color. Avoid outlining every interior detail.
- Shade materials with 3–4 colors. Use sparse, deliberate texture clusters, not blanket noise.
- No anti-aliased edges, blur, or fractional scaling in artwork.
- Light generally falls from above-left in textures. Real warm lights and the flashlight add dynamic illumination.
- Use transparent backgrounds on props and actors. Keep collision independent from transparent art padding.
- Smooth light/fog textures are allowed atmospheric effects. They are not painted into sprite sheets.

## Palette

| Use | Hex values |
| --- | --- |
| Deep shadows | `#111b24` `#1b2932` |
| Stone / steel | `#2c3b42` `#40504f` `#59635b` |
| Weathered trim | `#7b7b65` `#a09b7a` |
| Brass / warm highlights | `#d0b98a` `#f1d7a2` |
| Wood | `#6c5148` `#8b6955` `#aca080` |
| Glass / cool cloth | `#435c62` `#648080` `#8faaaa` `#b9c6b5` |

Use highlight colors sparingly. A readable low-contrast object can be lit by Godot; you do not need to bake a bright halo around it.

## Asset sizes (native pixels)

| Asset | Size | Usage |
| --- | --- | --- |
| Player / enemy | 20×36 per frame, 120×36 sheet | Six horizontal walk frames; frame 0 doubles as idle |
| Gun | 17×8 | Separate aiming sprite, source points right |
| House / shop | 160×170 | Background façade variants |
| Station façade | 200×190 | Optional larger building, also menu background |
| Door | 36×64 | Background building entrance |
| Gate | 55×85 | Animated physical passage |
| Ground / brick | 32×32 | Repeatable texture regions |
| Wooden floor | 32×16 | Repeatable interior floor |
| Crate | 32×32 | Solid prop art |
| Bench | 60×35 | Decorative prop |
| Lamp | 32×110 | Post paired with a real warm light |
| Shelf / radiator | 64×72 / 44×28 | Interior dressing |
| Bin / drain / bollard / pipe | 24×36 / 32×8 / 10×26 / 8×100 | Street dressing |
| Sign | 50×22 | Blank plaque: add a Godot Label for your text |
| Bolt cutters / dressing / cloth / antiseptic | 24×28 each | New tool, medicine, and combination materials |
| Ammo / fuse / key / notice / switchboard | See source PNG dimensions | Inventory and interaction props |

## Replace an asset

1. Save a backup or commit your current work.
2. Edit its **source** PNG, retaining dimensions and transparent padding.
3. Export a copy enlarged exactly 200%, nearest-neighbor, over the matching `art/pixel/name.png`.
4. Return to Godot and let it reimport. All scene instances update.
5. For a new asset, duplicate a similar object scene, replace its Sprite2D Texture, and save it with a new name. Resize its collision separately if solid.

To replace character animation, keep six frames side by side at the same dimensions. Godot's Sprite2D uses Hframes = 6; the script advances frames when moving. This is a compact walk-cycle foundation, not a complete set of hand-animated aim/jump/dodge/death actions. The gun rotates independently, and invulnerability is communicated through a tint. You can expand the animation controller later without redrawing the level.

`art/beam.svg`, `art/light.svg`, and `art/fog.svg` remain smooth effect textures. **Do not pixelate the flashlight gradient to repair its position:** its PointLight2D `Offset` and its gun-parent transform control that.

The font `art/fonts/Silkscreen-Regular.ttf` is a third-party OFL font, with its license beside it. All pixel assets in this kit are original editable placeholders. None reproduce Silver Pines artwork or characters.
