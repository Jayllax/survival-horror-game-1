extends CanvasLayer
var message_remaining := 0.0
var puzzle_target: Area2D
var dials := Vector3i(1, 1, 1)
@onready var root: Control = $Root

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    add_to_group("hud")
    Game.changed.connect(refresh)
    Game.message.connect(show_message)
    $Root/PausePanel/Resume.pressed.connect(toggle_pause)
    $Root/PausePanel/Retry.pressed.connect(Game.start_game)
    $Root/PausePanel/Menu.pressed.connect(back_to_menu)
    $Root/InventoryPanel/Close.pressed.connect(close_panels)
    $Root/NotePanel/Close.pressed.connect(close_panels)
    $Root/PuzzlePanel/Close.pressed.connect(close_panels)
    $Root/PuzzlePanel/Dial1.pressed.connect(cycle_dial.bind(0))
    $Root/PuzzlePanel/Dial2.pressed.connect(cycle_dial.bind(1))
    $Root/PuzzlePanel/Dial3.pressed.connect(cycle_dial.bind(2))
    $Root/PuzzlePanel/Submit.pressed.connect(submit_puzzle)
    $Root/EndingPanel/Retry.pressed.connect(Game.start_game)
    $Root/EndingPanel/Menu.pressed.connect(back_to_menu)
    refresh()
    show_message("NØRREBY • 02:13. The bells have stopped. Read the notice by the station.")

func _process(delta: float) -> void:
    if not get_tree().paused:
        message_remaining = maxf(0.0, message_remaining - delta)
        $Root/Message.visible = message_remaining > 0
        var player := get_tree().get_first_node_in_group("player")
        if player:
            $Root/Reload.text = "RELOADING… %.1f" % player.reload_remaining if player.reload_remaining > 0 else ""

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if $Root/EndingPanel.visible:
            return
        if any_panel_open():
            close_panels()
        else:
            toggle_pause()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("inventory") and not Game.won:
        if $Root/InventoryPanel.visible:
            close_panels()
        elif not any_panel_open():
            $Root/InventoryPanel.show()
            get_tree().paused = true
        get_viewport().set_input_as_handled()

func any_panel_open() -> bool:
    for path in ["PausePanel", "InventoryPanel", "NotePanel", "PuzzlePanel", "EndingPanel"]:
        if root.get_node(path).visible:
            return true
    return false

func close_panels() -> void:
    for path in ["PausePanel", "InventoryPanel", "NotePanel", "PuzzlePanel"]:
        root.get_node(path).hide()
    get_tree().paused = false

func toggle_pause() -> void:
    var should_open: bool = not $Root/PausePanel.visible
    close_panels()
    $Root/PausePanel.visible = should_open
    get_tree().paused = should_open

func refresh() -> void:
    $Root/Health.text = "VITALS  %03d" % Game.health
    $Root/Ammo.text = "9 MM   %d / %d" % [Game.magazine, Game.count_item("ammo")]
    $Root/Objective.text = Game.objective()
    var grid := $Root/InventoryPanel/Slots
    for i in Game.SLOT_COUNT:
        var slot: Dictionary = Game.slots[i]
        var label: Label = grid.get_child(i)
        label.text = "%02d
— empty —" % (i + 1) if slot.is_empty() else "%02d
%s
× %d" % [i + 1, Game.item_name(slot["id"]), slot["count"]]
    if Game.health <= 0 and not any_panel_open():
        toggle_pause()
        $Root/PausePanel/Title.text = "THE TOWN KEPT YOU"
        $Root/PausePanel/Resume.disabled = true

func set_prompt(text: String) -> void:
    $Root/Prompt.text = text

func show_message(text: String) -> void:
    $Root/Message.text = text
    message_remaining = 7.0
    $Root/Message.show()

func show_note(text: String) -> void:
    $Root/NotePanel/Text.text = text
    $Root/NotePanel.show()
    get_tree().paused = true

func show_puzzle(target: Area2D) -> void:
    puzzle_target = target
    dials = Vector3i(1, 1, 1)
    update_dials()
    $Root/PuzzlePanel.show()
    get_tree().paused = true

func cycle_dial(index: int) -> void:
    dials[index] = dials[index] % 3 + 1
    update_dials()

func update_dials() -> void:
    for i in 3:
        $Root/PuzzlePanel.get_node("Dial%d" % (i + 1)).text = str(dials[i])

func submit_puzzle() -> void:
    if is_instance_valid(puzzle_target) and puzzle_target.solve_puzzle(dials):
        close_panels()
    else:
        $Root/PuzzlePanel/Feedback.text = $Root/Message.text

func show_ending() -> void:
    $Root/EndingPanel.show()
    get_tree().paused = true

func back_to_menu() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
