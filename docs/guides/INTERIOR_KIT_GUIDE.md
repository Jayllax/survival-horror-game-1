# Build interiors with the furniture kit

Use Godot **4.7.2 Standard**. The kit contains **24 furniture/lighting objects**, each in **Warm, Sage and Slate**, plus full/half-height stairs in both directions. These are real native PNGs and reusable scenes, ready to place; the preview is only a catalog.

[View every furniture color](../previews/interior-kit-catalog.png) · [Download the asset kit](../downloads/Ignotum-interior-kit.zip)

## Start placing furniture

1. Open your interior level in Godot's 2D editor.
2. In FileSystem, open `scenes/objects/interiors/`, choose a room folder, and drag a **`.tscn` scene** into your level's `Props` node. Use the scene instead of dragging a bare PNG: it includes the correct pixel scale, origin, optional collision, and lamp light.
3. Select the placed object's root. Set **Color Variant → Warm / Sage / Slate**. Its existing Artwork node updates in the editor and during play. You do not need to swap textures or program anything.
4. Floor-standing objects use their root as the **bottom-center ground point**. Put that root at the floor's Y coordinate, for example Y=620. Table lamps work the same way: put their root on top of a table/nightstand.
5. Wall cabinets, medicine cabinets, wall lamps and ceiling lamps use a **top-center mounting point**. Put their root where the object should begin on the wall/ceiling.
6. Keep root Scale at (1,1). Artwork is already Scale (2,2), matching one character-art pixel to one furniture-art pixel. Resize by redrawing the native PNG rather than stretching the scene.

Furniture sits behind the player and is passable by default, so you can walk in front of sofas, kitchens and beds. Turn on **Solid** only for an object that should physically block the walking plane. Its authored `Solid/Shape` collision becomes active; enable **Debug → Visible Collision Shapes** during play to check it. Reposition/resize that rectangle through Editable Children if your redraw needs a different blocking shape.

To create a reusable arrangement, put several objects under a Node2D, then right-click that parent → **Save Branch as Scene**. Make a kitchen or bathroom once and instance it in several houses. Do not edit shared PNGs when you only intend to change one placed object's color; use Color Variant.

## Adjust lamps

`lighting/` contains table lamps, floor lamps, ceiling pendants and wall lamps. Each scene has an editor-visible **PointLight2D** named `Light`, using the existing Godot radial light texture. Illumination is separate from the pixel artwork.

Select the lamp's root to set **Light Enabled**, **Light Energy**, **Light Color** and **Light Radius Scale**. These update the actual Light node in the editor. A color variation changes the fixture's paint, while the bulb's light remains warm unless you change Light Color. There is no interaction prompt or automatic switch logic attached.

The **Light node position** is also editable: enable Editable Children and move Light if your redraw moves its bulb. Its initial position is near the shade/bulb. An interior needs a **CanvasModulate** if you want dark areas and pools of illumination; inspect the showroom's AmbientTint for an example. The kit does not change the lighting of your existing levels.

## Walkable stairs and upper floors

Open `stairs/`:

| Scene | Direction when going up | World run / rise |
| --- | --- | --- |
| `stairs_right.tscn` | Right | 192 / 128 |
| `stairs_left.tscn` | Left | 192 / 128 |
| `stairs_half_right.tscn` | Right | 96 / 64 |
| `stairs_half_left.tscn` | Left | 96 / 64 |

Every stair scene has the same three color choices. Furniture is horizontally symmetrical; left/right stair scenes are exact mirrored partners. The half flights reuse a cropped part of the full-size art, so there are no duplicate enlarged or left-facing PNGs.

