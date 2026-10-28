class_name CharacterAttachmentProfile
extends Resource
## Editable alongside SpriteFrames; one track per animation, no image scanning at runtime.
@export var reference_aim_position := Vector2(0,-9)
@export var tracks: Array[CharacterAttachmentTrack] = []

func track_for(animation: StringName) -> CharacterAttachmentTrack:
    for track in tracks:
        if track != null and track.animation == animation:
            return track
    return null
