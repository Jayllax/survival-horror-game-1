extends CanvasLayer
## Exploration stays unobstructed. Item identity lives in the inventory, not the world HUD.
@export var health_feedback_seconds: float = 3.5
@export var pickup_hint_seconds: float = 1.6
@export var message_seconds: float = 2.5
@export var show_pickup_hint: bool = true
var message_remaining := 0.0
var health_remaining := 0.0
var pickup_remaining := 0.0
var previous_health := 100
var selected_slot := 0
var combining_id := ""
var interaction_target: Area2D
var puzzle_target: Area2D
var dials := Vector3i(1, 1, 1)
@onready var root: Control = $Root

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    add_to_group("hud")
    previous_health = Game.health
    Game.changed.connect(refresh)
    Game.message.connect(show_message)
    Game.item_collected.connect(on_item_collected)
    Game.checkpoint_saved.connect(on_checkpoint_saved)
    $Root/PausePanel/Resume.pressed.connect(toggle_pause)
    $Root/PausePanel/Retry.pressed.connect(Game.retry_checkpoint)
    $Root/PausePanel/Menu.pressed.connect(back_to_menu)
    $Root/PausePanel/Save.pressed.connect(Game.save_run)
    $Root/InventoryPanel/Use.pressed.connect(use_selected)
    $Root/InventoryPanel/Combine.pressed.connect(begin_combine)
    $Root/PausePanel/Controls.pressed.connect(show_controls)
    $Root/ControlsPanel/Close.pressed.connect(func():
        $Root/ControlsPanel.hide()
        $Root/PausePanel.show())
    for path in ["InventoryPanel", "NotePanel", "PuzzlePanel"]:
        root.get_node(path + "/Close").pressed.connect(close_panels)
    for i in 8:
        var slot: Button = $Root/InventoryPanel/Slots.get_child(i)
        slot.pressed.connect(select_slot.bind(i))
        slot.focus_entered.connect(select_slot.bind(i))
    for i in 3:
        $Root/PuzzlePanel.get_node("Dial%d" % (i+1)).pressed.connect(cycle_dial.bind(i))
    $Root/PuzzlePanel/Submit.pressed.connect(submit_puzzle)
    refresh()

func _exit_tree() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
    var playing: bool = not get_tree().paused and not Game.transitioning
    Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if playing else Input.MOUSE_MODE_VISIBLE
    $Root/Backdrop.visible = any_panel_open()
    var player := get_tree().get_first_node_in_group("player")
    var combat: bool = playing and player != null and player.is_aiming()
    $Root/Crosshair.visible = combat
    $Root/Crosshair.position = get_viewport().get_mouse_position() - Vector2(8,12)
    $Root/Ammo.visible = combat
    $Root/Reload.visible = combat and player.reload_remaining > 0 if player else false
    $Root/Reload.text = "RELOADING" if $Root/Reload.visible else ""
    $Root/Prompt.visible = playing and is_instance_valid(interaction_target) and interaction_target.is_available()
    if $Root/Prompt.visible:
        var point: Vector2 = get_viewport().get_canvas_transform() * (interaction_target.global_position + interaction_target.prompt_offset)
        $Root/Prompt.position = Vector2(clampf(point.x - 90, 12, get_viewport().get_visible_rect().size.x - 192), clampf(point.y, 12, get_viewport().get_visible_rect().size.y - 44))
    if playing:
        message_remaining = maxf(0, message_remaining - delta)
        health_remaining = maxf(0, health_remaining - delta)
        pickup_remaining = maxf(0, pickup_remaining - delta)
    $Root/Message.visible = playing and message_remaining > 0
    $Root/HealthBrief.visible = playing and (health_remaining > 0 or Game.health <= 25)
    $Root/HealthBrief.modulate.a = minf(health_remaining, 1.0) if Game.health > 25 else 1.0
    $Root/PickupHint.visible = playing and show_pickup_hint and pickup_remaining > 0 and not combat

func _unhandled_input(event: InputEvent) -> void:
    if Game.transitioning:
        return
    if event.is_action_pressed("pause"):
        if any_panel_open():
            close_panels()
        else:
            toggle_pause()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("inventory") and Game.health > 0:
        if $Root/InventoryPanel.visible:
            close_panels()
        elif not any_panel_open():
            open_inventory()
        get_viewport().set_input_as_handled()

func any_panel_open() -> bool:
    for path in ["PausePanel", "InventoryPanel", "NotePanel", "PuzzlePanel", "ControlsPanel"]:
        if root.get_node(path).visible:
            return true
    return false

func close_panels() -> void:
    if Game.health <= 0:
        return
    combining_id = ""
    for path in ["PausePanel", "InventoryPanel", "NotePanel", "PuzzlePanel", "ControlsPanel"]:
        root.get_node(path).hide()
    get_tree().paused = false

func toggle_pause() -> void:
    if Game.health <= 0 and $Root/PausePanel.visible:
        return
    var should_open: bool = not $Root/PausePanel.visible
    close_panels()
    $Root/PausePanel.visible = should_open
    get_tree().paused = should_open

func open_inventory() -> void:
    refresh()
    $Root/InventoryPanel.show()
    get_tree().paused = true
    if Game.slots[selected_slot].is_empty():
        for i in 8:
            if not Game.slots[i].is_empty():
                selected_slot = i
                break
    select_slot(selected_slot)
    $Root/InventoryPanel/Slots.get_child(selected_slot).grab_focus()
    pickup_remaining = 0

