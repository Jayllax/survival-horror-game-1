class_name LocationPaths
extends RefCounted
## Compatibility for locations renamed in the designer's October 29 snapshot.
const RENAMED := {
    "res://scenes/levels/town.tscn": "res://scenes/levels/town_01.tscn",
    "res://scenes/levels/alley.tscn": "res://scenes/levels/alleyway_01.tscn",
    "res://scenes/levels/interior.tscn": "res://scenes/levels/house_01.tscn",
    "res://scenes/levels/interior1_2.tscn": "res://scenes/levels/house_01_2.tscn",
    "res://scenes/levels/house_01_02.tscn": "res://scenes/levels/house_01_2.tscn",
}

static func resolve(path: String) -> String:
    return RENAMED.get(path, path) if not ResourceLoader.exists(path) else path

static func resolve_world(world: Dictionary) -> Dictionary:
    var result := world.duplicate(true)
    for key in world:
        if not key is String:
            continue
        for old_path in RENAMED:
            if not key.begins_with(old_path + ":"):
                continue
            var current := resolve(old_path)
            if current == old_path:
                continue
            var new_key: String = current + key.substr(old_path.length())
            if not result.has(new_key):
                result[new_key] = world[key]
            result.erase(key)
    return result
