class_name CharacterVisuals
extends AnimatedSprite2D
## Replace named animations through Godot's SpriteFrames editor; no gameplay edits needed.
var state_name: StringName = &""

func has_state(state: StringName) -> bool:
    return sprite_frames != null and sprite_frames.has_animation(state) and sprite_frames.get_frame_count(state) > 0

func state_length(state: StringName) -> float:
    if not has_state(state):
        return 0.0
    var duration := 0.0
    for index in sprite_frames.get_frame_count(state):
        duration += sprite_frames.get_frame_duration(state,index)
    return duration / maxf(sprite_frames.get_animation_speed(state),0.01)

func play_state(state: StringName, seconds: float = 0.0, restart: bool = false) -> void:
    var clip := state if has_state(state) else &"idle"
    if not has_state(clip):
        return
    speed_scale = state_length(clip) / seconds if seconds > 0 else 1.0
    if state_name != state or animation != clip or restart:
        state_name = state
        stop()
        play(clip)
    elif sprite_frames.get_animation_loop(clip) and not is_playing():
        play(clip)
