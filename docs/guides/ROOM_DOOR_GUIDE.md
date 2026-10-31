# Side-view doors between rooms

Use **`scenes/objects/room_door_side.tscn`** for a physical door between two rooms **inside the same level**. Walk up from either side and press your existing interaction key to open it. Walk through normally. An open door can also be closed, unless you turn off Allow Close.

## Place the door

1. Open your interior level. Drag `room_door_side.tscn` into its **Interactables** branch.
2. Position the **RoomDoorSide root** on the floor at the boundary between the rooms. The root is at the bottom of the door; its default height is **88 world pixels** and width **8 world pixels**, matching the existing doorway and character scale.
3. Leave an opening in the room divider for the door. Any wall collision above the doorway should end at the **top of the door**, 88 pixels above the root. A full-height wall hidden behind it will still block passage after opening.
4. Give **Persistent Id** a unique stable value, such as `house01_bedroom_door`. Keep different doors' IDs different.
5. Choose **Opens Left** to put the open leaf on the left side of the profile, or leave it off for the right. This controls the artwork; the door works from either side in both cases.
6. Run the level and approach the door. The normal nearby interaction prompt appears. Opening animates the leaf into the depth of the room and clears the solid barrier when fully open.

This scene does not need a Destination Scene or spawn marker. Continue to use `entrance.tscn` for doors that fade to another scene.

## Inspector settings

| Setting | Effect |
| --- | --- |
| **Starting Open** | Initial state for a new game; previews immediately in the editor. Saved state takes priority when revisiting/loading. |
| **Allow Close** | Let an open door be closed again. Off makes it an open-once passage. |
| **Opens Left** | Mirror which side the open leaf occupies; previews in the editor. |
| **Opening Seconds** | Duration of opening or closing, initially 0.4 seconds. |
| **Persistent Id** | Stable identity used by room revisits and bicycle saves. |
| **Interaction Radius** | How close the player's origin must be to the door's floor origin. Default 60 allows interaction from both sides with the current player dimensions. |
| **Prompt Offset** | Position of the existing nearby interaction prompt. |
| **Open/Close Prompt** | Text used by that prompt. |
| **Required Key** | Optional inventory item ID. Leave empty for an ordinary door. |
| **Locked/Blocked Message** | Feedback when a key is missing or something occupies the doorway. |

A door cannot close over a player, enemy or pushable body. If one enters while it is closing, the leaf opens again. Closed doors also block the existing enemy sight and weapon rays through their world collision. An authored native LightOccluder2D blocks shadow-enabled lights while closed and is hidden when open.

## Artwork and collision

- `art/pixel/doors/side_door_frame.png` is the new **native 4×44** pixel profile. It uses the project palette, has a mirrored design and is displayed at 2× scale. Edit this one PNG for its appearance; there is no extra enlarged runtime copy.
- `Artwork/LeafPivot/Leaf` reuses the existing green door artwork through an AtlasTexture. It projects into view while opening. You can assign your own leaf texture; adjust its position so its bottom edge rests on the root and its hinge edge is at x=0 relative to LeafPivot.
- Select the root's **Z Index** to move the whole door behind/in front of other props, just like other 2D objects. No CanvasLayer is used.
- To resize collision for a different door, enable **Editable Children**, then edit `Barrier/CollisionShape2D` → Shape → Size and Position. Each instance has its own shape. Match the artwork and update the `LightOccluder2D` polygon if the doorway dimensions change. Keep the door's root scale at (1,1).

All artwork, collision and shadow nodes are present in the `.tscn` and visible in the editor. The door does not generate level geometry.

## Keys and saving

Required Key uses an item's actual **ID**, rather than its display name. A successful unlock follows that item's **Remove After Use** setting. Unlocking is remembered separately, so closing and reopening never asks for the same key again. A consumed key is also safe if the room is left during the opening animation.

Completed open/closed states are stored in the existing run state and included in bicycle save files. Loading another slot restores that slot's door state independently. An unfinished animation returns to its last completed open/closed state on reconstruction, while an already successful key unlock remains remembered. Opening a door does not automatically write a save file.

If Persistent Id is blank, the door falls back to the level filename and node path. A named ID is recommended so rearranging/renaming nodes does not change their saved identity. Changing Starting Open affects new runs, not an already saved door state.

## Separate test room

Open `tests/fixtures/room_door_sandbox.tscn` and press F6 for an isolated two-room test. It includes the actual player, an upper divider, the side-view door, movable furniture and a bicycle. It has no story text and no links from your campaign. No doors have been inserted into your levels automatically.

Automated checks: `GODOT_BIN=/path/to/godot bash tools/check.sh room_doors`. They exercise actual E input and movement from both sides, safe closing, disposable keys, per-instance collision and independent bicycle saves.
