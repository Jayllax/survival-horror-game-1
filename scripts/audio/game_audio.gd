extends Node
## Persistent soundtrack: regional music, local overrides, ambience and sight-based danger.
@export var default_region_music: AudioCue
@export var combat_music: AudioCue
@export_range(0.0,3.0) var combat_fade_in: float = 0.35
@export_range(0.0,5.0) var combat_fade_out: float = 1.2
@export_range(0.0,3.0) var lost_sight_grace: float = 0.6
@export_range(-60.0,0.0) var combat_duck_db: float = -30.0
var region_music: AudioCue
var location_ref: WeakRef
var allow_combat := true
var combat_active := false
var sight_remaining := 0.0
@onready var music: Node = $Music
@onready var combat: Node = $Combat
@onready var ambience: Node = $Ambience

func _enter_tree() -> void:
    if has_node("Music"):
        return
    # Instantiate the authored channels at runtime so the editor can finish
    # importing brand-new audio before an autoload scene tries to load it.
    var template: Node = load("res://scenes/audio/game_audio.tscn").instantiate()
    process_mode = Node.PROCESS_MODE_ALWAYS
    for property in template.get_property_list():
        if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and property["usage"] & PROPERTY_USAGE_EDITOR:
            set(property["name"],template.get(property["name"]))
    for child in template.get_children():
        clear_template_ownership(child)
        template.remove_child(child)
        add_child(child)
    template.free()

func clear_template_ownership(node: Node) -> void:
    node.owner = null
    for child in node.get_children():
        clear_template_ownership(child)

func use_location(location: Node, cue: AudioCue, inherit_region: bool, atmosphere: AudioCue, enable_combat: bool) -> void:
    location_ref = weakref(location)
    allow_combat = enable_combat
    sight_remaining = 0.0
    if cue and cue.continue_in_connected_rooms:
        region_music = cue
    var selected := cue
    if selected == null and inherit_region:
        selected = region_music if region_music else default_region_music
    music.play_cue(selected)
    ambience.play_cue(atmosphere)
    if not enable_combat:
        set_combat(false)

func set_combat(enabled: bool) -> void:
    if combat_active == enabled:
        return
    combat_active = enabled
    combat.play_cue(combat_music if enabled else null,combat_fade_in if enabled else combat_fade_out)

func _physics_process(delta: float) -> void:
    var scene := get_tree().current_scene
    if scene != null and not scene.has_method("location_title"):
        if location_ref != null:
            clear_location()
    elif scene != null and location_ref != null:
        if Game.health <= 0:
            sight_remaining = 0
            set_combat(false)
        elif not get_tree().paused and not Game.transitioning:
            var visible_threat := false
            var player := get_tree().get_first_node_in_group("player") as Node2D
            if allow_combat and player != null:
                for enemy in get_tree().get_nodes_in_group("enemy"):
                    if enemy is CanvasItem and not enemy.is_visible_in_tree():
                        continue
                    if scene.is_ancestor_of(enemy) and enemy.has_method("is_music_threat") and enemy.is_music_threat(player):
                        visible_threat = true
                        break
            sight_remaining = lost_sight_grace if visible_threat else maxf(0,sight_remaining-delta)
            set_combat(allow_combat and (visible_threat or sight_remaining > 0))
    var alive := Game.health > 0
    var music_target := (db_to_linear(combat_duck_db) if combat_active else 1.0) if alive else 0.0
    music.mix_gain = move_toward(float(music.mix_gain),music_target,delta/maxf(combat_fade_in if combat_active else combat_fade_out,0.01))
    ambience.mix_gain = move_toward(float(ambience.mix_gain),1.0 if alive else 0.0,delta)

func clear_location() -> void:
    location_ref = null
    region_music = null
    sight_remaining = 0
    set_combat(false)
    music.play_cue(null)
    ambience.play_cue(null)

func stop_all() -> void:
    combat_active = false
    sight_remaining = 0.0
    location_ref = null
    region_music = null
    for layer in [music,combat,ambience]:
        if is_instance_valid(layer):
            layer.stop_immediately()
            layer.mix_gain = 1.0

func _exit_tree() -> void:
    stop_all()
