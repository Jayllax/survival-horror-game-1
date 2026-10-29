class_name GridInventory
extends RefCounted
## Item instances own coordinates, orientation, quantity and weapon ammunition.
## Definitions are shared read-only; instance state is always deep-copied.
var columns := 8
var rows := 4
var entries: Array[Dictionary] = []
var next_uid := 1
var definitions: Dictionary = {}

func _init(catalog: Dictionary = {}, width: int = 8, height: int = 4) -> void:
    definitions = catalog
    columns = width
    rows = height

func copy() -> GridInventory:
    var result := GridInventory.new(definitions, columns, rows)
    result.entries.assign(entries.duplicate(true))
    result.next_uid = next_uid
    return result

func entry(uid: int) -> Dictionary:
    for item in entries:
        if item["uid"] == uid:
            return item
    return {}

func first_uid(id: String) -> int:
    for item in entries:
        if item["id"] == id:
            return int(item["uid"])
    return -1

func dimensions(id: String, rotated: bool = false, upgrades: Array = []) -> Vector2i:
    var definition: InventoryItemDefinition = definitions.get(id)
    var size := definition.grid_size if definition else Vector2i.ONE
    for upgrade_id in upgrades:
        var kit: InventoryItemDefinition = definitions.get(upgrade_id)
        if kit and kit.upgrade and kit.upgrade.effect == InventoryUpgrade.Effect.COMPACT and kit.upgrade.accepts(definition):
            size = definition.compact_grid_size
    return Vector2i(size.y, size.x) if rotated else size

func item_dimensions(item: Dictionary, rotated: Variant = null) -> Vector2i:
    return dimensions(item["id"], item["rotated"] if rotated == null else bool(rotated), item.get("upgrades", []))

func bounds(item: Dictionary) -> Rect2i:
    return Rect2i(Vector2i(item["x"], item["y"]), item_dimensions(item))

func item_at(cell: Vector2i) -> int:
    for item in entries:
        if bounds(item).has_point(cell):
            return int(item["uid"])
    return -1

func can_place(id: String, cell: Vector2i, rotated: bool = false, ignore_uid: int = -1, upgrades: Array = []) -> bool:
    var definition: InventoryItemDefinition = definitions.get(id)
    if rotated and definition and not definition.can_rotate:
        return false
    var rect := Rect2i(cell, dimensions(id, rotated, upgrades))
    if rect.size.x < 1 or rect.size.y < 1 or not Rect2i(0, 0, columns, rows).encloses(rect):
        return false
    for item in entries:
        if item["uid"] != ignore_uid and bounds(item).intersects(rect):
            return false
    return true

func can_place_entry(item: Dictionary, cell: Vector2i, rotated: bool) -> bool:
    return can_place(item["id"], cell, rotated, item["uid"], item.get("upgrades", []))

func find_space(id: String) -> Dictionary:
    var definition: InventoryItemDefinition = definitions.get(id)
    for rotated in [false, true]:
        if rotated and (not definition or not definition.can_rotate or definition.grid_size.x == definition.grid_size.y):
            continue
        for y in rows:
            for x in columns:
                if can_place(id, Vector2i(x,y), rotated):
                    return {"x": x, "y": y, "rotated": rotated}
    return {}

func count(id: String) -> int:
    var result := 0
    for item in entries:
        if item["id"] == id:
            result += int(item["count"])
    return result

func limit(id: String) -> int:
    var definition: InventoryItemDefinition = definitions.get(id)
    return definition.max_stack if definition else 1

func add(id: String, amount: int = 1) -> bool:
    if amount <= 0 or id.is_empty():
        return false
    var before := entries.duplicate(true)
    var old_uid := next_uid
    var remaining := amount
    for item in entries:
        if item["id"] == id and item.get("upgrades", []).is_empty():
            var added := mini(remaining, limit(id) - int(item["count"]))
            item["count"] += added
            remaining -= added
    while remaining > 0:
        var place := find_space(id)
        if place.is_empty():
            entries.assign(before)
            next_uid = old_uid
            return false
        var added := mini(remaining, limit(id))
        var item := {"uid": next_uid, "id": id, "count": added,
            "x": place["x"], "y": place["y"], "rotated": place["rotated"], "magazine": 0, "upgrades": []}
        entries.append(item)
        next_uid += 1
        remaining -= added
    return true

func consume_uid(uid: int, amount: int = 1) -> bool:
    var item := entry(uid)
    if amount <= 0 or item.is_empty() or int(item["count"]) < amount:
        return false
    item["count"] -= amount
    if item["count"] == 0:
        entries.erase(item)
    return true

func remove(id: String, amount: int = 1) -> bool:
    if amount <= 0 or count(id) < amount:
        return false
    var remaining := amount
    for item in entries.duplicate():
        if item["id"] == id:
            var taken := mini(remaining, int(item["count"]))
            consume_uid(int(item["uid"]), taken)
            remaining -= taken
            if remaining == 0:
                break
    return true

