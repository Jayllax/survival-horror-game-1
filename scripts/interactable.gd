extends Area2D
## All interactables are placed in the editor. Duplicate an existing scene and edit these fields.
@export_enum("Pickup", "Clue", "Switchboard", "Door", "Examine") var kind: int = 0
@export var prompt_text: String = "Take item"
@export var interaction_radius: float = 84.0
@export var item_id: String = "ammo"
@export_range(1, 99) var quantity: int = 6
@export_multiline var description: String = ""
@export var required_key: String = "gate_key"
@export var requires_power: bool = true
@export var escape_door: bool = false
@export var puzzle_solution: Vector3i = Vector3i(3, 1, 2)
@export var door_animation_seconds: float = 0.8
var opened := false

func _ready() -> void:
    add_to_group("interactable")

func is_available() -> bool:
    return not opened

func interact(_player: Node) -> void:
    match kind:
        0:
            if Game.add_item(item_id, quantity):
                Game.message.emit("Collected %s × %d" % [Game.item_name(item_id), quantity])
                opened = true
                queue_free()
        1:
            Game.clue_read = true
            Game.changed.emit()
            get_tree().get_first_node_in_group("hud").show_note(description)
        2:
            if Game.power_restored:
                Game.message.emit("The power is already on. The eastern gate is waiting.")
            else:
                get_tree().get_first_node_in_group("hud").show_puzzle(self)
        3:
            open_door()
        4:
            get_tree().get_first_node_in_group("hud").show_note(description)

func solve_puzzle(code: Vector3i) -> bool:
    if Game.power_restored:
        return true
    if not Game.clue_read:
        Game.message.emit("I need a clue. The station notice might explain these dials.")
        return false
    if Game.count_item("fuse") == 0:
        Game.message.emit("The empty socket needs a ceramic fuse. Look near the crates.")
        return false
    if code != puzzle_solution:
        Game.message.emit("Only a dead click. That sequence is wrong.")
        return false
    # Consume the fuse first: this frees its pocket for the key, even in a full inventory.
    Game.take_item("fuse")
    if not Game.add_item("gate_key"):
        Game.add_item("fuse")
        return false
    Game.power_restored = true
    Game.changed.emit()
    $Indicator.color = Color(0.5, 1, 0.6)
    Game.message.emit("The lamps wake. A brass gate key drops from the switchboard.")
    return true

func open_door() -> void:
    if opened:
        return
    if requires_power and not Game.power_restored:
        Game.message.emit("No power. The switchboard must be restored.")
        return
    if not required_key.is_empty() and not Game.take_item(required_key):
        Game.message.emit("Locked. I need the brass gate key.")
        return
    opened = true
    Game.message.emit("The lock turns. For a moment, the street feels familiar.")
    if has_node("Barrier/CollisionShape2D"):
        $Barrier/CollisionShape2D.set_deferred("disabled", true)
    var tween := create_tween()
    tween.tween_property($Leaf, "position:y", -125.0, door_animation_seconds).set_trans(Tween.TRANS_SINE)
    tween.tween_callback(finish_open)

func finish_open() -> void:
    if escape_door:
        Game.won = true
        Game.changed.emit()
        get_tree().get_first_node_in_group("hud").show_ending()
