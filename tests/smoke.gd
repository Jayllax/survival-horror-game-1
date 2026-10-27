extends Node
# Integration tests exercise the authored level, real physics, UI, and shared state.
var checks := 0
var failures := 0
var level: Node2D
var player: CharacterBody2D
var hud: CanvasLayer

func check(condition: bool, description: String) -> void:
    checks += 1
    if condition:
        print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)

func frames(amount: int) -> void:
    for i in amount:
        await get_tree().physics_frame
        await get_tree().process_frame

func press(action: String) -> void:
    Input.action_press(action)
    await frames(2)
    Input.action_release(action)
    await frames(1)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    run.call_deferred()

func run() -> void:
    Game.reset_run()
    check(Game.slots.size() == 8, "Exactly eight inventory slots")
    check(Game.count_item("ammo") == 12 and Game.magazine == 6, "Starting ammunition")
    check(Game.add_item("ammo", 20), "Ammunition stacks across slots")
    check(Game.slots[0]["count"] == 24 and Game.slots[1]["count"] == 8, "24-round stack cap")
    for i in 6:
        check(Game.add_item("object_" + str(i)), "Fill pocket %d" % i)
    check(not Game.add_item("fuse"), "Full inventory rejects new item without losing it")
    check(Game.count_item("fuse") == 0, "Failed pickup is atomic")
    check(not Game.take_item("ammo", 33), "Cannot remove more ammunition than owned")
    Game.reset_run()
    level = load("res://scenes/levels/town.tscn").instantiate()
    add_child(level)
    player = level.get_node("Actors/Player")
    hud = level.get_node("HUD")
    # Keep the enemy still while testing movement; use it for combat later.
    var enemy: CharacterBody2D = level.get_node("Actors/LostMemory")
    enemy.set_physics_process(false)
    await frames(10)
    check(player.is_on_floor(), "Player lands on authored street collision")
    var start_x: float = player.position.x
    Input.action_press("move_right")
    await frames(15)
    Input.action_release("move_right")
    check(player.position.x > start_x + 30, "Movement input moves player right")
    await frames(2)
    var grounded_y: float = player.position.y
    await press("jump")
    await frames(6)
    check(player.position.y < grounded_y - 15, "Jump input lifts player")
    await frames(65)
    check(player.is_on_floor(), "Gravity returns player to street")
    check(player.get_node("Camera2D").enabled, "Follow camera is enabled")
    var flashlight: PointLight2D = player.get_node("Aim/Flashlight")
    var initial_light: bool = flashlight.enabled
    await press("flashlight")
    check(flashlight.enabled != initial_light and Game.slots.size() == 8, "F toggles actual 2D light without inventory slot")
    await press("flashlight")
    # Freeze physics for exact boundary tests: damage works immediately when 0.5s expires.
    player.set_physics_process(false)
    player.begin_dodge(1.0)
    check(is_equal_approx(player.invulnerable_remaining, 0.5), "Dodge grants exactly 0.5 seconds")
    player.take_damage(10)
    check(Game.health == 100, "Damage blocked at start of dodge")
    player._physics_process(0.499)
    player.take_damage(10)
    check(Game.health == 100, "Damage blocked before 0.5 seconds")
    player._physics_process(0.0011)
    player.take_damage(10)
    check(Game.health == 90, "Damage applies after 0.5 seconds with no extra grace")
    player.dodge_remaining = 0.0
    player.invulnerable_remaining = 0.0
    player.set_physics_process(true)
    # Traverse the actual route using movement and jump inputs, without teleporting past obstacles.
    Input.action_press("move_right")
    var route_frames := 0
    while player.position.x < 1110 and route_frames < 600:
        if player.is_on_floor() and player.is_on_wall():
            await press("jump")
            route_frames += 3
        else:
            await frames(2)
            route_frames += 2
    Input.action_release("move_right")
    check(player.position.x >= 1110, "Authored station step and stacked crates are traversable with movement and jumps")
    enemy.position = player.position + Vector2(40, 0)
    var health_before_contact: int = Game.health
    enemy.set_physics_process(true)
    await frames(10)
    enemy.set_physics_process(false)
    check(Game.health < health_before_contact, "Enemy AI attacks and damages nearby player")
    # Exercise hitscan against the actual enemy collider.
    player.position = Vector2(1150, 582)
    enemy.position = Vector2(1300, 582)
    await frames(3)
    player.aim.rotation = 0.0
    player.shot_cooldown = 0.0
    player.shoot()
    check(enemy.health == 52 and Game.magazine == 5, "Hitscan shot damages enemy and spends magazine round")
    player.reload_seconds = 0.08
    player.reload_weapon()
    await frames(12)
    check(Game.magazine == 6 and Game.count_item("ammo") == 11, "Timed reload transfers reserve rounds")
    player.position = Vector2(1250, 582)
    player.facing = 1.0
    await frames(3)
    await press("melee")
    check(enemy.health == 18, "Melee input damages nearby enemy")
    enemy.take_damage(18)
    await frames(2)
    check(get_tree().get_nodes_in_group("enemy").is_empty(), "Enemy dies and leaves combat group")
    var gate: Area2D = level.get_node("Interactables/EasternGate")
    gate.open_door()
    check(not gate.opened and not Game.won, "Gate rejects escape without power and key")
    var board: Area2D = level.get_node("Interactables/Switchboard")
    check(not board.solve_puzzle(Vector3i(3, 1, 2)), "Puzzle requires clue")
    # E-key path: the nearest editor-placed clue opens its panel.
    player.position = Vector2(492, 540)
    await frames(3)
    await press("interact")
    check(Game.clue_read and get_tree().paused and hud.get_node("Root/NotePanel").visible, "E reads clue and pauses into note panel")
    hud.close_panels()
    check(not board.solve_puzzle(Vector3i(3, 1, 2)), "Puzzle requires physical fuse pickup")
    player.position = Vector2(1080, 580)
    await frames(3)
    await press("interact")
    check(Game.count_item("fuse") == 1, "E collects authored fuse into a pocket")
    await frames(2)
    player.position = Vector2(1590, 580)
    await frames(3)
    await press("interact")
    check(get_tree().paused and hud.get_node("Root/PuzzlePanel").visible, "E activates switchboard puzzle UI")
    hud.submit_puzzle()
    check(not Game.power_restored, "Wrong dial sequence does not solve puzzle")
    hud.dials = Vector3i(3, 1, 2)
    hud.submit_puzzle()
    check(Game.power_restored and Game.count_item("gate_key") == 1 and Game.count_item("fuse") == 0, "Correct puzzle consumes fuse and awards key")
    check(not get_tree().paused, "Solved puzzle returns to gameplay")
    # Simulate real UI key events; Input.action_press alone does not dispatch _unhandled_input.
    var inventory_event := InputEventAction.new()
    inventory_event.action = "inventory"
    inventory_event.pressed = true
    hud._unhandled_input(inventory_event)
    check(get_tree().paused and hud.get_node("Root/InventoryPanel").visible, "Inventory opens and pauses gameplay")
    hud.close_panels()
    hud.toggle_pause()
    check(get_tree().paused, "Pause freezes scene tree")
    hud.toggle_pause()
    check(not get_tree().paused, "Resume unpauses scene tree")
    player.position = Vector2(2680, 582)
    await frames(3)
    await press("interact")
    check(gate.opened and Game.count_item("gate_key") == 0, "E unlocks gate and consumes correct key")
    await get_tree().create_timer(1.0).timeout
    check(gate.get_node("Leaf").position.y < -120, "Door leaf animation completes")
    check(gate.get_node("Barrier/CollisionShape2D").disabled, "Unlocked gate collision opens")
    check(Game.won and hud.get_node("Root/EndingPanel").visible and get_tree().paused, "Complete clue → fuse → puzzle → key → escape ending")
    get_tree().paused = false
    Game.reset_run()
    check(Game.health == 100 and not Game.won and not Game.clue_read and not Game.power_restored and Game.count_item("gate_key") == 0, "Restart clears all progression")
    level.get_node("AmbientSound").stop()
    level.queue_free()
    await frames(3)
    var platform_a: StaticBody2D = load("res://scenes/objects/platform.tscn").instantiate()
    var platform_b: StaticBody2D = load("res://scenes/objects/platform.tscn").instantiate()
    add_child(platform_a)
    add_child(platform_b)
    platform_a.platform_size = Vector2(240, 30)
    check(platform_a.get_node("CollisionShape2D").shape.size == Vector2(240, 30), "Inspector platform size updates collision")
    check(platform_b.get_node("CollisionShape2D").shape.size == Vector2(160, 20), "Platform instances have independent shapes")
    platform_a.queue_free()
    platform_b.queue_free()
    Game.reset_run()
    Game.add_item("fuse")
    for i in 6:
        Game.add_item("object_" + str(i))
    Game.clue_read = true
    var full_board: Area2D = load("res://scenes/objects/switchboard.tscn").instantiate()
    add_child(full_board)
    check(full_board.solve_puzzle(Vector3i(3, 1, 2)) and Game.count_item("gate_key") == 1, "Solving with all eight pockets full exchanges fuse for key")
    full_board.queue_free()
    # Keep this test node alive while real menu / restart transitions replace current_scene.
    get_tree().current_scene = null
    var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
    get_tree().root.add_child(menu)
    get_tree().current_scene = menu
    menu.get_node("Start").pressed.emit()
    await frames(6)
    var running: Node = get_tree().current_scene
    check(running.scene_file_path == "res://scenes/levels/town.tscn" and Game.health == 100, "Main menu Start button loads a fresh town")
    running.get_node("Actors/Player").take_damage(100)
    check(get_tree().paused and running.get_node("HUD/Root/PausePanel/Resume").disabled, "Death opens pause screen and disables Continue")
    running.get_node("HUD/Root/PausePanel/Retry").pressed.emit()
    await frames(6)
    running = get_tree().current_scene
    check(Game.health == 100 and not get_tree().paused and not running.get_node("HUD/Root/PausePanel/Resume").disabled, "Retry button resets health and death state")
    running.get_node("HUD").back_to_menu()
    await frames(6)
    check(get_tree().current_scene.scene_file_path == "res://scenes/ui/main_menu.tscn", "Main menu navigation completes")
    get_tree().current_scene.queue_free()
    await frames(3)
    print("IGNOTUM: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)
