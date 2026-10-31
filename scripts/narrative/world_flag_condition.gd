@tool
class_name WorldFlagCondition
extends Node2D
## Connect a saved story flag to editor-placed artwork, pickups and passage blockers.
@export var flag_id: String = "":
    set(value):
        flag_id = value
        if is_inside_tree() and Engine.is_editor_hint():
            update_configuration_warnings()
@export var required_value: bool = true
## Select whole pickup/interactable roots, not only their sprites.
@export var visible_when_met: Array[NodePath] = []
@export var visible_when_unmet: Array[NodePath] = []
## Whole enemy/actor roots: show and enable processing/physics only when matched.
@export var activate_when_met: Array[NodePath] = []
## Opposite activation, e.g. an actor that disappears after a story event.
@export var activate_when_unmet: Array[NodePath] = []
## Optional existing entrance/interactable roots; keeps artwork visible while gating use.
@export var enable_interaction_when_met: Array[NodePath] = []
## CollisionShape2D / CollisionPolygon2D nodes disabled when the flag matches.
@export var disable_collision_when_met: Array[NodePath] = []
@export var enable_collision_when_met: Array[NodePath] = []
var initialized := false
var matched := false
var original_process_modes: Dictionary = {}

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    Game.changed.connect(sync_state)
    # Wait for sibling pickups and doors to restore their own saved state.
    sync_state.call_deferred()

func sync_state() -> void:
    if flag_id.strip_edges().is_empty():
        return
    var next_match := bool(Game.world.get(flag_id.strip_edges(), false)) == required_value
    if initialized and next_match == matched:
        return
    initialized = true
    matched = next_match
    apply_visibility(visible_when_met, matched)
    apply_visibility(visible_when_unmet, not matched)
    apply_activation(activate_when_met, matched)
    apply_activation(activate_when_unmet, not matched)
    for path in enable_interaction_when_met:
        if not path.is_empty():
            var target := get_node_or_null(path)
            if target != null:
                target.set_meta("story_interaction_enabled", matched)
    apply_collision(disable_collision_when_met, matched)
    apply_collision(enable_collision_when_met, not matched)

func apply_visibility(paths: Array[NodePath], enabled: bool) -> void:
    for path in paths:
        if path.is_empty():
            continue
        var target := get_node_or_null(path)
        if target is CanvasItem:
            target.visible = enabled

func apply_collision(paths: Array[NodePath], disabled: bool) -> void:
    for path in paths:
        if path.is_empty():
            continue
        var target := get_node_or_null(path)
        if target is CollisionShape2D or target is CollisionPolygon2D:
            target.set_deferred("disabled", disabled)

func apply_activation(paths: Array[NodePath], enabled: bool) -> void:
    for path in paths:
        if path.is_empty():
            continue
        var target := get_node_or_null(path)
        if target == null or target.is_queued_for_deletion():
            continue
        var identity := target.get_instance_id()
        if not original_process_modes.has(identity):
            original_process_modes[identity] = target.process_mode
        if target is CanvasItem:
            target.visible = enabled
        if target.has_method("set_story_active"):
            # Signals can still reach disabled nodes. Actors also gate those
            # callbacks immediately, before the deferred physics change.
            target.set_story_active(enabled)
        target.set_meta("story_active", enabled)
        target.set_deferred("process_mode", original_process_modes[identity] if enabled else Node.PROCESS_MODE_DISABLED)

func _get_configuration_warnings() -> PackedStringArray:
    var warnings := PackedStringArray()
    if flag_id.strip_edges().is_empty():
        warnings.append("Set Flag Id to the exact saved flag written by a dialogue choice. An empty ID leaves all targets unchanged.")
    for path in visible_when_met + visible_when_unmet:
        if not path.is_empty() and not get_node_or_null(path) is CanvasItem:
            warnings.append("Visibility targets must be existing CanvasItem nodes, such as whole pickup roots or sprites.")
    for path in disable_collision_when_met + enable_collision_when_met:
        var target := get_node_or_null(path)
        if not path.is_empty() and not (target is CollisionShape2D or target is CollisionPolygon2D):
            warnings.append("Collision targets must be existing CollisionShape2D or CollisionPolygon2D nodes.")
    for path in enable_interaction_when_met:
        var target := get_node_or_null(path)
        if not path.is_empty() and (target == null or not target.has_method("interact")):
            warnings.append("Interaction targets must be existing entrance/interactable roots.")
    for path in activate_when_met + activate_when_unmet:
        if path.is_empty():
            continue
        var target := get_node_or_null(path)
        if target == null:
            warnings.append("Activation targets must be existing whole enemy/actor roots.")
        elif target.get_parent() != null and target.get_parent().has_method("set_story_active"):
            warnings.append("For an enemy, select its whole root, not Body or another child.")
        elif target.process_mode == Node.PROCESS_MODE_DISABLED:
            warnings.append("Leave an activation target's authored Process Mode on Inherit so it can be enabled.")
        elif target is CollisionObject2D and target.disable_mode != CollisionObject2D.DISABLE_MODE_REMOVE:
            warnings.append("Keep the actor's Disable Mode on Remove so its physics are removed while inactive.")
    return warnings
