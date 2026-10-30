extends Node
var checks := 0
var failures := 0
var serial := 0
var room: Node2D
var player: CharacterBody2D
const ACTIONS := ["move_left","move_right","jump","sprint","dodge","crouch","aim","shoot"]

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

func release_inputs() -> void:
    for action in ACTIONS:
        Input.action_release(action)

func place_player(point: Vector2) -> void:
    release_inputs()
    player.global_position = point
    player.velocity = Vector2.ZERO
    player.dodge_remaining = 0
    player.dodge_cooldown = 0
    player.story_jump_held = false
    await frames(4)

func furniture(point: Vector2, settings: Dictionary = {}, id: String = "") -> Node2D:
    var result: Node2D = load("res://scenes/objects/physics/pushable_nightstand.tscn").instantiate()
    serial += 1
    result.name = "TestFurniture%d" % serial
    result.position = point
    var body: PushableBody = result.get_node("PushableBody")
    body.persistent_id = id if not id.is_empty() else "test_pushable_%d" % serial
    for key in settings:
        body.set(key, settings[key])
    room.get_node("Props").add_child(result)
    return result

func fresh_room() -> void:
    release_inputs()
    if is_instance_valid(room):
        get_tree().current_scene = null
        room.queue_free()
        await frames(3)
    Game.reset_run()
    room = load("res://tests/fixtures/pushable_sandbox.tscn").instantiate()
    get_tree().root.add_child(room)
    get_tree().current_scene = room
    player = room.get_node("Actors/Player")
    await frames(8)

