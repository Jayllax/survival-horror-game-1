extends Node
const KEY_DEFINITION = preload("res://data/items/gate_key.tres")
var checks := 0
var failures := 0
var room: Node2D
var player: CharacterBody2D
var hud: CanvasLayer
var bike: Area2D
var messages: Array[String] = []
var pickups: Array[String] = []

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

func key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    await frames(2)
    event = event.duplicate()
    event.pressed = false
    Input.parse_input_event(event)
    await frames(2)

func entry(id: String, quantity: int = 1) -> LootEntry:
    var result := LootEntry.new()
    result.item = Game.item_catalog[id]
    result.quantity = quantity
    return result

func make_container(id: String, items: Array[LootEntry] = []) -> LootContainer:
    var result: LootContainer = load("res://scenes/objects/loot/loot_container.tscn").instantiate()
    result.persistent_id = id
    result.contents.assign(items)
    result.position = Vector2(150, 588)
    room.get_node("Interactables").add_child(result)
    return result

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    Game.message.connect(func(text: String): messages.append(text))
    Game.item_collected.connect(func(id: String): pickups.append(id))
    run.call_deferred()

func refresh_room() -> void:
    room = get_tree().current_scene
    player = room.get_node("Actors/Player")
    hud = room.get_node("HUD")
    bike = room.get_node("Interactables/SaveBicycle")

