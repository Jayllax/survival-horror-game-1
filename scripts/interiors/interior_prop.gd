@tool
class_name InteriorProp
extends InteriorVariant
## Decor is passable by default, so it can sit behind the walking plane.
@export var solid: bool = false:
    set(value):
        solid = value
        refresh_when_ready()

func refresh_artwork() -> void:
    super.refresh_artwork()
    var shape := get_node_or_null("Solid/Shape") as CollisionShape2D
    if shape:
        shape.set_deferred("disabled", not solid)
