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
var world: Dictionary = {}
var location_name := "Street"
var spawn_id := "default"
var transitioning := false
var flashlight_on := true
const SAVE_PATH := "user://checkpoint.json"

func _ready() -> void:
    var settings := ConfigFile.new()
    if settings.load("user://settings.cfg") == OK:
        AudioServer.set_bus_volume_db(0, float(settings.get_value("audio", "master_db", -6.0)))
        AudioServer.set_bus_mute(0, AudioServer.get_bus_volume_db(0) <= -60)
        if bool(settings.get_value("display", "fullscreen", false)) and DisplayServer.get_name() != "headless":
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    reset_run()

func save_settings() -> void:
    var settings := ConfigFile.new()
    settings.set_value("audio", "master_db", AudioServer.get_bus_volume_db(0))
    settings.set_value("display", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
    settings.save("user://settings.cfg")

func reset_run() -> void:
    slots.clear()
    for i in SLOT_COUNT:
        slots.append({})
    health = 100
    magazine = 6
    clue_read = false
    power_restored = false
    world.clear()
    spawn_id = "default"
    flashlight_on = true
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
    return location_name.to_upper()

func object_id(node: Node) -> String:
    var location: Node = node
    while location.get_parent() and not location.has_method("checkpoint_name"):
        location = location.get_parent()
    return location.scene_file_path + ":" + str(location.get_path_to(node))

func has_checkpoint() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func save_run() -> void:
    if health <= 0:
        return
    var scene := get_tree().current_scene
    if scene == null or not scene.has_method("checkpoint_name"):
        return
    var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
    if file == null:
        message.emit("Checkpoint could not be written.")
        return
    file.store_string(JSON.stringify({"version": 1, "scene": scene.scene_file_path, "spawn": spawn_id,
        "slots": slots, "health": health, "magazine": magazine, "world": world,
        "clue": clue_read, "power": power_restored, "flashlight": flashlight_on}))
    file.flush()
    file.close()
    if DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".tmp"), ProjectSettings.globalize_path(SAVE_PATH)) != OK:
        message.emit("Checkpoint could not be committed.")
        return
    message.emit("Checkpoint saved.")

func continue_game() -> void:
    if not has_checkpoint():
        return
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
    if not data is Dictionary or data.get("version") != 1 or not data.get("slots") is Array or data["slots"].size() != 8:
        message.emit("Checkpoint is invalid.")
        return
    var path: String = data.get("scene", "")
    if not path.begins_with("res://scenes/levels/") or not ResourceLoader.exists(path):
        message.emit("Checkpoint location is unavailable.")
        return
    reset_run()
    for i in SLOT_COUNT:
        if data["slots"][i] is Dictionary:
            slots[i] = data["slots"][i]
    health = clampi(int(data.get("health", 100)), 1, 100)
    magazine = clampi(int(data.get("magazine", 6)), 0, 99)
    world = data.get("world", {})
    clue_read = data.get("clue", false)
    power_restored = data.get("power", false)
    flashlight_on = data.get("flashlight", true)
    spawn_id = data.get("spawn", "default")
    get_tree().paused = false
    get_tree().change_scene_to_file(path)

func retry_checkpoint() -> void:
    if has_checkpoint():
        continue_game()
    else:
        start_game()

func start_game() -> void:
    get_tree().paused = false
    reset_run()
    get_tree().change_scene_to_file("res://scenes/levels/town.tscn")
