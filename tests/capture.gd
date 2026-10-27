extends Node
func _ready() -> void:
    run.call_deferred()

func snap(path: String) -> void:
    await get_tree().create_timer(0.4).timeout
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(path)

func run() -> void:
    get_tree().current_scene = null
    var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
    add_child(menu)
    await snap("/tmp/ignotum-menu.png")
    menu.queue_free()
    for name in ["town", "interior", "alley"]:
        Game.reset_run()
        var location: Node2D = load("res://scenes/levels/" + name + ".tscn").instantiate()
        location.get_node("AmbientSound").autoplay = false
        get_tree().root.add_child(location)
        get_tree().current_scene = location
        var player: CharacterBody2D = location.get_node("Actors/Player")
        await get_tree().create_timer(0.3).timeout
        player.set_physics_process(false)
        player.aim.rotation = 0
        await snap("/tmp/ignotum-" + name + ".png")
        if name == "town":
            player.position.x = 900
            await snap("/tmp/ignotum-alley-entrance.png")
        location.queue_free()
        get_tree().current_scene = null
        for i in 4:
            await get_tree().process_frame
    get_tree().quit()
