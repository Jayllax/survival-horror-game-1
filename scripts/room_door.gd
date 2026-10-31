@tool
class_name RoomDoor
extends Area2D
## A physical doorway inside one level. Place the root on the floor.
signal toggled(is_open: bool)

@export_group("Door")
@export var starting_open: bool = false:
	set(value):
		starting_open = value
		preview_pose()
@export var allow_close: bool = true
## Projects the open leaf to the left rather than the right of its hinge.
@export var opens_left: bool = false:
	set(value):
		opens_left = value
		preview_pose()
@export_range(0.1, 3.0) var opening_seconds: float = 0.4
## Keep unique and stable when rearranging placed doors.
@export var persistent_id: String = ""

@export_group("Interaction")
@export_range(16.0, 200.0) var interaction_radius: float = 60.0
@export var prompt_offset := Vector2(0, -58)
@export var open_prompt: String = "Open door"
@export var close_prompt: String = "Close door"
## Optional inventory ID. Blank makes a normal unlocked door.
@export var required_key: String = ""
@export var locked_message: String = "The door is locked."
@export var blocked_message: String = "The doorway is blocked."

var opened := false
var unlocked := false
var moving := false
var _target_open := false
var _amount := 0.0
var _pending_actor: WeakRef

func _ready() -> void:
	if Engine.is_editor_hint():
		preview_pose()
		return
	add_to_group("interactable")
	opened = bool(Game.world.get(state_key(), starting_open))
	unlocked = required_key.is_empty() or starting_open or bool(Game.world.get(unlock_key(), false))
	_target_open = opened
	_amount = 1.0 if opened else 0.0
	apply_pose(_amount)
	$Barrier/CollisionShape2D.set_deferred("disabled", opened)
	$LightOccluder2D.visible = not opened

func state_key() -> String:
	return "room_door:" + (persistent_id if not persistent_id.is_empty() else Game.object_id(self))

func unlock_key() -> String:
	return state_key() + ":unlocked"

func interaction_action() -> String:
	return close_prompt if opened else open_prompt

func is_available() -> bool:
	return not moving and _pending_actor == null and Game.health > 0 and (not opened or allow_close)

func interact(player: Node) -> void:
	if not is_available() or get_tree().paused or Game.transitioning or not actor_in_reach(player):
		return
	# Closing uses a physics overlap query. Handle the request in a physics tick.
	_pending_actor = weakref(player)

func actor_in_reach(player: Node) -> bool:
	return is_instance_valid(player) and player is Node2D and global_position.distance_to(player.global_position) < interaction_radius

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _pending_actor != null:
		var actor: Node = _pending_actor.get_ref()
		_pending_actor = null
		if not Game.transitioning and Game.health > 0 and actor_in_reach(actor):
			begin_toggle()
	if not moving or Game.transitioning or Game.health <= 0:
		return
	if not _target_open and doorway_occupied():
		# A player, enemy or pushable can enter while the leaf is closing.
		# Reverse before ever enabling its solid collider around them.
		_target_open = true
		Game.message.emit(blocked_message)
	var destination := 1.0 if _target_open else 0.0
	_amount = move_toward(_amount, destination, delta / maxf(opening_seconds, 0.1))
	apply_pose(_amount)
	if is_equal_approx(_amount, destination):
		finish_motion()

func begin_toggle() -> void:
	if opened:
		if not allow_close:
			return
		if doorway_occupied():
			Game.message.emit(blocked_message)
			return
	elif not unlocked:
		var uid := Game.find_use_uid(required_key)
		if uid < 0 or not Game.finish_item_use(uid, false):
			Game.message.emit(locked_message)
			return
		unlocked = true
		# Unlock separately so a disposable key is never needed twice, even if
		# the scene is left or saved before the opening animation has finished.
		Game.world[unlock_key()] = true
		Game.changed.emit()
	_target_open = not opened
	moving = true

func finish_motion() -> void:
	var was_open := opened
	opened = _target_open
	moving = false
	$Barrier/CollisionShape2D.set_deferred("disabled", opened)
	$LightOccluder2D.visible = not opened
	Game.world[state_key()] = opened
	Game.changed.emit()
	if was_open != opened:
		toggled.emit(opened)

func doorway_occupied() -> bool:
	var collision: CollisionShape2D = $Barrier/CollisionShape2D
	if collision.shape == null:
		return true
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.collision_mask = 7 # World/pushables, player and enemies.
	query.exclude = [$Barrier.get_rid()]
	query.collide_with_areas = false
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 128):
		if hit.collider is CharacterBody2D or hit.collider is RigidBody2D:
			return true
	return false

func preview_pose() -> void:
	if not is_inside_tree() or not Engine.is_editor_hint():
		return
	apply_pose(1.0 if starting_open else 0.0)
	var collision := get_node_or_null("Barrier/CollisionShape2D") as CollisionShape2D
	if collision:
		collision.disabled = starting_open
	var occluder := get_node_or_null("LightOccluder2D") as LightOccluder2D
	if occluder:
		occluder.visible = not starting_open

func apply_pose(amount: float) -> void:
	var pivot := get_node_or_null("Artwork/LeafPivot") as Node2D
	if pivot == null:
		return
	var direction := -1.0 if opens_left else 1.0
	# Simulate turning into the depth of a 2D room without rotating the leaf
	# sideways across the floor. Nearest filtering keeps the pixel blocks crisp.
	var eased := sin(clampf(amount, 0.0, 1.0) * PI / 2.0)
	pivot.scale.x = direction * lerpf(0.125, 1.0, eased)
	pivot.visible = amount > 0.0
