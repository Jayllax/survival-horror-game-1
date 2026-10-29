@tool
class_name LootContainer
extends Area2D
## Invisible searchable-container component. All furniture stays in the level.
signal searched

@export_group("Contents")
## Leave this array empty for a deliberately empty drawer/cabinet.
@export var contents: Array[LootEntry] = []:
    set(value):
        contents = value
        if is_inside_tree() and Engine.is_editor_hint():
            update_configuration_warnings()
@export var empty_message: String = "Empty"

@export_group("Interaction")
@export var action_label: String = "Search"
@export_range(16.0, 240.0) var interaction_radius: float = 70.0
@export var prompt_offset: Vector2 = Vector2(0, -50)
## Unique per container. Keep it unchanged when moving/renaming the furniture.
@export var persistent_id: String = ""
## Optional exact Game.world flag set after a successful search.
@export var completion_flag: String = ""

@export_group("Opening (optional)")
@export_node_path("CanvasItem") var closed_visual_path: NodePath
@export_node_path("CanvasItem") var searched_visual_path: NodePath
@export_node_path("AnimationPlayer") var animation_player_path: NodePath
@export var search_animation: StringName = &"open"

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    add_to_group("interactable")
    for entry in contents:
        if entry != null and entry.item != null:
            Game.register_item(entry.item)
    if has_searched():
        apply_searched_state(true)

func state_key() -> String:
    return "loot_container:" + (persistent_id if not persistent_id.is_empty() else Game.object_id(self))

func has_searched() -> bool:
    return bool(Game.world.get(state_key(), false))

func interaction_action() -> String:
    return action_label

func is_available() -> bool:
    return not has_searched()

func interact(_player: Node) -> void:
    search()

func search() -> bool:
    if not is_available() or get_tree().paused or Game.transitioning or Game.health <= 0:
        return false
    if not contents_valid():
        Game.message.emit("This container has not been configured.")
        return false
    if not contents.is_empty():
        # Trial the complete contents. Failure cannot take part of the loot.
        for entry in contents:
            Game.register_item(entry.item)
        var trial := Game.inventory.copy()
        for entry in contents:
            if not trial.add(entry.item.id, entry.quantity):
                Game.message.emit("No room in the inventory. Rearrange items or free some space.")
                return false
        Game.inventory = trial
    Game.world[state_key()] = true
    if not completion_flag.is_empty():
        Game.world[completion_flag] = true
    apply_searched_state(false)
    Game.changed.emit()
    var hud := get_tree().get_first_node_in_group("hud")
    if hud:
        hud.set_interaction(null)
    if contents.is_empty():
        Game.message.emit(empty_message)
    else:
        for entry in contents:
            Game.item_collected.emit(entry.item.id)
    searched.emit()
    return true

func contents_valid() -> bool:
    for entry in contents:
        if entry == null or entry.item == null or entry.item.id.strip_edges().is_empty() or entry.quantity < 1:
            return false
    return true

func _get_configuration_warnings() -> PackedStringArray:
    if not contents_valid():
        return PackedStringArray(["Every Contents entry needs an item with an ID and a positive quantity. For an intentionally empty container, set the array size to zero."])
    return PackedStringArray()

func apply_searched_state(restoring: bool) -> void:
    if not closed_visual_path.is_empty():
        var artwork := get_node_or_null(closed_visual_path) as CanvasItem
        if artwork:
            artwork.hide()
    if not searched_visual_path.is_empty():
        var artwork := get_node_or_null(searched_visual_path) as CanvasItem
        if artwork:
            artwork.show()
    if not animation_player_path.is_empty():
        var animator := get_node_or_null(animation_player_path) as AnimationPlayer
        if animator and animator.has_animation(search_animation):
            animator.play(search_animation)
            if restoring:
                animator.seek(animator.get_animation(search_animation).length, true)
                animator.pause()
