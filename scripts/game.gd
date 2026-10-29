extends Node
## Run state is applied atomically. Save files own independent inventory/world snapshots.
signal changed
signal message(text: String)
signal item_collected(id: String)
signal save_written(slot_index: int)
## Gameplay hearing event; independent of audio volume or audio playback.
signal noise_emitted(origin: Vector2, radius: float, source: Node)
var item_catalog: Dictionary = {}
var recipes: Array[InventoryRecipe] = []
var last_combined_id := ""
var last_combined_uid := -1
var inventory: GridInventory
var equipped_uid := -1
var loading_save := false
var health: int = 100
var magazine: int:
    get:
        var item := inventory.entry(equipped_uid) if inventory else {}
        return int(item.get("magazine", 0))
    set(value):
        if inventory:
            var item := inventory.entry(equipped_uid)
            if not item.is_empty():
                var definition: InventoryItemDefinition = item_catalog.get(item["id"])
                item["magazine"] = clampi(value, 0, definition.magazine_size if definition else 0)
var clue_read := false
var power_restored := false
var world: Dictionary = {}
var location_name := "Street"
var spawn_id := "default"
var transitioning := false
var flashlight_on := true
const SAVE_SLOT_COUNT := 4
const SAVE_VERSION := 4
var pending_restore: Dictionary = {}
var play_seconds := 0.0

func emit_noise(origin: Vector2, radius: float, source: Node = null) -> void:
    if radius > 0 and health > 0 and not transitioning and not get_tree().paused:
        noise_emitted.emit(origin,radius,source)

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
    health = 100
    clue_read = false
    power_restored = false
    world = {}
    spawn_id = "default"
    flashlight_on = true
    loading_save = false
    transitioning = false
    var settings: InventorySettings = load("res://data/inventory_settings.tres")
    inventory = GridInventory.new(item_catalog, settings.columns, settings.rows)
    equipped_uid = -1
    inventory.add("ammo", settings.starting_ammo)
    if not settings.starting_weapon.is_empty() and inventory.add(settings.starting_weapon):
        equipped_uid = inventory.first_uid(settings.starting_weapon)
        var definition := active_weapon()
        if definition:
            magazine = definition.magazine_size
    changed.emit()

func load_item_catalog() -> void:
    var catalog: InventoryCatalog = load("res://data/catalog.tres")
    for definition in catalog.items:
        register_item(definition)
    recipes.assign(catalog.recipes)

func use_item(id: String) -> bool:
    return use_uid(inventory.first_uid(id))

func use_uid(uid: int) -> bool:
    var item := inventory.entry(uid)
    var definition: InventoryItemDefinition = item_catalog.get(item.get("id", ""))
    if not definition or definition.heal_amount <= 0 or health >= 100 or item.is_empty():
        return false
    if not finish_item_use(uid, false):
        return false
    health = mini(100, health + definition.heal_amount)
    changed.emit()
    return true

func find_use_uid(required_id: String) -> int:
    return inventory.find_use_uid(required_id)

func finish_item_use(uid: int, notify: bool = true, force_remove: bool = false) -> bool:
    if not inventory.finish_use(uid, force_remove):
        return false
    _repair_equipment()
    if notify:
        changed.emit()
    return true

func can_combine(id: String) -> bool:
    var definition: InventoryItemDefinition = item_catalog.get(id)
    if definition and (definition.upgrade or definition.is_weapon or definition.compact_grid_size != Vector2i.ZERO):
        return true
    if stack_limit(id) > 1:
        return true
    for recipe in recipes:
        if recipe.input_a == id or recipe.input_b == id:
            return true
    return false

func combine_items(first: String, second: String) -> bool:
    var first_uid := inventory.first_uid(first)
    var second_uid := -1
    for item in inventory.entries:
        if item["id"] == second and item["uid"] != first_uid:
            second_uid = int(item["uid"])
            break
    return combine_uids(first_uid, second_uid)

