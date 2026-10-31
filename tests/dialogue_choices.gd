extends Node
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
    checks += 1
    if ok: print("PASS: " + text)
    else:
        failures += 1
        push_error("FAIL: " + text)
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
    Game.reset_run()
    var room: Node2D = load("res://tests/fixtures/dialogue_choices_sandbox.tscn").instantiate()
    get_tree().root.add_child(room)
    get_tree().current_scene = room
    await frames(8)
    var player: CharacterBody2D = room.get_node("Actors/Player")
    var npc: Area2D = room.get_node("Actors/NPC")
    var hud: CanvasLayer = room.get_node("HUD")
    var ui: Control = hud.get_node("StoryUI")
    var pickup: Area2D = room.get_node("Interactables/ConditionalAmmo")
    var entrance: Area2D = room.get_node("Interactables/ConditionalEntrance")
    var shape: CollisionShape2D = room.get_node("Geometry/ChoiceBarrier/Shape")
    check(not pickup.visible and not shape.disabled, "An absent story flag hides the reward and keeps the passage blocked")
    check(not entrance.get_meta("story_interaction_enabled",true) and entrance.visible, "A gated entrance remains visible while its interaction is disabled")
    player.global_position = pickup.global_position
    await frames(5)
    check(player.nearest != pickup, "A hidden pickup never offers an invisible interaction")
    player.global_position = entrance.global_position
    await frames(5)
    check(player.nearest != entrance, "A flag-disabled entrance cannot be selected for interaction")
    var bike: Area2D = room.get_node("Interactables/SaveBicycle")
    player.global_position = bike.global_position + Vector2(-35,-32)
    await frames()
    check(Game.save_slot(0,bike), "Save A captures the world before a response is chosen")
    var before := FileAccess.get_file_as_string(Game.slot_path(0))
    player.global_position = npc.global_position + Vector2(-35,0)
    await frames()
    await key(KEY_E)
    check(ui.is_dialogue() and not ui.get_node("DialoguePanel/Choices").visible, "Answers stay hidden while the question is being revealed")
    await key(KEY_E)
    check(ui.choice_buttons.size() == 2 and not ui.get_node("DialoguePanel/Continue").visible, "A fully revealed question shows its two answers instead of Continue")
    check(get_viewport().gui_get_focus_owner() == ui.choice_buttons[0], "The first answer receives keyboard focus")
    await key(KEY_E,true)
    check(ui.choice_buttons.size() == 2 and not Game.world.has("dialogue_choice:framework_accept"), "Held key repeats cannot accidentally select an answer")
    await key(KEY_ESCAPE)
    await key(KEY_TAB)
    check(ui.is_dialogue() and get_tree().paused and ui.choice_buttons.size() == 2 and not hud.get_node("Root/InventoryPanel").visible, "Escape and inventory cannot bypass a required choice")
    await key(KEY_DOWN)
    check(get_viewport().gui_get_focus_owner() == ui.choice_buttons[1], "Arrow keys can select another response")
    await key(KEY_E)
    check(ui.body.text.begins_with("Second test branch"), "Confirming the focused answer enters its own dialogue branch")
    check(Game.world.get("dialogue_choice:framework_decline",false) and not Game.world.get("story:framework_path",true), "The selected response records its ID and false flag value")
    check(not Game.world.get("dialogue_choice:framework_accept",false) and not pickup.visible and not shape.disabled, "Unselected answers have no effects")
    check(not npc.has_completed(), "Selecting an answer does not complete the conversation before its branch finishes")
    await key(KEY_ESCAPE)
    check(ui.is_dialogue(), "Branch dialogue cannot be abandoned either")
    ui.characters_per_second = 0
    if ui.body.visible_characters >= 0: await key(KEY_E)
    await key(KEY_E)
    check(not ui.is_open() and npc.has_completed(), "Finishing the branch closes dialogue and records NPC completion")
    await key(KEY_E)
    check(ui.choice_buttons.size() == 2, "The NPC can replay its question when no repeat sequence is assigned")
    ui.choice_buttons[0].pressed.emit()
    await frames()
    check(ui.body.text.begins_with("First test branch") and ui.is_dialogue(), "Clicking a response button selects the other branch")
    check(Game.world.get("dialogue_choice:framework_accept",false) and Game.world.get("story:framework_path",false), "The accepted response records its stable ID and true story flag")
    check(pickup.visible and shape.disabled and not room.get_node("Geometry/ChoiceBarrier/Artwork").visible, "The choice reveals the editor-placed item and opens the editor-placed barrier")
    check(entrance.get_meta("story_interaction_enabled",false), "The same flag enables an existing entrance")
    check(get_tree().paused, "World consequences do not resume movement before the branch is finished")
    await key(KEY_E)
    check(not ui.is_open() and not get_tree().paused, "The final branch line returns normally to gameplay")
    check(npc.dialogue.lines[0].choices.size() == 2, "Playing branches never mutates shared dialogue resources")
    player.global_position = bike.global_position + Vector2(-35,-32)
    await frames()
    check(Game.save_slot(1,bike), "Save B captures selected answers and their world consequences")
    check(FileAccess.get_file_as_string(Game.slot_path(0)) == before, "Later choices never modify an older save file")
    check(Game.load_slot(0), "The earlier choice snapshot loads")
    await frames(10)
    room = get_tree().current_scene
    check(not Game.world.has("dialogue_choice:framework_accept") and not room.get_node("Interactables/ConditionalAmmo").visible and not room.get_node("Geometry/ChoiceBarrier/Shape").disabled, "Save A restores the unchosen state, hidden item and closed barrier")
    check(Game.load_slot(1), "The later choice snapshot loads")
    await frames(10)
    room = get_tree().current_scene
    player = room.get_node("Actors/Player")
    npc = room.get_node("Actors/NPC")
    hud = room.get_node("HUD")
    ui = hud.get_node("StoryUI")
    pickup = room.get_node("Interactables/ConditionalAmmo")
    check(Game.world.get("dialogue_choice:framework_accept",false) and Game.world.get("dialogue_choice:framework_decline",false) and pickup.visible and room.get_node("Geometry/ChoiceBarrier/Shape").disabled, "Save B restores choice history, flag values and conditional objects independently")
    player.global_position = pickup.global_position
    await frames(5)
    check(player.nearest == pickup, "The revealed reward becomes normally interactable")
    var normal_top: float = ui.get_node("DialoguePanel").offset_top
    var line := DialogueLine.new()
    line.text = "Long answer list for scrolling and keyboard navigation."
    for i in 8:
        var option := DialogueChoice.new()
        option.text = "Response %d — a longer response that should fit within its selectable button." % (i+1)
        option.choice_id = "long_response_%d" % i
        line.choices.append(option)
    var sequence := DialogueSequence.new()
    sequence.lines = [line]
    ui.characters_per_second = 0
    check(hud.show_dialogue(sequence,npc) and ui.choice_buttons.size() == 8, "Choice lists support more than a fixed number of responses")
    await frames()
    var scroll: ScrollContainer = ui.get_node("DialoguePanel/Choices")
    check(scroll.get_v_scroll_bar().max_value > scroll.size.y, "Long answer lists remain accessible through scrolling")
    for i in 7: await key(KEY_DOWN)
    check(get_viewport().gui_get_focus_owner() == ui.choice_buttons[7] and scroll.scroll_vertical > 0, "Keyboard focus scrolls down to an offscreen answer")
    await key(KEY_SPACE)
    check(not ui.is_open() and Game.world.get("dialogue_choice:long_response_7",false), "Space selects the focused last answer and can finish a final-line choice")
    check(is_equal_approx(ui.get_node("DialoguePanel").offset_top,normal_top), "Closing choices restores the original dialogue panel layout")
    check(not Game.world.has("dialogue_choice:long_response_0"), "Only the selected answer is saved from a long list")
    var invalid := DialogueChoice.new()
    invalid.text = "Invalid branch"
    invalid.next_dialogue = DialogueSequence.new()
    var blank := DialogueChoice.new()
    var safe_line := DialogueLine.new()
    safe_line.text = "Invalid responses are skipped safely."
    safe_line.choices = [null, blank, invalid]
    var safe_sequence := DialogueSequence.new()
    safe_sequence.lines = [safe_line]
    check(hud.show_dialogue(safe_sequence,npc) and ui.choice_buttons.is_empty() and ui.get_node("DialoguePanel/Continue").visible, "Empty responses and empty branch targets cannot trap a conversation")
    await key(KEY_E)
    check(not ui.is_open(), "A line with no valid responses still finishes normally")
    var set_line := DialogueLine.new()
    set_line.text = "Continue in the same sequence."
    var set_choice := DialogueChoice.new()
    set_choice.text = "Continue"
    set_choice.set_flag = "story:same_sequence"
    set_line.choices = [set_choice]
    var following := DialogueLine.new()
    following.text = "The following original line."
    var same := DialogueSequence.new()
    same.lines = [set_line,following]
    hud.show_dialogue(same,npc)
    await key(KEY_E)
    check(ui.is_dialogue() and ui.line_index == 1 and ui.body.text == following.text and Game.world.get("story:same_sequence",false), "An answer with no branch target continues the original sequence")
    await key(KEY_E)
    room.queue_free()
    get_tree().current_scene = null
    GameAudio.stop_all()
    await get_tree().create_timer(0.2).timeout
    print("IGNOTUM DIALOGUE CHOICES: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures == 0 else 1)
