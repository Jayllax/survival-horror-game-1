# Place fences and tool-gated routes

Try `tests/fixtures/fence_sandbox.tscn` with **F6**. It contains a player, cutters, a save bicycle, and both broad-panel and narrow end-view fences. Your town, alley and interiors are unchanged by this demonstration.

## Choose a reusable scene

| Scene under `scenes/objects/` | Appearance | Gameplay |
| --- | --- | --- |
| `fence_cuttable.tscn` | Broad wire-mesh panel | Cut with matching bolt cutters |
| `fence_reinforced.tscn` | Broad solid metal bars | Permanent physical barrier |
| `fence_cuttable_side.tscn` | Narrow end-on wire/post | Cut and fold onto the floor |
| `fence_reinforced_side.tscn` | Narrow reinforced end-on post | Permanent physical barrier |

All four are **64 world pixels tall**, matching the player's scale. Broad panels are 96 world pixels wide; end views are 12. Native PNGs have 48×32 or 6×32 pixels, displayed at 2×. No giant source image or second enlarged export is needed.

The broad view shows the whole fence along the screen. The narrow view is for looking along a fence that crosses the path into/out of the screen. Both are ordinary 2D editor-visible scene nodes.

## Placement

1. Drag the scene into your level. Put cuttable fences under **Interactables**, and permanent ones under **Props** or **Geometry** for clarity.
2. Place the root exactly on the floor: for a floor at Y=620, set the root's Y to **620**. Its artwork and collision extend upward from that point.
3. Leave scale at (1,1). The sprite children already provide the matching 2× art scale. Move or duplicate whole scene roots.
4. Place a `bolt_cutters.tscn` pickup where you want the player to find the tool. Its existing inventory definition takes 3 cells and remains reusable. For disposable cutters, place `scenes/objects/equipment/bolt_cutters_single_use.tscn` instead; both satisfy the same Required Tool. Removal follows the item’s **Use Behavior → Remove After Use** checkbox.
5. Test with F6. A nearby cuttable fence offers **Cut fence**, without revealing a title under the world asset. The reinforced fence offers no interaction.

## Inspector settings on a cuttable fence

- **Required Tool**: inventory requirement ID, default `bolt_cutters`; item variants may match it through Use As Item Id. Empty means no item required.
- **Interaction Radius**, **Prompt Offset**, **Action Label**: nearby interaction presentation.
- **Cut Seconds**: duration of the folding animation, default 0.65.
- **Folded Panel Scale**: amount of remaining wire at the sides in the broad view.
- **Cutting Noise Radius**: hearing event for enemy AI; set 0 for silent cutting.
- **Persistent ID**: optional stable key; leave empty to use scene path plus node path. Give each fence a distinct explicit ID if you set one. Do not reuse an unrelated puzzle/door key.
- **Edge On Break**: already set correctly by the end-view scene; uses a fold-down animation.

The collision remains until cutting finishes. The game then records the open route in `Game.world` and disables the barrier. Later bicycle saves restore the final opened artwork and passable collision; an earlier save restores the closed fence and that slot's inventory. Returning to the scene preserves completed cuts. In-progress animation is transient and is not saved as complete.

Both permanent and uncut wire fences block movement and gun rays. Permanent fences have no damage or unlocking script. The wire fence's gameplay collider covers its panel, including visible mesh holes; these are not bullet-through gaps. New enemy hearing events can be emitted by cutting, without needing a sound asset or changing audio volume.

The old `chained_gate.tscn` path is retained as an alias to the new broad cuttable scene. For old custom instances, move their roots to floor height because the old oversized gate used a center anchor. The legacy powered/key gate in `door.tscn` is retained for existing puzzle/test compatibility; use the new fence scenes for new level design.

See [Reusable and single-use items](ITEM_USE_GUIDE.md) for making variants. Cutting commits removal only after completion; failed cuts leave the tool and route unchanged.
