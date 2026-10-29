extends Node
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
    checks += 1
    if ok:
        print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)

func frames(count: int = 3) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame

func mouse_at(world_point: Vector2) -> void:
    var event := InputEventMouseMotion.new()
    event.position = get_viewport().get_canvas_transform() * world_point
    event.global_position = event.position
    Input.parse_input_event(event)
    await frames()

func right_mouse(pressed: bool) -> void:
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_RIGHT
    event.button_mask = MOUSE_BUTTON_MASK_RIGHT if pressed else 0
    event.pressed = pressed
    event.position = get_viewport().get_mouse_position()
    event.global_position = event.position
    Input.parse_input_event(event)
    await frames()

func _ready() -> void:
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    Game.reset_run()
    preload("res://tests/support/loadout.gd").handgun()
    var room: Node2D = load("res://scenes/levels/house_01.tscn").instantiate()
    room.get_node("AmbientSound").autoplay = false
    get_tree().root.add_child(room)
    get_tree().current_scene = room
    await frames(8)
    var player: CharacterBody2D = room.get_node("Actors/Player")
    var gun: Sprite2D = player.get_node("Aim/Gun")
    var light: PointLight2D = gun.get_node("Flashlight")
    var hud: CanvasLayer = room.get_node("HUD")
    check(Game.has_equipped_weapon() and gun.texture == null, "Equipped gun starts holstered")
    check(gun.visible and light.enabled and light.is_visible_in_tree(), "Holstering keeps the flashlight node active")
    await mouse_at(player.global_position + Vector2(-180, -100))
    check(player.facing == 1 and is_zero_approx(player.aim.rotation), "Idle mouse movement cannot turn the player or flashlight")
    Input.action_press("move_left")
    await frames(6)
    Input.action_release("move_left")
    await frames(6)
    check(player.facing < 0 and is_equal_approx(absf(player.aim.rotation), PI), "Walking left points the flashlight left")
    await mouse_at(player.global_position + Vector2(180, -100))
    check(player.facing < 0 and is_equal_approx(absf(player.aim.rotation), PI), "Stopping retains the last walking direction despite cursor position")
    await right_mouse(true)
    var target_angle: float = (player.get_global_mouse_position() - player.aim.global_position).angle()
    check(Input.is_action_pressed("aim") and player.is_aiming(), "Actual right mouse button engages aiming")
    check(is_equal_approx(player.aim.rotation, target_angle) and not is_zero_approx(sin(target_angle)), "Held aim points the gun and flashlight at the cursor")
    check(gun.texture == Game.active_weapon().weapon_texture and hud.get_node("Root/Crosshair").visible, "Aiming draws the equipped weapon and crosshair")
    await mouse_at(player.global_position + Vector2(-150, -90))
    check(player.facing < 0 and gun.flip_v and light.position.y == -4, "Aiming across the player mirrors the gun and flashlight correctly")
    await mouse_at(player.global_position + Vector2(150, -90))
    var rounds := Game.magazine
    Input.action_press("shoot")
    await frames(2)
    check(Game.magazine == rounds - 1, "Left click while aiming fires one round")
    await right_mouse(false)
    await frames(24)
    Input.action_release("shoot")
    check(Game.magazine == rounds - 1, "Releasing right mouse blocks further shots even with left mouse held")
    check(gun.texture == null and not player.is_aiming(), "Releasing aim immediately holsters the gun")
    check(is_zero_approx(player.aim.rotation) and light.enabled, "Released aim returns the working flashlight to horizontal facing")
    check(not hud.get_node("Root/Crosshair").visible and hud.get_node("Root/Ammo").visible, "Recent firing keeps brief ammo feedback without a cursor crosshair")
    player.shoot()
    check(Game.magazine == rounds - 1, "Holstered shooting is rejected at the combat entry point")
    Game.add_item(Game.active_weapon().ammunition_id, 3)
    Input.action_press("reload")
    await frames(2)
    Input.action_release("reload")
    check(player.reload_remaining > 0 and gun.texture == null, "Reload remains available with the gun holstered")
    await get_tree().create_timer(player.reload_seconds + 0.1).timeout
    check(Game.magazine == rounds and gun.texture == null and not hud.get_node("Root/Crosshair").visible, "Holstered reload transfers ammunition without drawing the gun or crosshair")
    var pistol_uid := Game.equipped_uid
    Game.equip_weapon(pistol_uid)
    await right_mouse(true)
    await mouse_at(player.global_position + Vector2(-160, -90))
    target_angle = (player.get_global_mouse_position() - player.aim.global_position).angle()
    check(not Game.has_equipped_weapon() and gun.texture == null and is_equal_approx(player.aim.rotation, target_angle), "Unarmed right mouse still aims the flashlight without drawing a weapon")
    check(not hud.get_node("Root/Crosshair").visible, "Unarmed flashlight aiming does not show weapon feedback")
    var beam_direction := Vector2.RIGHT.rotated(light.global_rotation)
    check(beam_direction.distance_to((player.get_global_mouse_position()-light.global_position).normalized())<0.001, "Unarmed flashlight aims at the cursor from its animated hand, rather than the old chest position")
    var was_enabled := light.enabled
    Input.action_press("flashlight")
    await frames(2)
    Input.action_release("flashlight")
    check(light.enabled != was_enabled and Game.flashlight_on == light.enabled, "F toggles the flashlight independently of aiming and equipment")
    await right_mouse(false)
    Game.equip_weapon(pistol_uid)
    await frames()
    check(Game.has_equipped_weapon() and gun.texture == null, "Equipping through inventory state keeps the gun holstered until aim is held")
    Input.action_press("move_right")
    await frames(6)
    Input.action_release("move_right")
    await frames()
    check(player.facing > 0 and is_zero_approx(player.aim.rotation), "Walking right restores forward flashlight direction after unarmed aiming")
    room.queue_free()
    get_tree().current_scene = null
    await frames()
    print("IGNOTUM AIMING: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)
