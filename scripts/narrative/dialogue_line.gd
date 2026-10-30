class_name DialogueLine
extends Resource
## One displayed line. Leave Speaker empty for an unnamed voice or narration.
@export var speaker: DialogueSpeaker
@export_multiline var text: String = ""
## Optional player responses, shown after this line finishes revealing.
@export var choices: Array[DialogueChoice] = []

func playable_choices() -> Array[DialogueChoice]:
    var result: Array[DialogueChoice] = []
    for choice in choices:
        if choice != null and choice.is_playable():
            result.append(choice)
    return result
