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
var selected_uid := -1
var combining_uid := -1
var return_to_pause := false
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
    $Root/PausePanel/Resume.pressed.connect(toggle_pause)
    $Root/PausePanel/Retry.pressed.connect(open_load_menu)
    $SaveMenu.closed.connect(on_save_menu_closed)
    $Root/PausePanel/Menu.pressed.connect(back_to_menu)
    $Root/InventoryPanel/Use.pressed.connect(use_selected)
    $Root/InventoryPanel/Combine.pressed.connect(begin_combine)
    $Root/PausePanel/Controls.pressed.connect(show_controls)
    $Root/ControlsPanel/Close.pressed.connect(func():
        $Root/ControlsPanel.hide()
        $Root/PausePanel.show())
    for path in ["InventoryPanel", "NotePanel", "PuzzlePanel"]:
        root.get_node(path + "/Close").pressed.connect(close_panels)
    $Root/InventoryPanel/Grid.item_selected.connect(select_item)
    $Root/InventoryPanel/Grid.feedback.connect(inventory_feedback)
    $Root/InventoryPanel/Rotate.pressed.connect(func(): $Root/InventoryPanel/Grid.rotate_item())
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
    var combat: bool = playing and player != null and player.is_showing_combat_feedback()
    $Root/Crosshair.visible = playing and player != null and player.is_aiming()
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

func _input(event: InputEvent) -> void:
    if Game.transitioning or $SaveMenu.is_open():
        return
    if event.is_echo():
        if $Root/InventoryPanel.visible and event.is_action("inventory"):
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("pause"):
        if $Root/InventoryPanel.visible and $Root/InventoryPanel/Grid.cancel_drag():
            get_viewport().set_input_as_handled()
            return
        if any_panel_open():
            close_panels()
        else:
            toggle_pause()
        get_viewport().set_input_as_handled()
    elif $Root/InventoryPanel.visible and event.is_action_pressed("inventory_rotate"):
        $Root/InventoryPanel/Grid.rotate_item()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("inventory") and Game.health > 0 and ($Root/InventoryPanel.visible or not any_panel_open()):
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
    combining_uid = -1
    $Root/InventoryPanel/Grid.combining = false
    $Root/InventoryPanel/Grid.cancel_drag()
    for path in ["PausePanel", "InventoryPanel", "NotePanel", "PuzzlePanel", "ControlsPanel"]:
        root.get_node(path).hide()
    get_tree().paused = false

func toggle_pause() -> void:
    if Game.health <= 0 and $Root/PausePanel.visible:
        return
    var should_open: bool = not $Root/PausePanel.visible
    close_panels()
    $Root/PausePanel/Retry.disabled = not Game.has_saves()
    $Root/PausePanel.visible = should_open
    get_tree().paused = should_open

func open_inventory() -> void:
    inventory_feedback("Drag items to move · R to rotate · Esc cancels a drag")
    $Root/InventoryPanel.show()
    get_tree().paused = true
    refresh()
    var grid: Control = $Root/InventoryPanel/Grid
    grid.grab_focus()
    var item := Game.inventory.entry(selected_uid)
    grid.keyboard_cell = Vector2i(item["x"], item["y"]) if not item.is_empty() else Vector2i.ZERO
    pickup_remaining = 0

func inventory_feedback(text: String) -> void:
    $Root/InventoryPanel/Help.text = text

func select_item(uid: int) -> void:
    if combining_uid >= 0:
        var first := combining_uid
        combining_uid = -1
        $Root/InventoryPanel/Grid.combining = false
        selected_uid = first
        if Game.combine_uids(first, uid):
            if Game.inventory.entry(first).get("id", "") != Game.last_combined_id:
                selected_uid = Game.inventory.first_uid(Game.last_combined_id)
            inventory_feedback("Items combined.")
        else:
            inventory_feedback("These items cannot combine, or there is no room for the result.")
    else:
        selected_uid = uid
    update_selection()

