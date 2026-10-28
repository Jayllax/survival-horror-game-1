class_name DialogueSequence
extends Resource
@export var lines: Array[DialogueLine] = []

func playable_lines() -> Array[DialogueLine]:
    var result: Array[DialogueLine] = []
    for line in lines:
        if line != null and not line.text.strip_edges().is_empty():
            result.append(line)
    return result
