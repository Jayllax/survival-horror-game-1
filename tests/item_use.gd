extends Node
var checks := 0
var failures := 0
var originals: Dictionary
var room: Node2D
var player: CharacterBody2D
func check(ok: bool, description: String) -> void:
    checks += 1
    if ok:print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)
func frames(count: int = 2) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame
func reset() -> void:
    Game.item_catalog = originals.duplicate()
    Game.reset_run()
func configure(id: String, remove: bool) -> InventoryItemDefinition:
    var definition: InventoryItemDefinition = originals[id].duplicate()
    definition.remove_after_use = remove
    Game.register_item(definition)
    return definition
func _ready() -> void:
    get_tree().current_scene = null
    originals = Game.item_catalog.duplicate()
    run.call_deferred()
func run() -> void:
    verify_inventory_use()
    await verify_puzzles_and_doors()
    await verify_cutters_and_saves()
    await verify_entrances()
    if is_instance_valid(room):room.queue_free()
    await frames(5)
    print("IGNOTUM ITEM USE: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)

func verify_inventory_use() -> void:
    reset()
    Game.add_item("bandage", 2)
    var bandage := Game.inventory.first_uid("bandage")
    check(not Game.use_uid(bandage) and Game.count_item("bandage") == 2, "Full health never wastes a consumable")
    Game.health = 40
    check(Game.use_uid(bandage) and Game.health == 70 and Game.count_item("bandage") == 1, "Checked medical item removes exactly one unit on success")
    configure("bandage", false)
    check(Game.use_uid(bandage) and Game.health == 100 and Game.count_item("bandage") == 1, "Unchecked medical item heals without being removed")
    reset()
    configure("compact_saw", false)
    Game.add_item("pistol", 2)
    Game.add_item("compact_saw")
    var tool := Game.inventory.first_uid("compact_saw")
    var targets := Game.inventory.entries.filter(func(e):return e["id"] == "pistol")
    check(Game.combine_uids(tool, targets[0]["uid"]) and Game.count_item("compact_saw") == 1, "Unchecked upgrade kit stays after a successful upgrade")
    var before := Game.inventory.snapshot()
    check(not Game.combine_uids(tool, targets[0]["uid"]) and Game.inventory.snapshot() == before, "Failed repeated upgrade leaves the kit and target untouched")
    check(Game.combine_uids(targets[1]["uid"], tool) and Game.inventory.entry(tool)["id"] == "compact_saw", "A reusable upgrade kit can upgrade a second item instance")
    reset()
    configure("cloth", false)
    Game.add_item("cloth")
    Game.add_item("antiseptic")
    var cloth := Game.inventory.first_uid("cloth")
    check(Game.combine_items("cloth", "antiseptic") and Game.count_item("cloth") == 1 and Game.count_item("antiseptic") == 0 and Game.count_item("bandage") == 1, "Crafting keeps a reusable ingredient while consuming the checked ingredient")
    check(not Game.inventory.entry(cloth).is_empty(), "Reusable crafting ingredients retain their instance identity")
    reset()
    configure("cloth", false)
    configure("antiseptic", false)
    Game.inventory = GridInventory.new(Game.item_catalog, 4, 2)
    Game.add_item("cloth")
    Game.add_item("antiseptic")
    for i in 6:Game.inventory.add("filler_%d" % i)
    before = Game.inventory.snapshot()
    check(not Game.combine_items("cloth", "antiseptic") and Game.inventory.snapshot() == before, "Full-grid crafting failure cannot consume, relocate or duplicate reusable inputs")
    reset()
    Game.add_item("bolt_cutters_single_use")
    var single := Game.inventory.first_uid("bolt_cutters_single_use")
    check(Game.find_use_uid("bolt_cutters") == single, "Use As Item Id lets a distinct disposable variant satisfy the common tool requirement")
    Game.add_item("bolt_cutters")
    check(Game.find_use_uid("bolt_cutters") == Game.inventory.first_uid("bolt_cutters"), "Carrying a permanent tool prevents wasting a disposable variant")
    check(Game.find_use_uid("") == -1 and Game.find_use_uid("missing_tool") == -1, "Missing and empty requirements do not accidentally select an unrelated item")

func board(channel: String) -> Area2D:
    var result: Area2D = load("res://scenes/objects/switchboard.tscn").instantiate()
    result.power_channel = channel
    add_child(result)
    return result
func door(id: String) -> Area2D:
    var result: Area2D = load("res://scenes/objects/door.tscn").instantiate()
    result.persistent_id = id
    result.requires_power = false
    add_child(result)
    return result
func single_key() -> void:
    var definition: InventoryItemDefinition = originals["gate_key"].duplicate()
    definition.id = "test_single_key"
    definition.use_as_item_id = "gate_key"
    definition.remove_after_use = true
    Game.register_item(definition)

func verify_puzzles_and_doors() -> void:
    reset()
    Game.inventory = GridInventory.new(Game.item_catalog, 4, 2)
    Game.add_item("fuse")
    var fuse := Game.inventory.first_uid("fuse")
    Game.move_item(fuse, Vector2i(3, 0), true)
    for i in 6:Game.inventory.add("filler_%d" % i)
    var puzzle := board("test_consumable_puzzle")
    puzzle.puzzle_reward_item = "shotgun"
    var before := Game.inventory.snapshot()
    check(not puzzle.solve_puzzle(Vector3i(1, 1, 1)) and Game.inventory.snapshot() == before, "Wrong puzzle solution costs no input")
    check(not puzzle.solve_puzzle(puzzle.puzzle_solution) and Game.inventory.snapshot() == before and not puzzle.is_powered(), "An oversized puzzle reward rolls back the exact rotated input and progress")
    puzzle.puzzle_reward_item = "gate_key"
    check(puzzle.solve_puzzle(puzzle.puzzle_solution) and Game.count_item("fuse") == 0 and Game.count_item("gate_key") == 1, "Successful puzzle can exchange a consumed two-cell input for its reward in a full grid")
    before = Game.inventory.snapshot()
    check(puzzle.solve_puzzle(puzzle.puzzle_solution) and Game.inventory.snapshot() == before, "Completed puzzles do not use inputs or grant rewards twice")
    puzzle.queue_free()
    reset()
    configure("fuse", false)
    Game.add_item("fuse")
    puzzle = board("test_reusable_puzzle")
    puzzle.puzzle_reward_item = ""
    check(puzzle.solve_puzzle(puzzle.puzzle_solution) and Game.count_item("fuse") == 1, "Unchecked puzzle input remains available after success")
    puzzle.queue_free()
    reset()
    single_key()
    Game.add_item("test_single_key", 2)
    var gate := door("test_single_door")
    gate.requires_power = true
    before = Game.inventory.snapshot()
    gate.open_door()
    check(not gate.opened and Game.inventory.snapshot() == before, "An unpowered door does not spend its key")
    gate.requires_power = false
    gate.open_door()
    await frames()
    check(gate.opened and Game.count_item("test_single_key") == 1 and gate.get_node("Barrier/CollisionShape2D").disabled, "A checked key opens its door and removes one matching instance")
    gate.open_door()
    check(Game.count_item("test_single_key") == 1 and Game.world[gate.state_key()], "Reusing an opened door cannot spend another key")
    gate.queue_free()
    reset()
    Game.add_item("gate_key")
    gate = door("test_permanent_door")
    gate.open_door()
    check(gate.opened and Game.count_item("gate_key") == 1, "Existing unchecked key remains reusable")
    gate.queue_free()
    gate = door("test_legacy_door")
    gate.consume_key = true
    gate.open_door()
    check(gate.opened and Game.count_item("gate_key") == 0, "Legacy Consume Key override remains compatible")
    gate.queue_free()
    await frames()

func refresh_room() -> void:
    room = get_tree().current_scene
    player = room.get_node("Actors/Player")
    player.set_physics_process(false)
    room.get_node("Actors/Enemy").set_physics_process(false)
func fence(id: String, x: float = 400) -> Area2D:
    var result: Area2D = load("res://scenes/objects/fence_cuttable_side.tscn").instantiate()
    result.persistent_id = id
    result.position = Vector2(x, 620)
    result.interaction_radius = 100
    result.cut_seconds = 0.06
    room.get_node("Interactables").add_child(result)
    return result
func wait_for_cut(gate: Area2D) -> void:
    for i in 120:
        if not gate.cutting:return
        await frames(1)

func verify_cutters_and_saves() -> void:
    reset()
    room = load("res://tests/fixtures/weapon_workbench.tscn").instantiate()
    get_tree().root.add_child(room)
    get_tree().current_scene = room
    await frames(6)
    refresh_room()
    var pickup: Area2D = load("res://scenes/objects/equipment/bolt_cutters_single_use.tscn").instantiate()
    room.get_node("Interactables").add_child(pickup)
    pickup.interact(player)
    await frames()
    check(Game.count_item("bolt_cutters_single_use") == 1, "The reusable pickup scene grants the separate single-use cutter item")
    Game.add_item("bolt_cutters_single_use")
    var used := Game.find_use_uid("bolt_cutters")
    var remaining: Dictionary = Game.inventory.entries.filter(func(e):return e["id"] == "bolt_cutters_single_use" and e["uid"] != used)[0].duplicate(true)
    var gate := fence("test_saved_cut")
    var bike: Area2D = room.get_node("Interactables/SaveBicycle")
    player.position = bike.position + Vector2(0, -32)
    var first := Game.inventory.snapshot()
    check(Game.save_slot(0, bike), "Slot A saves two unspent disposable tools and a closed route")
    gate.interact(player)
    check(not gate.cutting and Game.inventory.snapshot() == first, "Out-of-range cutting does not spend a tool")
    player.position = Vector2(400, 588)
    gate.interact(player)
    gate.interact(player)
    check(gate.cutting and Game.count_item("bolt_cutters_single_use") == 2, "Starting or repeating an unfinished cut does not spend the tool early")
    await wait_for_cut(gate)
    check(gate.opened and Game.count_item("bolt_cutters_single_use") == 1 and Game.inventory.entry(used).is_empty(), "A completed cut removes exactly the tool instance selected for that action")
    check(Game.inventory.entry(remaining["uid"]) == remaining, "Another disposable cutter retains its identity and complete instance state")
    gate.interact(player)
    check(Game.count_item("bolt_cutters_single_use") == 1, "An opened fence never consumes another tool")
    player.position = bike.position + Vector2(0, -32)
    var second := Game.inventory.snapshot()
    check(Game.save_slot(1, bike), "Slot B saves the spent tool and opened route together")
    for index in [0, 1]:
        check(Game.load_slot(index), "Disposable-tool save slot loads: " + str(index))
        await frames(8)
        refresh_room()
        check(Game.inventory.snapshot() == (first if index == 0 else second), "Each slot restores its own unspent disposable tool instances: " + str(index))
        var restored := fence("test_saved_cut")
        await frames()
        check(restored.opened == (index == 1) and restored.get_node("Barrier/CollisionShape2D").disabled == (index == 1), "Saved route and tool count stay synchronized: " + str(index))
    reset()
    Game.add_item("bolt_cutters_single_use")
    var a := fence("test_race_a")
    var b := fence("test_race_b", 430)
    player.position = Vector2(410, 588)
    a.interact(player)
    b.interact(player)
    await wait_for_cut(a)
    await wait_for_cut(b)
    check(a.opened != b.opened and Game.count_item("bolt_cutters_single_use") == 0, "Overlapping cuts cannot open two fences with one disposable tool")
    var failed := b if a.opened else a
    check(not failed.cutting and not failed.get_node("Barrier/CollisionShape2D").disabled and failed.get_node("LeftPanel").rotation == 0, "The losing cut restores closed artwork and collision")
    a.queue_free()
    b.queue_free()
    Game.add_item("bolt_cutters")
    a = fence("test_reusable_cut")
    player.position = Vector2(400, 588)
    a.interact(player)
    await wait_for_cut(a)
    check(a.opened and Game.count_item("bolt_cutters") == 1, "Existing reusable cutters still survive a completed cut")

func entrance(id: String, path: String) -> Area2D:
    var result: Area2D = load("res://scenes/objects/entrance.tscn").instantiate()
    result.required_key = "gate_key"
    result.destination_scene = path
    result.destination_spawn = "default"
    result.persistent_id = id
    room.get_node("Interactables").add_child(result)
    return result
func verify_entrances() -> void:
    reset()
    single_key()
    Game.add_item("test_single_key")
    var start := room
    var entry := entrance("test_missing_destination", "res://scenes/missing_destination.tscn")
    var before := Game.inventory.snapshot()
    entry.interact(player)
    check(not Transition.busy and Game.inventory.snapshot() == before and not Game.world.get(entry.state_key(), false), "A missing entrance destination cannot spend its key or unlock the route")
    entry.queue_free()
    entry = entrance("test_removed_key", "res://tests/fixtures/weapon_workbench.tscn")
    entry.interact(player)
    Game.take_item("test_single_key")
    await get_tree().create_timer(0.95).timeout
    check(get_tree().current_scene == start and not Game.world.get(entry.state_key(), false) and not Transition.busy, "Losing the selected key during the fade cancels travel without unlocking the entrance")
    entry.queue_free()
    Game.add_item("test_single_key")
    entry = entrance("test_unlocked_entrance", "res://tests/fixtures/weapon_workbench.tscn")
    entry.interact(player)
    check(Game.count_item("test_single_key") == 1 and Transition.busy, "Entrance keys remain in inventory while the transition is unfinished")
    await get_tree().create_timer(0.95).timeout
    refresh_room()
    check(Game.count_item("test_single_key") == 0 and Game.world.get("test_unlocked_entrance", false) and not Transition.busy, "Successful scene travel consumes its key and records the unlocked entrance")
    entry = entrance("test_unlocked_entrance", "res://tests/fixtures/weapon_workbench.tscn")
    check(entry.unlocked and entry.is_available(), "Reloaded unlocked entrances remain interactable without the spent key")
    entry.interact(player)
    await get_tree().create_timer(0.95).timeout
    refresh_room()
    check(not Transition.busy and not Game.transitioning and Game.count_item("test_single_key") == 0, "An unlocked entrance supports backtracking without another key")
