# Conversation choices and story flags

Use Godot 4.7.2 Standard. The Inspector controls the conversation content and consequences; no story has been added to your campaign.

## Add player responses

1. Open the NPC's **Dialogue** resource, then expand its **Lines** array.
2. Expand the line after which the player should answer. Write the NPC's question in its **Text** field and select its **Speaker** normally.
3. Expand that line's **Choices** array and set its size, for example **2**.
4. For each entry, choose **New DialogueChoice** and expand it.
5. Fill in the following fields and save the resource.

| Field | Meaning |
| --- | --- |
| **Text** | The answer shown on the response button. It is not automatically added as a spoken player line. |
| **Choice Id** | Optional unique, stable ID, such as `jax_answer_help`. Records that this response was selected. |
| **Set Flag** | Optional exact story flag, such as `story:jax_helped`. |
| **Flag Value** | The value to write: checked means true, unchecked means false. |
| **Next Dialogue** | Optional saved DialogueSequence to play after this answer. |
| **Return After Branch** | On by default: resume the next parent line after that sequence ends. Turn off only to replace the rest of the conversation. |

For a branch, create a separate DialogueSequence with its own lines and assign it to **Next Dialogue**. It starts at its first playable line, then **automatically returns to the parent conversation's next line**. Existing choices also use this behavior without being rewritten. For example, a choice on array index **5** plays its branch, then resumes at parent index **6**.

You can put more choices inside a branch: a nested branch returns to its own next line, then the outer branch returns to the main conversation. A choice at the end of a branch still returns to any remaining outer conversation. The final **Finish** action appears only when no parent lines remain. To intentionally replace all remaining dialogue with a different ending, uncheck **Return After Branch** on that particular choice.

To speak the player's chosen answer aloud, include a player-speaker DialogueLine in the branch. Response-button text itself is not a separate voiced line.

Leave **Next Dialogue** empty to continue with the next line of the current sequence. If this was the final line, selecting an answer finishes the conversation. A line with no choices behaves as before. Blank choices and branches with no playable lines are skipped safely.

Answers appear after the question finishes revealing. Click a response, or move focus with the arrow keys and confirm with E/Enter/Space. Long lists scroll and long button text wraps. The player must select a response and finish its branch: there is no Leave button, and Escape, pause and inventory cannot abandon the conversation. The final Finish action returns to gameplay. Notes retain their Close button and normal Escape behavior.

## Choice IDs and flags

Choosing `jax_answer_help` records the boolean world key `dialogue_choice:jax_answer_help`. This is historical: if a replayed conversation later chooses another answer, both history IDs can be true. Use **Set Flag** when you want a current, reversible condition, such as `story:jax_helped` set true by one response and false by another.

Names are case-sensitive. Use a `story:` prefix for your own flags to avoid existing item, power, puzzle and saved-object keys. Reuse the exact same flag name wherever you want the same condition. Other responses have no effects until selected.

Flags and IDs change in the current run immediately. They are written to disk when the player saves at a bicycle. Loading an older slot restores that slot's choices and consequences independently. The conversation's reading position is not saved; NPC completion is recorded only after the entire conversation, including resumed parent lines, finishes. The existing Repeat Dialogue behavior still applies afterwards.

## Animate an NPC during conversation

Movement, combat and enemy AI remain paused so conversations are safe. The speaking NPC's **AnimatedSprite2D** can continue its idle and talking clips independently.

Select the **NPC root → Conversation Animation**:

| Field | Meaning |
| --- | --- |
| **Animate During Dialogue** | Enable the visual animation while gameplay is paused. |
| **Dialogue Body Path** | Path to the AnimatedSprite2D, normally `Body`. |
| **Idle Animation** | Clip used while listening or waiting for an answer, normally `idle`. |
| **Talking Animation** | Your speaking clip's exact name, normally `talking`; `NPC_talking` or another custom name also works. |
| **Dialogue Speakers** | Speaker resources that represent this NPC. Add every alias used in their lines. Empty means every line can animate this NPC. |

Jax is already configured for **both `unknown.tres` and `jax_dole.tres`**. His existing artwork and `talking` animation are unchanged. He idles on `you.tres` lines and while waiting for a text-only response selection. Other NPCs can have their own clip names and speaker resources. Missing or empty talking clips fall back to idle. NPCs stay in place; this adds no walking behavior.

For text-only lines, the talking clip runs until the next line or response selection. For voiced lines, it runs while their recording plays, then returns to idle. Closing or leaving the scene restores the original animation/playback and process mode. Ordinary notes retain their existing paused reader and transparent background.

## Add recorded voice lines

