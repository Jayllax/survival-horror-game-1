# Notes and NPC dialogue

Use Godot **4.7.2 Standard**. Everything below is editable in the Inspector; you do not need to edit scripts or create dialogue nodes at runtime.

## Try the framework first

Open `tests/fixtures/story_sandbox.tscn` and press **F6**. Walk right to the note on the bench, then the NPC, then the save bicycle. The sandbox is separate from your town and contains placeholder writing only. **F5** still starts your existing main menu and town.

Nearby objects show only **Read** or **Talk**, without key hints. Reading opens a centered, scrollable note; conversation opens a box at the bottom of the screen. Both pause the player and enemies. Use **E**, **Enter**, or **Space** to reveal/advance dialogue, or click its Continue button. First press finishes revealing the current line; next press advances. Conversations must be finished: there is no Leave button, and **Esc**, pause and inventory cannot interrupt dialogue. The final Continue/Finish action closes the window. Notes can still be closed with **Esc** or Close. Inventory cannot open over either reader.

The example NPC now uses its own green-shirt palette variant of your current player design, with a six-frame idle animation. Its art has the same head, proportions, native pixel scale and standing height as the player. No player artwork has been changed.

## Place and write a note

1. Drag `scenes/objects/note.tscn` from FileSystem into the level's `Interactables` node. Move it to the desired position in the 2D editor.
2. Select the new Note root. Open the **Document** resource menu and choose **Make Unique**, then click the resource to expand its fields. This prevents editing every note that shares the template.
3. Set **Title** and **Text**. Text accepts paragraphs and line breaks; long documents scroll. Text is displayed literally, including square brackets.
4. Save the document through the resource's menu → **Save As**, for example `res://data/narrative/your_note.tres`. Alternatively, create a new **NoteDocument** resource and drag it into Document.
5. Expand the Note instance in the scene tree. To change its artwork, enable **Editable Children** from its scene-tree context menu, then replace the `Sprite2D` texture. Keep the root where you want interaction proximity measured.
6. Adjust **Interaction Radius**, **Prompt Offset**, and optionally **Action Label** on the root. The action should stay generic, such as Read, rather than revealing the note's title.

The reader shows the title only after interaction. Reading adds no inventory item and does not remove the note; it remains available to read again. A blank document safely disables its interaction.

Existing Clue and Examine objects still use their original description panel. Keep using Clue for the existing switchboard reference logic; the new Note scene does not automatically activate a puzzle circuit.

## Create speakers

In FileSystem, right-click `data/narrative/speakers` → **Create New → Resource**, search for **DialogueSpeaker**, and save a resource for each character. Set **Display Name** and **Text Color**. Both the speaker's name and dialogue text use this color. The existing `player.tres` and `example_npc.tres` are examples.

Reuse the same speaker resource in all that character's lines. Editing it updates their name/color consistently. A speaker resource controls text identity, not which world sprite is displayed: a single conversation can include the NPC, player, and other voices.

## Write a conversation

1. Create a **DialogueSequence** resource in `data/narrative`, or duplicate `example_conversation.tres` and give it a new filename.
2. Expand its **Lines** array. Set its size to the number of dialogue entries you want.
3. For each entry, use its resource dropdown → **New DialogueLine**, then expand it. Assign a **Speaker** resource and write the multiline **Text**.
4. Repeat in speaking order. Reorder lines by dragging their array handles. Entries without text are skipped. Leaving Speaker empty produces an unnamed line with the UI's default color.
5. Save the sequence. If you duplicated an existing sequence, make its embedded line resources unique before rewriting them; keep speaker resources shared deliberately.

Each entry is one displayed block, rather than one sentence or one physical text line. Long dialogue blocks scroll inside the box. Lines can optionally contain player responses with their own branches and saved story flags. See [DIALOGUE_CHOICES_GUIDE.md](DIALOGUE_CHOICES_GUIDE.md) for Inspector steps and conditional items or passages.

## Place an NPC

Drag `scenes/actors/npc.tscn` into the level's `Actors` node. Place its root at the same height as the player's center: with the example ground at Y = 620, the character root is Y = 588. Assign your **Dialogue** sequence in the Inspector. Optionally assign **Repeat Dialogue** for subsequent conversations; leaving it empty replays the first conversation.