func move(uid: int, cell: Vector2i, rotated: bool) -> bool:
    var item := entry(uid)
    if item.is_empty() or not can_place_entry(item, cell, rotated):
        return false
    item["x"] = cell.x
    item["y"] = cell.y
    item["rotated"] = rotated
    return true

func merge(target_uid: int, source_uid: int) -> bool:
    var target := entry(target_uid)
    var source := entry(source_uid)
    if target_uid == source_uid or target.is_empty() or source.is_empty() or target["id"] != source["id"] or target.get("upgrades", []) != source.get("upgrades", []):
        return false
    var amount := mini(int(source["count"]), limit(target["id"]) - int(target["count"]))
    if amount <= 0:
        return false
    target["count"] += amount
    return consume_uid(source_uid, amount)

func can_apply_upgrade(uid: int, upgrade_id: String) -> bool:
    var target := entry(uid)
    var kit: InventoryItemDefinition = definitions.get(upgrade_id)
    var definition: InventoryItemDefinition = definitions.get(target.get("id", ""))
    if target.is_empty() or int(target["count"]) != 1 or not kit or not kit.upgrade or not kit.upgrade.accepts(definition):
        return false
    for installed_id in target.get("upgrades", []):
        var installed: InventoryItemDefinition = definitions.get(installed_id)
        if not installed or not installed.upgrade or installed.upgrade.effect == kit.upgrade.effect:
            return false
    return true

func apply_upgrade(uid: int, upgrade_id: String) -> bool:
    if not can_apply_upgrade(uid, upgrade_id):
        return false
    var target := entry(uid)
    var installed: Array = target.get("upgrades", []).duplicate()
    installed.append(upgrade_id)
    target["upgrades"] = installed
    return true

func weapon_damage(uid: int) -> int:
    var item := entry(uid)
    var definition: InventoryItemDefinition = definitions.get(item.get("id", ""))
    if not definition or not definition.is_weapon:
        return 0
    var damage := float(definition.bullet_damage)
    for upgrade_id in item.get("upgrades", []):
        var kit: InventoryItemDefinition = definitions.get(upgrade_id)
        if kit and kit.upgrade and kit.upgrade.effect == InventoryUpgrade.Effect.DAMAGE:
            damage *= kit.upgrade.damage_multiplier
    return maxi(1, roundi(damage))

func snapshot() -> Dictionary:
    return {"columns": columns, "rows": rows, "next_uid": next_uid, "items": entries.duplicate(true)}

static func whole(value: Variant, minimum: int, maximum: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and value == int(value) and value >= minimum and value <= maximum

static func restore(data: Variant, catalog: Dictionary) -> GridInventory:
    if not data is Dictionary or not whole(data.get("columns"), 4, 12) or not whole(data.get("rows"), 2, 8) or not data.get("items") is Array:
        return null
    var result := GridInventory.new(catalog, int(data["columns"]), int(data["rows"]))
    var highest_uid := 0
    for raw in data["items"]:
        if not raw is Dictionary or not raw.get("id") is String or raw["id"].is_empty() or not whole(raw.get("uid"), 1, 1000000000):
            return null
        if not whole(raw.get("count"), 1, result.limit(raw["id"])) or not whole(raw.get("x"), 0, 11) or not whole(raw.get("y"), 0, 7) or not raw.get("rotated") is bool:
            return null
        var uid := int(raw["uid"])
        var upgrades: Variant = raw.get("upgrades", [])
        if not upgrades is Array:
            return null
        var candidate := {"uid": uid, "id": raw["id"], "count": int(raw["count"]), "upgrades": []}
        # Validate metadata before using its smaller footprint to check placement.
        result.entries.append(candidate)
        for upgrade_id in upgrades:
            if not upgrade_id is String or not result.apply_upgrade(uid, upgrade_id):
                return null
        result.entries.erase(candidate)
        if not result.entry(uid).is_empty() or not result.can_place(raw["id"], Vector2i(raw["x"],raw["y"]), raw["rotated"], -1, upgrades):
            return null
        var definition: InventoryItemDefinition = catalog.get(raw["id"])
        var maximum := definition.magazine_size if definition and definition.is_weapon else 0
        if not whole(raw.get("magazine",0), 0, maximum):
            return null
        var item: Dictionary = raw.duplicate(true)
        for field in ["uid", "count", "x", "y", "magazine"]:
            item[field] = int(raw.get(field, 0))
        result.entries.append(item)
        highest_uid = maxi(highest_uid, uid)
    if not whole(data.get("next_uid"), highest_uid + 1, 1000000001):
        return null
    result.next_uid = int(data["next_uid"])
    return result
