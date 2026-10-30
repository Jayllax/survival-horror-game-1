extends Control
## HUD routes modal input here so inventory/pause cannot open over a conversation.
signal closed
signal choice_selected(choice_id: String)
const CHOICE_BUTTON = preload("res://scenes/ui/dialogue_choice_button.tscn")
@export_range(0.0, 120.0, 1.0) var characters_per_second: float = 45.0
@export var default_text_color: Color = Color("ccbb98")
var dialogue_lines: Array[DialogueLine] = []
var line_index := 0
var revealed := 0.0
var source: Node
var mode := ""
var active_choices: Array[DialogueChoice] = []
var choice_buttons: Array[Button] = []
@onready var body: RichTextLabel = $DialoguePanel/Body
@onready var note_body: RichTextLabel = $NotePanel/Body
@onready var default_note_font: Font = note_body.get_theme_font("normal_font")
@onready var default_note_font_size: int = note_body.get_theme_font_size("normal_font_size")
@onready var default_dialogue_top: float = $DialoguePanel.offset_top
@onready var default_body_bottom: float = body.offset_bottom

func _ready() -> void:
    hide()
    $NotePanel/Close.pressed.connect(close)
    $DialoguePanel/Continue.pressed.connect(advance)

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
    line_index = 0
    source = origin
    mode = "dialogue"
    $NotePanel.hide()
    $DialoguePanel.show()
    show()
    get_tree().paused = true
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
    update_continue()

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
    $DialoguePanel/Continue.text = "Reveal" if body.visible_characters >= 0 else ("Finish" if line_index == dialogue_lines.size() - 1 else "Continue")

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

func show_choices(choices: Array[DialogueChoice]) -> void:
    active_choices = choices
    $DialoguePanel.offset_top = minf(default_dialogue_top, -380.0)
    body.offset_bottom = -220.0
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
    else:
        if is_instance_valid(source) and source.has_method("mark_completed"):
            source.mark_completed()
        close(true)

func close(force: bool = false) -> void:
    # Only the final advance closes dialogue. Force is reserved for lifecycle cleanup.
    if not is_open() or (is_dialogue() and not force):
        return
    clear_choices()
    hide()
    mode = ""
    source = null
    dialogue_lines.clear()
    get_tree().paused = false
    closed.emit()

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
