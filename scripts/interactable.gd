extends Area2D
## All interactables are placed in the editor. Duplicate an existing scene and edit these fields.
@export_enum("Pickup", "Clue", "Switchboard", "Door", "Examine", "Entrance") var kind: int = 0
@export var interaction_radius: float = 84.0
@export var item_definition: InventoryItemDefinition
@export var action_label: String = ""
@export var prompt_offset: Vector2 = Vector2(0, -54)
@export var item_id: String = "ammo"
@export_range(1, 99) var quantity: int = 6
@export_multiline var description: String = ""
@export var required_key: String = "gate_key"
@export var requires_power: bool = true
@export var power_channel: String = "street"
@export var puzzle_input_item: String = "fuse"
@export var puzzle_reward_item: String = "gate_key"
@export var require_reference: bool = false
@export_file("*.tscn") var destination_scene: String = ""
@export var destination_spawn: String = "default"
@export var persistent_id: String = ""
@export var puzzle_solution: Vector3i = Vector3i(3, 1, 2)
@export var door_animation_seconds: float = 0.8
@export_group("Legacy compatibility")
## Old per-door override. Leave off to follow the item's Remove After Use setting.
@export var consume_key: bool = false
var opened := false
var unlocked := false

func _ready() -> void:
	add_to_group("interactable")
	if item_definition:
		item_id = item_definition.id
		Game.register_item(item_definition)
		if kind == 0 and has_node("Sprite2D") and item_definition.icon:
			$Sprite2D.texture = item_definition.icon

	if Game.world.get(state_key(), false):
		if kind == 0:
			queue_free()
		elif kind == 3:
			opened = true
			$Leaf.position.y = -125
			$Barrier/CollisionShape2D.set_deferred("disabled", true)
		elif kind == 5:
			unlocked = true

func is_powered() -> bool:
	return bool(Game.world.get("power:" + power_channel, false))

func state_key() -> String:
	return persistent_id if not persistent_id.is_empty() else Game.object_id(self)

func interaction_action() -> String:
	if not action_label.is_empty():
		return action_label
	return ["Take", "Examine", "Use", "Open", "Examine", "Enter"][kind]

func is_available() -> bool:
	return not opened

func interact(_player: Node) -> void:
	if Game.transitioning:
		return
	match kind:
		0:
			if Game.add_item(item_id, quantity):
				Game.world[state_key()] = true
				opened = true
				Game.item_collected.emit(item_id)
				queue_free()
		1:
			Game.world["reference:" + power_channel] = true
			Game.clue_read = true
			Game.changed.emit()
			get_tree().get_first_node_in_group("hud").show_note(description)
		2:
			if is_powered():
				Game.message.emit("Power is on.")
			else:
				get_tree().get_first_node_in_group("hud").show_puzzle(self)
		3:
			open_door()
		4:
			get_tree().get_first_node_in_group("hud").show_note(description)
		5:
			if requires_power and not is_powered():
				Game.message.emit("Power required.")
				return
			var key_uid := -1
			if not unlocked and not required_key.is_empty():
				key_uid = Game.find_use_uid(required_key)
				if key_uid < 0:
					Game.message.emit("Locked. Requires " + Game.item_name(required_key) + ".")
					return
			Transition.travel(destination_scene, destination_spawn, key_uid, state_key() if key_uid >= 0 else "", consume_key)

func solve_puzzle(code: Vector3i) -> bool:
	if is_powered():
		return true
	if require_reference and not bool(Game.world.get("reference:" + power_channel, false)):
		Game.message.emit("Read the reference card first.")
		return false
	var input_uid := Game.find_use_uid(puzzle_input_item) if not puzzle_input_item.is_empty() else -1
	if not puzzle_input_item.is_empty() and input_uid < 0:
		Game.message.emit("Required: " + Game.item_name(puzzle_input_item))
		return false
	if code != puzzle_solution:
		Game.message.emit("Incorrect sequence.")
		return false
	# Trial both the input's use and the reward. Failure preserves exact item state.
	var trial := Game.inventory.copy()
	if input_uid >= 0 and not trial.finish_use(input_uid):
		return false
	if not puzzle_reward_item.is_empty() and not trial.add(puzzle_reward_item):
		Game.message.emit("No room in the inventory for the reward.")
		return false
	Game.inventory = trial
	Game._repair_equipment()
	Game.world["power:" + power_channel] = true
	Game.changed.emit()
	Game.message.emit("Circuit activated.")
	return true

func open_door() -> void:
	if opened:
		return
	if requires_power and not is_powered():
		Game.message.emit("No power. The switchboard must be restored.")
		return
	var key_uid := Game.find_use_uid(required_key) if not required_key.is_empty() else -1
	if not required_key.is_empty() and key_uid < 0:
		Game.message.emit("Required key not held.")
		return
	if key_uid >= 0 and not Game.finish_item_use(key_uid, false, consume_key):
		return
	opened = true
	Game.world[state_key()] = true
	Game.message.emit("Door unlocked.")
	if has_node("Barrier/CollisionShape2D"):
		$Barrier/CollisionShape2D.set_deferred("disabled", true)
	Game.changed.emit()
	var tween := create_tween()
	tween.tween_property($Leaf, "position:y", -125.0, door_animation_seconds).set_trans(Tween.TRANS_SINE)
