extends Node
# Optional rendering check. Run with an X11 display (see DESIGNER_GUIDE).
func _ready() -> void:
    capture.call_deferred()

func capture() -> void:
    var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
    add_child(menu)
    await get_tree().create_timer(0.5).timeout
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("/tmp/ignotum-menu.png")
    menu.queue_free()
    Game.reset_run()
    var level: Node2D = load("res://scenes/levels/town.tscn").instantiate()
    # Screenshot capture is silent; audio playback is exercised by smoke.tscn.
    level.get_node("AmbientSound").autoplay = false
    add_child(level)
    await get_tree().create_timer(0.5).timeout
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("/tmp/ignotum-town.png")
    var player: CharacterBody2D = level.get_node("Actors/Player")
    player.position = Vector2(1590, 582)
    await get_tree().create_timer(0.8).timeout
    var hud: CanvasLayer = level.get_node("HUD")
    hud.show_note(level.get_node("Interactables/StationNotice").description)
    await get_tree().create_timer(0.3).timeout
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("/tmp/ignotum-note.png")
    hud.close_panels()
    hud.show_puzzle(level.get_node("Interactables/Switchboard"))
    await get_tree().create_timer(0.3).timeout
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("/tmp/ignotum-puzzle.png")
    hud.close_panels()
    level.get_node("AmbientSound").stop()
    level.queue_free()
    for i in 3:
        await get_tree().physics_frame
        await get_tree().process_frame
    get_tree().quit()
