extends CanvasLayer
var busy := false
@onready var curtain: ColorRect = $Curtain

func travel(path: String, destination_spawn: String) -> void:
    if busy or Game.health <= 0:
        return
    if not ResourceLoader.exists(path):
        Game.message.emit("Destination scene is missing. Check this entrance in the Inspector.")
        return
    busy = true
    Game.transitioning = true
    curtain.mouse_filter = Control.MOUSE_FILTER_STOP
    var player := get_tree().get_first_node_in_group("player")
    if player:
        player.velocity = Vector2.ZERO
    var tween := create_tween()
    tween.tween_property(curtain, "color:a", 1.0, 0.35)
    await tween.finished
    var previous_spawn := Game.spawn_id
    Game.spawn_id = destination_spawn
    var tree := get_tree()
    var result := tree.change_scene_to_file(path)
    if result == OK:
        # SceneTree.scene_changed is unavailable in older Godot 4 releases.
        # Scene replacement is deferred: wait for the new root and its _ready().
        await tree.process_frame
        while tree.current_scene == null or not tree.current_scene.is_node_ready():
            await tree.process_frame
        Game.save_run()
    else:
        Game.spawn_id = previous_spawn
        Game.message.emit("Unable to load destination.")
    tween = create_tween()
    tween.tween_property(curtain, "color:a", 0.0, 0.4)
    await tween.finished
    curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
    Game.transitioning = false
    busy = false
