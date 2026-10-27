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

func frames(count: int) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame

func press(action: String) -> void:
    Input.action_press(action)
    await frames(2)
    Input.action_release(action)
    await frames(2)

func slot_for(id: String) -> int:
    for i in 8:
        if Game.slots[i].get("id", "") == id:
            return i
    return -1

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    Game.reset_run()
    Game.take_item("ammo", 12)
    Game.add_item("cloth", 2)
    Game.add_item("antiseptic", 2)
    Game.add_item("bandage", 3)
    for i in 5:
        Game.add_item("filler" + str(i))
    var before: Array[Dictionary] = Game.slots.duplicate(true)
    check(not Game.combine_items("cloth", "antiseptic") and Game.slots == before, "Crafting rolls back both materials when output cannot fit")
    check(not Game.combine_items("cloth", "cloth") and Game.slots == before, "Invalid recipe consumes nothing")
    Game.start_game()
    await frames(8)
    var street: Node2D = get_tree().current_scene
    var hud: CanvasLayer = street.get_node("HUD")
    var player: CharacterBody2D = street.get_node("Actors/Player")
    for old in ["TopShade", "BottomShade", "Controls", "Title", "Objective", "Health", "Dodge"]:
        check(not hud.has_node("Root/" + old), "Removed persistent HUD element: " + old)
    check(not hud.get_node("Root/Ammo").visible and not hud.get_node("Root/Crosshair").visible and not hud.get_node("Root/HealthBrief").visible, "Idle exploration has no combat overlay")
    check(not hud.get_node("Root/Message").visible, "Autosave creates no gameplay text banner")
    check(not hud.get_node("Root/Prompt").visible, "No interaction prompt out of range")
    Input.action_press("aim")
    Input.action_press("move_right")
    await frames(18)
    check(hud.get_node("Root/Ammo").visible and hud.get_node("Root/Crosshair").visible, "Right mouse reveals compact aiming feedback")
    check(absf(player.velocity.x) < player.move_speed * 0.6, "Aiming slows movement")
    Input.action_release("aim")
    Input.action_release("move_right")
    await frames(3)
    check(not hud.get_node("Root/Ammo").visible and not hud.get_node("Root/Crosshair").visible, "Combat feedback disappears on return to exploration")
    player.take_damage(10)
    await frames(2)
    check(hud.get_node("Root/HealthBrief").visible, "Damage briefly reveals a small health bar")
    await get_tree().create_timer(3.7).timeout
    check(not hud.get_node("Root/HealthBrief").visible, "Health feedback fades away when not critical")
    Game.health = 20
    Game.changed.emit()
    await frames(2)
    check(hud.get_node("Root/HealthBrief").visible, "Critical health remains legible")
    Game.health = 100
    Game.changed.emit()
    Transition.travel("res://scenes/levels/interior.tscn", "from_street")
    await get_tree().create_timer(1.2).timeout
    var room: Node2D = get_tree().current_scene
    hud = room.get_node("HUD")
    player = room.get_node("Actors/Player")
    var pickup: Area2D = room.get_node("Interactables/SupplyBox")
    check(not pickup.has_node("EditorLabel") and not pickup.has_node("Indicator"), "Pickup is just its artwork: no title or floating marker")
    player.position = Vector2(770,588)
    await frames(3)
    check(hud.get_node("Root/Prompt").visible and hud.get_node("Root/Prompt").text == "[E]  Take", "Nearby pickup offers a generic action without revealing identity")
    var prompt_position: Vector2 = hud.get_node("Root/Prompt").position
    check(prompt_position.x > 100 and prompt_position.y > 100, "Prompt follows object's screen position")
    await press("interact")
    check(not room.has_node("Interactables/SupplyBox") and not hud.get_node("Root/Prompt").visible, "Successful pickup removes object and prompt")
    check(hud.get_node("Root/Message").text.is_empty(), "Pickup does not announce item name on the world HUD")
    hud.open_inventory()
    await frames(2)
    check(get_tree().paused and hud.get_node("Root/InventoryPanel").visible, "Inventory inspection pauses the game")
    check(hud.get_node("Root/InventoryPanel/Slots").get_child_count() == 8, "Icon inventory retains exactly eight pockets")
    hud.select_slot(slot_for("ammo"))
    check(hud.get_node("Root/InventoryPanel/ItemName").text == "9 mm rounds", "Item identity is revealed in inventory")
    check(hud.get_node("Root/InventoryPanel/Portrait").texture == Game.item_icon("ammo") and not hud.get_node("Root/InventoryPanel/Description").text.is_empty(), "Inventory displays item artwork and useful description")
    check(hud.get_node("Root/InventoryPanel/Slots").get_child(slot_for("ammo")).get_node("Count").text == "24", "Inventory displays ammunition stack count")
    Game.add_item("bandage")
    hud.select_slot(slot_for("bandage"))
    check(hud.get_node("Root/InventoryPanel/Use").disabled and not Game.use_item("bandage") and Game.count_item("bandage") == 1, "Medical item cannot be wasted at full health")
    Game.health = 60
    Game.changed.emit()
    hud.select_slot(slot_for("bandage"))
    hud.get_node("Root/InventoryPanel/Use").pressed.emit()
    check(Game.health == 90 and Game.count_item("bandage") == 0, "Inventory Use consumes one dressing and heals 30")
    Game.add_item("cloth")
    Game.add_item("antiseptic")
    hud.select_slot(slot_for("cloth"))
    hud.get_node("Root/InventoryPanel/Combine").pressed.emit()
    hud.get_node("Root/InventoryPanel/Slots").get_child(slot_for("antiseptic")).pressed.emit()
    check(Game.count_item("cloth") == 0 and Game.count_item("antiseptic") == 0 and Game.count_item("bandage") == 1, "Inventory Combine crafts from the selected pair")
    check(hud.get_node("Root/InventoryPanel/ItemName").text == "Field dressing", "Combination result is selected for immediate inspection")
    hud.close_panels()
    check(not get_tree().paused, "Inventory closes back to exploration")
    Transition.travel("res://scenes/levels/alley.tscn", "from_street")
    await get_tree().create_timer(1.2).timeout
    var alley: Node2D = get_tree().current_scene
    player = alley.get_node("Actors/Player")
    var enemy: CharacterBody2D = alley.get_node("Actors/Enemy")
    enemy.set_physics_process(false)
    var gate: Area2D = alley.get_node("Interactables/ToolGate")
    gate.open_door()
    check(not gate.opened, "Chained route stays closed without its tool")
    Game.add_item("bolt_cutters")
    player.position = Vector2(1230,588)
    await frames(3)
    await press("interact")
    await get_tree().create_timer(0.9).timeout
    check(gate.opened and gate.get_node("Barrier/CollisionShape2D").disabled, "Carried tool opens chained route with E")
    check(Game.count_item("bolt_cutters") == 1, "Route-opening tool is reusable")
    Game.save_run()
    Game.item_catalog.erase("bolt_cutters")
    Game.continue_game()
    await frames(10)
    alley = get_tree().current_scene
    gate = alley.get_node("Interactables/ToolGate")
    check(gate.opened and gate.get_node("Barrier/CollisionShape2D").disabled, "Tool-opened route remains open after loading")
    check(Game.item_name("bolt_cutters") == "Bolt cutters" and Game.item_icon("bolt_cutters") != null, "Saved item definitions restore inventory inspection metadata")
    alley.get_node("HUD").toggle_pause()
    alley.get_node("HUD/Root/PausePanel/Controls").pressed.emit()
    check(get_tree().paused and alley.get_node("HUD/Root/ControlsPanel").visible, "Controls remain available in pause menu")
    alley.get_node("HUD").close_panels()
    alley.get_node("AmbientSound").stop()
    alley.queue_free()
    get_tree().current_scene = null
    await frames(5)
    print("IGNOTUM INTERFACE: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)