1. Put one recording per line into `audio/voice/`, optionally in character folders such as `audio/voice/jax/`.
2. Expand the relevant **DialogueLine**, including any lines inside a choice's Next Dialogue sequence.
3. Expand **Voice (optional)** and drag a `.wav`, `.ogg` or `.mp3` into **Voice Audio**.
4. Adjust **Voice Volume Db** if that individual line needs balancing. Leave Voice Audio empty for a text-only line.

Playback begins as soon as the line appears and continues while text reveals. Pressing Reveal does not restart or stop the recording. Advancing to another line, selecting a response or finishing dialogue stops the old recording before playing a new one. Imported looping settings are ignored for voice playback, without editing the source asset.

Lines still advance manually: when the recording ends, its text stays on screen until the player continues. Finishing the text reveal can show response buttons while the recording finishes; choosing an answer can skip its remaining audio. There is no overlapping speech or automatic line skipping. The authored **StoryUI/Voice** player continues while the game is paused and uses the separate **Voice** audio bus beneath Master. Existing Master volume controls still apply.

No recorded or generated speech has been added; this is the framework for your own future performances.

## Response-box sizing

The response list now fits the actual button heights and keeps a small bottom margin. One or two answers no longer reserve the old fixed empty area. Long answers wrap; longer lists scroll. The question retains its own scrollable area above the responses. The original dialogue-box layout returns after the response is selected.

On `scenes/ui/story_ui.tscn`'s root, **Response Layout → Choice List Max Height** and **Choice Text Max Height** cap the response list and question area. Smaller windows reduce the layout to fit. The normal dialogue panel, note appearance, fonts and button styling remain authored in their existing scenes.

## Make objects react through the Inspector

Add `scenes/objects/story/world_flag_condition.tscn` to your level. It is an invisible child component with no artwork or collision of its own. It can be a child of a prop or another existing level node.

1. Set **Flag Id** to the exact flag, such as `story:jax_helped`.
2. Keep **Required Value** checked to react when it is true; uncheck it to react when false. Missing flags count as false.
3. Expand one or more target arrays, add entries, and select/drag nodes from the scene tree into their NodePath fields. Paths are relative to this component.

| Target array | When the flag matches Required Value |
| --- | --- |
| **Visible When Met** | Shows these CanvasItem nodes; hides them otherwise. |
| **Visible When Unmet** | Hides these nodes; shows them otherwise. |
| **Enable Interaction When Met** | Enables these existing entrance/interactable roots; disables their interaction otherwise, keeping their artwork visible. |
| **Disable Collision When Met** | Disables these CollisionShape2D/CollisionPolygon2D nodes; enables them otherwise. |
| **Enable Collision When Met** | Enables these collision shapes; disables them otherwise. |

### Reveal an item

Place the ordinary pickup in the editor. Add its **whole root** to Visible When Met, not just its Sprite2D. While hidden, it offers no invisible interaction. Its normal collection and save behavior remains intact: an already-collected pickup is not recreated by a flag change.

### Open or close a passage

Place the door artwork and a StaticBody2D with a fitted CollisionShape2D. Add the closed artwork to Visible When Unmet and the shape to Disable Collision When Met. A matching flag hides the closed artwork and removes the barrier; a nonmatching flag restores both. You can also select alternate open artwork in Visible When Met. This switches states without adding an opening animation.

For a background door that travels to another scene, add the existing **Entrance root** to Enable Interaction When Met. Its normal destination, key and power requirements still apply when enabled. To show a locked message while disabled, place a separate Examine interaction and use another condition with the opposite Required Value to enable that message only while locked.

Use one condition controller per target, and avoid assigning a self-unlocking Door/CuttableFence collider to a second controller that also manages that same collider. Visibility targets control appearance; add collision shapes separately when a solid object must become passable. Empty Flag Id leaves authored targets unchanged.

The component reads saved flags when a location loads and updates when choices change them. It never creates level geometry or spawns objects through code: all target items, artwork, entrances and collision shapes remain editable in the scene.

## Test separately

Open `tests/fixtures/dialogue_choices_sandbox.tscn` and press F6. This development-only fixture demonstrates two placeholder responses, different branches, an optional ammo pickup, an entrance and a passage blocker. It is not connected to your campaign. The bicycle is before the question so you can compare saved states.

Optional automated checks: `GODOT_BIN=/path/to/godot bash tools/check.sh narrative dialogue_choices dialogue_flow`. They cover input, nested return/replacement, both real Jax routes, selected-only effects, compact layout/resizing, paused actor animation, voice lifecycle, completion and independent save slots. Voice timing uses silent test-only streams; no placeholder speech is included in the game.

For fonts, transparent note panels and per-note typewriter text, see [FONT_GUIDE.md](FONT_GUIDE.md).

[View the response UI preview](../previews/dialogue-choices.png). Change response button fonts and styling in `scenes/ui/dialogue_choice_button.tscn`; the panel and scrolling layout are in `scenes/ui/story_ui.tscn`.
