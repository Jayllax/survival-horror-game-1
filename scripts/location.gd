extends Node2D
## Attach to every location root. Spawn markers are authored Marker2Ds, not generated.
@export var display_name: String = "Street"
@export var camera_bounds: Rect2i = Rect2i(0, 0, 3100, 720)

func checkpoint_name() -> String:
    return display_name

func _ready() -> void:
    Game.location_name = display_name
    var player := get_tree().get_first_node_in_group("player")
    var marker := get_node_or_null("Spawns/" + Game.spawn_id)
    if not marker:
        marker = get_node_or_null("Spawns/default")
    if player and marker:
        player.global_position = marker.global_position
        player.velocity = Vector2.ZERO
        var camera: Camera2D = player.get_node("Camera2D")
        camera.limit_left = camera_bounds.position.x
        camera.limit_top = camera_bounds.position.y
        camera.limit_right = camera_bounds.end.x
        camera.limit_bottom = camera_bounds.end.y
        camera.reset_smoothing()
    Game.changed.emit()
    if not Game.transitioning:
        await get_tree().process_frame
        Game.save_run()