func run() -> void:
    Game.reset_run()
    room = load("res://tests/fixtures/story_sandbox.tscn").instantiate()
    get_tree().root.add_child(room)
    get_tree().current_scene = room
    refresh_room()
    await frames(6)
    await verify_empty_and_interaction()
    await verify_contents_and_failure()
    await verify_visuals()
    await verify_slots()
    for audio in room.find_children("*", "AudioStreamPlayer", true, false):
        audio.stop()
    room.queue_free()
    await frames(5)
    print("IGNOTUM LOOT: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)

func verify_empty_and_interaction() -> void:
    var container := make_container("empty_test")
    check(container.is_available() and container.contents_valid() and container._get_configuration_warnings().is_empty(), "An empty Contents list is a valid searchable container")
    check(container.is_in_group("interactable") and container.get_child_count() == 1, "Invisible reusable scene supplies editor-visible interaction geometry without furniture art")
    player.global_position = container.global_position + Vector2(20, 0)
    await frames()
    check(hud.get_node("Root/Prompt").text == "Search", "Nearby E prompt offers Search without showing item titles")
    var before := Game.inventory.snapshot()
    var emitted := [0]
    container.searched.connect(func(): emitted[0] += 1)
    messages.clear()
    pickups.clear()
    await key(KEY_E)
    check(messages == ["Empty"] and pickups.is_empty(), "Searching an empty container emits Empty once and no pickup event")
    check(container.has_searched() and not container.is_available() and Game.inventory.snapshot() == before, "Empty search records completion without changing inventory")
    check(not hud.get_node("Root/Prompt").visible and hud.get_node("Root/Message").visible and hud.get_node("Root/Message").text == "Empty", "Empty feedback is visible and the Search prompt disappears")
    check(is_instance_valid(container) and container.is_inside_tree() and not get_tree().paused, "Interaction leaves furniture/component in the scene and exploration running")
    await key(KEY_E)
    check(not container.search() and messages == ["Empty"] and emitted[0] == 1, "Already searched container cannot emit Empty or completion again")
    container.queue_free()
    await frames()
    container = make_container("empty_test")
    check(container.has_searched() and not container.is_available(), "Scene reinstancing retains the empty container's searched state")
    container.queue_free()
    await frames()
    var full := GridInventory.new(Game.item_catalog, 1, 1)
    full.add("bandage")
    Game.inventory = full
    container = make_container("empty_with_full_bag")
    check(container.search() and container.has_searched(), "An empty drawer can be searched with a completely full inventory")
    container.queue_free()
    await frames()

func verify_contents_and_failure() -> void:
    var container := make_container("mixed_contents", [entry("ammo"), entry(KEY_DEFINITION.id)])
    container.completion_flag = "puzzle:test_cabinet"
    var full := GridInventory.new(Game.item_catalog, 1, 1)
    var partial_count := Game.stack_limit("ammo") - 1
    full.add("ammo", partial_count)
    Game.inventory = full
    var before := Game.inventory.snapshot()
    pickups.clear()
    check(not container.search() and Game.inventory.snapshot() == before, "Multi-item loot is atomic even when the first item could stack but a later item cannot fit")
    check(not container.has_searched() and container.is_available() and not Game.world.has(container.completion_flag) and pickups.is_empty(), "Inventory failure leaves contents, progress and pickup feedback untouched")
    check(messages.back().begins_with("No room"), "Inventory failure explains why the container is still searchable")
    var bigger := GridInventory.new(Game.item_catalog, 4, 2)
    bigger.add("ammo", partial_count)
    Game.inventory = bigger
    check(container.search(), "Making room allows a later complete search")
    check(Game.count_item("ammo") == partial_count + 1 and Game.count_item(KEY_DEFINITION.id) == 1, "Configured quantities stack and different item types are granted together")
    check(container.has_searched() and bool(Game.world.get(container.completion_flag, false)) and pickups == ["ammo", KEY_DEFINITION.id], "Completion and all pickup feedback correspond to the committed contents")
    before = Game.inventory.snapshot()
    check(not container.search() and Game.inventory.snapshot() == before, "A full container cannot be looted twice")
    container.queue_free()
    await frames()
    Game.inventory = GridInventory.new(Game.item_catalog, 8, 4)
    container = make_container("stack_and_weapon", [entry("ammo", Game.stack_limit("ammo") + 2), entry("shotgun")])
    check(container.search() and Game.count_item("ammo") == Game.stack_limit("ammo") + 2 and Game.count_item("shotgun") == 1, "Larger quantities split into stacks and weapon items use their normal footprints")
    check(not Game.has_equipped_weapon() and Game.inventory.entry(Game.inventory.first_uid("shotgun"))["magazine"] == 0, "Looted weapon remains unequipped with an empty magazine")
    container.queue_free()
    var bad := LootEntry.new()
    container = make_container("invalid_entry", [bad])
    before = Game.inventory.snapshot()
    check(not container.contents_valid() and container._get_configuration_warnings().size() == 1, "An unfinished entry warns in the editor instead of being treated as empty")
    check(not container.search() and not container.has_searched() and Game.inventory.snapshot() == before, "Unconfigured contents are never discarded or marked searched")
    container.queue_free()
    container = make_container("blocked_use")
    get_tree().paused = true
    check(not container.search(), "Paused gameplay cannot search a container")
    get_tree().paused = false
    Game.transitioning = true
    check(not container.search(), "Scene transitions cannot search a container")
    Game.transitioning = false
    Game.health = 0
    check(not container.search() and not container.has_searched(), "A defeated player cannot search a container")
    Game.health = 100
    container.queue_free()
    await frames()

func verify_visuals() -> void:
    var container := make_container("open_visuals")
    var closed_art := Node2D.new()
    closed_art.name = "ClosedArt"
    container.add_child(closed_art)
    var open_art := Node2D.new()
    open_art.name = "OpenArt"
    open_art.hide()
    container.add_child(open_art)
    container.closed_visual_path = NodePath("ClosedArt")
    container.searched_visual_path = NodePath("OpenArt")
    var animator := AnimationPlayer.new()
    animator.name = "Animator"
    container.add_child(animator)
    var animation := Animation.new()
    animation.length = 1.0
    var track := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(track, NodePath("OpenArt:position"))
    animation.track_insert_key(track, 0.0, Vector2.ZERO)
    animation.track_insert_key(track, 1.0, Vector2(0, -12))
    var library := AnimationLibrary.new()
    library.add_animation(&"open", animation)
    animator.add_animation_library(&"", library)
    container.animation_player_path = NodePath("Animator")
    check(container.search() and not closed_art.visible and open_art.visible and animator.is_playing(), "Searching can swap assigned artwork and play the designer's opening animation")
    closed_art.show()
    open_art.hide()
    var before := Game.inventory.snapshot()
    var feedback_count := messages.size()
    container.apply_searched_state(true)
    check(not closed_art.visible and open_art.visible and open_art.position == Vector2(0, -12) and not animator.is_playing(), "Restoring searched visuals seeks to the final opening pose")
    check(Game.inventory.snapshot() == before and messages.size() == feedback_count, "Visual restoration never grants loot or repeats Empty feedback")
    container.queue_free()
    await frames()

func verify_slots() -> void:
    Game.reset_run()
    var empty := make_container("saved_empty")
    var filled := make_container("saved_filled", [entry(KEY_DEFINITION.id, 2)])
    await frames()
    player.global_position = bike.global_position + Vector2(-25, 0)
    await frames()
    check(Game.save_slot(0, bike), "Slot A saves both containers before searching")
    check(empty.search() and filled.search(), "The empty and filled drawers can be searched after saving A")
    check(Game.save_slot(1, bike), "Slot B saves both searched containers and their loot")
    var a: Dictionary = Game._read_slot(0)
    var b: Dictionary = Game._read_slot(1)
    check(not bool(a["world"].get(empty.state_key(), false)) and not bool(a["world"].get(filled.state_key(), false)) and bool(b["world"][empty.state_key()]) and bool(b["world"][filled.state_key()]), "On-disk slots keep independent searched/unsearched progress")
    check(Game.load_slot(0), "Load slot A through the actual save system")
    await frames(8)
    refresh_room()
    empty = make_container("saved_empty")
    filled = make_container("saved_filled", [entry(KEY_DEFINITION.id, 2)])
    check(empty.is_available() and filled.is_available() and Game.count_item(KEY_DEFINITION.id) == 0, "Earlier save restores searchable drawers and the earlier inventory")
    check(Game.load_slot(1), "Load slot B through the actual save system")
    await frames(8)
    refresh_room()
    empty = make_container("saved_empty")
    filled = make_container("saved_filled", [entry(KEY_DEFINITION.id, 2)])
    check(not empty.is_available() and not filled.is_available() and Game.count_item(KEY_DEFINITION.id) == 2, "Later save restores searched drawers and exactly its own loot")
    var message_count := messages.size()
    check(not empty.search() and not filled.search() and messages.size() == message_count and Game.count_item(KEY_DEFINITION.id) == 2, "Restored searched containers cannot repeat Empty or duplicate their rewards")
    empty.queue_free()
    filled.queue_free()
    await frames()
