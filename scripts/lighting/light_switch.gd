@tool
class_name RoomLightSwitch
extends Area2D
## Assign room lights and optional hidden clues directly in the level Inspector.
signal toggled(lights_on: bool)

@export_group("Connections")
## Assign Light2D nodes or the root of one of the interior lamp scenes.
@export var connected_lights: Array[NodePath] = []:
    set(value):
        connected_lights = value
        if is_inside_tree() and Engine.is_editor_hint():
            update_configuration_warnings()
## Optional existing artwork/text shown when off and hidden when on.
@export var reveal_when_off: Array[NodePath] = []:
    set(value):
        reveal_when_off = value
        if is_inside_tree() and Engine.is_editor_hint():
            update_configuration_warnings()
@export var starting_on: bool = true:
    set(value):
        starting_on = value
        if is_inside_tree() and Engine.is_editor_hint():
            update_artwork(starting_on)
## Use a unique ID for each circuit. Matching IDs intentionally link two switches.
@export var persistent_id: String = ""

@export_group("Interaction")
@export_range(16.0, 240.0) var interaction_radius: float = 70.0
@export var prompt_offset: Vector2 = Vector2(0, -32)
@export var turn_off_prompt: String = "Turn lights off"
@export var turn_on_prompt: String = "Turn lights on"

var is_on := true
var initialized := false

func _ready() -> void:
    if Engine.is_editor_hint():
        update_artwork(starting_on)
        return
    add_to_group("interactable")
    Game.changed.connect(sync_state)
    # Resolve sibling lamps after their own _ready() has applied Inspector settings.
    sync_state.call_deferred()

func state_key() -> String:
    return "light_switch:" + (persistent_id if not persistent_id.is_empty() else Game.object_id(self))

func interaction_action() -> String:
    return turn_off_prompt if is_on else turn_on_prompt

func is_available() -> bool:
    return Game.health > 0

func interact(_player: Node) -> void:
    if get_tree().paused or Game.transitioning or not is_available():
        return
    var current := bool(Game.world.get(state_key(), starting_on))
    Game.world[state_key()] = not current
    # Apply local lights before notifying other systems and linked switches.
    sync_state()
    Game.changed.emit()
    toggled.emit(is_on)
    var hud := get_tree().get_first_node_in_group("hud")
    if hud:
        hud.set_interaction(self)

func sync_state() -> void:
    var key := state_key()
    if not Game.world.has(key):
        Game.world[key] = starting_on
    var next_on := bool(Game.world[key])
    if initialized and next_on == is_on:
        return
    is_on = next_on
    initialized = true
    for path in connected_lights:
        if path.is_empty():
            continue
        var target := get_node_or_null(path)
        if target == null:
            continue
        if target.has_method("set_switch_enabled"):
            target.set_switch_enabled(is_on)
        elif target is Light2D:
            # Interior lamps own their child's enabled state when refreshing art.
            var parent := target.get_parent()
            if parent != null and parent.has_method("set_switch_enabled"):
                parent.set_switch_enabled(is_on)
            else:
                target.enabled = is_on
    for path in reveal_when_off:
        if path.is_empty():
            continue
        var clue := get_node_or_null(path) as CanvasItem
        if clue:
            clue.visible = not is_on
    update_artwork(is_on)

func update_artwork(value: bool) -> void:
    var lever := get_node_or_null("Artwork/Lever") as Node2D
    if lever:
        lever.position.y = -2.0 if value else 2.0

func _get_configuration_warnings() -> PackedStringArray:
    var warnings := PackedStringArray()
    if connected_lights.is_empty() and reveal_when_off.is_empty():
        warnings.append("Assign at least one Connected Lights or Reveal When Off node in the level Inspector.")
    for path in connected_lights:
        var target := get_node_or_null(path) if not path.is_empty() else null
        if target == null or not (target is Light2D or target.has_method("set_switch_enabled")):
            warnings.append("Connected Lights: assign a Light2D or an interior lamp root: " + str(path))
    for path in reveal_when_off:
        var target := get_node_or_null(path) if not path.is_empty() else null
        if not target is CanvasItem:
            warnings.append("Reveal When Off: assign existing 2D artwork or a text Control: " + str(path))
    return warnings