Enable **Editable Children** and select **Body → Sprite Frames** to replace the animation artwork. The supplied `data/animations/npc_frames.tres` uses `art/pixel/npc_motion.png`: **192×80**, six 32×40 cells across and two rows (**idle**, **walk**). Its editable Pixilart master is [npc_motion.pixil](../../art/pixlart/cast_animation/npc_motion.pixil); the [cast animation pack](../downloads/Ignotum-NPC-enemy-animations.zip) includes individual timeline files. Use **Make Unique → Save As** on SpriteFrames before editing one particular NPC's shared art.

Body is an **AnimatedSprite2D** with Position **(-1,32)**, Offset **(0,-20)**, Scale **(2,2)** and white Modulate. Idle plays automatically. Keep the same padding and ground baseline when replacing frames. For a still drawing, use a single frame in the idle animation. Older custom NPCs with a Sprite2D Body still turn correctly when spoken to.

NPCs stand in place and face the player when spoken to. **Face Player** can disable that turn. They do not block the walking plane and do not have combat, patrols or navigation. The walk clip is supplied as editable artwork for future behavior, not automatic walking. Their appearance, origin and interaction settings remain editable. You can make a reusable character scene with **Scene → Save As** and place it wherever you need.

## Track progress and save it

Each placed Note/NPC automatically records progress in the existing saved world state. Notes record that they have been opened. NPCs record completion **only after finishing the last line**. The player must finish the conversation before returning to gameplay. Finished NPCs select Repeat Dialogue on the next interaction.

By default identity comes from the level and node path. Before releasing content, give important objects a unique **Persistent Id**, for example `station_notice_01` or `station_attendant`. Keep those IDs stable when rearranging or renaming levels/nodes. Duplicating an object also duplicates its ID: clear or change it unless you intend the objects to share progress. Reusing the same conversation resource alone does not share completion between NPCs.

The internal keys are `note:<Persistent Id>` and `dialogue:<Persistent Id>`. **Completion Flag** optionally sets another exact named flag, such as `story:met_attendant`, when read/completed. This provides a saved hook for later puzzle/quest code. It does not by itself open doors, grant items, or create a journal. A new game clears these flags.

Progress is stored only when the player saves at a bicycle. Loading an older slot restores its earlier unread/unfinished state; another slot can independently retain later progress. Conversation position and the currently open text box are not saved: the next interaction begins the appropriate first/repeat conversation from its first line. The existing save format requires no conversion.

## Adjust presentation

Open `scenes/ui/story_ui.tscn` to change the centered **NotePanel** or bottom **DialoguePanel** in the 2D editor. Every panel, text field, and button is an authored node. They are hidden by default; temporarily turn their visibility on to preview layout, then restore it before saving. The scene is instanced once in the existing HUD.

Select the StoryUI root for **Characters Per Second** (45 by default; 0 means instant text) and **Default Text Color** for unnamed lines. Speaker colors come from the assigned speaker resource. Dialogue leaves the world visible; the note reader uses the HUD's dim backdrop. Gameplay is paused while either is open.

## Quick checks after writing

- Test each note/NPC with F6 in its actual level, including proximity and long text.
- Test reveal, advance, blocked dialogue cancellation, note closing, repeat conversations, and speaker changes.
- Save before and after finishing a conversation in separate bicycle slots, then load both.
- Test through normal level transitions as well as F6. Keep exactly one Player and one HUD per location.

For automated checks, `bash tools/check.sh aiming narrative` imports the project and tests real interactions, input safety, and independent saved progress with isolated test saves. Use `GODOT_BIN=/path/to/godot bash tools/check.sh aiming narrative` if the engine is not on your PATH. The older suites assume original template item values; they are not needed to test your new narrative content.

For fonts and optional per-document typewriter styling, see [FONT_GUIDE.md](FONT_GUIDE.md).

## Player responses and story conditions

Expand a DialogueLine's **Choices** array and add **DialogueChoice** resources. Each response can set a named flag and point to another DialogueSequence. `scenes/objects/story/world_flag_condition.tscn` connects those saved flags to editor-placed items, entrances, artwork and collision shapes. Full setup: [DIALOGUE_CHOICES_GUIDE.md](DIALOGUE_CHOICES_GUIDE.md).
