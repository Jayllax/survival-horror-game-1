extends Node
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("FAIL: " + description)
    else:
        print("PASS: " + description)

func frames(count: int = 3) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame

func key(code: Key, physical: Key = KEY_NONE) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = physical if physical != KEY_NONE else code
    event.pressed = true
    Input.parse_input_event(event)
    await frames(1)
    event = event.duplicate()
    event.pressed = false
    Input.parse_input_event(event)
    await frames(1)

func write_file(path: String, text: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
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
    write_file("user://checkpoint.json", "legacy checkpoint left untouched")
    Game.start_game()
    await frames(8)
    var town: Node2D = get_tree().current_scene
    var player: CharacterBody2D = town.get_node("Actors/Player")
    var hud: CanvasLayer = town.get_node("HUD")
    var bicycle: Area2D = town.get_node("Interactables/SaveBicycle")
    check(not Game.has_saves(), "Starting and entering a location writes no save files")
    check(not hud.has_node("Root/PausePanel/Save"), "Pause menu cannot save away from a bicycle")
    check(not Game.save_slot(0, null) and not Game.save_slot(0, player), "Saving requires an actual placed bicycle")
    check(not Game.save_slot(-1, bicycle) and not Game.save_slot(4, bicycle), "Only four save slot indices are accepted")
    # Actual OS-style key events must reach the HUD before focused GUI controls.
    await key(KEY_TAB)
    check(hud.get_node("Root/InventoryPanel").visible and get_tree().paused, "Tab opens inventory")
    var focused := get_viewport().gui_get_focus_owner()
    check(focused != null, "Inventory starts with keyboard focus on a slot")
    var repeated_tab := InputEventKey.new()
    repeated_tab.keycode = KEY_TAB
    repeated_tab.physical_keycode = KEY_TAB
    repeated_tab.pressed = true
    repeated_tab.echo = true
    Input.parse_input_event(repeated_tab)
    await frames(1)
    check(hud.get_node("Root/InventoryPanel").visible and get_viewport().gui_get_focus_owner() == focused, "Holding Tab never toggles repeatedly or advances inventory focus")
    await key(KEY_TAB)
    check(not hud.get_node("Root/InventoryPanel").visible and not get_tree().paused, "Tab closes inventory despite focused GUI button")
    await key(KEY_I)
    check(hud.get_node("Root/InventoryPanel").visible, "Existing I binding still opens inventory")
    await key(KEY_TAB)
    check(not get_tree().paused, "Tab closes an inventory opened with I")
    Game.slots[0] = {"id": "ammo", "count": 20}
    Game.slots[1] = {"id": "ammo", "count": 2}
    Game.changed.emit()
    hud.open_inventory()
    hud.select_slot(0)
    check(not hud.get_node("Root/InventoryPanel/Combine").disabled, "Ammunition supports Combine")
    hud.begin_combine()
    hud.get_node("Root/InventoryPanel/Slots").get_child(1).grab_focus()
    check(Game.slots[0]["count"] == 20 and Game.slots[1]["count"] == 2, "Keyboard focus alone never combines or consumes items")
    hud.get_node("Root/InventoryPanel/Slots").get_child(1).pressed.emit()
    check(Game.slots[0]["count"] == 22 and Game.slots[1].is_empty(), "Inventory Combine merges 20 plus 2 into 22 and frees a pocket")
    Game.slots[0] = {"id": "ammo", "count": 20}
    Game.slots[1] = {"id": "ammo", "count": 10}
    check(Game.combine_slots(0, 1) and Game.slots[0]["count"] == 24 and Game.slots[1]["count"] == 6, "Stack overflow stays in its original pocket without losing rounds")
    var before: Array[Dictionary] = Game.slots.duplicate(true)
    check(not Game.combine_slots(0, 1) and Game.slots == before, "Full destination stack consumes nothing")
    check(not Game.combine_slots(1, 1) and Game.slots == before, "A stack cannot combine with itself")
    check(not Game.combine_slots(-1, 0) and not Game.combine_slots(0, 8), "Invalid pocket indices are safe")
    var same_item_recipe := InventoryRecipe.new()
    same_item_recipe.input_a = "fuse"
    same_item_recipe.input_b = "fuse"
    same_item_recipe.output_id = "bandage"
    same_item_recipe.output_quantity = 1
    Game.recipes.append(same_item_recipe)
    Game.slots[2] = {"id": "fuse", "count": 1}
    Game.slots[3] = {"id": "fuse", "count": 1}
    check(Game.combine_slots(2,3) and Game.count_item("fuse") == 0 and Game.count_item("bandage") == 1, "Recipes requiring two identical nonstackable items still work")
    Game.recipes.erase(same_item_recipe)
    Game.take_item("bandage")
    hud.close_panels()
    # Place the player within interaction range; the reusable scene's origin is floor level.
    player.position = Vector2(160, 588)
    await frames()
    await key(KEY_E)
    check(bicycle.ringing and bicycle.get_node("BellSound").playing, "E at bicycle starts its bell interaction")
    await get_tree().create_timer(0.5).timeout
    var menu: CanvasLayer = hud.get_node("SaveMenu")
    check(menu.is_open() and get_tree().paused, "Bell interaction opens the save menu and pauses gameplay")
    check(menu.entries.get_child_count() == 4, "Save menu exposes exactly four slots")
    menu.choose_slot(0)
    check(Game.save_info(0)["valid"] and menu.feedback.text == "Game saved in slot 1.", "Empty slot saves immediately with visible confirmation")
    var old_save := FileAccess.get_file_as_string(Game.slot_path(0))
    Game.health = 75
    menu.choose_slot(0)
    check(menu.confirmation.visible and FileAccess.get_file_as_string(Game.slot_path(0)) == old_save, "Occupied slot asks before overwriting and leaves old save untouched")
    await key(KEY_ESCAPE)
    check(not menu.confirmation.visible and FileAccess.get_file_as_string(Game.slot_path(0)) == old_save, "Escape cancels overwrite without changing the file")
    # Fill all slots with distinguishable state.
    Game.world["manual:test"] = true
    Game.magazine = 3
    Game.flashlight_on = false
    Game.play_seconds = 185.0
    for index in Game.SAVE_SLOT_COUNT:
        Game.health = 75 - index * 15
        check(Game.save_slot(index, bicycle), "Bicycle can write save slot %d" % (index + 1))
    var slot_zero := FileAccess.get_file_as_string(Game.slot_path(0))
    Game.health = 50
    menu.choose_slot(1)
    menu.confirmation.confirmed.emit()
    menu.confirmation.hide()
    check(Game.save_info(1)["health"] == 50 and FileAccess.get_file_as_string(Game.slot_path(0)) == slot_zero, "Confirmed overwrite changes only the chosen slot")
    menu.close()
    check(not get_tree().paused, "Closing bicycle save menu resumes exploration")
    player.position = Vector2(1000, 588)
    check(not Game.save_slot(0, bicycle) and FileAccess.get_file_as_string(Game.slot_path(0)) == slot_zero, "A distant bicycle cannot authorize a save")
    Transition.travel("res://scenes/levels/interior.tscn", "from_street")
    await get_tree().create_timer(1.2).timeout
    check(FileAccess.get_file_as_string(Game.slot_path(0)) == slot_zero, "Changing locations never updates a manual save")
    var room: Node2D = get_tree().current_scene
    check(not room.get_node("Actors/Player/Camera2D").enabled and room.get_node("Camera2D").zoom == Vector2(2.1,2.1), "Custom fixed interior camera is preserved")
    Transition.travel("uid://duiums0oao68l", "default")
    await get_tree().create_timer(1.2).timeout
    check(get_tree().current_scene.scene_file_path.ends_with("interior1_2.tscn"), "Designer-authored UID scene transition still works")
    Game.health = 1
    Game.world.clear()
    check(Game.load_slot(0), "A valid manual save can be loaded")
    await frames(8)
    town = get_tree().current_scene
    player = town.get_node("Actors/Player")
    hud = town.get_node("HUD")
    bicycle = town.get_node("Interactables/SaveBicycle")
    check(Game.health == 75 and Game.magazine == 3 and Game.count_item("ammo") == 30, "Loading restores health, magazine and separate inventory stacks")
    check(Game.world.get("manual:test", false) and not Game.flashlight_on, "Loading restores world progress and flashlight equipment state")
    check(player.global_position.distance_to(bicycle.get_node("SaveSpawn").global_position) < 2, "Loading returns to the bicycle's editable SaveSpawn marker")
    check(not get_tree().paused and not hud.get_node("SaveMenu").is_open(), "Loaded game starts in playable state")
    check(FileAccess.get_file_as_string("user://checkpoint.json") == "legacy checkpoint left untouched", "Old checkpoint file is neither used nor erased")
    Game.health = 0
    Game.changed.emit()
    check(get_tree().paused and hud.get_node("Root/PausePanel/Resume").disabled, "Death prevents resuming the depleted player")
    hud.open_load_menu()
    menu = hud.get_node("SaveMenu")
    check(menu.is_open(), "Death screen offers the same four-slot load picker")
    menu.close()
    check(get_tree().paused and hud.get_node("Root/PausePanel").visible, "Canceling death load returns to the death menu")
    hud.open_load_menu()
    hud.get_node("SaveMenu").choose_slot(2)
    await frames(8)
    check(Game.health == 45 and not get_tree().paused, "Death load restores the selected slot rather than an automatic checkpoint")
    town = get_tree().current_scene
    hud = town.get_node("HUD")
    write_file(Game.slot_path(3), "{broken JSON")
    check(not Game.save_info(3)["valid"] and Game.save_info(3)["occupied"], "Corrupt slot is clearly marked as occupied but unavailable")
    var current_health: int = Game.health
    check(not Game.load_slot(3) and Game.health == current_health and get_tree().current_scene == town, "Invalid save cannot replace the current run")
    hud.back_to_menu()
    await frames(6)
    var main: Control = get_tree().current_scene
    main.get_node("Continue").pressed.emit()
    menu = main.get_node("SaveMenu")
    check(menu.is_open() and menu.entries.get_child(3).disabled, "Main menu opens slot selection and disables corrupt files")
    menu.close()
    Game.start_game()
    await frames(6)
    check(FileAccess.get_file_as_string(Game.slot_path(0)) == slot_zero, "New game never erases existing save slots")
    var art := load("res://art/pixel/bicycle.png") as Texture2D
    var image := art.get_image()
    var symmetrical := true
    for y in image.get_height():
        for x in image.get_width():
            if image.get_pixel(x,y) != image.get_pixel(image.get_width()-1-x,y):
                symmetrical = false
    check(image.get_size() == Vector2i(32,28) and symmetrical, "Production bicycle is native-resolution pixel art with exact mirror symmetry")
    get_tree().current_scene.get_node("AmbientSound").stop()
    await frames()
    get_tree().current_scene.queue_free()
    get_tree().current_scene = null
    await frames(5)
    print("IGNOTUM MANUAL SAVES: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)
