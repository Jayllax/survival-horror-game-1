extends Node
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
    checks += 1
    if ok: print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)

func frames(count: int = 3) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame

func key(code: Key, echo: bool = false) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = true
    event.echo = echo
    Input.parse_input_event(event)
    await frames(2)
    event = event.duplicate()
    event.pressed = false
    event.echo = false
    Input.parse_input_event(event)
    await frames(2)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    for index in Game.SAVE_SLOT_COUNT:
        if FileAccess.file_exists(Game.slot_path(index)):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(index)))
    Game.reset_run()
    preload("res://tests/support/loadout.gd").handgun()
    var sandbox: Node2D = load("res://tests/fixtures/story_sandbox.tscn").instantiate()
    get_tree().root.add_child(sandbox)
    get_tree().current_scene = sandbox
    await frames(8)
    var player: CharacterBody2D = sandbox.get_node("Actors/Player")
    var npc: Area2D = sandbox.get_node("Actors/NPC")
    var note: Area2D = sandbox.get_node("Interactables/Note")
    var bike: Area2D = sandbox.get_node("Interactables/SaveBicycle")
    var hud: CanvasLayer = sandbox.get_node("HUD")
    var ui: Control = hud.get_node("StoryUI")
    check(not ui.is_open() and not hud.any_panel_open(), "New narrative UI stays hidden during exploration")
    check(not player.get_node("Camera2D").enabled and sandbox.get_node("Camera2D").enabled, "Sandbox uses its authored fixed camera")
    var npc_body: AnimatedSprite2D = npc.get_node("Body")
    var npc_frames := npc_body.sprite_frames
    check(npc_frames.get_frame_texture("idle",0).get_size() == Vector2(32,40) and npc_body.scale == Vector2(2,2) and npc_body.modulate == Color.WHITE, "NPC uses native player-sized art with palette colors rather than a global tint")
    check(npc_frames.get_frame_count("idle") == 6 and npc_body.animation == &"idle" and npc_body.is_playing(), "Placed NPC starts its editable breathing animation automatically")
    var idle_frame := npc_body.frame
    var idle_progress := npc_body.frame_progress
    await get_tree().create_timer(0.15).timeout
    check(npc_body.frame != idle_frame or npc_body.frame_progress > idle_progress, "NPC idle playback advances during exploration")
    check(note.is_in_group("interactable") and npc.is_in_group("interactable"), "Placed notes and NPCs join the existing interaction system")
    check(not hud.get_node("Root/Prompt").visible, "No narrative interaction prompt appears out of range")
    player.global_position = bike.global_position + Vector2(-40,-32)
    await frames()
    check(Game.save_slot(0,bike), "Save A records progress before reading or speaking")
    var before_file := FileAccess.get_file_as_string(Game.slot_path(0))
    var inventory_before := Game.inventory.snapshot()
    player.global_position = note.global_position + Vector2(-25,32)
    await frames()
    check(hud.get_node("Root/Prompt").text == "Read", "Near a note the prompt offers Read without revealing its title")
    await key(KEY_E)
    check(ui.is_open() and ui.mode == "note" and get_tree().paused, "E opens the placed note and pauses gameplay")
    check(ui.get_node("NotePanel/Title").text == note.document.title and ui.get_node("NotePanel/Body").text == note.document.text, "Reader shows the resource's full title and multiline text")
    check(note.has_completed() and Game.inventory.snapshot() == inventory_before, "Reading records progress without using inventory space")
    check(hud.get_node("Root/Backdrop").visible and not hud.get_node("Root/Prompt").visible, "Reading dims the world and hides interaction feedback")
    await key(KEY_TAB)
    check(ui.is_open() and not hud.get_node("Root/InventoryPanel").visible, "Inventory cannot open on top of a note")
    var frozen_position := player.global_position
    Input.action_press("move_right")
    Input.action_press("aim")
    Input.action_press("shoot")
    await frames(8)
    check(player.global_position == frozen_position and Game.magazine == 6, "Reading suspends movement and shooting")
    Input.action_release("move_right")
    await key(KEY_E)
    await frames(20)
    check(not ui.is_open() and not get_tree().paused and Game.magazine == 6, "Closing with E neither reopens the note nor fires a held mouse button")
    Input.action_release("aim")
    Input.action_release("shoot")
    await frames()
    await key(KEY_E)
    check(ui.mode == "note", "Read notes remain available for rereading")
    await key(KEY_ESCAPE)
    check(not ui.is_open() and not hud.get_node("Root/PausePanel").visible, "Escape closes a note without opening the pause menu")
    player.global_position = npc.global_position + Vector2(-40,0)
    await frames()
    check(hud.get_node("Root/Prompt").text == "Talk", "Near an NPC the prompt offers Talk")
    await key(KEY_E)
    check(ui.is_dialogue() and get_tree().paused and ui.line_index == 0, "E starts the NPC's first dialogue at line one")
    check(npc.get_node("Body").flip_h, "NPC faces the interacting player")
    check(not hud.get_node("Root/Backdrop").visible and ui.get_node("DialoguePanel").get_global_rect().position.y > 300, "Conversation occupies the bottom box while keeping the world visible")
    var line: DialogueLine = npc.dialogue.lines[0]
    check(ui.get_node("DialoguePanel/Speaker").text == line.speaker.display_name, "Each line displays the chosen speaker name")
    check(ui.body.get_theme_color("default_color") == line.speaker.text_color and ui.get_node("DialoguePanel/Speaker").get_theme_color("font_color") == line.speaker.text_color, "Speaker resource colors both the name and spoken text")
    check(ui.body.visible_characters >= 0 and ui.body.visible_characters < ui.body.get_total_character_count(), "Dialogue reveals text progressively")
    await key(KEY_E, true)
    check(ui.line_index == 0 and ui.body.visible_characters >= 0, "Held key repeats do not skip dialogue lines")
    await key(KEY_E)
    check(ui.line_index == 0 and ui.body.visible_characters == -1, "First advance reveals the current line before moving on")
    await key(KEY_ENTER)
    check(ui.line_index == 1 and ui.get_node("DialoguePanel/Speaker").text == npc.dialogue.lines[1].speaker.display_name, "Enter advances to the next selected speaker")
    check(ui.body.get_theme_color("default_color") == npc.dialogue.lines[1].speaker.text_color, "Text color changes with the speaker")
    await key(KEY_ESCAPE)
    check(not ui.is_open() and not npc.has_completed(), "Leaving early cancels without recording conversation completion")
    check(npc.current_dialogue() == npc.dialogue, "Cancelled conversation keeps the first conversation available")
    ui.characters_per_second = 0
    await key(KEY_E)
    check(ui.line_index == 0 and ui.body.visible_characters == -1, "Zero character speed displays each full line instantly")
    npc.completion_flag = "story:test_conversation"
    for i in npc.dialogue.playable_lines().size():
        await key(KEY_E)
    check(not ui.is_open() and not get_tree().paused and npc.has_completed(), "Finishing the last line records completion and resumes gameplay")
    check(Game.world.get("story:test_conversation",false), "Optional designer completion flag records future story progress")
    check(npc.dialogue.lines.size() == 3 and not npc.dialogue.lines[0].text.is_empty(), "Displaying and closing does not modify shared content resources")
    await key(KEY_E)
    check(ui.dialogue_lines.size() == 1 and ui.body.text == npc.repeat_dialogue.lines[0].text, "Completed NPC uses the designer's repeat dialogue")
    ui.get_node("DialoguePanel/Continue").pressed.emit()
    await frames()
    check(not ui.is_open(), "Continue button also finishes conversations")
    var unnamed := DialogueLine.new()
    unnamed.text = "[Plain text] without a speaker."
    var sequence := DialogueSequence.new()
    sequence.lines = [null, DialogueLine.new(), unnamed]
    check(hud.show_dialogue(sequence,npc), "Empty/null entries are skipped without breaking a conversation")
    check(ui.dialogue_lines.size() == 1 and ui.get_node("DialoguePanel/Speaker").text.is_empty() and ui.body.text == unnamed.text and not ui.body.bbcode_enabled, "Unnamed lines use safe plain text and the default color")
    check(not hud.show_story_note(note.document,note), "A second narrative interaction cannot replace an open conversation")
    frozen_position = player.global_position
    await key(KEY_SPACE)
    check(not ui.is_open() and player.global_position.is_equal_approx(frozen_position), "Space can finish dialogue without leaking its jump binding into gameplay")
    var long_note := NoteDocument.new()
    long_note.title = "LONG NOTE"
    long_note.text = "A long paragraph for the scrollable note reader.\n\n".repeat(60)
    check(hud.show_story_note(long_note,note), "Long notes open in the same reusable reader")
    await frames()
    check(ui.get_node("NotePanel/Body").get_content_height() > ui.get_node("NotePanel/Body").size.y and ui.get_node("NotePanel/Body").scroll_active, "Long note text remains available through scrolling")
    ui.get_node("NotePanel/Close").pressed.emit()
    hud.open_inventory()
    check(not hud.show_dialogue(npc.dialogue,npc), "Conversation cannot replace an open inventory")
    hud.close_panels()
    check(not hud.show_dialogue(DialogueSequence.new(),npc) and not get_tree().paused, "Empty dialogue fails safely without pausing")
    player.global_position = bike.global_position + Vector2(-40,-32)
    await frames()
    check(Game.save_slot(1,bike), "Save B records note, conversation, and custom progress flags")
    check(FileAccess.get_file_as_string(Game.slot_path(0)) == before_file, "New narrative progress never changes the older slot")
    check(Game.load_slot(0), "Can load the earlier story snapshot")
    await frames(10)
    sandbox = get_tree().current_scene
    npc = sandbox.get_node("Actors/NPC")
    note = sandbox.get_node("Interactables/Note")
    check(not note.has_completed() and not npc.has_completed() and not Game.world.get("story:test_conversation",false), "Earlier slot restores unread notes and unfinished conversations independently")
    check(Game.load_slot(1), "Can load the later story snapshot")
    await frames(10)
    sandbox = get_tree().current_scene
    npc = sandbox.get_node("Actors/NPC")
    note = sandbox.get_node("Interactables/Note")
    check(note.has_completed() and npc.has_completed() and Game.world.get("story:test_conversation",false), "Later slot restores read notes, completed conversations, and custom story flags")
    check(npc.current_dialogue() == npc.repeat_dialogue, "Repeat dialogue selection survives actual save/load scene replacement")
    hud = sandbox.get_node("HUD")
    hud.show_note("Legacy clue text")
    check(hud.get_node("Root/NotePanel").visible and get_tree().paused, "Existing clue and examine panels keep working")
    hud.close_panels()
    sandbox.queue_free()
    get_tree().current_scene = null
    await frames()
    print("IGNOTUM NARRATIVE: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures == 0 else 1)
