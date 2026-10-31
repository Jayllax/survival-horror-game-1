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

@export_group("Conversation Animation")
@export var animate_during_dialogue: bool = true
@export_node_path("AnimatedSprite2D") var dialogue_body_path: NodePath = ^"Body"
@export var idle_animation: StringName = &"idle"
@export var talking_animation: StringName = &"talking"
## Which text identities belong to this NPC. Empty animates on every speaker's line.
## Add aliases too, e.g. both Unknown Man and Jax Dole for the same character.
@export var dialogue_speakers: Array[DialogueSpeaker] = []
var _dialogue_body: AnimatedSprite2D
var _body_state: Dictionary = {}

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
            var body := get_node("Body")
            if body is AnimatedSprite2D:
                (body as AnimatedSprite2D).flip_h = player.global_position.x < global_position.x
            elif body is Sprite2D:
                (body as Sprite2D).flip_h = player.global_position.x < global_position.x

func mark_completed() -> void:
    Game.world[state_key()] = true
    if not completion_flag.is_empty():
        Game.world[completion_flag] = true
    Game.changed.emit()

func begin_dialogue_animation() -> void:
    end_dialogue_animation()
    if not animate_during_dialogue:
        return
    _dialogue_body = get_node_or_null(dialogue_body_path) as AnimatedSprite2D
    if _dialogue_body == null or _dialogue_body.sprite_frames == null:
        return
    _body_state = {"process_mode": _dialogue_body.process_mode,
        "animation": _dialogue_body.animation, "frame": _dialogue_body.frame,
        "progress": _dialogue_body.frame_progress, "playing": _dialogue_body.is_playing()}
    # Only this visual continues during dialogue. Physics, AI and input stay paused.
    _dialogue_body.process_mode = Node.PROCESS_MODE_ALWAYS

func update_dialogue_animation(line: DialogueLine, speaking: bool) -> void:
    if not is_instance_valid(_dialogue_body) or _body_state.is_empty():
        return
    var belongs_to_npc := dialogue_speakers.is_empty() or line.speaker in dialogue_speakers
    var clip := talking_animation if speaking and belongs_to_npc else idle_animation
    if not _dialogue_body.sprite_frames.has_animation(clip) or _dialogue_body.sprite_frames.get_frame_count(clip) == 0:
        clip = idle_animation
    if _dialogue_body.sprite_frames.has_animation(clip) and _dialogue_body.sprite_frames.get_frame_count(clip) > 0:
        if _dialogue_body.animation != clip or not _dialogue_body.is_playing():
            _dialogue_body.play(clip)

func end_dialogue_animation() -> void:
    if is_instance_valid(_dialogue_body) and not _body_state.is_empty():
        _dialogue_body.process_mode = _body_state["process_mode"]
        var clip: StringName = _body_state["animation"]
        if _dialogue_body.sprite_frames != null and _dialogue_body.sprite_frames.has_animation(clip) and _dialogue_body.sprite_frames.get_frame_count(clip) > 0:
            _dialogue_body.play(clip)
            var frame := clampi(int(_body_state["frame"]), 0, _dialogue_body.sprite_frames.get_frame_count(clip) - 1)
            _dialogue_body.set_frame_and_progress(frame, float(_body_state["progress"]))
            if not bool(_body_state["playing"]):
                _dialogue_body.pause()
    _body_state.clear()
    _dialogue_body = null

func _exit_tree() -> void:
    end_dialogue_animation()
