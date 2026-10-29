# Four-digit code locks

The reusable lock adds a full-screen dial interface to your own furniture, containers or doors. It does not place anything in your levels, add notes, choose a puzzle solution for you or change existing puzzle objects.

## Add a lock to furniture

1. Open the level you want to edit.
2. Drag **`scenes/objects/puzzles/code_lock.tscn`** into the scene. You can make it a child of the bedside table so it moves with the furniture, or place it beside the table under your level's interactables.
3. Select **CodeLock** in the Scene tree. Its small circle is an editor-visible interaction marker; it has no in-game picture and does not block movement. Position it near the furniture, within reach of the player.
4. In the Inspector's **Lock** section, enter **Correct Code** as exactly four digits, including any leading zeroes. **Starting Code** sets the initial dial positions. Enter a unique **Persistent Id** for this particular lock, such as `house01_drawer01`. Keep that ID when moving or renaming the object, and change it when duplicating it into another puzzle.
5. Adjust **Interaction Radius**, **Prompt Offset**, **Action Label** and **Panel Title** if needed. Only the nearby interaction prompt is shown during exploration.
6. Choose what unlocking should do using the optional settings below. Save the scene and test with a new game or a save made before this lock was opened.

The same HUD already used by your levels contains the lock interface. You do not need to add another UI or any code. New levels need the existing `scenes/ui/hud.tscn` HUD, just like your other interactions.

## Give the player something inside

Under **Contents (optional)**, load or drag an item `.tres` into **Reward Item** and set **Reward Quantity**. Use an item resource from `data/items/`, or one you create using the existing item workflow. You can leave the reward empty for a lock that only opens a passage or animates an object.

The item is added once, on successful unlocking. If there is no room, the panel explains this and the lock stays closed. Close it, rearrange the inventory, then try again. Items are never dropped or lost because of a full inventory. Loading an unlocked lock does not grant its contents again.

## Show an open drawer or unlock a passage

All **Opening (optional)** fields refer to nodes you already have in the level. Assign them using the Inspector's node picker or by dragging the desired node from the Scene tree:

| Inspector setting | Assign this |
| --- | --- |
| **Blocker Path** | The `CollisionShape2D` or `CollisionPolygon2D` that blocks the player. Unlocking disables it. Leave the furniture's unrelated collision alone. |
| **Locked Visual Path** | Optional closed artwork to hide when opened. |
| **Unlocked Visual Path** | Optional open artwork to show when opened. Hide this node initially in your scene. |
| **Animation Player Path** | Optional `AnimationPlayer` containing your opening animation. |
| **Unlock Animation** | The exact name of that animation, initially `open`. Use a non-looping animation. |
| **Completion Flag** | Optional custom progress flag in `Game.world` for other systems. Most locks can leave this empty. |

You can use a reward, a visual swap, a collision change and an animation together, or just one of them. Do not point either visual field at the whole furniture root if it also contains the lock or other artwork you still want visible. For a coded passage, use this lock as its interaction component, with a StaticBody2D barrier and your own artwork. The separate key/power Door prefab retains its own interaction rules; use a single interaction component for each opening. An invisible lock alone does not supply a new physical door or drawer illustration.

When returning to the room or loading a save, open artwork and disabled collision are restored. An assigned opening animation is shown at its final pose rather than replayed. The lock also exposes an **unlocked** signal for optional custom connections in Godot's Signals panel; the Inspector settings above require no signal connections or programming. Restore state through the Inspector fields: the signal fires only for a new unlock.

## Using the panel

Interact near the lock to open it. Each of the four dials has a **+** and **−** button and wraps between 0 and 9. Click a digit to select it, or use left/right arrows; up/down arrows turn the selected dial. Typing a digit sets the selected dial and moves to the next one. **Unlock**, Enter or the configured Interact action checks the combination. The code must match all four digits. There is no automatic success simply from displaying the correct digits, and no attempt limit.

**Close** or Escape leaves the lock. Unsolved dial positions are remembered. The game pauses while the panel is open; inventory, dialogue and save menus cannot open over it. Closing will not fire a held mouse button or immediately reopen the lock.

## Saving and editing safely

The existing four bicycle save slots store each lock's completion and unsolved dial positions alongside inventory and other progress. Solving a lock does **not** automatically save the game. Loading an earlier slot restores that slot's puzzle state and inventory.

Give every independent lock a different **Persistent Id**. Two copies sharing an ID intentionally share completion. When the ID is blank, identity comes from the level filename and node path; moving or renaming that object can then lose the association with an existing save. Changing the code does not reset a lock already opened in an old save: test with an earlier save or a new game.

All panel elements are editable nodes in `scenes/ui/code_lock_ui.tscn`. It uses your existing UI font and palette. Editing that shared scene changes every code-lock panel; keep the node names and hierarchy if you restyle it.

## Verification

Run the lock regression suite with `GODOT_BIN=/path/to/godot bash tools/check.sh code_lock`. It checks real interaction input, dial wrapping, incorrect codes, leading zeroes, full inventories, one-time rewards, opening visuals/collision/animation and independent bicycle save slots. Test-created locks stay in automated tests and are not added to your playable levels.