func combine_uids(first_uid: int, second_uid: int) -> bool:
    last_combined_id = ""
    last_combined_uid = -1
    var first := inventory.entry(first_uid)
    var second := inventory.entry(second_uid)
    if first_uid == second_uid or first.is_empty() or second.is_empty():
        return false
    var pair := upgrade_pair(first_uid, second_uid)
    if not pair.is_empty():
        var trial := inventory.copy()
        var tool := trial.entry(pair["tool"])
        if not trial.apply_upgrade(pair["target"], tool["id"]) or not trial.finish_use(pair["tool"]):
            return false
        inventory = trial
        last_combined_uid = int(pair["target"])
        last_combined_id = inventory.entry(last_combined_uid)["id"]
        changed.emit()
        return true
    for recipe in recipes:
        if not ((recipe.input_a == first["id"] and recipe.input_b == second["id"]) or (recipe.input_b == first["id"] and recipe.input_a == second["id"])):
            continue
        var trial := inventory.copy()
        trial.finish_use(first_uid)
        trial.finish_use(second_uid)
        if not trial.add(recipe.output_id, recipe.output_quantity):
            return false
        inventory = trial
        last_combined_id = recipe.output_id
        last_combined_uid = inventory.first_uid(recipe.output_id)
        _repair_equipment()
        changed.emit()
        return true
    return merge_items(first_uid, second_uid)

func upgrade_pair(first_uid: int, second_uid: int) -> Dictionary:
    if first_uid == second_uid:
        return {}
    for pair in [[first_uid, second_uid], [second_uid, first_uid]]:
        var tool := inventory.entry(pair[0])
        if not tool.is_empty() and inventory.can_apply_upgrade(pair[1], tool["id"]):
            return {"tool": pair[0], "target": pair[1]}
    return {}

func merge_items(target_uid: int, source_uid: int) -> bool:
    var target := inventory.entry(target_uid)
    if target.is_empty():
        return false
    var id: String = target["id"]
    if not inventory.merge(target_uid, source_uid):
        return false
    last_combined_id = id
    last_combined_uid = target_uid
    _repair_equipment()
    changed.emit()
    return true

func move_item(uid: int, cell: Vector2i, rotated: bool) -> bool:
    if not inventory.move(uid, cell, rotated):
        return false
    changed.emit()
    return true

func expand_inventory(columns: int, rows: int) -> bool:
    if columns < inventory.columns or rows < inventory.rows or columns > 12 or rows > 8:
        return false
    inventory.columns = columns
    inventory.rows = rows
    changed.emit()
    return true

func active_weapon() -> InventoryItemDefinition:
    var item := inventory.entry(equipped_uid) if inventory else {}
    var definition: InventoryItemDefinition = item_catalog.get(item.get("id", ""))
    return definition if definition and definition.is_weapon else null

func has_equipped_weapon() -> bool:
    return active_weapon() != null

func equip_weapon(uid: int) -> bool:
    var item := inventory.entry(uid)
    var definition: InventoryItemDefinition = item_catalog.get(item.get("id", ""))
    if not definition or not definition.is_weapon:
        return false
    equipped_uid = -1 if equipped_uid == uid else uid
    changed.emit()
    return true

func _repair_equipment() -> void:
    if active_weapon() == null:
        equipped_uid = -1

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
    return inventory.count(id)

func add_item(id: String, amount: int = 1) -> bool:
    if not inventory.add(id, amount):
        message.emit("No room in the inventory. Rearrange items or free some space.")
        return false
    changed.emit()
    return true

func take_item(id: String, amount: int = 1) -> bool:
    if not inventory.remove(id, amount):
        return false
    _repair_equipment()
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
    var data: Variant = parser.data
    if data is Dictionary:
        if data.get("scene") is String:
            data["scene"] = LocationPaths.resolve(data["scene"])
        if data.get("world") is Dictionary:
            data["world"] = LocationPaths.resolve_world(data["world"])
    return data

func _saved_catalog(data: Dictionary) -> Dictionary:
    var catalog := item_catalog.duplicate()
    for definition_path in data.get("item_definitions", []):
        if not definition_path is String or not definition_path.begins_with("res://") or not definition_path.ends_with(".tres") or not ResourceLoader.exists(definition_path):
            return {}
        var definition := load(definition_path) as InventoryItemDefinition
        if not definition:
            return {}
        catalog[definition.id] = definition
    return catalog

