extends Control
## HUD routes modal input here so inventory/pause cannot open over a conversation.
signal closed
signal choice_selected(choice_id: String)
const CHOICE_BUTTON = preload("res://scenes/ui/dialogue_choice_button.tscn")
@export_range(0.0, 120.0, 1.0) var characters_per_second: float = 45.0
@export var default_text_color: Color = Color("ccbb98")
@export_group("Response Layout")
@export_range(44.0, 400.0) var choice_list_max_height: float = 180.0
@export_range(36.0, 240.0) var choice_text_max_height: float = 110.0
var dialogue_lines: Array[DialogueLine] = []
var return_stack: Array[Dictionary] = []
var line_index := 0
var revealed := 0.0
var source: Node
var mode := ""
var active_choices: Array[DialogueChoice] = []
var choice_buttons: Array[Button] = []
var _layout_pending := false
@onready var body: RichTextLabel = $DialoguePanel/Body
@onready var voice: AudioStreamPlayer = $Voice
@onready var note_body: RichTextLabel = $NotePanel/Body
@onready var default_note_font: Font = note_body.get_theme_font("normal_font")
@onready var default_note_font_size: int = note_body.get_theme_font_size("normal_font_size")
@onready var default_dialogue_top: float = $DialoguePanel.offset_top
@onready var default_body_bottom: float = body.offset_bottom
@onready var default_choices_top: float = $DialoguePanel/Choices.offset_top
@onready var default_choices_bottom: float = $DialoguePanel/Choices.offset_bottom

func _ready() -> void:
    hide()
    $NotePanel/Close.pressed.connect(close)
    $DialoguePanel/Continue.pressed.connect(advance)
    voice.finished.connect(update_speaking_animation)
    resized.connect(queue_choice_layout)
    $DialoguePanel/Choices/Options.minimum_size_changed.connect(queue_choice_layout)

func is_open() -> bool:
    return visible and not mode.is_empty()

func is_dialogue() -> bool:
    return is_open() and mode == "dialogue"

func can_open() -> bool:
    return not is_open() and not get_tree().paused and not Game.transitioning and Game.health > 0

func open_note(document: NoteDocument, origin: Node) -> bool:
    if document == null or document.text.strip_edges().is_empty() or not can_open():
        return false
    mode = "note"
    source = origin
    $NotePanel/Title.text = document.title
    note_body.add_theme_font_override("normal_font", document.body_font if document.body_font != null else default_note_font)
    note_body.add_theme_font_size_override("normal_font_size", document.body_font_size if document.body_font_size > 0 else default_note_font_size)
    $NotePanel/Body.text = document.text
    $NotePanel/Body.scroll_to_line(0)
    $NotePanel.show()
    $DialoguePanel.hide()
    show()
    get_tree().paused = true
    $NotePanel/Close.grab_focus()
    return true

func open_dialogue(sequence: DialogueSequence, origin: Node) -> bool:
    if sequence == null or not can_open():
        return false
    var lines := sequence.playable_lines()
    if lines.is_empty():
        return false
    dialogue_lines = lines
    return_stack.clear()
    line_index = 0
    source = origin
    mode = "dialogue"
    $NotePanel.hide()
    $DialoguePanel.show()
    show()
    get_tree().paused = true
    if is_instance_valid(source) and source.has_method("begin_dialogue_animation"):
        source.begin_dialogue_animation()
    display_line()
    if $DialoguePanel/Continue.visible:
        $DialoguePanel/Continue.grab_focus()
    return true

func display_line() -> void:
    clear_choices()
    var line := dialogue_lines[line_index]
    var color := line.speaker.text_color if line.speaker else default_text_color
    $DialoguePanel/Speaker.text = line.speaker.display_name if line.speaker else ""
    $DialoguePanel/Speaker.add_theme_color_override("font_color", color)
    body.add_theme_color_override("default_color", color)
    body.text = line.text
    body.scroll_to_line(0)
    revealed = 0.0
    body.visible_characters = 0 if characters_per_second > 0 else -1
    play_voice(line)
    update_continue()
    update_speaking_animation()

func _process(delta: float) -> void:
    if not is_dialogue() or body.visible_characters < 0:
        return
    revealed += delta * characters_per_second
    body.visible_characters = int(revealed)
    if body.visible_characters >= body.get_total_character_count():
        body.visible_characters = -1
        update_continue()

func update_continue() -> void:
    if body.visible_characters < 0:
        var choices := dialogue_lines[line_index].playable_choices()
        if not choices.is_empty():
            if choice_buttons.is_empty():
                show_choices(choices)
            return
    var final_line := line_index == dialogue_lines.size() - 1 and return_stack.is_empty()
    $DialoguePanel/Continue.text = "Reveal" if body.visible_characters >= 0 else ("Finish" if final_line else "Continue")

func clear_choices() -> void:
    active_choices.clear()
    for button in choice_buttons:
        button.disabled = true
        button.get_parent().remove_child(button)
        button.queue_free()
    choice_buttons.clear()
    $DialoguePanel/Choices.hide()
    $DialoguePanel/Continue.show()
    $DialoguePanel.offset_top = default_dialogue_top
    body.offset_bottom = default_body_bottom
    $DialoguePanel/Choices.offset_top = default_choices_top
    $DialoguePanel/Choices.offset_bottom = default_choices_bottom

