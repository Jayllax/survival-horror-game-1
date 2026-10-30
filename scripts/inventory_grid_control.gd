extends Control
## UI only: levels and gameplay objects remain authored scene nodes.
signal item_selected(uid: int)
signal feedback(text: String)
var selected_uid := -1
var held_uid := -1
var held_rotated := false
var grab_offset := Vector2i.ZERO
var keyboard_cell := Vector2i.ZERO
var combining := false
var pointer_cell := Vector2i.ZERO
const UI_FONT = preload("res://art/fonts/styles/ui_text.tres")

func _ready() -> void:
    focus_mode = Control.FOCUS_ALL
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    Game.changed.connect(sync_grid)
    sync_grid()

func is_valid_cell(cell: Vector2i) -> bool:
    return Game.inventory != null and cell.x >= 0 and cell.y >= 0 and cell.x < Game.inventory.columns and cell.y < Game.inventory.rows

func sync_grid() -> void:
    if Game.inventory:
        keyboard_cell.x = clampi(keyboard_cell.x, 0, Game.inventory.columns - 1)
        keyboard_cell.y = clampi(keyboard_cell.y, 0, Game.inventory.rows - 1)
    queue_redraw()

func _has_point(point: Vector2) -> bool:
    # The authored Control leaves room for larger inventories. Only drawn cells
    # participate in GUI hit testing; its unused margins are not extra slots.
    var step := cell_size()
    return step > 0 and Rect2(Vector2.ZERO, Vector2(Game.inventory.columns, Game.inventory.rows) * step).has_point(point)

func cell_size() -> float:
    if Game.inventory == null or Game.inventory.columns <= 0 or Game.inventory.rows <= 0:
        return 0.0
    return floorf(minf(64, minf(size.x / Game.inventory.columns, size.y / Game.inventory.rows)))

func cell_at(point: Vector2) -> Vector2i:
    var step := cell_size()
    return Vector2i(floori(point.x / step), floori(point.y / step)) if step > 0 else Vector2i(-1, -1)

func item_rect(item: Dictionary) -> Rect2:
    return Rect2(Vector2(item["x"], item["y"]) * cell_size() + Vector2(2,2), Vector2(Game.inventory.item_dimensions(item)) * cell_size() - Vector2(4,4))

func _draw() -> void:
    if not Game.inventory:
        return
    var step := cell_size()
    if step <= 0:
        return
    for y in Game.inventory.rows:
        for x in Game.inventory.columns:
            var rect := Rect2(Vector2(x,y) * step + Vector2.ONE, Vector2.ONE * (step - 2))
            draw_rect(rect, Color("211f29"))
            draw_rect(rect, Color("514450"), false, 1)
    for item in Game.inventory.entries:
        if item["uid"] != held_uid:
            draw_item(item, item_rect(item))
    if held_uid >= 0:
        var item := Game.inventory.entry(held_uid).duplicate(true)
        if not item.is_empty():
            var place := pointer_cell - grab_offset
            item["x"] = place.x
            item["y"] = place.y
            item["rotated"] = held_rotated
            var valid := Game.inventory.can_place_entry(item, place, held_rotated)
            var target := Game.inventory.entry(Game.inventory.item_at(pointer_cell))
            var merge: bool = not target.is_empty() and target["uid"] != held_uid and target["id"] == item["id"] and Game.stack_limit(item["id"]) > int(target["count"])
            var upgrade := not target.is_empty() and not Game.upgrade_pair(held_uid, int(target["uid"])).is_empty()
            draw_item(item, item_rect(item), Color(0.55,0.85,0.65,0.9) if valid or merge or upgrade else Color(0.95,0.4,0.4,0.9))
    if has_focus() and is_valid_cell(keyboard_cell):
        draw_rect(Rect2(Vector2(keyboard_cell) * step + Vector2(2,2), Vector2.ONE * (step-4)), Color("ccbb98"), false, 1)

