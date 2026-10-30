@tool
class_name PushableBody
extends CharacterBody2D
## Add as a CHILD of furniture. The physics body moves its parent and all artwork.
@export_group("Pushing")
@export var push_enabled: bool = true
@export_range(1.0, 200.0) var push_speed: float = 45.0
## Prevent the old furniture collider from competing with this body's collider.
@export var disable_original_collisions: bool = true

@export_group("Gravity")
@export var use_gravity: bool = true
@export_range(0.0, 3000.0) var gravity: float = 1050.0
@export_range(1.0, 2000.0) var maximum_fall_speed: float = 600.0

@export_group("Optional travel limits")
@export var use_travel_limits: bool = false
## World-pixel distances from the furniture's authored position, not its loaded position.
@export_range(0.0, 10000.0) var left_distance: float = 160.0
@export_range(0.0, 10000.0) var right_distance: float = 160.0

@export_group("Saving")
@export var remember_position: bool = true
## Unique per movable object. Keep unchanged when moving/renaming its nodes.
@export var persistent_id: String = ""

var furniture: Node2D
var body_to_furniture := Transform2D.IDENTITY
var authored_x := 0.0
var recorded_position := Vector2.INF

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    furniture = get_parent() as Node2D
    if not valid_parent() or has_active_sibling():
        collision_layer = 0
        collision_mask = 0
        set_physics_process(false)
        return
    authored_x = global_position.x
    body_to_furniture = global_transform.affine_inverse() * furniture.global_transform
    # Independent world transform avoids moving the collider twice when its parent follows.
    var placed_transform := global_transform
    top_level = true
    global_transform = placed_transform
    if disable_original_collisions:
        var originals := furniture.find_children("*", "StaticBody2D", true, false)
        if furniture is StaticBody2D:
            originals.append(furniture)
        for body in originals:
            body.collision_layer = 0
            body.collision_mask = 0
    if remember_position:
        var saved: Variant = Game.world.get(state_key())
        if saved is Dictionary and valid_saved_position(saved.get("position")):
            global_position = Vector2(saved.position[0], saved.position[1])
    add_to_group("pushable")
    sync_furniture()

func valid_parent() -> bool:
    return furniture != null and not furniture is CharacterBody2D and not furniture is RigidBody2D and not furniture.has_method("location_title")

func has_active_sibling() -> bool:
    for sibling in furniture.get_children():
        if sibling != self and sibling.is_in_group("pushable"):
            return true
    return false

func state_key() -> String:
    return "pushable:" + (persistent_id if not persistent_id.is_empty() else Game.object_id(self))

static func valid_saved_position(value: Variant) -> bool:
    if not value is Array or value.size() != 2:
        return false
    for coordinate in value:
        if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)):
            return false
    return true

func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    if Game.transitioning or Game.health <= 0 or get_tree().paused:
        velocity = Vector2.ZERO
        return
    velocity.x = 0.0 # Furniture never coasts after the player releases movement.
    velocity.y = minf(velocity.y + gravity * delta, maximum_fall_speed) if use_gravity else 0.0
    var held_x := global_position.x
    move_and_slide()
    # Only an intentional push changes X. Gravity's contact recovery must not
    # gradually shove adjacent furniture sideways or create a chain push.
    global_position.x = held_x
    sync_furniture()

## Called by the grounded player's side-contact check, once per physics step.
## Return actual travel, including walls/other bodies stopping the object.
func push_from(pusher: CharacterBody2D, requested_motion: float, delta: float) -> float:
    if not push_enabled or delta <= 0 or Game.transitioning or Game.health <= 0 or get_tree().paused:
        return 0.0
    if not pusher.is_in_group("player") or not pusher.is_on_floor():
        return 0.0
    if use_gravity and not is_on_floor():
        return 0.0
    var motion := clampf(requested_motion, -push_speed * delta, push_speed * delta)
    if use_travel_limits:
        var target := clampf(global_position.x + motion, authored_x - left_distance, authored_x + right_distance)
        motion = clampf(target - global_position.x, -push_speed * delta, push_speed * delta)
        if motion * requested_motion < 0:
            motion = 0
    if is_zero_approx(motion):
        return 0.0
    var before := global_position.x
    move_and_collide(Vector2(motion, 0), false, safe_margin)
    var travelled := global_position.x - before
    velocity.x = travelled / delta
    sync_furniture()
    return travelled

func sync_furniture() -> void:
    if not is_instance_valid(furniture):
        return
    furniture.global_transform = global_transform * body_to_furniture
    # The player queries/moves immediately after this body, within the same tick.
    # Flush its transform notification so physics sees the new collider now.
    force_update_transform()
    if remember_position and not global_position.is_equal_approx(recorded_position):
        recorded_position = global_position
        # Update memory only. Bicycle saves capture this with the rest of Game.world.
        Game.world[state_key()] = {"position": [global_position.x, global_position.y]}

func _get_configuration_warnings() -> PackedStringArray:
    var warnings := PackedStringArray()
    var parent := get_parent() as Node2D
    if parent == null or parent is CharacterBody2D or parent is RigidBody2D or parent.has_method("location_title"):
        warnings.append("Add PushableBody as a child of an individual Node2D/Sprite2D furniture object, not a player, enemy, rigid body or level root.")
    elif parent != null:
        for sibling in parent.get_children():
            if sibling != self and sibling is PushableBody:
                warnings.append("Use only one PushableBody child per furniture object.")
                break
    var collider := get_node_or_null("CollisionShape2D") as CollisionShape2D
    if collider == null or collider.shape == null:
        warnings.append("PushableBody needs its CollisionShape2D and an assigned shape.")
    if not is_zero_approx(global_rotation) or not global_scale.is_equal_approx(Vector2.ONE):
        warnings.append("Keep this physics body's global rotation at 0 and scale at (1,1). Resize its Shape; rotate/scale the furniture artwork separately.")
    return warnings
