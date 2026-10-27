extends Node
# Runtime checks for the resized art: validate imported texture sizes and scene placement.
var checks := 0
var failures := 0

func check(ok: bool, text: String) -> void:
    checks += 1
    if ok:
        print("PASS: " + text)
    else:
        failures += 1
        push_error("FAIL: " + text)

func _ready() -> void:
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    for name in ["town", "interior", "alley"]:
        Game.reset_run()
        var scene: Node2D = load("res://scenes/levels/" + name + ".tscn").instantiate()
        scene.get_node("AmbientSound").autoplay = false
        get_tree().root.add_child(scene)
        get_tree().current_scene = scene
        await get_tree().physics_frame
        await get_tree().process_frame
        for building in scene.get_node("Buildings").get_children():
            if building is Sprite2D and not building.region_enabled:
                var bottom: float = building.global_position.y + building.texture.get_height() * building.global_scale.y / 2
                check(is_equal_approx(bottom,620), name + ": resized building stays grounded / " + building.name)
        for object in scene.get_node("Interactables").get_children():
            if object.get("kind") == 5 and object.has_node("Facade"):
                var facade: Sprite2D = object.get_node("Facade")
                var bottom: float = facade.global_position.y + facade.texture.get_height() * facade.global_scale.y / 2
                check(is_equal_approx(bottom,620), name + ": doorway art meets ground / " + object.name)
            if object.get("kind") == 3:
                var leaf: Sprite2D = object.get_node("Leaf")
                check(is_equal_approx(leaf.global_position.y + leaf.texture.get_height()/2.0,620), name + ": physical gate art aligns with collision floor")
        for object in scene.get_node("Props").get_children():
            if object.has_node("Post"):
                var post: Sprite2D = object.get_node("Post")
                var light: PointLight2D = object.get_node("WarmLight")
                check(is_equal_approx(post.global_position.y + post.texture.get_height()/2.0,620), name + ": resized lamp meets ground / " + object.name)
                var bulb: Vector2 = post.global_position + Vector2(4,-72)
                check(light.global_position.distance_to(bulb) <= 1, name + ": lamp light is attached to new bulb / " + object.name)
        var player: CharacterBody2D = scene.get_node("Actors/Player")
        check(player.get_node("Body").hframes == 6 and player.get_node("Body").texture.get_height() == 72, name + ": existing player animation dimensions remain valid")
        scene.queue_free()
        get_tree().current_scene = null
        await get_tree().process_frame
        await get_tree().physics_frame
    print("IGNOTUM ASSETS: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures == 0 else 1)
