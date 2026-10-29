extends Control
## HUD owns modal routing; this panel never receives gameplay input while hidden.
signal closed
var target: CodeLock
var digits: Array[int] = [0, 0, 0, 0]
var selected_dial := 0
var previously_paused := false
@onready var dial_row: HBoxContainer = $Center/Panel/Margin/Content/Dials
@onready var feedback: Label = $Center/Panel/Margin/Content/Feedback

func _ready() -> void:
    hide()
    for index in 4:
        var dial := dial_row.get_child(index)
        dial.get_node("Up").pressed.connect(cycle_dial.bind(index, 1))
        dial.get_node("Down").pressed.connect(cycle_dial.bind(index, -1))
        dial.get_node("Digit").pressed.connect(select_dial.bind(index))
        dial.get_node("Digit").focus_entered.connect(func(): selected_dial = index)
    $Center/Panel/Margin/Content/Actions/Unlock.pressed.connect(submit)
    $Center/Panel/Margin/Content/Actions/Close.pressed.connect(close)

func is_open() -> bool:
    return visible and is_instance_valid(target)

func open_lock(origin: CodeLock) -> bool:
    if is_open() or not is_instance_valid(origin) or origin.has_unlocked() or get_tree().paused or Game.transitioning or Game.health <= 0:
        return false
    target = origin
    var initial := origin.current_digits()
    for index in 4:
        digits[index] = int(initial[index])
    previously_paused = get_tree().paused
    $Center/Panel/Margin/Content/Title.text = origin.panel_title
    feedback.text = ""
    update_digits()
    show()
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    select_dial(0)
    return true

func selected_code() -> String:
    return "%d%d%d%d" % digits

func update_digits() -> void:
    for index in 4:
        dial_row.get_child(index).get_node("Digit").text = str(digits[index])

func select_dial(index: int) -> void:
    selected_dial = posmod(index, 4)
    dial_row.get_child(selected_dial).get_node("Digit").grab_focus()

func cycle_dial(index: int, direction: int) -> void:
    if not is_open():
        return
    digits[index] = posmod(digits[index] + direction, 10)
    select_dial(index)
    changed_digits()

func changed_digits() -> void:
    update_digits()
    feedback.text = ""
    target.remember_digits(selected_code())

func submit() -> void:
    if not is_open():
        return
    feedback.text = target.attempt_unlock(selected_code())
    if feedback.text.is_empty():
        close()

func close() -> void:
    if not visible:
        return
    hide()
    target = null
    get_tree().paused = previously_paused
    closed.emit()

func handle_input(event: InputEvent) -> void:
    if not is_open():
        return
    if event.is_echo():
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("pause"):
        close()
    elif event.is_action_pressed("inventory"):
        pass # Do not open inventory or let Tab change focus inside a lock.
    elif event.is_action_pressed("ui_left"):
        select_dial(selected_dial - 1)
    elif event.is_action_pressed("ui_right"):
        select_dial(selected_dial + 1)
    elif event.is_action_pressed("ui_up"):
        cycle_dial(selected_dial, 1)
    elif event.is_action_pressed("ui_down"):
        cycle_dial(selected_dial, -1)
    elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
        submit()
    elif event is InputEventKey and event.pressed and event.keycode >= KEY_0 and event.keycode <= KEY_9:
        digits[selected_dial] = event.keycode - KEY_0
        changed_digits()
        select_dial(selected_dial + 1)
    else:
        return # Mouse events must reach the actual dial and action buttons.
    get_viewport().set_input_as_handled()
