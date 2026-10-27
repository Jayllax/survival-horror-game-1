extends Node
## Shared run state. Inventory has exactly eight slots; the flashlight is equipment.
signal changed
signal message(text: String)
const SLOT_COUNT := 8
var slots: Array[Dictionary] = []
var health: int = 100
var magazine: int = 6
var clue_read := false
var power_restored := false
var won := false

func _ready() -> void:
    reset_run()

func reset_run() -> void:
    slots.clear()
    for i in SLOT_COUNT:
        slots.append({})
    health = 100
    magazine = 6
    clue_read = false
    power_restored = false
    won = false
    add_item("ammo", 12)
    changed.emit()

func item_name(id: String) -> String:
    return {"ammo": "9 mm rounds", "gate_key": "Brass gate key", "fuse": "Ceramic fuse"}.get(id, id.capitalize())

func stack_limit(id: String) -> int:
    return 24 if id == "ammo" else 1

func count_item(id: String) -> int:
    var total := 0
    for slot in slots:
        if slot.get("id", "") == id:
            total += int(slot["count"])
    return total

func add_item(id: String, amount: int = 1) -> bool:
    if amount <= 0:
        return false
    var capacity := 0
    for slot in slots:
        if slot.is_empty():
            capacity += stack_limit(id)
        elif slot.get("id") == id:
            capacity += stack_limit(id) - int(slot["count"])
    if capacity < amount:
        message.emit("All eight pockets are full. Free space by using ammunition or puzzle items.")
        return false
    var remaining := amount
    for slot in slots:
        if slot.get("id", "") == id:
            var added: int = mini(remaining, stack_limit(id) - int(slot["count"]))
            slot["count"] += added
            remaining -= added
    for i in SLOT_COUNT:
        if remaining > 0 and slots[i].is_empty():
            var added: int = mini(remaining, stack_limit(id))
            slots[i] = {"id": id, "count": added}
            remaining -= added
    changed.emit()
    return true

func take_item(id: String, amount: int = 1) -> bool:
    if amount <= 0 or count_item(id) < amount:
        return false
    var remaining := amount
    for i in SLOT_COUNT:
        if slots[i].get("id", "") == id:
            var taken: int = mini(remaining, int(slots[i]["count"]))
            slots[i]["count"] -= taken
            remaining -= taken
            if slots[i]["count"] == 0:
                slots[i] = {}
            if remaining == 0:
                break
    changed.emit()
    return true

func objective() -> String:
    if won:
        return "You left the square. The town remembers."
    if power_restored:
        return "Use the brass key at the eastern gate."
    if clue_read:
        return "Find a fuse. Restore power at the switchboard."
    return "Find out why the station bells stopped."

func start_game() -> void:
    get_tree().paused = false
    reset_run()
    get_tree().change_scene_to_file("res://scenes/levels/town.tscn")
