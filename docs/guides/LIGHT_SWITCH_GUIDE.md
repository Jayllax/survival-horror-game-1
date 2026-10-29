# Room light switches

Place **`scenes/objects/lighting/light_switch.tscn`** wherever the player should be able to turn room lights on and off. It works with the existing nearby Interact action, normally E. No switch has been placed in your levels.

## Connect the lights

1. Drag the switch scene into your level and position the small wall plate near the furniture or doorway you want. The plate is 16×24 world pixels, matching an 8×12 drawing displayed at 2×. Its simple symmetrical shapes use your palette and remain editable nodes.
2. Select **LightSwitch**. Expand **Connections → Connected Lights** in the Inspector and add an array element for each light you want to control.
3. Assign each element using its node picker. Choose a `PointLight2D` or `DirectionalLight2D` in this same level. For one of the supplied interior lamps, you can select the **whole lamp root**, such as CeilingLamp, instead of editing its children. Both its root and its `Light` child are supported. A streetlamp's actual light is its **WarmLight** child.
4. Set **Starting On** for a new game's initial state. Give this room's circuit a unique **Persistent Id**, such as `house01_bedroom_lights`. Keep this ID when moving or renaming the switch so old saves can still identify it.
5. Adjust **Interaction Radius**, **Prompt Offset**, **Turn Off Prompt** and **Turn On Prompt** as needed. Save the level and run it. The nearby prompt changes with the switch position.

Connected Lights are paths relative to the placed switch. Use the picker from the actual level instance, where the other room nodes exist. Editor configuration warnings flag missing connections and unsupported node types. A missing node is skipped at runtime so the remaining connections keep working.

Only assigned lights are switched. Their energy, color, range, shadows and depth settings remain controlled by their normal Inspector settings. The switch does not change the player flashlight, CanvasModulate, camera or unrelated lamps. With the supplied interior lamps, their **Light Enabled** property also follows the switch, so changing their color variant does not accidentally turn them back on. A streetlamp still follows its existing power-channel energy settings when enabled.

## Reveal a clue when the switch is off

**Reveal When Off** is optional. Add existing artwork, a Label or other CanvasItem nodes to this array. These nodes are hidden while the switch is on and shown while it is off. You supply the clue and its wording/artwork; the system creates no puzzle content.

For writing that should glow or remain readable in a dark room, give the clue a **CanvasItemMaterial** with **Light Mode → Unshaded**. A normal lit sprite may still be too dark to see after you turn off the room lights. Avoid assigning a parent that contains the switch or the lights themselves: use just the clue artwork/text.

This reveal follows the circuit's on/off state. It does not measure pixel brightness or detect whether another light or the player flashlight falls on the clue. Its visibility is restored from the switch state when returning to the room or loading a save. For a clue that should always exist and merely become easier to see in the dark, leave this array empty and use your own glowing artwork.

## Save state and linked switches

The existing bicycle save slots remember each visited circuit's on/off state independently. Returning to a room keeps its current state. Saving does not turn lights on, and using a switch does not automatically save. Loading an older save restores that save's state, including clue visibility and switch position. **Starting On** affects circuits not yet recorded in that run; an existing saved circuit state takes priority.

Normally, give each circuit a different **Persistent Id**. To put two switches on one circuit, deliberately give them the **same ID**, matching **Starting On**, and connect them to that circuit's lights. Either switch updates both switch positions. Each linked switch may also control additional lights/reveal nodes belonging to that circuit.

Keep a light on one circuit. Different switch IDs controlling the same light can override one another. Leave an ID empty only if you are happy to use the scene filename and switch node path as its identity; renaming or moving it may then break its association with existing saves.

## Artwork and future puzzle connections

The scene contains ordinary editor-visible Polygon2D artwork under **Artwork**. Hide or remove that child if you already have a switch drawn into your background. You can replace it with your own pixel art; the interaction keeps working. The optional **Artwork/Lever** node moves two pixels up/down to show the current position.

The switch also exposes a **toggled(lights_on)** signal for custom puzzle connections. It fires when the player uses the switch; restored save state does not replay that signal. Normal light control and Reveal When Off need no signal wiring or programming. There is no built-in requirement for an item, fuse or puzzle solution to operate this switch.

## Verification

`GODOT_BIN=/path/to/godot bash tools/check.sh light_switch` checks E interaction, multiple lights, native and supplied lamp types, nearby prompts, held input, independent circuits, paired switches, clue visibility, scene initialization order and independent bicycle saves. Automated test instances are separate from your gameplay levels.
