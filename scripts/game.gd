extends Node
## Shared run state. Inventory has exactly eight slots; the flashlight is equipment.
signal changed
signal message(text: String)
signal item_collected(id: String)
signal save_written(slot_index: int)
var item_catalog: Dictionary = {}
var recipes: Array[InventoryRecipe] = []
var last_combined_id := ""
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
const SAVE_SLOT_COUNT := 4
const SAVE_VERSION := 2
var pending_restore: Dictionary = {}
var play_seconds := 0.0

func _ready() -> void:
    load_item_catalog()
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
    pending_restore.clear()
    play_seconds = 0.0
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

func load_item_catalog() -> void:
    var catalog: InventoryCatalog = load("res://data/catalog.tres")
    for definition in catalog.items:
        register_item(definition)
    recipes.assign(catalog.recipes)

func use_item(id: String) -> bool:
    var definition: InventoryItemDefinition = item_catalog.get(id)
    if not definition or definition.heal_amount <= 0 or health >= 100 or count_item(id) == 0:
        return false
    take_item(id)
    health = mini(100, health + definition.heal_amount)
    changed.emit()
    return true

func can_combine(id: String) -> bool:
    if stack_limit(id) > 1:
        return true
    for recipe in recipes:
        if recipe.input_a == id or recipe.input_b == id:
            return true
    return false

func combine_items(first: String, second: String) -> bool:
    last_combined_id = ""
    for recipe in recipes:
        if not ((recipe.input_a == first and recipe.input_b == second) or (recipe.input_a == second and recipe.input_b == first)):
            continue
        if count_item(first) < (2 if first == second else 1) or count_item(second) < 1:
            return false
        var before: Array[Dictionary] = slots.duplicate(true)
        take_item(first)
        take_item(second)
        if not add_item(recipe.output_id, recipe.output_quantity):
            slots.assign(before)
            changed.emit()
            return false
        last_combined_id = recipe.output_id
        changed.emit()
        return true
    return false

# Slot indices matter: identical item IDs can occupy separate pockets.
func combine_slots(first: int, second: int) -> bool:
    last_combined_id = ""
    if first < 0 or second < 0 or first >= SLOT_COUNT or second >= SLOT_COUNT or first == second:
        return false
    if slots[first].is_empty() or slots[second].is_empty():
        return false
    var id: String = slots[first]["id"]
    var other_id: String = slots[second]["id"]
    for recipe in recipes:
        if (recipe.input_a == id and recipe.input_b == other_id) or (recipe.input_b == id and recipe.input_a == other_id):
            return combine_items(id, other_id)
    if id != other_id:
        return false
    var amount := mini(int(slots[second]["count"]), stack_limit(id) - int(slots[first]["count"]))
    if amount <= 0:
        return false
    slots[first]["count"] += amount
    slots[second]["count"] -= amount
    if slots[second]["count"] == 0:
        slots[second] = {}
    last_combined_id = id
    changed.emit()
    return true

func register_item(definition: InventoryItemDefinition) -> void:
    if definition and not definition.id.is_empty():
        item_catalog[definition.id] = definition

func item_name(id: String) -> String:
    var definition: InventoryItemDefinition = item_catalog.get(id)
    return definition.display_name if definition else id.capitalize()

func item_description(id: String) -> String:
    var definition: InventoryItemDefinition = item_catalog.get(id)
    return definition.description if definition else "A carried object. Its matching lock or mechanism can be used while it is in your inventory."

func item_category(id: String) -> String:
    var definition: InventoryItemDefinition = item_catalog.get(id)
    return definition.category if definition else "Object"

func item_icon(id: String) -> Texture2D:
    var definition: InventoryItemDefinition = item_catalog.get(id)
    return definition.icon if definition else preload("res://art/pixel/notice.png")

func stack_limit(id: String) -> int:
    var definition: InventoryItemDefinition = item_catalog.get(id)
    return definition.max_stack if definition else 1

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
    while location.get_parent() and not location.has_method("location_title"):
        location = location.get_parent()
    return location.scene_file_path + ":" + str(location.get_path_to(node))

func _process(delta: float) -> void:
    var scene := get_tree().current_scene
    if scene and scene.has_method("location_title") and health > 0 and not transitioning:
        play_seconds += delta

func slot_path(index: int) -> String:
    return "user://save_%d.json" % (index + 1)

func _read_slot(index: int) -> Variant:
    if index < 0 or index >= SAVE_SLOT_COUNT or not FileAccess.file_exists(slot_path(index)):
        return null
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(slot_path(index))) != OK:
        return null
    return parser.data

