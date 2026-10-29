@tool
class_name CodeLock
extends Area2D
## Invisible interaction component: place beside furniture, containers or doors.
signal unlocked

@export_group("Lock")
## Keep this a string so codes such as 0042 retain their leading zeroes.
@export var correct_code: String = "0000":
    set(value):
        correct_code = value
        if is_inside_tree() and Engine.is_editor_hint():
            update_configuration_warnings()
@export var starting_code: String = "0000":
    set(value):
        starting_code = value
        if is_inside_tree() and Engine.is_editor_hint():
            update_configuration_warnings()
@export var panel_title: String = "CODE LOCK"
@export var action_label: String = "Examine lock"
@export_range(16.0, 240.0) var interaction_radius: float = 70.0
@export var prompt_offset: Vector2 = Vector2(0, -50)
## Give each placed lock a unique ID to preserve saves when rearranging a level.
@export var persistent_id: String = ""

@export_group("Contents (optional)")
## Given once when unlocking. An inventory that cannot fit it leaves the lock closed.
@export var reward_item: InventoryItemDefinition
@export_range(1, 99) var reward_quantity: int = 1

@export_group("Opening (optional)")
## Drag an existing collision shape here to let the player pass after unlocking.
@export_node_path("CollisionShape2D", "CollisionPolygon2D") var blocker_path: NodePath
## Optional closed/open artwork belonging to this lock or its furniture.
@export_node_path("CanvasItem") var locked_visual_path: NodePath
@export_node_path("CanvasItem") var unlocked_visual_path: NodePath
@export_node_path("AnimationPlayer") var animation_player_path: NodePath
@export var unlock_animation: StringName = &"open"
## Optional exact Game.world flag for other puzzle systems.
@export var completion_flag: String = ""

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    add_to_group("interactable")
    if reward_item:
        Game.register_item(reward_item)
    if has_unlocked():
        apply_open_state(true)

static func valid_code(value: String) -> bool:
    if value.length() != 4:
        return false
    for digit in value:
        if digit < "0" or digit > "9":
            return false
    return true

func _get_configuration_warnings() -> PackedStringArray:
    var warnings := PackedStringArray()
    if not valid_code(correct_code):
        warnings.append("Correct Code must contain exactly four digits (0–9), for example 0042.")
    if not valid_code(starting_code):
        warnings.append("Starting Code must contain four digits. Invalid values use 0000.")
    return warnings

func state_key() -> String:
    return "code_lock:" + (persistent_id if not persistent_id.is_empty() else Game.object_id(self))

func has_unlocked() -> bool:
    return bool(Game.world.get(state_key(), false))

func current_digits() -> String:
    var saved: Variant = Game.world.get(state_key() + ":dials", starting_code)
    return saved if saved is String and valid_code(saved) else "0000"

func remember_digits(value: String) -> void:
    if valid_code(value) and not has_unlocked():
        Game.world[state_key() + ":dials"] = value

func interaction_action() -> String:
    return action_label

func is_available() -> bool:
    return not has_unlocked()

func interact(_player: Node) -> void:
    if not is_available() or get_tree().paused or Game.transitioning or Game.health <= 0:
        return
    var hud := get_tree().get_first_node_in_group("hud")
    if hud:
        hud.show_code_lock(self)

## Empty feedback means success. No inventory or progress changes on failure.
func attempt_unlock(value: String) -> String:
    if has_unlocked():
        return ""
    if not valid_code(correct_code):
        return "This lock has not been configured."
    if not valid_code(value) or value != correct_code:
        return "The lock stays closed."
    if reward_item:
        var trial := Game.inventory.copy()
        if not trial.add(reward_item.id, reward_quantity):
            return "Make room in your inventory before opening this lock."
        Game.inventory = trial
    Game.world[state_key()] = true
    Game.world.erase(state_key() + ":dials")
    if not completion_flag.is_empty():
        Game.world[completion_flag] = true
    apply_open_state(false)
    Game.changed.emit()
    unlocked.emit()
    return ""

func apply_open_state(restoring: bool) -> void:
    if not blocker_path.is_empty():
        var blocker := get_node_or_null(blocker_path)
        if blocker is CollisionShape2D or blocker is CollisionPolygon2D:
            blocker.set_deferred("disabled", true)
    if not locked_visual_path.is_empty():
        var artwork := get_node_or_null(locked_visual_path) as CanvasItem
        if artwork:
            artwork.hide()
    if not unlocked_visual_path.is_empty():
        var artwork := get_node_or_null(unlocked_visual_path) as CanvasItem
        if artwork:
            artwork.show()
    if not animation_player_path.is_empty():
        var animator := get_node_or_null(animation_player_path) as AnimationPlayer
        if animator and animator.has_animation(unlock_animation):
            animator.play(unlock_animation)
            if restoring:
                animator.seek(animator.get_animation(unlock_animation).length, true)
                animator.pause()
