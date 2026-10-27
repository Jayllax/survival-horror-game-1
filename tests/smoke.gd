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

func frames(n: int) -> void:
    for i in n:
        await get_tree().physics_frame
        await get_tree().process_frame

func press(action: String) -> void:
    Input.action_press(action)
    await frames(2)
    Input.action_release(action)
    await frames(1)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    for index in Game.SAVE_SLOT_COUNT:
        if FileAccess.file_exists(Game.slot_path(index)):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(index)))
    Game.reset_run()
    check(Game.slots.size() == 8, "Eight inventory slots")
    Game.add_item("ammo", 20)
    check(Game.slots[0]["count"] == 24 and Game.slots[1]["count"] == 8, "Ammo stack split at 24")
    for i in 6:
        Game.add_item("test" + str(i))
    check(not Game.add_item("fuse") and Game.count_item("fuse") == 0, "Full inventory rejects pickup atomically")
    check(not Game.take_item("ammo", 99), "No negative reserve")
    Game.reset_run()
    Game.add_item("fuse")
    for i in 6:
        Game.add_item("object" + str(i))
    var board: Area2D = load("res://scenes/objects/switchboard.tscn").instantiate()
    var other_board: Area2D = load("res://scenes/objects/switchboard.tscn").instantiate()
    other_board.power_channel = "basement"
    add_child(board)
    add_child(other_board)
    check(not board.solve_puzzle(Vector3i(1,1,1)), "Wrong puzzle answer costs nothing")
    check(board.solve_puzzle(Vector3i(3,1,2)) and Game.count_item("gate_key") == 1 and Game.count_item("fuse") == 0, "Full inventory exchanges puzzle item for reward")
    check(board.is_powered() and not other_board.is_powered(), "Independent power circuits")
    var gate: Area2D = load("res://scenes/objects/door.tscn").instantiate()
    gate.requires_power = false
    gate.persistent_id = "test_gate"
    add_child(gate)
    gate.open_door()
    await get_tree().create_timer(0.9).timeout
    check(gate.opened and gate.get_node("Leaf").position.y < -120 and gate.get_node("Barrier/CollisionShape2D").disabled, "Animated door opens and releases collision")
    check(Game.count_item("gate_key") == 1 and Game.world.get("test_gate", false), "Door preserves reusable key and records unlock")
    gate.queue_free()
    board.queue_free()
    other_board.queue_free()
    var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
    get_tree().root.add_child(menu)
    get_tree().current_scene = menu
    menu.get_node("Start").pressed.emit()
    await frames(8)
    var town: Node2D = get_tree().current_scene
    check(town.scene_file_path.ends_with("town.tscn"), "Menu starts street")
    check(not town.has_node("HUD/Root/EndingPanel"), "No ending screen")
    var player: CharacterBody2D = town.get_node("Actors/Player")
    check(player.is_on_floor(), "Spawn lands on street")
    var x: float = player.position.x
    Input.action_press("move_right")
    await frames(20)
    Input.action_release("move_right")
    check(player.position.x > x + 40, "Movement input")
    var y: float = player.position.y
    await press("jump")
    await frames(8)
    check(player.position.y < y - 20, "Jump input")
    await frames(60)
    check(player.is_on_floor(), "Gravity and ground collision")
    var light: PointLight2D = player.get_node("Aim/Gun/Flashlight")
    check(light.get_parent() == player.get_node("Aim/Gun"), "Flashlight physically parented to gun")
    check(light.offset.x == 256, "Beam texture extends forward from barrel, not behind player")
    var enabled: bool = light.enabled
    await press("flashlight")
    check(light.enabled != enabled and Game.flashlight_on == light.enabled, "F toggles equipped flashlight")
    await press("flashlight")
    player.set_physics_process(false)
    for angle in [0.0, PI, -PI/2, PI/2]:
        player.aim.rotation = angle
        var forward := Vector2.RIGHT.rotated(angle)
        check((light.global_position + forward * light.offset.x - player.aim.global_position).dot(forward) > 200, "Flashlight beam extends ahead of grip at angle %.2f" % angle)
    player.begin_dodge(1)
    check(is_equal_approx(player.invulnerable_remaining, 0.5), "Exactly 0.5s dodge window")
    player.take_damage(10)
    check(Game.health == 100, "Dodge blocks initial damage")
    player._physics_process(0.499)
    player.take_damage(10)
    check(Game.health == 100, "Dodge blocks before boundary")
    player._physics_process(0.0011)
    player.take_damage(10)
    check(Game.health == 90, "Damage applies after 0.5s")
    player.set_physics_process(true)
    player.position = Vector2(town.get_node("Interactables/ShopEntrance").position.x,588)
    await frames(3)
    await press("interact")
    check(Game.transitioning, "E starts entrance fade")
    # Input is locked; a second entrance request cannot start another transition.
    Transition.travel("res://scenes/levels/alley.tscn", "default")
    await get_tree().create_timer(1.2).timeout
    var interior: Node2D = get_tree().current_scene
    check(interior.scene_file_path.ends_with("interior.tscn") and not Game.transitioning, "Fade loads interior and completes")
    check(not Transition.busy and is_zero_approx(Transition.curtain.color.a), "Transition completes fade and releases input lock")
    check(not Game.has_saves(), "Entering a location does not create an automatic save")
    player = interior.get_node("Actors/Player")
    check(absf(player.position.x - interior.get_node("Spawns/from_street").position.x) < 2, "Named entry spawn selected")
    check(Game.health == 90 and Game.magazine == 6, "Health and magazine persist between scenes")
    var supply: Area2D = interior.get_node("Interactables/SupplyBox")
    player.global_position = supply.global_position + Vector2(0, 20)
    await frames(1)
    await press("interact")
    check(Game.count_item("ammo") == 24, "Interior pickup collected")
    check(Game.world.size() == 1, "Pickup stores stable location state")
    player.position = Vector2(interior.get_node("Interactables/ExitToStreet").position.x,588)
    await frames(3)
    await press("interact")
    await get_tree().create_timer(1.2).timeout
    town = get_tree().current_scene
    player = town.get_node("Actors/Player")
    check(town.scene_file_path.ends_with("town.tscn") and absf(player.position.x-town.get_node("Spawns/from_shop").position.x)<2, "Return door selects street return marker")
    player.position = Vector2(town.get_node("Interactables/ShopEntrance").position.x,588)
    await frames(3)
    await press("interact")
    await get_tree().create_timer(1.2).timeout
    interior = get_tree().current_scene
    check(not interior.has_node("Interactables/SupplyBox"), "Collected item stays absent on revisit")
    Transition.travel("res://scenes/levels/town.tscn", "from_shop")
    await get_tree().create_timer(1.2).timeout
    town = get_tree().current_scene
    player = town.get_node("Actors/Player")
    player.position = Vector2(1240,588)
    await frames(3)
    await press("interact")
    await get_tree().create_timer(1.2).timeout
    var alley: Node2D = get_tree().current_scene
    check(alley.scene_file_path.ends_with("alley.tscn"), "E enters alley using same portal system")
    player = alley.get_node("Actors/Player")
    var enemy: CharacterBody2D = alley.get_node("Actors/Enemy")
    enemy.set_physics_process(false)
    player.position = Vector2(1000,588)
    enemy.position = Vector2(1120,588)
    await frames(3)
    player.aim.rotation = 0
    player.shoot()
    check(enemy.health == 52 and Game.magazine == 5, "Hitscan damages enemy and spends round")
    player.reload_seconds = 0.1
    player.reload_weapon()
    await frames(15)
    check(Game.magazine == 6 and Game.count_item("ammo") == 23, "Reload transfers reserve")
    player.position = Vector2(1070,588)
    player.facing = 1
    player.melee()
    check(enemy.health == 18, "Melee damages nearby enemy")
    enemy.attack_cooldown = 0
    enemy.set_physics_process(true)
    await frames(8)
    check(Game.health < 90, "Enemy attacks")
    enemy.take_damage(100)
    await frames(3)
    check(get_tree().get_nodes_in_group("enemy").is_empty(), "Enemy defeat")
    var test_bike: Area2D = load("res://scenes/objects/save_bicycle.tscn").instantiate()
    test_bike.position = Vector2(1000,620)
    alley.get_node("Interactables").add_child(test_bike)
    player.position = Vector2(960,588)
    check(Game.save_slot(0, test_bike) and Game.has_saves(), "Bicycle writes a manual save")
    Game.health = 1
    Game.world.clear()
    Game.load_slot(0)
    await frames(10)
    alley = get_tree().current_scene
    check(Game.health > 1 and Game.count_item("ammo") == 23, "Continue restores health and inventory")
    check(not alley.has_node("Actors/Enemy"), "Continue restores defeated enemy state")
    var hud: CanvasLayer = alley.get_node("HUD")
    hud.toggle_pause()
    check(get_tree().paused, "Pause")
    hud.toggle_pause()
    check(not get_tree().paused, "Resume")
    player = alley.get_node("Actors/Player")
    player.take_damage(100)
    check(get_tree().paused and hud.get_node("Root/PausePanel/Resume").disabled, "Death disables Continue")
    var escape := InputEventAction.new()
    escape.action = "pause"
    escape.pressed = true
    hud._input(escape)
    check(get_tree().paused, "Escape cannot bypass death screen")
    Game.load_slot(0)
    await frames(10)
    check(Game.health > 0 and not get_tree().paused, "Retry restores saved game")
    var running: Node = get_tree().current_scene
    running.get_node("HUD").back_to_menu()
    await frames(6)
    check(not get_tree().current_scene.get_node("Continue").disabled, "Menu load picker available after manual save")
    var final_menu: Control = get_tree().current_scene
    final_menu.get_node("Start").pressed.emit()
    await frames(6)
    check(Game.has_saves(), "Starting a new game preserves existing manual saves")
    get_tree().current_scene.get_node("HUD").back_to_menu()
    await frames(6)
    final_menu = get_tree().current_scene
    final_menu.set_volume(-12)
    check(is_equal_approx(AudioServer.get_bus_volume_db(0), -12), "Options slider changes master volume")
    final_menu.set_volume(0)
    get_tree().current_scene.queue_free()
    get_tree().current_scene = null
    await frames(6)
    print("IGNOTUM: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)