func feet_y() -> float:
    var shape: CollisionShape2D = player.get_node("CollisionShape2D")
    return player.global_position.y + shape.position.y + shape.shape.height / 2.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    await fresh_room()
    await verify_child_and_movement()
    await verify_blocking_and_options()
    await verify_platform_puzzle()
    await verify_saves()
    release_inputs()
    get_tree().paused = false
    room.queue_free()
    await frames(5)
    print("IGNOTUM PUSHABLES: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)

func verify_child_and_movement() -> void:
    var prop := furniture(Vector2(400,620))
    prop.solid = true
    var body: PushableBody = prop.get_node("PushableBody")
    await frames(6)
    check(body.get_parent() == prop and body.top_level and body.is_in_group("pushable"), "PushableBody is a child component with an independent physics transform")
    check(body.is_on_floor() and absf(prop.global_position.y-620)<0.2, "Furniture settles onto the floor without sinking")
    check(prop.get_node("Solid").collision_layer == 0 and body.collision_layer == 1, "Original furniture collision cannot compete with the resized pushable collider")
    await place_player(Vector2(360,588))
    var start := prop.global_position
    Input.action_press("move_right")
    var greatest_step := 0.0
    var closest_gap := INF
    for i in 90:
        var before := prop.global_position.x
        var tick := Engine.get_physics_frames()
        await frames(1)
        greatest_step = maxf(greatest_step, (prop.global_position.x-before)/maxi(1,Engine.get_physics_frames()-tick))
        closest_gap = minf(closest_gap,body.global_position.x-player.global_position.x)
    check(prop.global_position.x > start.x+30 and prop.global_position.x < start.x+70, "Walking into the furniture pushes it at a controlled speed")
    check(greatest_step <= body.push_speed / Engine.physics_ticks_per_second + 0.2, "Sprinting/player speed cannot make furniture exceed its push speed")
    check(prop.global_position.is_equal_approx(body.global_position), "Whole furniture follows the collider without double movement")
    check(closest_gap>=25.9, "Player follows the moved object without overlapping its solid side")
    Input.action_release("move_right")
    start = prop.global_position
    await frames(12)
    check(prop.global_position.distance_to(start)<0.1, "Furniture stops when movement is released and does not coast")
    check(player.move_speed == 90 and player.jump_velocity == -250 and player.get_node("Camera2D").zoom == Vector2(2,2), "Current movement tuning and camera zoom remain unchanged")
    await place_player(Vector2(prop.global_position.x+40,588))
    Input.action_press("move_left")
    await frames(60)
    Input.action_release("move_left")
    check(prop.global_position.x < start.x-15, "The same object can be pushed back from its other side")
    var other := furniture(Vector2(650,620))
    await frames()
    var first_shape: RectangleShape2D = body.get_node("CollisionShape2D").shape
    var second_shape: RectangleShape2D = other.get_node("PushableBody/CollisionShape2D").shape
    first_shape.size = Vector2(24,30)
    check(first_shape != second_shape and second_shape.size == Vector2(28,30), "Each instance owns its collider resource so resizing one does not resize every object")
    prop.queue_free()
    other.queue_free()
    await frames()
    prop = furniture(Vector2(450,440))
    body = prop.get_node("PushableBody")
    await place_player(Vector2(100,588))
    await frames(50)
    check(body.is_on_floor() and absf(prop.global_position.y-620)<0.2 and prop.global_position.is_equal_approx(body.global_position), "Gravity moves parent artwork with the child body and lands it safely on solid ground")
    prop.queue_free()
    await frames()
    prop = furniture(Vector2(450,620), {"position":Vector2(8,0)})
    body = prop.get_node("PushableBody")
    await place_player(Vector2(410,588))
    Input.action_press("move_right")
    await frames(45)
    release_inputs()
    check(prop.global_position.x>460 and absf(body.global_position.x-prop.global_position.x-8)<0.1, "An offset child collider preserves its original relationship to the furniture artwork")
    var duplicate: PushableBody = load("res://scenes/objects/physics/pushable_body.tscn").instantiate()
    prop.add_child(duplicate)
    check(not duplicate.is_in_group("pushable") and duplicate.collision_layer==0, "An accidental second component cannot fight the first physics body")
    prop.queue_free()
    await frames()
    var misplaced: PushableBody = load("res://scenes/objects/physics/pushable_body.tscn").instantiate()
    room.add_child(misplaced)
    check(not misplaced.is_in_group("pushable") and misplaced.collision_layer==0 and room.get_node("Geometry/Floor").collision_layer==1, "An incorrectly placed level-root component cannot disable the room's world collision")
    misplaced.queue_free()
    await frames()

func verify_blocking_and_options() -> void:
    var first := furniture(Vector2(400,620))
    var second := furniture(Vector2(440,620))
    await place_player(Vector2(360,588))
    Input.action_press("move_right")
    await frames(65)
    release_inputs()
    check(first.global_position.x<=412.2 and absf(second.global_position.x-440)<0.2, "Other pushable objects block movement without an unintended chain push")
    first.queue_free()
    second.queue_free()
    await frames()
    var prop := furniture(Vector2(1470,620))
    var body: PushableBody = prop.get_node("PushableBody")
    await place_player(Vector2(1430,588))
    Input.action_press("move_right")
    Input.action_press("sprint")
    await frames(80)
    release_inputs()
    check(prop.global_position.x>1470 and prop.global_position.x<=1476.1 and player.global_position.x<1460, "A wall stops both furniture and player without tunnelling")
    prop.queue_free()
    await frames()
    prop = furniture(Vector2(400,620), {"use_travel_limits":true,"left_distance":20.0,"right_distance":20.0})
    body = prop.get_node("PushableBody")
    await place_player(Vector2(360,588))
    Input.action_press("move_right")
    await frames(65)
    Input.action_release("move_right")
    check(absf(prop.global_position.x-420)<0.2, "Optional right travel limit stops the object at its authored range")
    await place_player(Vector2(460,588))
    Input.action_press("move_left")
    await frames(90)
    release_inputs()
    check(absf(prop.global_position.x-380)<0.2, "Optional left travel limit is measured from the original placement")
    prop.queue_free()
    await frames()
    prop = furniture(Vector2(450,620), {"push_enabled":false})
    await place_player(Vector2(410,588))
    Input.action_press("move_right")
    await frames(45)
    release_inputs()
    check(absf(prop.global_position.x-450)<0.1 and player.global_position.x<425, "Disabling pushing leaves a solid stationary platform")
    prop.queue_free()
    await frames()
    prop = furniture(Vector2(450,620))
    body = prop.get_node("PushableBody")
    await place_player(Vector2(424,588))
    Input.action_press("move_right")
    Input.action_press("jump")
    await frames(10)
    release_inputs()
    check(absf(prop.global_position.x-450)<0.2 and not player.is_on_floor(), "Jumping against an object does not push it through the air")
    await place_player(Vector2(424,588))
    Input.action_press("move_right")
    Input.action_press("dodge")
    await frames(9)
    release_inputs()
    check(absf(prop.global_position.x-450)<0.2, "Dodging into furniture does not launch it")
    var position_before := prop.global_position
    get_tree().paused = true
    await frames(5)
    check(prop.global_position == position_before, "Pause freezes the child body and its furniture")
    get_tree().paused = false
    Game.transitioning = true
    check(body.push_from(player,3,1.0/60.0) == 0, "Transitions reject new pushes")
    Game.transitioning = false
    var enemy := CharacterBody2D.new()
    room.add_child(enemy)
    check(body.push_from(enemy,3,1.0/60.0) == 0, "Enemies and arbitrary physics bodies cannot initiate a player push")
    enemy.queue_free()
    prop.queue_free()
    await frames()
    prop = furniture(Vector2(450,430))
    prop.process_mode = Node.PROCESS_MODE_ALWAYS
    var falling_position := prop.global_position
    get_tree().paused = true
    await frames(5)
    check(prop.global_position == falling_position, "Even an always-processing furniture parent cannot make its falling body move during pause")
    get_tree().paused = false
    prop.queue_free()
    await frames()

func verify_platform_puzzle() -> void:
    await place_player(Vector2(1060,588))
    Input.action_press("move_right")
    Input.action_press("jump")
    var highest_feet := feet_y()
    for i in 45:
        await frames(1)
        highest_feet = minf(highest_feet,feet_y())
    release_inputs()
    check(highest_feet>565 and feet_y()>600, "The upper ledge cannot be reached by the unmodified player's floor jump alone")
    var prop: Node2D = room.get_node("Props/Nightstand")
    var body: PushableBody = prop.get_node("PushableBody")
    await place_player(Vector2(960,588))
    Input.action_press("move_right")
    for i in 210:
        await frames(1)
        if prop.global_position.x >= 1085.8:
            break
    release_inputs()
    check(absf(prop.global_position.x-1086)<0.3, "The player can push the nightstand next to the escape ledge")
    await place_player(Vector2(1060,588))
    Input.action_press("move_right")
    Input.action_press("jump")
    await frames(55)
    release_inputs()
    await frames(4)
    check(player.is_on_floor() and absf(feet_y()-590)<0.5 and player.global_position.x>1070, "Player can jump onto the pushed object using current jump settings")
    var body_position := body.global_position
    await frames(12)
    check(body.global_position.distance_to(body_position)<0.1, "Standing on the object does not push or destabilize it")
    Input.action_press("move_right")
    Input.action_press("jump")
    await frames(60)
    release_inputs()
    await frames(4)
    check(player.is_on_floor() and absf(feet_y()-565)<0.5 and player.global_position.x>1110, "Jumping from the movable furniture reaches the previously inaccessible ledge")

func verify_saves() -> void:
    await fresh_room()
    var prop: Node2D = room.get_node("Props/Nightstand")
    var body: PushableBody = prop.get_node("PushableBody")
    var bike: Area2D = room.get_node("Interactables/SaveBicycle")
    var start := prop.global_position
    await place_player(bike.global_position+Vector2(-20,-32))
    check(Game.save_slot(0,bike), "Bicycle slot A saves the furniture before movement")
    await place_player(Vector2(960,588))
    Input.action_press("move_right")
    await frames(60)
    release_inputs()
    var moved := prop.global_position
    check(moved.x>start.x+20, "Furniture moves between the two save snapshots")
    Game.health=57
    Game.add_item("ammo",3)
    Game.world["puzzle:test_pushable_progress"]=true
    await place_player(bike.global_position+Vector2(-20,-32))
    check(Game.save_slot(1,bike), "Bicycle slot B saves moved furniture and later inventory/progress")
    var first: Dictionary=Game._read_slot(0)
    var second: Dictionary=Game._read_slot(1)
    check(is_equal_approx(first.world[body.state_key()].position[0], start.x) and is_equal_approx(second.world[body.state_key()].position[0], moved.x), "On-disk slots contain independent object coordinates")
    check(Game.load_slot(0), "Load slot A through the real save system")
    await frames(8)
    room=get_tree().current_scene
    player=room.get_node("Actors/Player")
    prop=room.get_node("Props/Nightstand")
    check(prop.global_position.distance_to(start)<0.2 and Game.health==100 and Game.count_item("ammo")==0, "Loading A restores initial furniture, health and inventory without old-scene overwrites")
    check(Game.load_slot(1), "Load slot B through the real save system")
    await frames(8)
    room=get_tree().current_scene
    player=room.get_node("Actors/Player")
    prop=room.get_node("Props/Nightstand")
    check(prop.global_position.distance_to(moved)<0.2 and Game.health==57 and Game.count_item("ammo")==3 and bool(Game.world.get("puzzle:test_pushable_progress",false)), "Loading B restores its own position and unrelated saved puzzle progress")
    Transition.travel(room.scene_file_path,"default")
    await frames(70)
    room=get_tree().current_scene
    player=room.get_node("Actors/Player")
    prop=room.get_node("Props/Nightstand")
    check(not Game.transitioning and prop.global_position.distance_to(moved)<0.2, "Returning through a scene transition preserves the moved furniture")
    var temporary := furniture(Vector2(400,620), {"remember_position":false}, "temporary_prop")
    var temporary_body: PushableBody = temporary.get_node("PushableBody")
    await place_player(Vector2(360,588))
    Input.action_press("move_right")
    await frames(45)
    release_inputs()
    check(temporary.global_position.x>405 and not Game.world.has(temporary_body.state_key()), "Remember Position can be disabled for objects that reset on room reload")
    temporary.queue_free()
    await frames()
    await place_player(Vector2(100,588))
    temporary=furniture(Vector2(400,620), {"remember_position":false}, "temporary_prop")
    await frames()
    check(absf(temporary.global_position.x-400)<0.1, "Nonpersistent furniture returns to its authored position")
    for value in [null,[],["bad",620],[INF,620],[1,2,3]]:
        check(not PushableBody.valid_saved_position(value), "Malformed saved coordinates are rejected safely: "+str(value))