func _saved_inventory(data: Dictionary, catalog: Dictionary) -> GridInventory:
    if data.get("version", 0) >= 3:
        return GridInventory.restore(data.get("inventory"), catalog)
    # Read version-2 saves without modifying them. The old handgun was implicit equipment.
    var old_slots: Variant = data.get("slots")
    if not old_slots is Array or old_slots.size() != 8:
        return null
    var result := GridInventory.new(catalog, 8, 4)
    for pocket in old_slots:
        if not pocket is Dictionary:
            return null
        if not pocket.is_empty():
            if not pocket.get("id") is String or not GridInventory.whole(pocket.get("count"), 1, 99) or not result.add(pocket["id"], int(pocket["count"])):
                return null
    if result.first_uid("pistol") < 0 and not result.add("pistol"):
        return null
    var pistol := result.entry(result.first_uid("pistol"))
    if not GridInventory.whole(data.get("magazine", 6), 0, 6):
        return null
    pistol["magazine"] = int(data.get("magazine",6))
    return result

func _save_error(data: Variant) -> String:
    if not data is Dictionary or not GridInventory.whole(data.get("version"), 2, SAVE_VERSION):
        return "Save format is invalid."
    var path: Variant = data.get("scene")
    if not path is String or not path.begins_with("res://") or not path.ends_with(".tscn") or not ResourceLoader.exists(path):
        return "Saved location is unavailable."
    if not data.get("world") is Dictionary or not data.get("item_definitions") is Array:
        return "Saved world state is invalid."
    var catalog := _saved_catalog(data)
    var model := _saved_inventory(data, catalog) if not catalog.is_empty() else null
    if model == null:
        return "Saved inventory or item definitions are invalid."
    if data["version"] >= 3:
        if not GridInventory.whole(data.get("equipped_uid"), -1, 1000000000):
            return "Saved equipment is invalid."
        var equipped := model.entry(int(data["equipped_uid"]))
        var weapon: InventoryItemDefinition = catalog.get(equipped.get("id", ""))
        if data["equipped_uid"] != -1 and (not weapon or not weapon.is_weapon):
            return "Saved weapon is unavailable."
    var position: Variant = data.get("position")
    if not position is Array or position.size() != 2:
        return "Saved position is invalid."
    for coordinate in position:
        if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)):
            return "Saved position is invalid."
    for field in ["health", "play_seconds", "facing"]:
        var value: Variant = data.get(field)
        if not (value is float or value is int) or not is_finite(float(value)):
            return "Saved player state is invalid."
    if not GridInventory.whole(data["health"], 1, 100) or data["play_seconds"] < 0:
        return "Saved player state is invalid."
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
    if data["version"] >= 3:
        info["item_count"] = data["inventory"]["items"].size()
        info["grid_columns"] = int(data["inventory"]["columns"])
        info["grid_rows"] = int(data["inventory"]["rows"])
        info["armed"] = data["equipped_uid"] != -1
    else:
        info["item_count"] = data["slots"].filter(func(item): return not item.is_empty()).size() + 1
        info["grid_columns"] = 8
        info["grid_rows"] = 4
        info["armed"] = true
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
        "inventory": inventory.snapshot(), "equipped_uid": equipped_uid,
        "health": health, "magazine": magazine, "world": world.duplicate(true),
        "clue": clue_read, "power": power_restored, "flashlight": flashlight_on,
        "item_definitions": definition_paths.duplicate()}
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
    var catalog := _saved_catalog(data)
    var restored := _saved_inventory(data, catalog)
    # Reject another load during deferred scene replacement. No partial reset/change signals.
    var result := get_tree().change_scene_to_packed(packed)
    if result != OK:
        message.emit("Saved location could not be opened.")
        return false
    loading_save = true
    transitioning = true
    inventory = restored
    item_catalog = catalog
    inventory.definitions = item_catalog
    equipped_uid = int(data["equipped_uid"]) if data["version"] >= 3 else inventory.first_uid("pistol")
    health = int(data["health"])
    world = data["world"].duplicate(true)
    clue_read = bool(data.get("clue", false))
    power_restored = bool(data.get("power", false))
    flashlight_on = bool(data.get("flashlight", true))
    play_seconds = float(data["play_seconds"])
    spawn_id = "default"
    pending_restore = {"position": Vector2(data["position"][0], data["position"][1]), "facing": float(data["facing"])}
    get_tree().paused = false
    return true

func finish_location_load() -> void:
    if loading_save:
        loading_save = false
        transitioning = false
    changed.emit()

func start_game() -> void:
    get_tree().paused = false
    reset_run()
    get_tree().change_scene_to_file("res://scenes/levels/town_01.tscn")
