# Searchable drawers, cabinets and other containers

Use **`scenes/objects/loot/loot_container.tscn`** as an invisible interaction beside your own furniture. It supports both deliberately empty containers and containers holding one or more item types. No instances or loot placements have been added to your levels.

## Empty container: no items required

1. Open the level and drag **loot_container.tscn** into it. You can parent the instance to the cabinet/drawer so it moves with that furniture, or place it under your level's interactables.
2. Select **LootContainer** and position its small editor-visible square near the furniture, within reach of the player. This square has no in-game artwork and does not block movement.
3. Set a unique **Persistent Id**, such as `house01_bedside_drawer01`. Keep it unchanged when moving or renaming this container. Change it when duplicating the container for a different drawer.
4. Leave **Contents** at **size 0**. The default **Empty Message** is `Empty`; edit the wording if you want.
5. Save and run the level. A nearby **Search** prompt appears. Interacting shows **Empty**, records the container as searched, and removes its interaction. Your furniture stays in place.

You do not need a blank item definition, an item without an icon or a quantity of zero. A deliberately empty Contents array is the supported way to make an empty drawer. For filled drawers, the item's shared resource stays unchanged.

## Put items inside

1. Expand **Contents** in the Inspector and set the array size to the number of different item entries you want.
2. In each element's resource dropdown, choose **New LootEntry**. Click the new resource to expand its fields.
3. Assign **Item** to an existing item `.tres`, such as one under `data/items/`. Set **Quantity** for that entry.
4. Repeat for additional item types. To return this container to empty, set Contents size back to **0**; a blank/null element in a nonempty array is an unfinished configuration and will not be silently discarded.

The entire contents must fit before anything is taken. Existing ammunition stacks are filled normally, quantities may split into several stacks, and weapons/puzzle items use their normal inventory footprints. If anything cannot fit, a message asks the player to make room and the container stays searchable with all its contents intact. There is no partial transfer, lost remainder or repeatable reward. Weapons enter the inventory unequipped and unloaded, like the existing pickups.

Item names and descriptions remain in the inventory. Filled containers use the existing pickup feedback; there are no permanent item titles attached to the furniture. **Action Label**, **Interaction Radius** and **Prompt Offset** customize the nearby prompt.

## Optional open/searched appearance

You can leave all **Opening (optional)** fields empty. For a drawer with separate artwork, assign **Closed Visual Path** to its closed picture and **Searched Visual Path** to its open picture. Hide the open picture initially in the level. Assign only the relevant artwork, rather than a whole furniture root that also contains other visible parts or the interaction itself.

Alternatively, assign an **Animation Player Path** and the exact **Search Animation** name, initially `open`. Supply a non-looping animation. Searching plays it; returning to the level or loading a searched container shows its final pose without replaying feedback or granting items again. You can combine the animation and visual swap.

Both empty and filled containers support these opening settings. You create the artwork, animation and any environmental storytelling. The **searched** signal fires only after a successful first search, and **Completion Flag** optionally sets an exact `Game.world` progress flag for another system. Normal looting needs neither custom connections nor code.

## Save state

Bicycle saves record empty and filled containers' searched state independently alongside the inventory. A save from before searching restores both the interaction and the earlier inventory. A save from after searching keeps the prompt removed and restores only the items in that slot. Searching does not automatically save the game.

Every independent drawer needs its own **Persistent Id**. Matching IDs share searched state, so do not duplicate them accidentally. A blank ID falls back to the scene filename and node path; moving or renaming that node may then change its identity in older saves. Editing Contents does not refill an already searched container in an old save: test using an earlier slot or a new game.

The separate code-lock scene still requires a four-digit code. Use LootContainer for ordinary searches and CodeLock for locked drawers. Use one interaction for a drawer so the player's nearby prompt remains clear. Your levels need the normal existing HUD to display search/Empty/pickup feedback.

## Verification

`GODOT_BIN=/path/to/godot bash tools/check.sh loot` checks real E interactions, empty feedback and disappearing prompts, multi-item atomic transfers, stack splitting, weapon loot, malformed configuration, searched artwork/animations, one-time rewards and independent bicycle save slots. Test-created containers are outside your gameplay levels.
