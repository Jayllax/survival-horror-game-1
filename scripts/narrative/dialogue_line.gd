class_name DialogueLine
extends Resource
## One displayed line. Leave Speaker empty for an unnamed voice or narration.
@export var speaker: DialogueSpeaker
@export_multiline var text: String = ""
## Optional player responses, shown after this line finishes revealing.
@export var choices: Array[DialogueChoice] = []

@export_group("Voice (optional)")
## One recorded line. Leave empty for text-only dialogue; WAV, Ogg and MP3 work.
@export var voice_audio: AudioStream
@export_range(-40.0, 12.0, 0.5) var voice_volume_db: float = 0.0

func playable_choices() -> Array[DialogueChoice]:
    var result: Array[DialogueChoice] = []
    for choice in choices:
        if choice != null and choice.is_playable():
            result.append(choice)
    return result
