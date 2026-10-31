class_name AudioCue
extends Resource
## Reusable music/ambience settings. Imported recordings remain unchanged.
@export var stream: AudioStream
@export_range(-60.0, 24.0) var volume_db: float = -16.0
@export_range(0.0, 10.0) var fade_seconds: float = 1.5
@export var loop: bool = true
@export_range(0.0, 600.0) var loop_offset: float = 0.0
## Region themes continue through rooms without their own music. Safe-room overrides do not.
@export var continue_in_connected_rooms: bool = false

func playback_stream() -> AudioStream:
    if stream == null:
        return null
    var result := stream.duplicate() as AudioStream
    if result is AudioStreamMP3 or result is AudioStreamOggVorbis:
        result.loop = loop
        result.loop_offset = clampf(loop_offset,0.0,maxf(0.0,result.get_length()-0.01))
    elif result is AudioStreamWAV:
        result.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
        result.loop_end = maxi(1,roundi(result.get_length()*result.mix_rate))
        result.loop_begin = clampi(roundi(loop_offset*result.mix_rate),0,result.loop_end-1)
    return result
