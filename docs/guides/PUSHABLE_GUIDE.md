# Pushable furniture: a child component

**`scenes/objects/physics/pushable_body.tscn` is added as a child of your existing furniture.** It moves the whole furniture object, including its normal artwork, overlays and attached interaction nodes. You resize its collision shape in the editor. No programming or new input actions are needed.

## Add it to furniture you already placed

1. Open your level and find the particular furniture object in the Scene tree, such as **Nightstand**.
2. Drag **`scenes/objects/physics/pushable_body.tscn`** from the FileSystem onto that Nightstand node in the Scene tree. Keep **PushableBody** as a direct child of the individual object. Its local position can normally stay **(0,0)**.
3. Right-click the PushableBody scene instance and enable **Editable Children**. Expand it and select **CollisionShape2D**.
4. Resize the rectangle using its orange shape handles or **Shape → Size** in the Inspector. Move CollisionShape2D to align the box with the furniture. Change the shape dimensions rather than stretching the physics body node.
5. Select **PushableBody** and give **Persistent Id** a unique name, such as `house04_nightstand01`. Set **Push Speed** and any optional settings below.
6. Save the level and run it. Walking into either side pushes the object. The top remains solid, so the player can jump onto it.

The hierarchy looks like this:

```text
Nightstand                     ← your existing furniture
├── Artwork
├── Solid                      ← its original furniture collision, if any
└── PushableBody                ← the reusable child component
    └── CollisionShape2D        ← the box you resize and position
```

The supplied furniture roots have their origin at floor level. The generic body starts with a 32×32 rectangle positioned at **(0,-16)** so its bottom is on that origin. If your parent is a centred Sprite2D, position the collision shape to match that image instead—often **(0,0)**. Fit the box visually to the actual object, especially its top platform surface.

Each component instance owns its collision-shape resource. If you assign an external/shared shape manually, use **Make Unique** before editing an individual instance. Editing the base pushable_body scene changes its defaults for all future instances.

## Ready-made nightstand

You can also drag **`scenes/objects/physics/pushable_nightstand.tscn`** into a level. It is the normal nightstand with PushableBody already added as its child and a fitted 28×30 collision box. Its existing colour-variant settings remain on the Nightstand root. Give each placed component its own Persistent Id.

The original non-pushable nightstand and your existing placements remain unchanged.

## Inspector settings

| Setting on PushableBody | What it controls |
| --- | --- |
| **Push Enabled** | Allows player pushing. Turning it off leaves a solid platform. |
| **Push Speed** | Maximum intended horizontal push speed in world pixels/second; initially 45, slower than your current walk speed. Sprinting does not launch the object. |
| **Disable Original Collisions** | Normally keep on. The component ignores the furniture's original StaticBody2D collisions at runtime, using its own resized box instead. |
| **Use Gravity** | Makes the furniture fall and settle on surfaces. Disable for a fixed-height sliding prop. |
| **Gravity / Maximum Fall Speed** | Falling behaviour. The object stays upright at its authored angle; it does not roll or topple like a rigid body. |
| **Use Travel Limits** | Enables the optional horizontal movement range. |
| **Left Distance / Right Distance** | Allowed world-pixel travel from its original placement. Zero means no travel in that direction when limits are enabled. |
| **Remember Position** | Restores the position when revisiting the room and through bicycle saves. |
| **Persistent Id** | Stable, unique identity of this particular movable object. |

The furniture's original **Solid** checkbox can be left off to keep the editor view clear. With Disable Original Collisions enabled, existing StaticBody2D collisions under this particular furniture are switched off during play, even if Solid had been on. Areas used for loot, notes or other interactions remain active and move with the furniture. The scene files and shared furniture resources are not changed by this runtime adjustment.

## Plan the platforming puzzle

The player pushes by walking into the side while grounded. Airborne movement and dodges do not shove furniture. Releasing movement stops it, walls and other solid objects block it, and another pushable does not create a chain push. Standing or walking on top does not count as a side push. The existing walking/crouching animations are retained.

Pushing does not increase jump height. Make the object's top reachable with your player settings, then make the remaining climb from that top reachable as well. Use Travel Limits to keep an important step within the puzzle area and plan clear entry/save-spawn spaces around the object's possible positions. With gravity enabled, pushing beyond the floor can make the furniture fall.

For a simple flat platform, keep the component's **global rotation at 0 and global scale at (1,1)**. The supplied furniture root is normally unscaled, with 2× scale on Artwork, so a sibling PushableBody naturally has the correct physics scale. For a parent already scaled 2×, counter-scale the component to (0.5,0.5); resize its Shape to fit the world-sized object. For tilted furniture, you can rotate only Artwork or counter-rotate the component so its collision top stays flat. Editor warnings point out rotation/scale configurations to check.

Use one PushableBody per furniture object. A second component is ignored at runtime and warned about in the editor. This component is intended for scenery under Node2D/Sprite2D or static furniture roots; player/enemy CharacterBody2D roots and RigidBody2D objects already have movement controllers. Select an individual furniture object as the parent, rather than your level or entire Props container.

## Saving

Moved positions stay in the current run when leaving and re-entering a room. Bicycle saves capture them alongside inventory, health and other puzzle progress. Loading an older slot restores that slot's furniture positions without merging in newer positions. Movement does not automatically write a save file.

With **Remember Position** off, the object starts from its authored placement when the room is reconstructed. When it is on, keep Persistent Id stable as you edit or rename the furniture. Distinct objects need distinct IDs. A blank ID falls back to scene filename and node path, so moving/renaming those nodes can change identity in old saves. Adding this child does not reparent your existing loot/note nodes or change their identities.

Positions are saved, while active falling velocity resets when loading. If you later change level geometry or collision sizes around an old saved position, test using a new game or an appropriate earlier save. Normal player movement, jump tuning, camera settings and input mappings are unchanged.

## Try it separately

Open **`tests/fixtures/pushable_sandbox.tscn`** and press **F6**. It contains the real nightstand/component hierarchy and a ledge reachable by pushing the nightstand near it, jumping onto it, then jumping to the ledge. Its floors, obstacles, player and furniture are editor-visible nodes. It is an isolated development fixture and is not linked into your campaign.

For automated verification, run **`GODOT_BIN=/path/to/godot bash tools/check.sh pushables`**. It exercises actual movement input, both push directions, solid-wall/other-object blocking, per-instance resizing, offset child bodies, falling, pausing, duplicate-component handling, the complete platforming route, scene revisits and independent bicycle save slots.
