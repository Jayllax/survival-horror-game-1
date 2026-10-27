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
        var hud: CanvasLayer = location.get_node("HUD")
        await get_tree().create_timer(0.3).timeout
        player.set_physics_process(false)
        player.aim.rotation = 0
        hud.set_interaction(null)
        await snap("/tmp/ignotum-" + name + ".png")
        if name == "town":
            player.position = Vector2(150,588)
            player.update_interaction()
            player.get_node("Camera2D").force_update_scroll()
            await snap("/tmp/ignotum-bicycle.png")
            hud.show_save_station(location.get_node("Interactables/SaveBicycle"))
            await snap("/tmp/ignotum-save-menu.png")
            hud.get_node("SaveMenu").close()
            player.combat_remaining = 10
            await snap("/tmp/ignotum-combat.png")
        if name == "interior":
            player.global_position = location.get_node("Interactables/SupplyBox").global_position + Vector2(0,20)
            player.update_interaction()
            await snap("/tmp/ignotum-pickup-prompt.png")
            Game.add_item("bandage")
            Game.add_item("cloth")
            Game.add_item("antiseptic")
            Game.add_item("bolt_cutters")
            Game.move_item(Game.inventory.first_uid("pistol"), Vector2i(6,1), true)
            hud.open_inventory()
            await snap("/tmp/ignotum-inventory.png")
            Game.health = 70
            Game.changed.emit()
            hud.select_item(Game.inventory.first_uid("pistol"))
            await snap("/tmp/ignotum-inventory-inspect.png")
            hud.close_panels()
        location.queue_free()
        get_tree().current_scene = null
        for i in 4:
            await get_tree().process_frame
    get_tree().quit()
