class_name DialogueChoice
extends Resource
## One player response. Empty Next Dialogue continues the current sequence.
@export_multiline var text: String = ""
## Optional stable ID, recorded as dialogue_choice:<id> when selected.
@export var choice_id: String = ""
## Optional exact world flag, for example story:jax_helped.
@export var set_flag: String = ""
@export var flag_value: bool = true
## Assign another DialogueSequence to branch to its first playable line.
@export var next_dialogue: DialogueSequence
## After Next Dialogue, resume the line after this choice, including nested branches.
## Turn off only when this branch should replace the rest of the conversation.
@export var return_after_branch: bool = true

func is_playable() -> bool:
    return not text.strip_edges().is_empty() and (next_dialogue == null or not next_dialogue.playable_lines().is_empty())
