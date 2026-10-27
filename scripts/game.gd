extends Node
## Shared run state. Inventory has exactly eight slots; the flashlight is equipment.
signal changed
signal message(text: String)
signal item_collected(id: String)
signal checkpoint_saved
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
const SAVE_PATH := "user://checkpoint.json"

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
    var definition_paths: Array[String] = []
    for definition in item_catalog.values():
        if not definition.resource_path.is_empty():
            definition_paths.append(definition.resource_path)
    file.store_string(JSON.stringify({"version": 1, "scene": scene.scene_file_path, "spawn": spawn_id,
        "slots": slots, "health": health, "magazine": magazine, "world": world,
        "clue": clue_read, "power": power_restored, "flashlight": flashlight_on, "item_definitions": definition_paths}))
    file.flush()
    file.close()
    if DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".tmp"), ProjectSettings.globalize_path(SAVE_PATH)) != OK:
        message.emit("Checkpoint could not be committed.")
        return
    checkpoint_saved.emit()

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
    for definition_path in data.get("item_definitions", []):
        if definition_path is String and definition_path.begins_with("res://") and definition_path.ends_with(".tres") and ResourceLoader.exists(definition_path):
            var definition: Resource = load(definition_path)
            if definition is InventoryItemDefinition:
                register_item(definition)
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
