extends Node
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
    checks += 1
    if ok: print("PASS: " + text)
    else:
        failures += 1
        push_error("FAIL: " + text)
func frames(count: int = 5) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame
func enter(path: String) -> void:
    get_tree().paused = false
    var error := get_tree().change_scene_to_file(path)
    await frames()
    check(error==OK and get_tree().current_scene.scene_file_path==path, "Opens actual designer location: "+path.get_file())
    for enemy in get_tree().get_nodes_in_group("enemy"):
        enemy.process_mode = Node.PROCESS_MODE_DISABLED
func find_loot(id: String) -> LootContainer:
    for target in get_tree().get_nodes_in_group("interactable"):
        if target is LootContainer:
            for entry in target.contents:
                if entry != null and entry.item != null and entry.item.id==id:
                    return target
    return null
func save_from_menu(index: int) -> bool:
    var station: Area2D = get_tree().get_first_node_in_group("save_station")
    var player: Node2D = get_tree().get_first_node_in_group("player")
    player.global_position = station.global_position + Vector2(-20,-25)
    await frames(2)
    var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")
    hud.show_save_station(station)
    var picker: CanvasLayer = hud.get_node("SaveMenu")
    picker.choose_slot(index)
    var succeeded: bool = picker.feedback.text == "Game saved in slot %d." % (index+1)
    picker.close()
    return succeeded
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()
func run() -> void:
    if OS.get_cmdline_user_args().has("--verify-fresh-load"):
        await verify_fresh_process()
        await finish()
        return
    for index in Game.SAVE_SLOT_COUNT:
        if FileAccess.file_exists(Game.slot_path(index)):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(index)))
    Game.reset_run()
    Game.add_item("ammo",5)
    await enter("res://scenes/levels/alleyway_02.tscn")
    var house_key: InventoryItemDefinition = Game.item_catalog.get("house_03_key")
    check(house_key != null and house_key.resource_path.contains(".tscn::"), "The actual alley registers an Inspector-created scene-contained house key")
    if house_key == null:
        await finish()
        return
    var key_path := house_key.resource_path
    check(Game.count_item("house_03_key")==0, "The regression also covers visiting without collecting the key")
    await enter("res://scenes/levels/town_01.tscn")
    Game.health = 95
    Game.flashlight_on = false
    Game.world["story:embedded_save_test"] = false
    var saved_a := await save_from_menu(0)
    check(saved_a, "The real bicycle save menu writes slot A after visiting the alley")
    if not saved_a:
        await finish()
        return
    check(Game.save_info(0)["valid"], "Slot A is immediately available to load")
    var earlier := FileAccess.get_file_as_string(Game.slot_path(0))
    var snapshot_a: Dictionary = Game._read_slot(0)
    check(snapshot_a["item_definitions"].has(key_path) and snapshot_a["inventory"]["items"].size()==1, "The saved catalog retains the embedded resource path even before pickup")
    await enter("res://scenes/levels/alleyway_02.tscn")
    var drawer := find_loot("house_03_key")
    check(drawer != null and drawer.search(), "The designer's actual drawer gives the embedded house key")
    if drawer == null:
        await finish()
        return
    var drawer_state := drawer.state_key()
    check(Game.count_item("house_03_key")==1, "The collected house key occupies its normal inventory entry")
    await enter("res://scenes/levels/house_04_2.tscn")
    var gate_drawer := find_loot("gate_key")
    check(gate_drawer != null and gate_drawer.search(), "A second location's embedded gate key can be collected too")
    if gate_drawer == null:
        await finish()
        return
    var gate_state := gate_drawer.state_key()
    await enter("res://scenes/levels/town_01.tscn")
    Game.add_item("pistol")
    Game.equip_weapon(Game.inventory.first_uid("pistol"))
    Game.magazine = 3
    Game.add_item("ammo",7)
    Game.health = 74
    Game.flashlight_on = true
    Game.world["story:embedded_save_test"] = true
    Game.world["dialogue_choice:embedded_save_test"] = true
    var snapshot_b := Game.inventory.snapshot()
    var saved_b := await save_from_menu(1)
    check(saved_b and Game.save_info(1)["valid"], "Slot B saves both custom keys, weapon ammunition, health and progress")
    if not saved_b:
        await finish()
        return
    check(FileAccess.get_file_as_string(Game.slot_path(0))==earlier, "Saving slot B leaves slot A byte-for-byte unchanged")
    check(Game.load_slot(0), "The earlier slot loads through the real save system")
    await frames(10)
    check(Game.count_item("house_03_key")==0 and Game.count_item("gate_key")==0 and Game.count_item("ammo")==5 and Game.health==95, "Slot A restores its own inventory and health without later keys")
    check(not Game.world.get(drawer_state,false) and not Game.world.get(gate_state,false) and not Game.world.get("story:embedded_save_test",true), "Slot A restores earlier loot and story progress independently")
    check(not Game.flashlight_on and not Game.has_equipped_weapon(), "Slot A restores its own equipment and flashlight state")
    check(Game.load_slot(1), "The later slot loads through the real save system")
    await frames(10)
    check(Game.inventory.snapshot()==snapshot_b and Game.health==74 and Game.magazine==3, "Slot B restores the exact inventory instances, health and weapon rounds")
    check(Game.world.get(drawer_state,false) and Game.world.get(gate_state,false) and Game.world.get("dialogue_choice:embedded_save_test",false), "Slot B restores both searched drawers and the later dialogue choice")
    check(Game.item_catalog["house_03_key"].grid_size==Vector2i(2,1) and Game.item_catalog["house_03_key"].remove_after_use and Game.item_catalog["house_03_key"].icon != null, "Embedded item footprints, use behavior and artwork survive loading")
    var malformed: Dictionary = Game._read_slot(1).duplicate(true)
    for bad_path in ["user://not_a_project_resource.tres", "res://scenes/levels/alleyway_02.tscn", "res://art/fonts/styles/ui_text.tres", "res://missing_item.tres"]:
        malformed["item_definitions"] = [bad_path]
        check(not Game._save_error(malformed).is_empty(), "Invalid or non-item resources remain rejected: "+bad_path)
    malformed = Game._read_slot(1).duplicate(true)
    malformed["inventory"]["items"][0]["count"] = 0
    check(not Game._save_error(malformed).is_empty(), "Malformed inventory quantities remain rejected")
    malformed = Game._read_slot(1).duplicate(true)
    malformed["position"] = [NAN,0]
    check(not Game._save_error(malformed).is_empty(), "Invalid saved positions remain rejected")
    await finish()
func verify_fresh_process() -> void:
    check(not Game.item_catalog.has("house_03_key") and not Game.item_catalog.has("gate_key"), "A fresh Godot process starts without either scene-contained key in its catalog")
    check(Game.save_info(0)["valid"] and Game.save_info(1)["valid"], "Both existing files validate without previously visiting their key locations")
    check(Game.load_slot(1), "The saved run loads in a completely fresh Godot process")
    await frames(10)
    check(Game.count_item("house_03_key")==1 and Game.count_item("gate_key")==1 and Game.count_item("ammo")==12, "A fresh session reconstructs the custom keys and reserve ammunition from the saved paths")
    check(Game.health==74 and Game.magazine==3 and Game.has_equipped_weapon() and Game.world.get("story:embedded_save_test",false), "A fresh session also restores health, equipped weapon, loaded rounds and story progress")
func finish() -> void:
    GameAudio.stop_all()
    if get_tree().current_scene:
        for audio in get_tree().current_scene.find_children("*","AudioStreamPlayer",true,false):audio.stop()
    await get_tree().create_timer(0.2).timeout
    print("IGNOTUM EMBEDDED ITEM SAVES: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures==0 else 1)
