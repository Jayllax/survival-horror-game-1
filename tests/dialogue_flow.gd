extends Node
var checks := 0
var failures := 0
var room: Node2D
var npc: Area2D
var player: CharacterBody2D
var ui: Control
var hud: CanvasLayer
var jax: DialogueSpeaker
var you: DialogueSpeaker

func check(ok: bool, description: String) -> void:
    checks += 1
    if ok:
        print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)

func frames(count: int = 3) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame

func text_line(text: String, speaker: DialogueSpeaker = null) -> DialogueLine:
    var result := DialogueLine.new()
    result.text = text
    result.speaker = speaker
    return result

func sequence(lines: Array[DialogueLine]) -> DialogueSequence:
    var result := DialogueSequence.new()
    result.lines = lines
    return result

func choice(text: String, next: DialogueSequence = null) -> DialogueChoice:
    var result := DialogueChoice.new()
    result.text = text
    result.next_dialogue = next
    return result

func silent_recording(seconds: float) -> AudioStreamWAV:
    var clip := AudioStreamWAV.new()
    clip.format = AudioStreamWAV.FORMAT_16_BITS
    clip.mix_rate = 8000
    var data := PackedByteArray()
    data.resize(int(seconds * 8000) * 2)
    data.fill(0)
    clip.data = data
    return clip

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    Game.reset_run()
    room = load("res://scenes/levels/house_03_2.tscn").instantiate()
    get_tree().root.add_child(room)
    get_tree().current_scene = room
    npc = room.get_node("Actors/NPC")
    player = room.get_node("Actors/Player")
    hud = room.get_node("HUD")
    ui = hud.get_node("StoryUI")
    jax = load("res://data/narrative/speakers/jax_dole.tres")
    you = load("res://data/narrative/speakers/you.tres")
    ui.characters_per_second = 0
    await frames(8)
    await verify_actual_jax_branches()
    await verify_nested_return_and_replacement()
    await verify_animation()
    await verify_compact_layout()
    await verify_voice()
    await verify_lifecycle_cleanup()
    print("IGNOTUM DIALOGUE FLOW: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)

func verify_actual_jax_branches() -> void:
    var parent: DialogueSequence = npc.dialogue
    var original_texts: Array[String] = []
    for entry in parent.lines:
        original_texts.append(entry.text)
    check(parent.lines.size() == 16 and parent.lines[5].choices.size() == 2, "The designer's real Jax conversation has sixteen parent lines and both authored choices")
    for route in 2:
        Game.world.erase(npc.state_key())
        check(hud.show_dialogue(parent, npc), "Jax route %d starts through the real HUD" % route)
        for i in 5:
            ui.advance()
        check(ui.line_index == 5 and ui.choice_buttons.size() == 2, "Jax route %d reaches the actual branching line" % route)
        ui.select_choice(route)
        var guard := 0
        while ui.is_dialogue() and ui.dialogue_lines != parent.lines and guard < 30:
            if not ui.active_choices.is_empty():
                ui.select_choice(0)
            else:
                ui.advance()
            guard += 1
        check(ui.is_dialogue() and ui.dialogue_lines == parent.lines and ui.line_index == 6 and ui.body.text == parent.lines[6].text, "Jax route %d returns from its nested sequence to parent index six" % route)
        check(not npc.has_completed() and get_tree().paused, "Jax route %d does not complete or resume gameplay at the end of a branch" % route)
        for i in range(6, 15):
            ui.advance()
        check(ui.is_dialogue() and ui.line_index == 15 and ui.get_node("DialoguePanel/Continue").text == "Finish", "Jax route %d reaches the real final parent line before offering Finish" % route)
        ui.advance()
        check(not ui.is_open() and npc.has_completed() and not get_tree().paused, "Jax route %d completes only after the full conversation" % route)
        await frames()
    var unchanged := true
    for i in parent.lines.size():
        unchanged = unchanged and parent.lines[i].text == original_texts[i]
    check(unchanged and parent.lines[5].choices.size() == 2, "Playing both routes leaves the designer's text and choices unchanged")

func verify_nested_return_and_replacement() -> void:
    var nested_question := text_line("Nested question")
    nested_question.choices = [choice("Nested answer", sequence([text_line("Deep answer")]))]
    var outer_question := text_line("Outer question")
    outer_question.choices = [choice("Outer answer", sequence([nested_question, text_line("Rest of branch")]))]
    var parent := sequence([outer_question, text_line("Rest of parent")])
    hud.show_dialogue(parent, npc)
    ui.select_choice(0)
    ui.select_choice(0)
    check(ui.return_stack.size() == 2 and ui.get_node("DialoguePanel/Continue").text == "Continue", "Nested branches retain both continuations and do not incorrectly offer Finish")
    ui.advance()
    check(ui.body.text == "Rest of branch" and ui.return_stack.size() == 1, "Finishing a deep answer first resumes its immediate parent branch")
    ui.advance()
    check(ui.body.text == "Rest of parent" and ui.return_stack.is_empty(), "Finishing that branch then resumes the outer conversation")
    ui.advance()
    var stop := choice("End on this branch", sequence([text_line("Alternate ending")]))
    stop.return_after_branch = false
    nested_question.choices = [stop]
    hud.show_dialogue(parent, npc)
    ui.select_choice(0)
    ui.select_choice(0)
    check(ui.body.text == "Alternate ending" and ui.return_stack.is_empty(), "Return After Branch can explicitly replace all pending continuations")
    ui.advance()
    check(not ui.is_open(), "An explicit replacement branch finishes without resuming old lines")

func verify_animation() -> void:
    var body: AnimatedSprite2D = npc.get_node("Body")
    var original_mode := body.process_mode
    var old_frame := body.frame
    var old_progress := body.frame_progress
    var parent: DialogueSequence = npc.dialogue
    hud.show_dialogue(parent, npc)
    check(get_tree().paused and npc.process_mode == Node.PROCESS_MODE_INHERIT and body.process_mode == Node.PROCESS_MODE_ALWAYS, "Only the NPC visual keeps processing while gameplay is paused")
    check(body.animation == &"idle", "Jax listens in idle while the player speaks")
    var point := player.global_position
    Input.action_press("move_right")
    await get_tree().create_timer(0.2).timeout
    Input.action_release("move_right")
    check(player.global_position == point and (body.frame != old_frame or body.frame_progress != old_progress), "Player physics remain frozen while the NPC's idle animation advances")
    ui.advance()
    check(body.animation == &"talking" and body.is_playing(), "The Unknown Man alias plays Jax's authored talking animation")
    old_frame = body.frame
    old_progress = body.frame_progress
    await get_tree().create_timer(0.2).timeout
    check(body.frame != old_frame or body.frame_progress != old_progress, "The actual talking animation advances despite SceneTree pause")
    ui.advance()
    check(body.animation == &"idle", "Changing to a player line returns Jax to idle")
    for i in 3:
        ui.advance()
    check(ui.choice_buttons.size() == 2 and body.animation == &"idle" and body.is_playing(), "Jax continues idle motion while waiting for a response")
    ui.close(true)
    check(body.process_mode == original_mode and body.animation == &"idle" and body.is_playing(), "Closing restores the NPC's original processing and animation playback")
    hud.show_dialogue(sequence([text_line("A named Jax line", jax)]), npc)
    check(body.animation == &"talking", "Jax Dole and Unknown Man resources both map to the same NPC")
    ui.advance()
    npc.animate_during_dialogue = false
    hud.show_dialogue(sequence([text_line("Animation disabled", jax)]), npc)
    check(body.process_mode == original_mode, "The NPC Inspector can disable conversation animation")
    ui.advance()
    npc.animate_during_dialogue = true
    var original_name: StringName = npc.talking_animation
    npc.talking_animation = &"missing_clip"
    hud.show_dialogue(sequence([text_line("Missing custom animation", jax)]), npc)
    check(body.animation == &"idle" and body.is_playing(), "A missing talking clip safely falls back to the NPC idle animation")
    ui.advance()
    var original_frames := body.sprite_frames
    body.sprite_frames = original_frames.duplicate()
    body.sprite_frames.add_animation(&"empty_talking")
    npc.talking_animation = &"empty_talking"
    hud.show_dialogue(sequence([text_line("A new, not yet drawn animation", jax)]), npc)
    check(body.animation == &"idle" and body.is_playing(), "An empty placeholder talking clip also falls back safely to idle")
    ui.advance()
    body.sprite_frames.rename_animation(&"talking", &"NPC_talking")
    npc.talking_animation = &"NPC_talking"
    hud.show_dialogue(sequence([text_line("Custom named animation", jax)]), npc)
    check(body.animation == &"NPC_talking", "Talking Animation accepts a designer's custom animation name")
    ui.advance()
    body.sprite_frames = original_frames
    npc.talking_animation = original_name
    await frames()

func verify_compact_layout() -> void:
    var question := text_line("Choose a response.", jax)
    question.choices = [choice("First response"), choice("Second response")]
    hud.show_dialogue(sequence([question]), npc)
    await frames(5)
    var panel: Panel = ui.get_node("DialoguePanel")
    var scroll: ScrollContainer = ui.get_node("DialoguePanel/Choices")
    var options: VBoxContainer = scroll.get_node("Options")
    check(panel.size.y < 260 and absf(scroll.size.y - options.get_combined_minimum_size().y) < 2, "Two short choices use their actual height instead of an oversized fixed list")
    check(absf(panel.get_global_rect().end.y - scroll.get_global_rect().end.y - 16) < 1, "Only sixteen pixels remain below the choices")
    check(ui.body.get_global_rect().end.y + 11 <= scroll.get_global_rect().position.y, "Question text and response buttons do not overlap")
    ui.select_choice(0)
    question.choices = [choice("A longer answer with enough text to wrap onto several lines. ".repeat(8)), choice("Another response")]
    var window := get_tree().root
    var original_size := window.size
    window.size = Vector2i(800, 600)
    hud.show_dialogue(sequence([question]), npc)
    await frames(6)
    check(ui.choice_buttons[0].size.y > 44 and scroll.get_v_scroll_bar().max_value >= scroll.size.y, "Long answers wrap and remain accessible through the bounded scrolling list")
    window.size = Vector2i(640, 360)
    await frames(6)
    check(panel.get_global_rect().position.y >= 0 and panel.get_global_rect().end.y <= ui.size.y and ui.body.size.y >= 36, "Choices resize within a smaller window while preserving readable question space")
    ui.select_choice(1)
    window.size = original_size
    await frames()
    check(is_equal_approx(panel.offset_top, ui.default_dialogue_top) and is_equal_approx(ui.body.offset_bottom, ui.default_body_bottom), "Finishing choices restores the authored normal dialogue layout")

func verify_voice() -> void:
    var first := text_line("A recorded line with deliberately slow text revealing.", jax)
    var recording := silent_recording(2.0)
    recording.loop_mode = AudioStreamWAV.LOOP_FORWARD
    recording.loop_end = 16000
    first.voice_audio = recording
    first.voice_volume_db = -7.0
    var second := text_line("The second recorded line.", jax)
    second.voice_audio = silent_recording(0.3)
    second.voice_volume_db = -3.0
    var response := text_line("Text-only question.", jax)
    var branch_line := text_line("A voiced branch line.", jax)
    branch_line.voice_audio = silent_recording(2.0)
    response.choices = [choice("Enter branch", sequence([branch_line]))]
    ui.characters_per_second = 1
    hud.show_dialogue(sequence([first, second, response, text_line("The parent continues.", you)]), npc)
    var voice: AudioStreamPlayer = ui.get_node("Voice")
    check(voice.playing and voice.bus == &"Voice" and AudioServer.get_bus_index("Voice") >= 0 and voice.volume_db == -7, "Per-line voice starts on the authored Voice bus with its own volume")
    check(voice.stream != recording and voice.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED and recording.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Voice is a private non-looping playback copy that leaves imported audio unchanged")
    await get_tree().create_timer(0.15).timeout
    var position := voice.get_playback_position()
    var stream := voice.stream
    check(voice.playing and position > 0.0 and get_tree().paused, "Voice playback progresses while the game world is paused")
    ui.advance()
    check(ui.line_index == 0 and voice.playing and voice.stream == stream and voice.get_playback_position() >= position, "Revealing text does not stop or restart the current voice recording")
    ui.characters_per_second = 0
    ui.advance()
    check(ui.line_index == 1 and voice.playing and voice.stream != stream and voice.volume_db == -3, "Advancing replaces the old clip and applies the next line's voice settings")
    await get_tree().create_timer(0.6).timeout
    check(not voice.playing and ui.line_index == 1 and ui.is_dialogue(), "Natural audio completion leaves the subtitle open for manual advancement")
    check(npc.get_node("Body").animation == &"idle" and npc.get_node("Body").is_playing(), "When voice ends the NPC returns to animated idle")
    ui.advance()
    check(voice.stream == null and not voice.playing and ui.choice_buttons.size() == 1, "Text-only lines work with no clip or leftover playback")
    ui.select_choice(0)
    check(voice.playing and ui.body.text == branch_line.text, "Voice recordings also play on lines inside a response branch")
    ui.advance()
    check(voice.stream == null and ui.body.text == "The parent continues.", "Returning to the parent stops branch audio and displays the next parent line")
    ui.advance()
    check(not voice.playing and voice.stream == null and not get_tree().paused, "Finishing a conversation releases voice playback and resumes gameplay")
    Game.world.erase(npc.state_key())
    hud.show_dialogue(sequence([first]), npc)
    ui.close()
    check(ui.is_dialogue() and voice.playing, "Normal close cannot bypass a voiced conversation")
    ui.close(true)
    check(not voice.playing and voice.stream == null and not npc.has_completed() and npc.get_node("Body").process_mode == Node.PROCESS_MODE_INHERIT, "Lifecycle cleanup stops speech and restores the actor without marking unfinished dialogue complete")
    await frames()

func verify_lifecycle_cleanup() -> void:
    var line := text_line("Scene teardown during a recorded line.", jax)
    line.voice_audio = silent_recording(2.0)
    hud.show_dialogue(sequence([line]), npc)
    room.queue_free()
    get_tree().current_scene = null
    await frames(5)
    check(not get_tree().paused and not is_instance_valid(ui), "Removing an active dialogue scene releases its pause and audio cleanly")
    GameAudio.stop_all()
    await get_tree().create_timer(0.2).timeout
