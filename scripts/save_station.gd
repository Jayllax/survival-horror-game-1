extends Area2D
## Place this scene in any location. SaveSpawn controls exactly where loading returns.
@export var station_name := "Bicycle"
@export_range(32.0, 240.0) var interaction_radius := 100.0
@export var prompt_offset := Vector2(0, -66)
@export var action_label := "Ring bell / Save"
@export var bell_animation_seconds := 0.35
var ringing := false

func _ready() -> void:
    add_to_group("interactable")
    add_to_group("save_station")

func is_available() -> bool:
    return not ringing and Game.health > 0

func interaction_action() -> String:
    return action_label

func interact(_player: Node) -> void:
    if ringing or Game.transitioning or get_tree().paused or Game.health <= 0:
        return
    ringing = true
    $BellSound.play()
    # A short, symmetrical handlebar movement accompanies the bell before the menu.
    var tween := create_tween()
    tween.tween_property($Bell, "position:y", -2.0, bell_animation_seconds / 2.0).as_relative()
    tween.tween_property($Bell, "position:y", 2.0, bell_animation_seconds / 2.0).as_relative()
    await tween.finished
    ringing = false
    if Game.health <= 0 or Game.transitioning or get_tree().paused:
        return
    var player := get_tree().get_first_node_in_group("player") as Node2D
    if not player or player.global_position.distance_to(global_position) > interaction_radius:
        return
    var hud := get_tree().get_first_node_in_group("hud")
    if hud:
        hud.show_save_station(self)
