extends Node
var checks := 0
var failures := 0
var room: Node2D
var player: CharacterBody2D
var door: RoomDoor
var hud: CanvasLayer
var last_message := ""

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

func place_player(x: float) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	player.global_position = Vector2(x, 368)
	player.velocity = Vector2.ZERO
	await frames()

func press_e() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.physical_keycode = KEY_E
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)

func settle() -> void:
	await frames(35)

func refresh() -> void:
	room = get_tree().current_scene
	player = room.get_node("Actors/Player")
	door = room.get_node("Interactables/Door")
	hud = room.get_node("HUD")

func make_door(id: String, x: float, initial: bool = false, left: bool = false) -> RoomDoor:
	var result: RoomDoor = load("res://scenes/objects/room_door_side.tscn").instantiate()
	result.persistent_id = id
	result.position = Vector2(x, 400)
	result.starting_open = initial
	result.opens_left = left
	room.get_node("Interactables").add_child(result)
	return result

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene = null
	run.call_deferred()

func run() -> void:
	Game.reset_run()
	Game.message.connect(func(text: String): last_message = text)
	room = load("res://tests/fixtures/room_door_sandbox.tscn").instantiate()
	get_tree().root.add_child(room)
	get_tree().current_scene = room
	refresh()
	await frames(8)
	await verify_passage()
	await verify_safety_and_options()
	await verify_key_use()
	await verify_saves()
	GameAudio.stop_all()
	room.queue_free()
	await get_tree().create_timer(0.2).timeout
	print("IGNOTUM ROOM DOORS: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func verify_passage() -> void:
	var image: Image = door.get_node("Artwork/Frame").texture.get_image()
	check(image.get_size() == Vector2i(4, 44), "Side profile uses a simple native 4 by 44 pixel texture at 2x scale")
	var symmetric := true
	var palette := [Color.html("b0866c"), Color.html("8f6c61"), Color.html("385450"), Color.html("3b2d30")]
	var in_palette := true
	for y in image.get_height():
		for x in image.get_width():
			symmetric = symmetric and image.get_pixel(x, y).is_equal_approx(image.get_pixel(3-x, y))
			in_palette = in_palette and image.get_pixel(x, y) in palette
	check(symmetric and in_palette, "Profile is exactly mirrored and uses only the project palette")
	check(not door.opened and not door.get_node("Barrier/CollisionShape2D").disabled and door.get_node("LightOccluder2D").visible, "Closed door is solid and casts a native 2D light shadow")
	check(player.nearest == door and hud.get_node("Root/Prompt").text == "Open door", "Existing nearby interaction offers Open door without a permanent label")
	Input.action_press("move_right")
	await frames(40)
	Input.action_release("move_right")
	check(player.global_position.x < 465, "Closed door physically blocks movement from the left")
	await press_e()
	check(door.moving and not door.get_node("Barrier/CollisionShape2D").disabled, "E starts the opening animation and keeps collision until the leaf is open")
	await settle()
	check(door.opened and door.get_node("Barrier/CollisionShape2D").disabled and not door.get_node("LightOccluder2D").visible, "Completed opening clears movement and light blocking")
	var original_scene := room
	Input.action_press("move_right")
	await frames(45)
	Input.action_release("move_right")
	check(player.global_position.x > 510 and get_tree().current_scene == original_scene, "Player walks into the other room without a scene transition")
	await place_player(520)
	await press_e()
	await settle()
	check(not door.opened and not door.get_node("Barrier/CollisionShape2D").disabled, "Door can be closed again from the right")
	Input.action_press("move_left")
	await frames(35)
	Input.action_release("move_left")
	check(player.global_position.x > 495, "Closed door physically blocks movement from the right")
	await press_e()
	await settle()
	Input.action_press("move_left")
	await frames(45)
	Input.action_release("move_left")
	check(player.global_position.x < 450 and door.opened, "E opens from the right and allows backtracking to the left room")

func verify_safety_and_options() -> void:
	await place_player(480)
	await press_e()
	await settle()
	check(door.opened and not door.moving and last_message == door.blocked_message, "Door refuses to close while the player occupies its collider")
	await place_player(520)
	await press_e()
	check(door.moving, "An empty doorway can begin closing")
	await place_player(480)
	await settle()
	check(door.opened and door.get_node("Barrier/CollisionShape2D").disabled, "Walking into a closing doorway reverses the animation without trapping the player")
	await place_player(520)
	var furniture: CharacterBody2D = room.get_node("Props/Nightstand/PushableBody")
	furniture.global_position = Vector2(480, 400)
	furniture.velocity = Vector2.ZERO
	await frames(4)
	await press_e()
	check(door.opened and not door.moving, "Movable furniture also prevents a door from closing through it")
	furniture.global_position = Vector2(760, 400)
	await frames(4)
	var enemy: CharacterBody2D = load("res://scenes/actors/enemy.tscn").instantiate()
	enemy.position = Vector2(480, 368)
	room.get_node("Actors").add_child(enemy)
	enemy.set_physics_process(false)
	await frames()
	await press_e()
	check(door.opened and not door.moving, "An enemy occupying the doorway prevents closing too")
	enemy.queue_free()
	await frames()
	get_tree().paused = true
	door.interact(player)
	await frames()
	check(not door.moving, "Paused interaction cannot operate a door")
	get_tree().paused = false
	Game.transitioning = true
	door.interact(player)
	await frames()
	check(not door.moving, "Scene transitions cannot operate a door")
	Game.transitioning = false
	Game.health = 0
	door.interact(player)
	await frames()
	check(not door.moving and not door.is_available(), "A defeated player cannot operate a door")
	Game.health = 100
	await place_player(300)
	door.interact(player)
	await frames()
	check(not door.moving and player.nearest != door, "A distant door cannot be operated and has no nearby prompt")
	var other := make_door("initially_open", 680, true, true)
	other.allow_close = false
	await frames()
	check(other.opened and not other.is_available() and other.get_node("Artwork/LeafPivot").scale.x < 0, "Inspector options support an initially open, left-opening, open-once door")
	var shape: RectangleShape2D = other.get_node("Barrier/CollisionShape2D").shape
	shape.size.x = 14
	check(door.get_node("Barrier/CollisionShape2D").shape.size.x == 8, "Resizing one placed door's collision shape does not change other instances")
	other.queue_free()
	await frames()

func verify_key_use() -> void:
	var key: InventoryItemDefinition = load("res://data/items/gate_key.tres")
	var locked: RoomDoor = load("res://scenes/objects/room_door_side.tscn").instantiate()
	locked.persistent_id = "disposable_key_door"
	locked.required_key = key.id
	locked.position = Vector2(680, 400)
	room.get_node("Interactables").add_child(locked)
	await place_player(640)
	await press_e()
	check(not locked.opened and not locked.moving and last_message == locked.locked_message, "An optional key requirement displays the configured locked message")
	Game.register_item(key)
	check(Game.add_item(key.id), "The configured disposable key fits in the inventory")
	await press_e()
	check(locked.moving and locked.unlocked and Game.count_item(key.id) == 0, "Opening consumes a Remove After Use key exactly once")
	# Reconstruct the room object before the unfinished animation completes.
	locked.queue_free()
	await frames()
	locked = load("res://scenes/objects/room_door_side.tscn").instantiate()
	locked.persistent_id = "disposable_key_door"
	locked.required_key = key.id
	locked.position = Vector2(680, 400)
	room.get_node("Interactables").add_child(locked)
	await frames()
	check(locked.unlocked and not locked.opened, "Leaving during opening retains the unlock without requiring the consumed key again")
	await press_e()
	await settle()
	check(locked.opened and Game.count_item(key.id) == 0, "Unlocked doors reopen without another key after a scene revisit")
	await press_e()
	await settle()
	await press_e()
	await settle()
	check(locked.opened and locked.unlocked, "Closing and reopening never relocks a successfully unlocked door")
	locked.queue_free()
	await frames()

func verify_saves() -> void:
	await place_player(520)
	await press_e()
	await settle()
	await place_player(180)
	check(Game.save_slot(0, room.get_node("Interactables/SaveBicycle")), "Bicycle slot A saves the closed door")
	await place_player(440)
	await press_e()
	await settle()
	await place_player(180)
	check(Game.save_slot(1, room.get_node("Interactables/SaveBicycle")), "Bicycle slot B saves the open door")
	var a: Dictionary = Game._read_slot(0)
	var b: Dictionary = Game._read_slot(1)
	check(not bool(a["world"][door.state_key()]) and bool(b["world"][door.state_key()]), "On-disk slots preserve independent closed and open states")
	check(Game.load_slot(0), "The real save system loads slot A")
	await frames(10)
	refresh()
	check(not door.opened and not door.get_node("Barrier/CollisionShape2D").disabled, "Loading A restores the closed door and its solid collider")
	check(Game.load_slot(1), "The real save system loads slot B")
	await frames(10)
	refresh()
	check(door.opened and door.get_node("Barrier/CollisionShape2D").disabled, "Loading B restores the open door and walk-through collider state")
