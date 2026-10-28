class_name DialogueLine
extends Resource
## One displayed line. Leave Speaker empty for an unnamed voice or narration.
@export var speaker: DialogueSpeaker
@export_multiline var text: String = ""