func show_choices(choices: Array[DialogueChoice]) -> void:
    active_choices = choices
    $DialoguePanel/Continue.hide()
    $DialoguePanel/Choices.show()
    $DialoguePanel/Choices.scroll_vertical = 0
    for index in choices.size():
        var button: Button = CHOICE_BUTTON.instantiate()
        button.text = choices[index].text
        button.pressed.connect(select_choice.bind(index))
        $DialoguePanel/Choices/Options.add_child(button)
        choice_buttons.append(button)
    choice_buttons[0].grab_focus()
    queue_choice_layout()
    update_speaking_animation()

func queue_choice_layout() -> void:
    if active_choices.is_empty() or _layout_pending:
        return
    _layout_pending = true
    fit_choices.call_deferred()

func fit_choices() -> void:
    _layout_pending = false
    if not is_dialogue() or active_choices.is_empty():
        return
    var panel: Panel = $DialoguePanel
    var scroll: ScrollContainer = $DialoguePanel/Choices
    var options: VBoxContainer = $DialoguePanel/Choices/Options
    var gap := 12.0
    var bottom := 16.0
    var max_panel := maxf(165.0, minf(size.y * 0.7, size.y - 48.0))
    var text_height := clampf(float(body.get_content_height()), 36.0, choice_text_max_height)
    var list_height := minf(maxf(44.0, options.get_combined_minimum_size().y), choice_list_max_height)
    text_height = minf(text_height, maxf(36.0, max_panel - body.offset_top - gap - bottom - list_height))
    list_height = minf(list_height, maxf(44.0, max_panel - body.offset_top - text_height - gap - bottom))
    panel.offset_top = panel.offset_bottom - (body.offset_top + text_height + gap + list_height + bottom)
    scroll.offset_top = -bottom - list_height
    scroll.offset_bottom = -bottom
    body.offset_bottom = -bottom - list_height - gap

func select_choice(index: int) -> void:
    if not is_dialogue() or body.visible_characters >= 0 or index < 0 or index >= active_choices.size():
        return
    var choice := active_choices[index]
    if not choice.is_playable():
        return
    var identity := choice.choice_id.strip_edges()
    var flag := choice.set_flag.strip_edges()
    if not identity.is_empty():
        Game.world["dialogue_choice:" + identity] = true
    if not flag.is_empty():
        Game.world[flag] = choice.flag_value
    clear_choices()
    if choice.next_dialogue != null:
        if not choice.return_after_branch:
            return_stack.clear()
        elif line_index + 1 < dialogue_lines.size():
            return_stack.append({"lines": dialogue_lines, "index": line_index + 1})
        dialogue_lines = choice.next_dialogue.playable_lines()
        line_index = 0
        display_line()
    else:
        advance_sequence()
    Game.changed.emit()
    choice_selected.emit(identity)

func advance() -> void:
    if not is_dialogue():
        return
    if body.visible_characters >= 0:
        body.visible_characters = -1
        update_continue()
    elif not active_choices.is_empty():
        var focus := get_viewport().gui_get_focus_owner()
        var index := choice_buttons.find(focus)
        if index >= 0:
            select_choice(index)
        else:
            choice_buttons[0].grab_focus()
    else:
        advance_sequence()

func advance_sequence() -> void:
    if line_index + 1 < dialogue_lines.size():
        line_index += 1
        display_line()
    elif not return_stack.is_empty():
        var resume: Dictionary = return_stack.pop_back()
        dialogue_lines = resume["lines"]
        line_index = int(resume["index"])
        display_line()
    else:
        if is_instance_valid(source) and source.has_method("mark_completed"):
            source.mark_completed()
        close(true)

func close(force: bool = false) -> void:
    # Only the final advance closes dialogue. Force is reserved for lifecycle cleanup.
    if not is_open() or (is_dialogue() and not force):
        return
    clear_choices()
    stop_voice()
    end_speaking_animation()
    hide()
    mode = ""
    source = null
    dialogue_lines.clear()
    return_stack.clear()
    get_tree().paused = false
    closed.emit()

func play_voice(line: DialogueLine) -> void:
    stop_voice()
    if line.voice_audio == null:
        return
    # Dialogue is a one-shot even if a recording was imported with looping on.
    var stream := line.voice_audio.duplicate() as AudioStream
    if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
        stream.loop = false
    elif stream is AudioStreamWAV:
        stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
    voice.stream = stream
    voice.volume_db = line.voice_volume_db
    voice.play()

func stop_voice() -> void:
    if is_instance_valid(voice):
        voice.stop()
        voice.stream = null

func update_speaking_animation() -> void:
    if not is_dialogue() or not is_instance_valid(source) or not source.has_method("update_dialogue_animation"):
        return
    var line := dialogue_lines[line_index]
    var speaking := voice.playing if line.voice_audio != null else active_choices.is_empty()
    source.update_dialogue_animation(line, speaking)

func end_speaking_animation() -> void:
    if is_instance_valid(source) and source.has_method("end_dialogue_animation"):
        source.end_dialogue_animation()

func _exit_tree() -> void:
    stop_voice()
    end_speaking_animation()
    if not mode.is_empty():
        get_tree().paused = false

func handle_input(event: InputEvent) -> void:
    if not is_open():
        return
    if event.is_echo():
        if event.is_action("interact") or event.is_action("ui_accept"):
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("pause"):
        if not is_dialogue():
            close()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
        if is_dialogue():
            advance()
        else:
            close()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("inventory"):
        get_viewport().set_input_as_handled()
