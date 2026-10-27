extends CanvasLayer
## Shared four-slot picker used by bicycles, the pause menu and the main menu.
signal closed
var saving := false
var station: Area2D
var pending_slot := -1
var previously_paused := false
@onready var panel: PanelContainer = $Shade/Center/Panel
@onready var entries: VBoxContainer = $Shade/Center/Panel/Margin/Content/Slots
@onready var feedback: Label = $Shade/Center/Panel/Margin/Content/Feedback
@onready var confirmation: ConfirmationDialog = $Overwrite

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    $Shade.hide()
    for index in Game.SAVE_SLOT_COUNT:
        entries.get_child(index).pressed.connect(choose_slot.bind(index))
    $Shade/Center/Panel/Margin/Content/Close.pressed.connect(close)
    confirmation.confirmed.connect(confirm_overwrite)
    confirmation.canceled.connect(func(): pending_slot = -1)
    Game.message.connect(on_message)

func is_open() -> bool:
    return $Shade.visible

func open_save(bicycle: Area2D) -> void:
    saving = true
    station = bicycle
    open()

func open_load() -> void:
    saving = false
    station = null
    open()

func open() -> void:
    previously_paused = get_tree().paused
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    pending_slot = -1
    feedback.text = "Choose a slot. Existing files are replaced only after confirmation." if saving else "Choose a saved game to load."
    $Shade/Center/Panel/Margin/Content/Title.text = "SAVE YOUR GAME" if saving else "LOAD GAME"
    refresh_slots()
    $Shade.show()
    for entry in entries.get_children():
        if not entry.disabled:
            entry.grab_focus()
            return
    $Shade/Center/Panel/Margin/Content/Close.grab_focus()

func refresh_slots() -> void:
    for index in Game.SAVE_SLOT_COUNT:
        var info := Game.save_info(index)
        var entry: Button = entries.get_child(index)
        entry.disabled = not saving and not info["valid"]
        var details := "Empty"
        if info["valid"]:
            var minutes := int(float(info["play_seconds"]) / 60.0)
            details = "%s  |  %s\n%s  |  Played %02d:%02d  |  Health %d%%" % [info.get("location", "Location"), info.get("station_label", "Bicycle"), info.get("saved_at", ""), minutes / 60, minutes % 60, int(info["health"])]
        elif info["occupied"]:
            details = "Unavailable save — " + info.get("error", "Invalid file")
        entry.text = "SLOT %d    %s" % [index + 1, details]
        entry.tooltip_text = entry.text

func choose_slot(index: int) -> void:
    if not is_open() or confirmation.visible:
        return
    if saving:
        if Game.save_info(index)["occupied"]:
            pending_slot = index
            confirmation.dialog_text = "Replace the saved game in slot %d?" % (index + 1)
            confirmation.popup_centered()
        else:
            write_slot(index)
    elif Game.load_slot(index):
        # The incoming scene controls pause state; never reopen the previous pause panel.
        $Shade.hide()

func confirm_overwrite() -> void:
    var index := pending_slot
    pending_slot = -1
    if index >= 0:
        write_slot(index)

func write_slot(index: int) -> void:
    if Game.save_slot(index, station):
        feedback.text = "Game saved in slot %d." % (index + 1)
        refresh_slots()
        entries.get_child(index).grab_focus()

func close() -> void:
    confirmation.hide()
    pending_slot = -1
    $Shade.hide()
    station = null
    get_tree().paused = previously_paused
    closed.emit()

func on_message(text: String) -> void:
    if is_open():
        feedback.text = text

func _input(event: InputEvent) -> void:
    if not is_open() or event.is_echo():
        return
    if event.is_action_pressed("pause"):
        if confirmation.visible:
            confirmation.hide()
            pending_slot = -1
        else:
            close()
        get_viewport().set_input_as_handled()
