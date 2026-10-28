extends Area2D
## Place the root on the floor. Bolt cutters open this route without being consumed.
@export_group("Interaction")
@export var required_tool: String = "bolt_cutters"
@export var interaction_radius: float = 100.0
@export var prompt_offset := Vector2(0,-74)
@export var action_label: String = "Cut fence"
## Leave blank for a scene/node-path key. Give duplicates different IDs.
@export var persistent_id: String = ""
@export_group("Cutting")
@export_range(0.05,5.0) var cut_seconds: float = 0.65
@export_range(0.05,0.4) var folded_panel_scale: float = 0.15
@export var cutting_noise_radius: float = 160.0
## Enable for the narrow end-view scene, where wire folds down to the floor.
@export var edge_on_break: bool = false
var opened := false
var cutting := false

func _ready() -> void:
    add_to_group("interactable")
    if bool(Game.world.get(state_key(),false)):
        opened = true
        apply_open_pose()
        $Barrier/CollisionShape2D.set_deferred("disabled",true)

func state_key() -> String:
    return persistent_id if not persistent_id.is_empty() else Game.object_id(self)

func interaction_action() -> String:
    return action_label

func is_available() -> bool:
    return not opened and not cutting

func interact(player: Node) -> void:
    if not is_available() or Game.transitioning or Game.health <= 0:
        return
    if not is_instance_valid(player) or not player is Node2D or global_position.distance_to(player.global_position) >= interaction_radius:
        return
    if not required_tool.is_empty() and Game.count_item(required_tool) <= 0:
        Game.message.emit("Requires " + Game.item_name(required_tool) + ".")
        return
    cutting = true
    Game.emit_noise(global_position,cutting_noise_radius,self)
    var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
    if edge_on_break:
        for panel in [$LeftPanel,$RightPanel]:
            tween.tween_property(panel,"rotation",PI/2,maxf(cut_seconds,0.05))
            tween.tween_property(panel,"position:y",-4.0,maxf(cut_seconds,0.05))
    else:
        tween.tween_property($LeftPanel,"scale:x",folded_panel_scale,maxf(cut_seconds,0.05))
        tween.tween_property($RightPanel,"scale:x",folded_panel_scale,maxf(cut_seconds,0.05))
    await tween.finished
    opened = true
    cutting = false
    Game.world[state_key()] = true
    $Barrier/CollisionShape2D.set_deferred("disabled",true)
    Game.changed.emit()

func apply_open_pose() -> void:
    if edge_on_break:
        for panel in [$LeftPanel,$RightPanel]:
            panel.rotation = PI/2
            panel.position.y = -4
    else:
        $LeftPanel.scale.x = folded_panel_scale
        $RightPanel.scale.x = folded_panel_scale
