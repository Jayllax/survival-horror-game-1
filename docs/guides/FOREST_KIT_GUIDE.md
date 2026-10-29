# Place forest scenery

Use Godot **4.7.2 Standard**. This kit has **21 objects in three colors**: Deep green, Muted sage and Autumn. The **63 native PNGs** use the existing Ignotum palette and the same pixel scale as the character and furniture. Silhouettes and painted details are horizontally symmetrical.

[Color catalog](../previews/forest-kit-catalog.png) · [In-game example](../previews/forest-kit-showroom.png) · [Download the kit](../downloads/Ignotum-forest-kit.zip)

## Place an object

1. Open your level's 2D editor. Drag a **scene** from `scenes/objects/forest/` into its Props node. Scenes include the correct artwork scale, ground origin, color choices and optional collision.
2. Put its root on the ground: the origin is the **bottom center**, for example Y=620. Keep root Scale at (1,1). Artwork is already displayed at (2,2), matching one native character pixel to one scenery pixel.
3. Select the root and choose **Color Variant → Deep green / Muted sage / Autumn**. The existing Artwork node updates in the editor and in play.
4. Objects are passable by default, so the player can walk in front of them. Turn on **Solid** only when an object should block the walking plane. Tree collision covers a narrow trunk, rather than the whole canopy. Enable Debug → Visible Collision Shapes during play to inspect it.
5. If you redraw an object, enable Editable Children and adjust its `Solid/Shape` rectangle if necessary. Enable collision deliberately: a log behind the path should remain passable; a log blocking the path can be Solid.

Most supplied trees start at Z Index -3 and smaller props at -1; your edited tall pine keeps Z Index 5. Your uploaded player now uses Z Index **0**, and the flashlight affects objects up to Z Index **1**. For foreground foliage that covers the player and is excluded from the flashlight, use an effective Z Index of **2 or higher**. Parent Z values also count when Z As Relative is enabled. This changes draw order, not collision. Leave the Artwork child at its supplied scale to keep pixels consistent.

These are scenery objects, not new interactions or AI rules. Decorative bushes do not automatically hide the player. Existing enemy sight checks can be blocked by enabled world collision, such as a solid trunk or boulder. No tree-cutting, gathering, climbing or new story is attached.

## Choose sizes

| Folder | Objects | Native canvas sizes |
| --- | --- | --- |
| `trees/` | Small/large broadleaf | 48×64, 72×104 |
| `trees/` | Small/tall pine | 40×80, 56×120 |
| `trees/` | Small/tall birch | 32×64, 40×96 |
| `trees/` | Bare tree, sapling | 40×80, 24×40 |
| `wood/` | Fallen log, mossy log | 48×14, 48×16 |
| `wood/` | Small/large stump | 12×12, 20×16 |
| `wood/` | Exposed roots, fallen branch | 32×10, 32×8 |
| `plants/` | Small/large bush | 24×16, 40×24 |
| `plants/` | Fern, grass tuft, mushrooms | 24×18, 16×10, 12×7 |
| `rocks/` | Small rock, boulder | 16×12, 28×22 |

The standing character is about 33 native pixels tall. Trees are taller objects drawn with the same size pixels, rather than denser textures. Duplicate different sizes/colors to form a woodland; combine grass, logs and bushes in small groups under a Node2D and save that branch as a reusable arrangement.

## Preview the colors

Your latest designer snapshot removes the separate forest showroom/catalog scenes from the gameplay level folder. Those removals are preserved. Use the linked PNG catalog and in-game screenshots to compare sizes and colors, then place reusable objects in your own levels. The portable download still includes its editor catalog as a reference snapshot.

## Redraw in Pixilart

Open a native PNG in **`art/pixel/forest/<category>/`**, keep its canvas dimensions, and export transparent PNG at **100%**. Names end in `_deep_green.png`, `_sage.png` or `_autumn.png`. These are the actual game textures: there is no enlarged source/export duplicate. Use `art/pixel/ignotum.gpl`, hard pixel edges, full transparency and horizontal symmetry. Avoid resampling or antialiasing.

Keep the bottom-center ground contact when redrawing. All variants of one object use the same dimensions and collision. Changing a shared PNG changes every scene instance using that color; use the Inspector color dropdown for individual placements.

## Files and portable download

Artwork lives in `art/pixel/forest/`; reusable objects in `scenes/objects/forest/`. The small `scripts/forest/forest_prop.gd` script reuses the interior kit's existing color/collision controls and supplies forest palette names. It does not generate objects or levels.

The download includes the 63 PNGs, 21 object scenes, editor catalog, palette, guide and required scripts. Copy its **art**, **scenes** and **scripts** folders into another Godot project while keeping paths. Keep both shared `scripts/interiors/interior_variant.gd` and `interior_prop.gd`; they are included because the forest scenes depend on them. The former playable showroom is available in Git history; your current project retains its removal.
