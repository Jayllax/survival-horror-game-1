extends Node2D
## Sound only. The player's existing enemy-hearing noise rules are unchanged.
@export var default_surface: FootstepSurface
@export var enabled := true
@export var contact_frames := PackedInt32Array([0,3])
@export_range(-40.0,0.0) var crouch_volume_db: float = -14.0
@export_range(0.0,6.0) var sprint_volume_db: float = 2.0
@export_range(0.01,0.5) var minimum_step_seconds: float = 0.12
var next_player := 0
var last_sample: AudioStream
var last_step_msec := -1000
var steps_played := 0
var rng := RandomNumberGenerator.new()
@onready var player: CharacterBody2D = get_parent()
@onready var body: AnimatedSprite2D = player.get_node("Body")
@onready var voices: Array[AudioStreamPlayer] = [$A,$B,$C,$D]

func _ready() -> void:
    rng.randomize()
    body.frame_changed.connect(on_frame_changed)

func current_surface() -> FootstepSurface:
    var result := default_surface
    var priority := -2147483648
    for zone in get_tree().get_nodes_in_group("footstep_surface"):
        if zone.surface != null and zone.surface_priority > priority and zone.get_overlapping_bodies().has(player):
            result = zone.surface
            priority = zone.surface_priority
    return result

func on_frame_changed() -> void:
    if not enabled or get_tree().paused or Game.transitioning or Game.health <= 0 or player.dodge_remaining > 0:
        return
    if not player.is_on_floor() or absf(player.get_real_velocity().x) <= 10:
        return
    if body.animation not in [&"walk",&"sprint",&"crouch_walk",&"aim_walk",&"crouch_aim_walk"] or body.frame not in contact_frames:
        return
    if Time.get_ticks_msec()-last_step_msec < minimum_step_seconds*1000:
        return
    var surface := current_surface()
    if surface == null or surface.samples.is_empty():
        return
    var options := surface.samples.filter(func(sample):return sample != null and (sample != last_sample or surface.samples.size()==1))
    if options.is_empty():
        options = surface.samples.filter(func(sample):return sample != null)
    if options.is_empty():
        return
    var sample: AudioStream = options[rng.randi_range(0,options.size()-1)]
    var voice := voices[next_player]
    next_player = (next_player+1)%voices.size()
    voice.stream = sample
    voice.volume_db = surface.volume_db + (crouch_volume_db if player.is_crouching else (sprint_volume_db if player.is_sprinting else 0.0))
    voice.pitch_scale = rng.randf_range(1.0-surface.pitch_variation,1.0+surface.pitch_variation)
    voice.play()
    last_sample = sample
    last_step_msec = Time.get_ticks_msec()
    steps_played += 1

func _process(_delta: float) -> void:
    if get_tree().paused or Game.transitioning or Game.health <= 0:
        for voice in voices:
            voice.stop()
