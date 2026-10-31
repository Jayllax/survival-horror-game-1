extends Area2D
## Resize the authored shape to cover the player above a particular floor material.
@export var surface: FootstepSurface
@export var surface_priority: int = 0
func _ready() -> void:
    add_to_group("footstep_surface")
