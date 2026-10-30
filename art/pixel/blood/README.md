# Blood overlays

Eight native transparent PNGs for your own scenery. Edit these directly in Pixilart; there are no enlarged runtime copies. Matching scenes under `scenes/objects/blood/` display them at **2×** with nearest filtering.

| PNG | Canvas |
| --- | --- |
| `blood_splat_small.png` | 16×16 |
| `blood_splash_wide.png` | 24×16 |
| `blood_droplets.png` | 16×16 |
| `blood_pool.png` | 24×8 |
| `blood_smear.png` | 24×8 |
| `blood_drips.png` | 16×24 |
| `blood_spatter.png` | 24×16 |
| `blood_dried.png` | 16×16 |

Colors are from `art/pixel/ignotum.gpl`: `#4a3337`, `#613943` and `#844344`. The dried patch uses the darkest tone. All source PNGs have hard alpha and simple horizontally symmetric pixel clusters. Individual instance opacity remains adjustable through Godot's Self Modulate.

The checkerboard and furniture shown in the [preview](../../../docs/previews/blood-overlays.png) are documentation backgrounds and are not part of the transparent textures. See the [placement and clipping guide](../../../docs/guides/BLOOD_OVERLAY_GUIDE.md).