func draw_item(item: Dictionary, rect: Rect2, tint: Color = Color.WHITE) -> void:
    var selected: bool = item["uid"] == selected_uid
    draw_rect(rect, Color("3d3545") if selected else Color("302b36"))
    draw_rect(rect, Color("ccbb98") if selected else Color("8f6c61"), false, 2)
    var texture := Game.item_icon(item["id"])
    if texture:
        var available := rect.size - Vector2(12,16)
        if item["rotated"]:
            available = Vector2(available.y, available.x)
        var fitted := minf(available.x / texture.get_width(), available.y / texture.get_height())
        var factor := floorf(fitted) if fitted >= 1.0 else fitted
        var drawn := texture.get_size() * factor
        draw_set_transform(rect.get_center() - Vector2(0,2), PI / 2 if item["rotated"] else 0.0)
        draw_texture_rect(texture, Rect2(-drawn / 2, drawn), false, tint)
        draw_set_transform(Vector2.ZERO)
    if item["count"] > 1:
        draw_string(UI_FONT, rect.end - Vector2(30,5), str(item["count"]), HORIZONTAL_ALIGNMENT_RIGHT, 26, 14, tint)
    if item["uid"] == Game.equipped_uid:
        draw_string(UI_FONT, rect.position + Vector2(5,14), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b4d1bd"))

func pick(uid: int, cell: Vector2i) -> void:
    if not is_valid_cell(cell):
        return
    var item := Game.inventory.entry(uid)
    if item.is_empty():
        return
    held_uid = uid
    held_rotated = item["rotated"]
    grab_offset = cell - Vector2i(item["x"], item["y"])
    pointer_cell = cell
    queue_redraw()

func drop_at(cell: Vector2i) -> bool:
    if not is_valid_cell(cell):
        cancel_drag()
        feedback.emit("That item does not fit there. Its original position is unchanged.")
        item_selected.emit(selected_uid)
        return false
    var uid := held_uid
    var target := Game.inventory.item_at(cell)
    var item := Game.inventory.entry(uid)
    var other := Game.inventory.entry(target)
    held_uid = -1
    var success := false
    var upgraded := false
    if not item.is_empty():
        if target != uid and not other.is_empty() and not Game.upgrade_pair(uid, target).is_empty():
            success = Game.combine_uids(uid, target)
            upgraded = success
            if success:
                selected_uid = Game.last_combined_uid
        elif target != uid and not other.is_empty() and item["id"] == other["id"]:
            success = Game.merge_items(target, uid)
            if success:
                selected_uid = target
        else:
            success = Game.move_item(uid, cell - grab_offset, held_rotated)
    if not success:
        feedback.emit("That item does not fit there. Its original position is unchanged.")
    if success:
        feedback.emit("Upgrade applied." if upgraded else ("Item placed." if target == uid or other.is_empty() else "Stacks combined."))
    item_selected.emit(selected_uid)
    queue_redraw()
    return success

func cancel_drag() -> bool:
    var was_held := held_uid >= 0
    held_uid = -1
    queue_redraw()
    return was_held

func rotate_item() -> void:
    var uid := held_uid if held_uid >= 0 else selected_uid
    var item := Game.inventory.entry(uid)
    var definition: InventoryItemDefinition = Game.item_catalog.get(item.get("id", ""))
    if item.is_empty() or (definition and not definition.can_rotate):
        return
    if held_uid >= 0:
        var old_size := Game.inventory.item_dimensions(item, held_rotated)
        grab_offset = Vector2i(grab_offset.y, old_size.x - 1 - grab_offset.x)
        held_rotated = not held_rotated
    elif not Game.move_item(uid, Vector2i(item["x"], item["y"]), not item["rotated"]):
        feedback.emit("Not enough room to rotate here. Drag it to a clear area first.")
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var cell := cell_at(event.position)
        if not is_valid_cell(cell):
            return
        grab_focus()
        keyboard_cell = cell
        var uid := Game.inventory.item_at(keyboard_cell)
        selected_uid = uid
        var was_combining := combining
        item_selected.emit(uid)
        if not was_combining and uid >= 0:
            pick(uid, keyboard_cell)
        accept_event()
    if event is InputEventKey and event.pressed and not event.echo:
        sync_grid()
        var direction := Vector2i.ZERO
        match event.keycode:
            KEY_LEFT: direction.x = -1
            KEY_RIGHT: direction.x = 1
            KEY_UP: direction.y = -1
            KEY_DOWN: direction.y = 1
            KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
                if held_uid >= 0:
                    drop_at(keyboard_cell)
                else:
                    var uid := Game.inventory.item_at(keyboard_cell)
                    selected_uid = uid
                    var was_combining := combining
                    item_selected.emit(uid)
                    if not was_combining:
                        pick(uid, keyboard_cell)
                accept_event()
        if direction != Vector2i.ZERO:
            keyboard_cell += direction
            keyboard_cell.x = clampi(keyboard_cell.x, 0, Game.inventory.columns - 1)
            keyboard_cell.y = clampi(keyboard_cell.y, 0, Game.inventory.rows - 1)
            pointer_cell = keyboard_cell
            if held_uid < 0 and not combining:
                selected_uid = Game.inventory.item_at(keyboard_cell)
                item_selected.emit(selected_uid)
            accept_event()
        queue_redraw()

func _input(event: InputEvent) -> void:
    if not is_visible_in_tree() or held_uid < 0:
        return
    if event is InputEventMouseMotion:
        pointer_cell = cell_at(get_global_transform_with_canvas().affine_inverse() * event.position)
        queue_redraw()
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
        drop_at(cell_at(get_global_transform_with_canvas().affine_inverse() * event.position))
        get_viewport().set_input_as_handled()