func update_selection() -> void:
    var item := Game.inventory.entry(selected_uid)
    $Root/InventoryPanel/Grid.selected_uid = selected_uid
    $Root/InventoryPanel/Grid.queue_redraw()
    if item.is_empty():
        $Root/InventoryPanel/Portrait.texture = null
        $Root/InventoryPanel/ItemName.text = "Select an item"
        $Root/InventoryPanel/Category.text = ""
        $Root/InventoryPanel/Description.text = ""
        $Root/InventoryPanel/Quantity.text = ""
        $Root/InventoryPanel/Footprint.text = ""
        $Root/InventoryPanel/Use.text = "Use"
        $Root/InventoryPanel/Use.disabled = true
        $Root/InventoryPanel/Combine.disabled = true
        $Root/InventoryPanel/Rotate.disabled = true
        return
    var id: String = item["id"]
    var definition: InventoryItemDefinition = Game.item_catalog.get(id)
    var weapon := definition != null and definition.is_weapon
    $Root/InventoryPanel/Use.text = ("Unequip" if Game.equipped_uid == selected_uid else "Equip") if weapon else "Use"
    $Root/InventoryPanel/Use.disabled = not weapon and (not definition or definition.heal_amount <= 0 or Game.health >= 100)
    $Root/InventoryPanel/Combine.disabled = not Game.can_combine(id)
    $Root/InventoryPanel/Rotate.disabled = definition != null and not definition.can_rotate
    $Root/InventoryPanel/Portrait.texture = Game.item_icon(id)
    $Root/InventoryPanel/ItemName.text = Game.item_name(id)
    $Root/InventoryPanel/Category.text = Game.item_category(id).to_upper() + (" · EQUIPPED" if Game.equipped_uid == selected_uid else "")
    $Root/InventoryPanel/Description.text = Game.item_description(id)
    $Root/InventoryPanel/Quantity.text = "LOADED %d / %d" % [item["magazine"], definition.magazine_size] if weapon else "QUANTITY  %d" % item["count"]
    var footprint := Game.inventory.dimensions(id, item["rotated"])
    $Root/InventoryPanel/Footprint.text = "%d × %d CELLS%s" % [footprint.x, footprint.y, " · ROTATED" if item["rotated"] else ""]

func use_selected() -> void:
    var item := Game.inventory.entry(selected_uid)
    var definition: InventoryItemDefinition = Game.item_catalog.get(item.get("id", ""))
    if definition and definition.is_weapon:
        Game.equip_weapon(selected_uid)
    else:
        Game.use_uid(selected_uid)

func begin_combine() -> void:
    if Game.inventory.entry(selected_uid).is_empty():
        return
    combining_uid = selected_uid
    $Root/InventoryPanel/Grid.combining = true
    inventory_feedback("Select a second item to combine. Close the inventory to cancel.")
    $Root/InventoryPanel/Grid.grab_focus()

func refresh() -> void:
    if Game.health < previous_health:
        health_remaining = health_feedback_seconds
    previous_health = Game.health
    $Root/HealthBrief.value = Game.health
    var definition := Game.active_weapon()
    var ammo_id := definition.ammunition_id if definition else "ammo"
    $Root/Ammo.text = "%d  /  %d" % [Game.magazine, Game.count_item(ammo_id)]
    var condition: String = "Stable" if Game.health > 60 else ("Wounded" if Game.health > 25 else "Critical")
    $Root/InventoryPanel/Condition.text = "CONDITION  %s  ·  %d%%" % [condition, Game.health]
    $Root/InventoryPanel/WeaponStatus.text = "%s  %d loaded / %d spare" % [definition.display_name.to_upper(), Game.magazine, Game.count_item(ammo_id)] if definition else "NO WEAPON EQUIPPED"
    $Root/InventoryPanel/Equipment.text = "FLASHLIGHT · EQUIPPED     GRID %d × %d" % [Game.inventory.columns, Game.inventory.rows]
    if Game.inventory.entry(selected_uid).is_empty():
        selected_uid = int(Game.inventory.entries[0]["uid"]) if not Game.inventory.entries.is_empty() else -1
    update_selection()
    if Game.health <= 0:
        for path in ["InventoryPanel", "NotePanel", "PuzzlePanel", "ControlsPanel"]:
            root.get_node(path).hide()
        $Root/PausePanel.show()
        get_tree().paused = true
        $Root/PausePanel/Title.text = "HEALTH DEPLETED"
        $Root/PausePanel/Resume.disabled = true
        $Root/PausePanel/Retry.disabled = not Game.has_saves()
        $Root/PausePanel/Subtitle.text = "Load a saved game or return to the main menu."

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

func show_save_station(station: Area2D) -> void:
    if any_panel_open() or $SaveMenu.is_open() or Game.health <= 0:
        return
    return_to_pause = false
    $SaveMenu.open_save(station)

func open_load_menu() -> void:
    return_to_pause = true
    $Root/PausePanel.hide()
    $SaveMenu.open_load()

func on_save_menu_closed() -> void:
    if return_to_pause:
        $Root/PausePanel.show()
        get_tree().paused = true
    return_to_pause = false

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
