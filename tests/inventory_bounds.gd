extends Node
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
    checks += 1
    if ok: print("PASS: " + text)
    else:
        failures += 1
        push_error("FAIL: " + text)
func frames(count: int = 2) -> void:
    for i in count:
        await get_tree().process_frame
func mouse(grid: Control, local_point: Vector2, pressed: bool) -> void:
    var event := InputEventMouseButton.new()
    event.position = grid.get_global_transform_with_canvas() * local_point
    event.global_position = event.position
    event.button_index = MOUSE_BUTTON_LEFT
    event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
    event.pressed = pressed
    # Viewport-local input avoids assumptions about the tester's physical window size.
    get_viewport().push_input(event,true)
    await frames()
func click(grid: Control, local_point: Vector2) -> void:
    await mouse(grid,local_point,true)
    await mouse(grid,local_point,false)
func key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = true
    get_viewport().push_input(event,true)
    await frames()
    event = event.duplicate()
    event.pressed = false
    get_viewport().push_input(event,true)
    await frames()
func action(name: String) -> void:
    var event := InputEventAction.new()
    event.action = name
    event.pressed = true
    get_viewport().push_input(event,true)
    await frames()
    event = event.duplicate()
    event.pressed = false
    get_viewport().push_input(event,true)
    await frames()
func point(grid: Control, cell: Vector2i) -> Vector2:
    return (Vector2(cell)+Vector2(0.5,0.5))*grid.cell_size()
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    run.call_deferred()
func run() -> void:
    Game.reset_run()
    Game.inventory = GridInventory.new(Game.item_catalog,6,3)
    Game.inventory.add("pistol")
    Game.inventory.add("ammo",Game.stack_limit("ammo")+2)
    var hud: CanvasLayer = load("res://scenes/ui/hud.tscn").instantiate()
    get_tree().root.add_child(hud)
    hud.open_inventory()
    await frames()
    var grid: Control = hud.get_node("Root/InventoryPanel/Grid")
    check(grid.cell_size()==64 and grid.size.x>384 and grid.size.y>192, "The six-by-three grid retains its authored larger layout rectangle")
    check(grid._has_point(Vector2(0,0)) and grid._has_point(Vector2(383.99,191.99)), "All displayed cells, including the last cell, accept input")
    check(not grid._has_point(Vector2(384,0)) and not grid._has_point(Vector2(0,192)) and not grid._has_point(Vector2(-0.01,0)), "Right, bottom and negative boundaries reject nonexistent cells")
    var pistol := Game.inventory.first_uid("pistol")
    await click(grid,point(grid,Vector2i(0,0)))
    check(grid.selected_uid==pistol and grid.keyboard_cell==Vector2i.ZERO, "Native GUI mouse input still selects an actual inventory item")
    var before := Game.inventory.snapshot()
    var selected: int = grid.selected_uid
    await click(grid,Vector2(480,32))
    check(grid.keyboard_cell==Vector2i.ZERO and grid.selected_uid==selected and Game.inventory.snapshot()==before, "Clicking the blank right margin cannot select a phantom cell or change an item")
    await click(grid,Vector2(32,240))
    check(grid.keyboard_cell==Vector2i.ZERO and grid.selected_uid==selected, "Clicking the blank bottom margin leaves the existing selection intact")
    var synthetic := InputEventMouseButton.new()
    synthetic.button_index = MOUSE_BUTTON_LEFT
    synthetic.pressed = true
    synthetic.position = Vector2(480,240)
    grid._gui_input(synthetic)
    check(grid.keyboard_cell==Vector2i.ZERO and grid.selected_uid==selected, "The GUI input handler also rejects an explicitly delivered out-of-grid press")
    await click(grid,point(grid,Vector2i(5,2)))
    check(grid.keyboard_cell==Vector2i(5,2) and grid.selected_uid<0, "The last real empty cell can still be selected")
    await key(KEY_RIGHT)
    await key(KEY_DOWN)
    check(grid.keyboard_cell==Vector2i(5,2), "Arrow-key selection stays within the current grid")
    await mouse(grid,point(grid,Vector2i(0,0)),true)
    check(grid.held_uid==pistol, "Dragging an actual two-cell item still starts normally")
    await mouse(grid,Vector2(480,32),false)
    check(grid.held_uid<0 and Game.inventory.snapshot()==before, "Releasing in the unused right margin cancels the drag without losing or moving the item")
    await mouse(grid,point(grid,Vector2i(0,0)),true)
    await mouse(grid,Vector2(32,240),false)
    check(grid.held_uid<0 and Game.inventory.snapshot()==before, "Releasing in the unused bottom margin also preserves the item")
    await mouse(grid,point(grid,Vector2i(0,0)),true)
    await mouse(grid,Vector2(600,32),false)
    check(grid.held_uid<0 and Game.inventory.snapshot()==before, "Releasing outside the whole Control cancels safely")
    await mouse(grid,point(grid,Vector2i(0,0)),true)
    await mouse(grid,point(grid,Vector2i(4,1)),false)
    check(Game.inventory.entry(pistol)["x"]==4 and Game.inventory.entry(pistol)["y"]==1, "Dragging to a valid destination still moves the item")
    await mouse(grid,point(grid,Vector2i(4,1)),true)
    await action("inventory_rotate")
    await mouse(grid,point(grid,Vector2i(4,2)),false)
    check(Game.inventory.entry(pistol)["rotated"] and Game.inventory.entry(pistol)["x"]==4 and Game.inventory.entry(pistol)["y"]==1, "Rotation and valid placement still work at the grid's lower edge")
    var stacks := Game.inventory.entries.filter(func(item):return item["id"]=="ammo")
    var target: Dictionary = stacks[0]
    var source: Dictionary = stacks[1]
    var target_uid: int = target["uid"]
    var source_uid: int = source["uid"]
    Game.inventory.consume_uid(target_uid,4)
    var total := Game.count_item("ammo")
    await mouse(grid,point(grid,Vector2i(source["x"],source["y"])),true)
    await mouse(grid,point(grid,Vector2i(target["x"],target["y"])),false)
    check(Game.inventory.entry(source_uid).is_empty() and Game.inventory.entry(target_uid)["count"]==total, "Dragging ammunition onto a compatible stack still combines it")
    grid.keyboard_cell = Vector2i(5,2)
    Game.inventory = GridInventory.new(Game.item_catalog,4,2)
    Game.changed.emit()
    await frames()
    check(grid.keyboard_cell==Vector2i(3,1), "Changing inventory dimensions brings keyboard focus back inside the real grid")
    check(not grid._has_point(Vector2(256,0)) and grid._has_point(Vector2(255,127)), "Click bounds automatically follow a smaller inventory")
    Game.inventory = GridInventory.new(Game.item_catalog,8,4)
    Game.changed.emit()
    check(grid._has_point(Vector2(511,255)) and not grid._has_point(Vector2(512,0)), "The same component also supports larger inventory dimensions")
    Game.inventory = GridInventory.new(Game.item_catalog,6,3)
    Game.changed.emit()
    grid.size = Vector2(320,120)
    check(grid.cell_size()==40 and grid._has_point(Vector2(239,119)) and not grid._has_point(Vector2(240,0)), "Resized UI controls use the displayed cell size for hit testing")
    grid.size = Vector2.ZERO
    check(not grid._has_point(Vector2.ZERO) and grid.cell_at(Vector2.ONE)==Vector2i(-1,-1), "A temporarily collapsed layout cannot divide by zero or accept a click")
    hud.close_panels()
    hud.queue_free()
    await frames()
    print("IGNOTUM INVENTORY BOUNDS: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures==0 else 1)