func _save_error(data: Variant) -> String:
    if not data is Dictionary or data.get("version") != SAVE_VERSION:
        return "Save format is invalid."
    var path: Variant = data.get("scene")
    if not path is String or not path.begins_with("res://") or not path.ends_with(".tscn") or not ResourceLoader.exists(path):
        return "Saved location is unavailable."
    var inventory: Variant = data.get("slots")
    if not inventory is Array or inventory.size() != SLOT_COUNT:
        return "Saved inventory is invalid."
    for pocket in inventory:
        if not pocket is Dictionary:
            return "Saved inventory is invalid."
        if not pocket.is_empty():
            if not pocket.get("id") is String or pocket["id"].is_empty():
                return "Saved item is invalid."
            var count: Variant = pocket.get("count")
            if not (count is float or count is int) or not is_finite(float(count)) or count != int(count) or count < 1 or count > 99:
                return "Saved item quantity is invalid."
    var position: Variant = data.get("position")
    if not position is Array or position.size() != 2:
        return "Saved position is invalid."
    for coordinate in position:
        if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)):
            return "Saved position is invalid."
    for field in ["health", "magazine", "play_seconds", "facing"]:
        var value: Variant = data.get(field)
        if not (value is float or value is int) or not is_finite(float(value)):
            return "Saved player state is invalid."
    if data["health"] < 1 or data["health"] > 100 or data["magazine"] < 0 or data["magazine"] > 99:
        return "Saved player state is invalid."
    if not data.get("world") is Dictionary or not data.get("item_definitions") is Array:
        return "Saved world state is invalid."
    for definition_path in data["item_definitions"]:
        if not definition_path is String or not definition_path.begins_with("res://") or not definition_path.ends_with(".tres") or not ResourceLoader.exists(definition_path):
            return "A saved item definition is unavailable."
        if not load(definition_path) is InventoryItemDefinition:
            return "A saved item definition is invalid."
    return ""

func save_info(index: int) -> Dictionary:
    if index < 0 or index >= SAVE_SLOT_COUNT:
        return {"occupied": false, "valid": false}
    var occupied := FileAccess.file_exists(slot_path(index))
    if not occupied:
        return {"occupied": false, "valid": false}
    var data: Variant = _read_slot(index)
    var error := _save_error(data)
    if not error.is_empty():
        return {"occupied": true, "valid": false, "error": error}
    var info: Dictionary = data.duplicate(true)
    info["occupied"] = true
    info["valid"] = true
    return info

func has_saves() -> bool:
    for index in SAVE_SLOT_COUNT:
        if save_info(index)["valid"]:
            return true
    return false

# Only a placed bicycle in the active location can authorize a save.
func save_slot(index: int, station: Node2D) -> bool:
    var scene := get_tree().current_scene
    var player := get_tree().get_first_node_in_group("player") as Node2D
    if index < 0 or index >= SAVE_SLOT_COUNT or health <= 0 or transitioning:
        return false
    if not is_instance_valid(station) or not station.is_in_group("save_station") or not scene or not scene.is_ancestor_of(station):
        return false
    if not player or player.global_position.distance_to(station.global_position) > station.interaction_radius:
        message.emit("Move closer to the bicycle to save.")
        return false
    var definition_paths: Array[String] = []
    for definition in item_catalog.values():
        if not definition.resource_path.is_empty():
            definition_paths.append(definition.resource_path)
    var position: Vector2 = station.get_node("SaveSpawn").global_position
    var data := {"version": SAVE_VERSION, "scene": scene.scene_file_path,
        "station": str(scene.get_path_to(station)), "station_label": station.station_name,
        "location": location_name, "position": [position.x, position.y], "facing": player.facing,
        "saved_at": Time.get_datetime_string_from_system(false, true),
        "timestamp": Time.get_unix_time_from_system(), "play_seconds": play_seconds,
        "slots": slots, "health": health, "magazine": magazine, "world": world,
        "clue": clue_read, "power": power_restored, "flashlight": flashlight_on,
        "item_definitions": definition_paths}
    var error := _save_error(data)
    if not error.is_empty():
        message.emit(error)
        return false
    var path := slot_path(index)
    var temporary_path := path + ".tmp"
    var file := FileAccess.open(temporary_path, FileAccess.WRITE)
    if file == null:
        message.emit("Could not write the save file. Your previous save is unchanged.")
        return false
    file.store_string(JSON.stringify(data))
    file.flush()
    var write_error := file.get_error()
    file.close()
    if write_error != OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path), ProjectSettings.globalize_path(path)) != OK:
        message.emit("Could not finish saving. Your previous save is unchanged.")
        return false
    save_written.emit(index)
    return true

func load_slot(index: int) -> bool:
    if transitioning:
        return false
    var data: Variant = _read_slot(index)
    var error := _save_error(data)
    if not error.is_empty():
        message.emit(error)
        return false
    var packed := load(data["scene"]) as PackedScene
    if packed == null:
        message.emit("Saved location could not be loaded.")
        return false
    reset_run()
    for definition_path in data["item_definitions"]:
        register_item(load(definition_path))
    for index_in_inventory in SLOT_COUNT:
        slots[index_in_inventory] = data["slots"][index_in_inventory].duplicate(true)
    health = int(data["health"])
    magazine = int(data["magazine"])
    world = data["world"].duplicate(true)
    clue_read = bool(data.get("clue", false))
    power_restored = bool(data.get("power", false))
    flashlight_on = bool(data.get("flashlight", true))
    play_seconds = maxf(0.0, float(data["play_seconds"]))
    pending_restore = {"position": Vector2(data["position"][0], data["position"][1]), "facing": float(data["facing"])}
    get_tree().paused = false
    return get_tree().change_scene_to_packed(packed) == OK

func start_game() -> void:
    get_tree().paused = false
    reset_run()
    get_tree().change_scene_to_file("res://scenes/levels/town.tscn")