1. Drag a stair scene into the level's `Geometry` node. Keep its rotation at 0 and root Scale at (1,1); choose the supplied opposite direction instead of negative scaling it.
2. The root is the **lower-left of the full bounding box**, not necessarily the low entry. Expand the scene and use its **LowerLanding** and **UpperLanding** Marker2Ds to align the low entry and high exit with floors.
3. Add the actual upper-floor **StaticBody2D + CollisionShape2D** and artwork yourself, just like any other floor. The staircase does not create floors or modify the level at runtime. Place the floor's walking surface exactly at UpperLanding Y, extending away from the high end.
4. Leave the opening over the flight clear. An upstairs collision rectangle extending back over the stair opening can block the player's head.
5. Test with F6. The player walks up/down with normal movement; these are physical stairs rather than scene transitions. They use an authored one-way ramp behind the drawn treads so the player does not catch on individual risers. The higher portion can be walked underneath.

Example: a right-rising full flight at **(400,620)** ends at **(592,492)**. Start the upper floor at X=592 with its top at Y=492. For a left-rising full flight at (400,620), the low entry is (592,620), while the high exit is (400,492). A half flight rises 64 world pixels instead of 128; combine aligned half flights or use them with lower raised platforms.

The player scene now has **Floor Snap Length = 8** so descending slopes stays grounded. Movement speed, jump settings, inputs and animation artwork are unchanged. The uploaded snapshot had empty player attachment point lists; their previous calibrated values have also been restored so the flashlight continues following the animated hand. When adapting the stairs for another CharacterBody2D, use a floor angle above the flight's approximately 34° slope and a similar floor snap length. Keep the WalkSurface collision active and one-way; the furniture Solid checkbox does not apply to stairs.

## See the kit in context

- **`scenes/levels/interior_kit_showroom.tscn`**: press F6 for a separate playable furnished showroom, including a bedroom on a walkable upper floor. It uses your existing player/HUD and is not linked to the campaign or main menu.
- **`scenes/levels/interior_kit_catalog.tscn`**: open in the 2D editor for all three colors of every object and all stair layouts. This is an editor catalog, not a playable level. Lamps are off there to make the paint colors easy to compare.

[Showroom screenshot](../previews/interior-kit-showroom.png) · [Stairs in game](../previews/interior-kit-stairs.png)

Both scenes contain placed nodes and scene instances in their `.tscn` files. Your town, alley and existing house interiors have not been refurnished by this kit.

## Edit artwork in Pixilart

The only game PNGs are in **`art/pixel/interiors/<room>/`**. Each object's three files end in `_warm.png`, `_sage.png`, `_slate.png`. These are native-resolution files; there is no extra source/export pair. Open a PNG in Pixilart, keep its canvas size, use hard edges/transparency, and export transparent PNG at 100%. Godot will display it at 2× automatically.

Use the existing **`art/pixel/ignotum.gpl`** palette. Keep the silhouette and pixel size consistent across the three variants. All supplied furniture is exactly mirrored horizontally, including details; use a symmetry tool when redrawing. Lamps can have smooth light falloff because that comes from Godot, not additional painted colors.

Stairs use one shared native 96×64 PNG per color. Changing one updates full, half and mirrored scenes. Keep the tread direction and overall dimensions if retaining their supplied collisions. To change geometry deliberately, update WalkSurface and the landing markers together.

## Folder map

| Location | Contents |
| --- | --- |
| `art/pixel/interiors/living_room/` | Sofa, armchair, coffee table, dining table/chair, bookcase, sideboard |
| `art/pixel/interiors/kitchen/` | Base/wall cabinets, sink cabinet, stove, fridge |
| `art/pixel/interiors/bathroom/` | Bathtub, toilet, pedestal sink, medicine cabinet, shower |
| `art/pixel/interiors/bedroom/` | Bed, nightstand, wardrobe |
| `art/pixel/interiors/lighting/` | Table, floor, ceiling and wall lamps |
| `art/pixel/interiors/stairs/` | Three shared stair PNGs |
| `scenes/objects/interiors/` | Reusable scenes, grouped into the same categories |
| `scripts/interiors/` | Editor color/collision/light controls; no level generation |

The download archive contains these assets/scenes/scripts, the required shared light texture, the guide and the catalog image. Copy its `art/`, `scenes/` and `scripts/` folders into a Godot project while keeping their paths. The playable showroom remains in the full Ignotum project because it uses your player and HUD.
