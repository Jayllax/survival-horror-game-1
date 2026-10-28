extends Control
## HUD routes modal input here so inventory/pause cannot open over a conversation.
signal closed
@export_range(0.0, 120.0, 1.0) var characters_per_second: float = 45.0
@export var default_text_color: Color = Color("ccbb98")
var dialogue_lines: Array[DialogueLine] = []
var line_index := 0
var revealed := 0.0
var source: Node
var mode := ""
@onready var body: RichTextLabel = $DialoguePanel/Body

func _ready() -> void:
    hide()
    $NotePanel/Close.pressed.connect(close)
    $DialoguePanel/Continue.pressed.connect(advance)
    $DialoguePanel/Leave.pressed.connect(close)

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
    $DialoguePanel/Continue.grab_focus()
    return true

func display_line() -> void:
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
    $DialoguePanel/Continue.text = "Reveal" if body.visible_characters >= 0 else ("Finish" if line_index == dialogue_lines.size() - 1 else "Continue")

func advance() -> void:
    if not is_dialogue():
        return
    if body.visible_characters >= 0:
        body.visible_characters = -1
        update_continue()
    elif line_index + 1 < dialogue_lines.size():
        line_index += 1
        display_line()
    else:
        if is_instance_valid(source) and source.has_method("mark_completed"):
            source.mark_completed()
        close()

func close() -> void:
    if not is_open():
        return
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
