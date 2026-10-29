extends Node
var checks := 0
var failures := 0
var room: Node2D
var player: CharacterBody2D
var hud: CanvasLayer
var ui: Control
var bike: Area2D

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

func key(code: Key, pressed: bool = true, echo: bool = false) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = pressed
    event.echo = echo
    Input.parse_input_event(event)
    await frames(2)
    if pressed and not echo:
        await key(code, false)

func make_lock(id: String) -> CodeLock:
    var lock: CodeLock = load("res://scenes/objects/puzzles/code_lock.tscn").instantiate()
    lock.persistent_id = id
    lock.correct_code = "0042"
    lock.position = Vector2(150, 588)
    room.get_node("Interactables").add_child(lock)
    return lock

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()

func refresh_room() -> void:
    room = get_tree().current_scene
    player = room.get_node("Actors/Player")
    hud = room.get_node("HUD")
    ui = hud.get_node("CodeLockUI")
    bike = room.get_node("Interactables/SaveBicycle")

func run() -> void:
    Game.reset_run()
    preload("res://tests/support/loadout.gd").handgun()
    room = load("res://tests/fixtures/story_sandbox.tscn").instantiate()
    get_tree().root.add_child(room)
    get_tree().current_scene = room
    refresh_room()
    await frames(8)
    check(not ui.is_open() and not ui.visible and not hud.any_panel_open(), "Lock UI is hidden and exploration unchanged on scene entry")
    check(CodeLock.valid_code("0042") and CodeLock.valid_code("9999"), "All four decimal digits including leading zeroes are accepted")
    for invalid in ["42", "00000", " 042", "abcd", "-042", "００４２"]:
        check(not CodeLock.valid_code(invalid), "Malformed lock code is rejected: " + invalid)
    var lock := make_lock("lock_ui_test")
    check(lock.is_in_group("interactable") and lock.is_available(), "Reusable invisible lock joins the existing interaction system")
    player.global_position = lock.global_position + Vector2(20, 0)
    await frames()
    check(hud.get_node("Root/Prompt").text == "Examine lock", "Nearby prompt identifies only the lock action")
    await key(KEY_E)
    check(ui.is_open() and get_tree().paused and hud.any_panel_open(), "E opens the four-dial panel and pauses gameplay")
    check(ui.selected_code() == "0000" and not lock.has_unlocked(), "Showing the starting digits never auto-solves the lock")
    check(ui.dial_row.get_child_count() == 4 and ui.get_viewport_rect().size == ui.size, "The editor-authored modal fills the viewport with four independent dials")
    var held_position := player.global_position
    var held_magazine := Game.magazine
    Input.action_press("move_right")
    Input.action_press("aim")
    Input.action_press("shoot")
    await frames(5)
    check(player.global_position == held_position and Game.magazine == held_magazine, "Lock pauses player movement, aiming and shooting")
    Input.action_release("move_right")
    ui.dial_row.get_child(0).get_node("Down").pressed.emit()
    check(ui.selected_code() == "9000", "Minus wraps a dial from zero to nine")
    ui.dial_row.get_child(0).get_node("Up").pressed.emit()
    check(ui.selected_code() == "0000", "Plus wraps a dial from nine to zero")
    await key(KEY_RIGHT)
    await key(KEY_UP)
    check(ui.selected_dial == 1 and ui.selected_code() == "0100", "Arrow keys select and turn individual dials")
    var before := Game.inventory.snapshot()
    await key(KEY_ENTER)
    check(ui.is_open() and not ui.feedback.text.is_empty() and not lock.has_unlocked() and Game.inventory.snapshot() == before, "Wrong codes stay open and leave inventory and completion untouched")
    await key(KEY_TAB)
    await key(KEY_I)
    check(ui.is_open() and not hud.get_node("Root/InventoryPanel").visible and ui.selected_dial == 1, "Inventory shortcuts and Tab cannot move focus or open another panel")
    check(not hud.show_dialogue(load("res://data/narrative/example_conversation.tres"), null), "Dialogue cannot open over the lock")
    hud.show_save_station(bike)
    check(not hud.get_node("SaveMenu").is_open(), "Save picker cannot open over the lock")
    await key(KEY_ESCAPE)
    check(not ui.is_open() and not get_tree().paused and not hud.get_node("Root/PausePanel").visible, "Escape closes the lock without opening the pause menu")
    await frames(8)
    check(Game.magazine == held_magazine and player.story_shoot_held, "Closing does not fire a held aiming mouse button")
    Input.action_release("aim")
    Input.action_release("shoot")
    await frames()
    lock.interact(player)
    check(ui.selected_code() == "0100", "Unsolved dial positions survive closing and reopening")
    ui.select_dial(0)
    for digit in [KEY_0, KEY_0, KEY_4, KEY_2]:
        await key(digit)
    check(ui.selected_code() == "0042" and ui.selected_dial == 0, "Typing digits sets each dial without losing leading zeroes")
    await key(KEY_E, true, true)
    check(ui.is_open() and not lock.has_unlocked(), "Held key repeats cannot submit or close the lock")
    await key(KEY_E, false)
    var signals_received := [0]
    lock.unlocked.connect(func(): signals_received[0] += 1)
    await key(KEY_ENTER)
    check(lock.has_unlocked() and not ui.is_open() and not get_tree().paused and not lock.is_available(), "Correct code unlocks once, closes the modal and resumes exploration")
    lock.attempt_unlock("0042")
    check(signals_received[0] == 1, "Repeated use cannot emit a second unlock")
    check(not Game.world.has(lock.state_key() + ":dials"), "Solved locks retain the completion flag rather than temporary dial positions")
    lock.queue_free()
    await frames()
    lock = make_lock("lock_ui_test")
    check(lock.has_unlocked() and not lock.is_available(), "Reinstanced locks restore the saved completion state")
    lock.queue_free()
    await frames()
    await verify_rewards_and_opening()
    await verify_save_slots()
    room.queue_free()
    await frames(5)
    print("IGNOTUM CODE LOCK: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)

func verify_rewards_and_opening() -> void:
    var lock := make_lock("reward_test")
    lock.reward_item = load("res://data/items/gate_key.tres")
    lock.completion_flag = "puzzle:test_drawer"
    var inventory_before := Game.inventory.snapshot()
    var full := GridInventory.new(Game.item_catalog, 1, 1)
    full.add("bandage")
    Game.inventory = full
    var full_before := Game.inventory.snapshot()
    check(not lock.attempt_unlock("0042").is_empty() and Game.inventory.snapshot() == full_before and not lock.has_unlocked() and not Game.world.has(lock.completion_flag), "Full inventory cannot lose the reward or mark the lock completed")
    Game.inventory = GridInventory.restore(inventory_before, Game.item_catalog)
    var count_before := Game.count_item("gate_key")
    var collision := CollisionShape2D.new()
    collision.name = "TestBarrier"
    var solid := StaticBody2D.new()
    solid.name = "TestSolid"
    lock.add_child(solid)
    solid.add_child(collision)
    collision.shape = RectangleShape2D.new()
    lock.blocker_path = NodePath("TestSolid/TestBarrier")
    var closed_art := Node2D.new()
    closed_art.name = "ClosedArt"
    lock.add_child(closed_art)
    var open_art := Node2D.new()
    open_art.name = "OpenArt"
    open_art.hide()
    lock.add_child(open_art)
    lock.locked_visual_path = NodePath("ClosedArt")
    lock.unlocked_visual_path = NodePath("OpenArt")
    var animator := AnimationPlayer.new()
    animator.name = "Animator"
    lock.add_child(animator)
    var animation := Animation.new()
    animation.length = 1.0
    var track := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(track, NodePath("OpenArt:position"))
    animation.track_insert_key(track, 0.0, Vector2.ZERO)
    animation.track_insert_key(track, 1.0, Vector2(0, -12))
    var library := AnimationLibrary.new()
    library.add_animation(&"open", animation)
    animator.add_animation_library(&"", library)
    lock.animation_player_path = NodePath("Animator")
    check(lock.attempt_unlock("0042").is_empty(), "Correct code with room grants the configured reward")
    await frames()
    check(Game.count_item("gate_key") == count_before + 1 and bool(Game.world.get(lock.completion_flag, false)), "One reward and the designer's custom progress flag commit together")
    check(collision.disabled and not closed_art.visible and open_art.visible, "Unlock disables the chosen blocker and swaps the assigned artwork")
    check(animator.is_playing(), "Successful opening starts the assigned AnimationPlayer animation")
    lock.attempt_unlock("0042")
    check(Game.count_item("gate_key") == count_before + 1, "Reattempting an unlocked container never duplicates its contents")
    collision.disabled = false
    closed_art.show()
    open_art.hide()
    lock.apply_open_state(true)
    await frames()
    check(collision.disabled and not closed_art.visible and open_art.visible and Game.count_item("gate_key") == count_before + 1, "Restoring open visuals/collision does not grant another reward")
    check(open_art.position == Vector2(0, -12) and not animator.is_playing(), "Restored opening animation shows its final pose instead of replaying")
    lock.queue_free()
    var invalid := make_lock("bad_config")
    invalid.correct_code = "42"
    check(not invalid.attempt_unlock("0042").is_empty() and not invalid.has_unlocked(), "An invalid configured code cannot accidentally unlock")
    invalid.starting_code = "wrong"
    check(invalid.current_digits() == "0000", "Invalid starting digits safely fall back to zeroes")
    invalid.queue_free()
    await frames()

func verify_save_slots() -> void:
    var lock := make_lock("saved_test")
    lock.reward_item = load("res://data/items/gate_key.tres")
    lock.remember_digits("0030")
    player.global_position = bike.global_position + Vector2(-25, 0)
    await frames()
    check(Game.save_slot(0, bike), "Bicycle slot A saves the unsolved lock and its dial positions")
    check(lock.attempt_unlock("0042").is_empty(), "Saved puzzle can subsequently be solved")
    check(Game.save_slot(1, bike), "Bicycle slot B saves the unlocked state and inventory reward")
    var first: Dictionary = Game._read_slot(0)
    var second: Dictionary = Game._read_slot(1)
    check(not bool(first["world"].get(lock.state_key(), false)) and first["world"][lock.state_key()+":dials"] == "0030" and bool(second["world"].get(lock.state_key(), false)), "On-disk slots contain independent solved/unsolved progress")
    check(Game.load_slot(0), "Load slot A through the real save system")
    await frames(8)
    refresh_room()
    lock = make_lock("saved_test")
    check(not lock.has_unlocked() and lock.current_digits() == "0030", "Loading A restores unsolved lock and previous dial positions")
    var count_a := Game.count_item("gate_key")
    check(Game.load_slot(1), "Load slot B through the real save system")
    await frames(8)
    refresh_room()
    lock = make_lock("saved_test")
    check(lock.has_unlocked() and not lock.is_available() and Game.count_item("gate_key") == count_a + 1, "Loading B restores unlocked state and its own inventory reward")
