extends Node
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
    checks += 1
    if ok:
        print("PASS: " + text)
    else:
        failures += 1
        push_error("FAIL: " + text)
func frames(count: int = 6) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame
func travel(path: String, spawn: String = "default") -> void:
    Transition.travel(path, spawn)
    await get_tree().create_timer(1.1).timeout
func file_text(index: int) -> String:
    return FileAccess.get_file_as_string(Game.slot_path(index))
func write_text(index: int, text: String) -> void:
    var file := FileAccess.open(Game.slot_path(index), FileAccess.WRITE)
    file.store_string(text)
    file.close()
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()
func run() -> void:
    for index in Game.SAVE_SLOT_COUNT:
        if FileAccess.file_exists(Game.slot_path(index)):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(index)))
    Game.start_game()
    await frames()
    var town: Node2D = get_tree().current_scene
    var player: CharacterBody2D = town.get_node("Actors/Player")
    var bike: Area2D = town.get_node("Interactables/SaveBicycle")
    player.position = Vector2(160,588)
    check(not Game.has_saves(), "New game and location entry do not autosave")
    check(not Game.save_slot(-1,bike) and not Game.save_slot(4,bike) and not Game.save_slot(0,null), "Only four slots and placed save stations authorize writes")
    var hud: CanvasLayer = town.get_node("HUD")
    bike.interact(player)
    await get_tree().create_timer(0.5).timeout
    var picker: CanvasLayer = hud.get_node("SaveMenu")
    check(picker.is_open() and get_tree().paused, "Bicycle bell opens the paused four-slot save menu")
    picker.entries.get_child(0).pressed.emit()
    var first_file := file_text(0)
    var first_inventory := Game.inventory.snapshot()
    var first_world := Game.world.duplicate(true)
    check(Game.save_info(0)["valid"], "Slot A records the initial run")
    picker.entries.get_child(0).pressed.emit()
    check(picker.confirmation.visible and file_text(0) == first_file, "Overwrite confirmation protects the existing file")
    picker.confirmation.canceled.emit()
    picker.confirmation.hide()
    picker.close()
    # Collect actual placed objects, not just manually assigned inventory dictionaries.
    await travel("res://scenes/levels/interior.tscn", "from_street")
    var room: Node2D = get_tree().current_scene
    check(not room.get_node("Actors/Player/Camera2D").enabled and room.get_node("Camera2D").zoom == Vector2(2.1,2.1), "Fixed interior camera survives inventory/save changes")
    for name in ["Cloth", "Antiseptic", "BoltCutters"]:
        room.get_node("Interactables/" + name).interact(room.get_node("Actors/Player"))
    await frames(2)
    check(Game.count_item("cloth") == 1 and Game.count_item("antiseptic") == 1 and Game.count_item("bolt_cutters") == 1, "Actual placed pickups enter inventory and world progress")
    Game.add_item("fuse")
    var board: Area2D = load("res://scenes/objects/switchboard.tscn").instantiate()
    board.power_channel = "save_test"
    room.get_node("Interactables").add_child(board)
    check(board.solve_puzzle(board.puzzle_solution), "A real puzzle records its completed circuit state")
    await travel("res://scenes/levels/alley.tscn")
    var alley: Node2D = get_tree().current_scene
    alley.get_node("Interactables/ToolGate").open_door()
    alley.get_node("Actors/Enemy").take_damage(100)
    await frames(2)
    await travel("res://scenes/levels/town.tscn")
    town = get_tree().current_scene
    player = town.get_node("Actors/Player")
    bike = town.get_node("Interactables/SaveBicycle")
    player.position = Vector2(160,588)
    Game.health = 71
    Game.magazine = 3
    Game.flashlight_on = false
    check(Game.move_item(Game.equipped_uid, Vector2i(5,2), true), "Weapon placement/orientation can differ between saves")
    hud = town.get_node("HUD")
    hud.show_save_station(bike)
    hud.get_node("SaveMenu").entries.get_child(1).pressed.emit()
    var second_inventory := Game.inventory.snapshot()
    var second_world := Game.world.duplicate(true)
    var second_file := file_text(1)
    check(first_inventory != second_inventory and first_world != second_world, "Save A and B contain different inventories and world snapshots")
    check(file_text(0) == first_file, "Saving later pickups to B does not alter A on disk")
    var before_preview := Game.inventory.snapshot()
    check(Game.save_info(0)["item_count"] != Game.save_info(1)["item_count"] and Game.inventory.snapshot()==before_preview, "Slot previews show stored item counts without changing the live inventory")
    hud.get_node("SaveMenu").close()
    # Follow the actual pause-menu load flow repeatedly, with inspection after each load.
    for index in [0,1,0,1]:
        hud = get_tree().current_scene.get_node("HUD")
        hud.toggle_pause()
        hud.get_node("Root/PausePanel/Retry").pressed.emit()
        picker = hud.get_node("SaveMenu")
        check(not picker.saving and picker.is_open(), "Pause opens load mode, not save mode")
        picker.entries.get_child(index).pressed.emit()
        check(not Game.load_slot(1-index), "A second same-frame load cannot race deferred scene replacement")
        await frames()
        var expected_inventory: Dictionary = first_inventory if index == 0 else second_inventory
        var expected_world: Dictionary = first_world if index == 0 else second_world
        check(Game.inventory.snapshot() == expected_inventory, "Slot %d restores its own item instances, counts, positions, rotation and magazines" % (index+1))
        check(Game.world == expected_world and Game.world.get("power:save_test",false) == (index==1), "Slot %d restores its own puzzle, pickup, gate and enemy state" % (index+1))
        check(Game.health == (100 if index==0 else 71) and Game.magazine == (6 if index==0 else 3), "Slot %d restores health and loaded weapon rounds" % (index+1))
        check(Game.count_item("cloth") == index and Game.count_item("bolt_cutters") == index, "Earlier slot never inherits later pickups")
        hud = get_tree().current_scene.get_node("HUD")
        hud.open_inventory()
        hud.select_item(Game.inventory.first_uid("cloth"))
        check(hud.get_node("Root/InventoryPanel/Portrait").texture == (Game.item_icon("cloth") if index==1 else null), "Inventory inspection reflects the loaded slot")
        hud.close_panels()
        player = get_tree().current_scene.get_node("Actors/Player")
        bike = get_tree().current_scene.get_node("Interactables/SaveBicycle")
        check(player.global_position.distance_to(bike.get_node("SaveSpawn").global_position) < 2, "Loading returns beside the saved bicycle")
    check(file_text(0)==first_file and file_text(1)==second_file, "Repeated loading and inspection never rewrites either save")
    await travel("res://scenes/levels/interior.tscn")
    check(not get_tree().current_scene.has_node("Interactables/Cloth"), "Collected object is absent after loading the later slot")
    await travel("res://scenes/levels/alley.tscn")
    alley = get_tree().current_scene
    check(alley.get_node("Interactables/ToolGate").opened and not alley.has_node("Actors/Enemy"), "Later slot restores the open gate and defeated enemy in the actual scene")
    Game.load_slot(0)
    await frames()
    await travel("res://scenes/levels/interior.tscn")
    check(get_tree().current_scene.has_node("Interactables/Cloth"), "The same object is restored by the earlier slot")
    await travel("res://scenes/levels/alley.tscn")
    alley = get_tree().current_scene
    check(not alley.get_node("Interactables/ToolGate").opened and alley.has_node("Actors/Enemy"), "Earlier slot restores the locked gate and living enemy")
    Game.load_slot(1)
    await frames()
    town = get_tree().current_scene
    bike = town.get_node("Interactables/SaveBicycle")
    player = town.get_node("Actors/Player")
    player.position = Vector2(160,588)
    Game.equip_weapon(Game.equipped_uid)
    Game.expand_inventory(10,5)
    check(Game.save_slot(2,bike), "Third slot saves unarmed equipment and upgraded capacity")
    Game.add_item("ammo", 25)
    Game.health = 42
    check(Game.save_slot(3,bike), "Fourth slot is independent")
    Game.load_slot(2)
    await frames()
    check(Game.inventory.entry(Game.inventory.first_uid("pistol"))["magazine"]==3, "Unequipped weapon retains its saved magazine")
    check(not Game.has_equipped_weapon() and Game.inventory.columns==10 and Game.inventory.rows==5 and Game.health==71, "Capacity and unequipped state restore per slot")
    Game.load_slot(3)
    await frames()
    check(Game.health==42 and Game.count_item("ammo")==37, "Fourth slot restores its distinct ammunition quantity")
    var corrupt: Dictionary = JSON.parse_string(file_text(3))
    corrupt["inventory"]["items"][1]["x"] = corrupt["inventory"]["items"][0]["x"]
    corrupt["inventory"]["items"][1]["y"] = corrupt["inventory"]["items"][0]["y"]
    write_text(3,JSON.stringify(corrupt))
    var unchanged := Game.inventory.snapshot()
    check(not Game.load_slot(3) and Game.inventory.snapshot()==unchanged, "Overlapping/corrupt inventory is rejected without resetting the current run")
    write_text(3,"{broken")
    check(not Game.save_info(3)["valid"] and not Game.load_slot(3), "Invalid JSON is handled without a crash")
    # Version-2 manual saves are migrated in memory only; no user's old file is overwritten.
    var old: Dictionary = JSON.parse_string(first_file)
    old["version"] = 2
    old.erase("inventory")
    old.erase("equipped_uid")
    old["slots"] = [{"id":"ammo","count":12},{"id":"cloth","count":2},{},{},{},{},{},{}]
    old["magazine"] = 4
    old["health"] = 82
    write_text(3,JSON.stringify(old))
    var legacy := file_text(3)
    check(Game.load_slot(3), "Previous version-2 saves still load")
    await frames()
    check(Game.count_item("cloth")==2 and Game.magazine==4 and Game.has_equipped_weapon() and Game.health==82, "Legacy implicit handgun becomes a real two-cell equipped item")
    check(file_text(3)==legacy, "Reading or loading a legacy slot does not rewrite its file")
    hud = get_tree().current_scene.get_node("HUD")
    Game.health = 0
    Game.changed.emit()
    hud.open_load_menu()
    check(hud.get_node("SaveMenu").is_open() and get_tree().paused, "Death still offers the four-slot load picker")
    hud.get_node("SaveMenu").entries.get_child(0).pressed.emit()
    await frames()
    check(Game.health==100 and not get_tree().paused, "Death load restores the selected complete snapshot")
    Game.start_game()
    await frames()
    check(file_text(0)==first_file, "New game preserves existing manual saves")
    get_tree().current_scene.get_node("AmbientSound").stop()
    await frames(3)
    get_tree().current_scene.queue_free()
    get_tree().current_scene = null
    await frames()
    print("IGNOTUM MANUAL SAVES: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures==0 else 1)
