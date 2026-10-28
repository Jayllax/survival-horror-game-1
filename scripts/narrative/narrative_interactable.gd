extends Area2D
## Reusable Note and NPC scenes share the existing nearby E interaction system.
@export_enum("Note", "NPC") var kind: int = 0
@export var document: NoteDocument
@export var dialogue: DialogueSequence
@export var repeat_dialogue: DialogueSequence
@export var interaction_radius: float = 90.0
@export var prompt_offset: Vector2 = Vector2(0, -54)
@export var action_label: String = ""
@export var persistent_id: String = ""
## Optional exact Game.world flag, set when read / when the conversation finishes.
@export var completion_flag: String = ""
@export var face_player: bool = true

func _ready() -> void:
    add_to_group("interactable")

func state_key() -> String:
    var identity := persistent_id if not persistent_id.is_empty() else Game.object_id(self)
    return ("note:" if kind == 0 else "dialogue:") + identity

func has_completed() -> bool:
    return bool(Game.world.get(state_key(), false))

func current_dialogue() -> DialogueSequence:
    return repeat_dialogue if has_completed() and repeat_dialogue != null else dialogue

func interaction_action() -> String:
    return action_label if not action_label.is_empty() else ("Read" if kind == 0 else "Talk")

func is_available() -> bool:
    if kind == 0:
        return document != null and not document.text.strip_edges().is_empty()
    var sequence := current_dialogue()
    return sequence != null and not sequence.playable_lines().is_empty()

func interact(player: Node) -> void:
    if not is_available() or Game.transitioning or Game.health <= 0 or get_tree().paused:
        return
    var hud := get_tree().get_first_node_in_group("hud")
    if hud == null:
        return
    if kind == 0:
        if hud.show_story_note(document, self):
            mark_completed()
    elif hud.show_dialogue(current_dialogue(), self):
        if face_player and player is Node2D and has_node("Body"):
            var body := get_node("Body") as Sprite2D
            if body:
                body.flip_h = player.global_position.x < global_position.x

func mark_completed() -> void:
    Game.world[state_key()] = true
    if not completion_flag.is_empty():
        Game.world[completion_flag] = true
    Game.changed.emit()