func select_slot(index: int) -> void:
    if not combining_id.is_empty() and not Game.slots[index].is_empty():
        var first := combining_id
        combining_id = ""
        var combined := Game.combine_items(first, Game.slots[index]["id"])
        selected_slot = index
        if combined:
            for i in 8:
                if Game.slots[i].get("id", "") == Game.last_combined_id:
                    selected_slot = i
                    break
        refresh()
        if combined:
            $Root/InventoryPanel/Category.text += " · COMBINED"
        else:
            $Root/InventoryPanel/Description.text = "These items cannot be combined, or there is no room for the result."
        return
    selected_slot = index
    for i in 8:
        $Root/InventoryPanel/Slots.get_child(i).set_pressed_no_signal(i == index)
    var slot: Dictionary = Game.slots[index]
    if slot.is_empty():
        $Root/InventoryPanel/Portrait.texture = null
        $Root/InventoryPanel/ItemName.text = "Empty pocket"
        $Root/InventoryPanel/Category.text = ""
        $Root/InventoryPanel/Description.text = ""
        $Root/InventoryPanel/Quantity.text = ""
        $Root/InventoryPanel/Use.disabled = true
        $Root/InventoryPanel/Combine.disabled = true
        return
    var id: String = slot["id"]
    var definition: InventoryItemDefinition = Game.item_catalog.get(id)
    $Root/InventoryPanel/Use.disabled = not definition or definition.heal_amount <= 0 or Game.health >= 100
    $Root/InventoryPanel/Combine.disabled = not Game.can_combine(id)
    $Root/InventoryPanel/Portrait.texture = Game.item_icon(id)
    $Root/InventoryPanel/ItemName.text = Game.item_name(id)
    $Root/InventoryPanel/Category.text = Game.item_category(id).to_upper()
    $Root/InventoryPanel/Description.text = Game.item_description(id)
    $Root/InventoryPanel/Quantity.text = "QUANTITY  %d" % slot["count"]

func use_selected() -> void:
    if Game.slots[selected_slot].is_empty():
        return
    var id: String = Game.slots[selected_slot]["id"]
    if Game.use_item(id):
        refresh()

func begin_combine() -> void:
    if Game.slots[selected_slot].is_empty():
        return
    combining_id = Game.slots[selected_slot]["id"]
    $Root/InventoryPanel/Description.text = "Choose a second item to combine with this one. Close the inventory to cancel."

func refresh() -> void:
    if Game.health < previous_health:
        health_remaining = health_feedback_seconds
    previous_health = Game.health
    $Root/HealthBrief.value = Game.health
    $Root/Ammo.text = "%d  /  %d" % [Game.magazine, Game.count_item("ammo")]
    var condition: String = "Stable" if Game.health > 60 else ("Wounded" if Game.health > 25 else "Critical")
    $Root/InventoryPanel/Condition.text = "CONDITION  %s  ·  %d%%" % [condition, Game.health]
    $Root/InventoryPanel/WeaponStatus.text = "HANDGUN  %d loaded  /  %d spare" % [Game.magazine, Game.count_item("ammo")]
    for i in 8:
        var slot: Dictionary = Game.slots[i]
        var button: Button = $Root/InventoryPanel/Slots.get_child(i)
        button.get_node("Icon").texture = null if slot.is_empty() else Game.item_icon(slot["id"])
        button.get_node("Count").text = str(slot["count"]) if not slot.is_empty() and int(slot["count"]) > 1 else ""
    select_slot(selected_slot)
    if Game.health <= 0:
        for path in ["InventoryPanel", "NotePanel", "PuzzlePanel", "ControlsPanel"]:
            root.get_node(path).hide()
        $Root/PausePanel.show()
        get_tree().paused = true
        $Root/PausePanel/Title.text = "HEALTH DEPLETED"
        $Root/PausePanel/Resume.disabled = true
        $Root/PausePanel/Save.disabled = true

func set_interaction(target: Area2D) -> void:
    interaction_target = target
    if is_instance_valid(target):
        $Root/Prompt.text = "[E]  " + target.interaction_action()
    else:
        $Root/Prompt.text = ""
        $Root/Prompt.hide()

func on_item_collected(_id: String) -> void:
    pickup_remaining = pickup_hint_seconds
    set_interaction(null)

func on_checkpoint_saved() -> void:
    if $Root/PausePanel.visible:
        $Root/PausePanel/Subtitle.text = "Checkpoint saved."

func show_message(text: String) -> void:
    $Root/Message.text = text
    message_remaining = message_seconds
    if $Root/PausePanel.visible:
        $Root/PausePanel/Subtitle.text = text

func show_controls() -> void:
    $Root/PausePanel.hide()
    $Root/ControlsPanel.show()
    get_tree().paused = true

func show_note(text: String) -> void:
    $Root/NotePanel/Text.text = text
    $Root/NotePanel.show()
    get_tree().paused = true

func show_puzzle(target: Area2D) -> void:
    puzzle_target = target
    dials = Vector3i(1, 1, 1)
    update_dials()
    $Root/PuzzlePanel/Feedback.text = ""
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

func back_to_menu() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
