extends Node
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
    checks += 1
    if ok: print("PASS: " + text)
    else:
        failures += 1
        push_error("FAIL: " + text)
func frames(count: int = 3) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame
func key(code: Key, echo: bool = false) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = true
    event.echo = echo
    Input.parse_input_event(event)
    await frames(1)
    event = event.duplicate()
    event.pressed = false
    event.echo = false
    Input.parse_input_event(event)
    await frames(1)
func mouse(point: Vector2, pressed: bool) -> void:
    var event := InputEventMouseButton.new()
    event.position = point
    event.global_position = point
    event.button_index = MOUSE_BUTTON_LEFT
    event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
    event.pressed = pressed
    Input.parse_input_event(event)
    await frames(1)
func motion(point: Vector2) -> void:
    var event := InputEventMouseMotion.new()
    event.position = point
    event.global_position = point
    event.button_mask = MOUSE_BUTTON_MASK_LEFT
    Input.parse_input_event(event)
    await frames(1)
func point(grid: Control, cell: Vector2i) -> Vector2:
    return grid.get_global_transform_with_canvas() * ((Vector2(cell) + Vector2(0.5,0.5)) * grid.cell_size())
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()
func run() -> void:
    var model := GridInventory.new(Game.item_catalog, 4,2)
    check(model.add("pistol") and model.entries.size()==1, "Two-cell weapon occupies one item instance")
    var uid := model.first_uid("pistol")
    check(model.item_at(Vector2i(0,0))==uid and model.item_at(Vector2i(1,0))==uid, "Every occupied cell resolves to the same weapon instance")
    var before := model.snapshot()
    check(not model.move(uid,Vector2i(3,1),false) and model.snapshot()==before, "Boundary rejection cannot lose or relocate an item")
    check(model.move(uid,Vector2i(3,0),true) and model.dimensions("pistol",true)==Vector2i(1,2), "Rotation swaps a two-cell weapon's footprint")
    check(model.add("ammo",24), "A stack fits in one remaining cell")
    var ammo_uid := model.first_uid("ammo")
    check(not model.move(ammo_uid,Vector2i(3,1),false), "Cannot place an item over the lower half of a rotated weapon")
    var copied := model.copy()
    copied.entry(uid)["magazine"] = 4
    copied.move(uid,Vector2i(2,0),true)
    check(model.entry(uid)["magazine"]==0 and model.entry(uid)["x"]==3, "Inventory copies never share instance dictionaries")
    var restored := GridInventory.restore(copied.snapshot(),Game.item_catalog)
    check(restored != null and restored.snapshot()==copied.snapshot(), "Snapshot round-trip preserves UID, orientation and per-weapon rounds")
    var large := InventoryItemDefinition.new()
    large.id = "test_large"
    large.grid_size = Vector2i(3,2)
    var catalog := Game.item_catalog.duplicate()
    catalog[large.id] = large
    var fragmented := GridInventory.new(catalog,4,4)
    for i in 3:
        fragmented.add("filler%d"%i)
    fragmented.move(fragmented.first_uid("filler1"),Vector2i(1,2),false)
    fragmented.move(fragmented.first_uid("filler2"),Vector2i(3,1),false)
    fragmented.move(fragmented.first_uid("filler0"),Vector2i(1,0),false)
    check(not fragmented.add("test_large"), "Free cells must form a contiguous area matching the item's shape")
    var full := GridInventory.new(catalog,4,2)
    full.add("ammo",20)
    for i in 7: full.add("filler%d"%i)
    before = full.snapshot()
    check(not full.add("ammo",10) and full.snapshot()==before, "Failed pickup rolls back partial stacking and preserves all quantities")
    var collection := GridInventory.new(catalog,8,4)
    check(collection.add("pistol",6) and collection.count("pistol")==6, "Grid supports carrying six separate weapon instances")
    var weapon_uids: Array[int] = []
    for item in collection.entries: weapon_uids.append(item["uid"])
    check(weapon_uids.size()==6 and collection.next_uid==7, "Weapons of the same type still have unique stable identities")
    Game.reset_run()
    check(not Game.has_equipped_weapon() and Game.count_item("pistol")==0, "New games respect the designer's unarmed starting loadout")
    preload("res://tests/support/loadout.gd").handgun()
    var fixture=load("res://tests/fixtures/combat_sandbox.tscn").instantiate()
    get_tree().root.add_child(fixture)
    get_tree().current_scene=fixture
    await frames(6)
    var scene: Node2D = get_tree().current_scene
    var hud: CanvasLayer = scene.get_node("HUD")
    var player: CharacterBody2D = scene.get_node("Actors/Player")
    var pistol_uid := Game.inventory.first_uid("pistol")
    check(Game.equipped_uid==pistol_uid and Game.magazine==6, "Combat fixture explicitly carries and equips the actual handgun item")
    await key(KEY_TAB)
    check(get_tree().paused and hud.get_node("Root/InventoryPanel").visible, "Tab opens the grid inventory")
    var grid: Control = hud.get_node("Root/InventoryPanel/Grid")
    await key(KEY_TAB,true)
    check(hud.get_node("Root/InventoryPanel").visible, "Held Tab does not close repeatedly or navigate GUI focus")
    await key(KEY_TAB)
    check(not get_tree().paused, "Second Tab closes inventory with the grid focused")
    await key(KEY_I)
    check(get_tree().paused, "I remains an alternate inventory toggle")
    var item := Game.inventory.entry(pistol_uid)
    var origin := Vector2i(item["x"],item["y"])
    before = Game.inventory.snapshot()
    await mouse(point(grid,origin),true)
    check(grid.held_uid==pistol_uid, "Actual mouse press picks up the multi-cell weapon")
    await motion(point(grid,Vector2i(7,3)))
    await mouse(point(grid,Vector2i(7,3)),false)
    check(Game.inventory.snapshot()==before and grid.held_uid<0, "Invalid mouse drop restores original position without changing inventory")
    await mouse(point(grid,origin),true)
    await key(KEY_R)
    await motion(point(grid,Vector2i(5,3)))
    await mouse(point(grid,Vector2i(5,3)),false)
    item = Game.inventory.entry(pistol_uid)
    check(item["rotated"] and item["x"]==5 and item["y"]==2, "Real mouse drag plus R rotates and places the handgun in two vertical cells")
    check(Game.equipped_uid==pistol_uid and Game.magazine==6, "Rearranging an equipped weapon preserves equipment and its ammunition")
    before = Game.inventory.snapshot()
    await mouse(point(grid,Vector2i(5,2)),true)
    await motion(point(grid,Vector2i(3,2)))
    await key(KEY_ESCAPE)
    check(grid.held_uid<0 and Game.inventory.snapshot()==before and get_tree().paused, "Escape cancels a drag while keeping the inventory open")
    await mouse(point(grid,Vector2i(5,2)),false)
    hud.select_item(pistol_uid)
    hud.get_node("Root/InventoryPanel/Use").pressed.emit()
    check(not Game.has_equipped_weapon() and player.get_node("Aim/Gun").texture==null, "Unequip removes the gun from the player's hands")
    hud.close_panels()
    player.shoot()
    player.reload_weapon()
    check(Game.magazine==0 and player.reload_remaining==0 and not player.is_aiming(), "Unarmed player cannot fire, reload or show weapon aiming feedback")
    var light: PointLight2D = player.get_node("Aim/Gun/Flashlight")
    var was_enabled := light.enabled
    Input.action_press("flashlight")
    await frames(2)
    Input.action_release("flashlight")
    check(light.enabled != was_enabled, "Flashlight remains independently usable with the gun unequipped")
    hud.open_inventory()
    hud.select_item(pistol_uid)
    hud.get_node("Root/InventoryPanel/Use").pressed.emit()
    check(Game.equipped_uid==pistol_uid and Game.magazine==6, "Re-equipping the same weapon restores its own loaded rounds")
    var other := InventoryItemDefinition.new()
    other.id = "test_other_weapon"
    other.display_name = "Test weapon"
    other.is_weapon = true
    other.magazine_size = 9
    other.bullet_damage = 40
    other.grid_size = Vector2i(3,1)
    other.weapon_texture = Game.item_icon("pistol")
    Game.register_item(other)
    Game.add_item(other.id)
    var other_uid := Game.inventory.first_uid(other.id)
    Game.inventory.entry(other_uid)["magazine"] = 8
    Game.equip_weapon(other_uid)
    check(Game.magazine==8 and player.magazine_size==9 and player.bullet_damage==40, "Another weapon definition supplies independent ammunition and combat stats")
    Game.equip_weapon(pistol_uid)
    check(Game.magazine==6 and Game.inventory.entry(other_uid)["magazine"]==8, "Switching weapons never transfers loaded rounds between instances")
    check(not Game.equip_weapon(Game.inventory.first_uid("ammo")), "Ammunition cannot be equipped as a weapon")
    if Game.count_item("ammo") > 0:Game.take_item("ammo", Game.count_item("ammo"))
    var stack_limit := Game.stack_limit("ammo")
    Game.add_item("ammo", stack_limit + 2)
    var stacks := Game.inventory.entries.filter(func(entry): return entry["id"]=="ammo")
    var full_target: int = stacks[0]["uid"]
    var small_source: int = stacks[1]["uid"]
    Game.inventory.consume_uid(full_target,4)
    var from := Game.inventory.entry(small_source)
    var into := Game.inventory.entry(full_target)
    await mouse(point(grid,Vector2i(from["x"],from["y"])),true)
    await motion(point(grid,Vector2i(into["x"],into["y"])))
    await mouse(point(grid,Vector2i(into["x"],into["y"])),false)
    check(Game.inventory.entry(full_target)["count"]==stack_limit-2 and Game.inventory.entry(small_source).is_empty(), "Dropping ammunition onto another stack merges within the designer's current stack limit")
    Game.take_item("ammo", Game.count_item("ammo"))
    Game.add_item("ammo", stack_limit + 2)
    stacks = Game.inventory.entries.filter(func(entry): return entry["id"]=="ammo")
    var target_uid: int = stacks[1]["uid"]
    var source_uid: int = stacks[0]["uid"]
    check(Game.merge_items(target_uid,source_uid) and Game.inventory.entry(target_uid)["count"]==stack_limit and Game.inventory.entry(source_uid)["count"]==2, "Stack merging preserves overflow across selected instances")
    var size_before := Vector2i(Game.inventory.columns,Game.inventory.rows)
    check(not Game.expand_inventory(4,2) and Vector2i(Game.inventory.columns,Game.inventory.rows)==size_before, "Inventory upgrades cannot accidentally shrink occupied storage")
    check(Game.expand_inventory(10,5), "Upgrade hook increases usable capacity without moving or deleting items")
    hud.close_panels()
    await frames(3)
    if scene.has_node("AmbientSound"): scene.get_node("AmbientSound").stop()
    await frames(3)
    scene.queue_free()
    get_tree().current_scene = null
    await frames(5)
    print("IGNOTUM GRID: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures==0 else 1)
