@tool
class_name ForestProp
extends InteriorProp
## Reuses the editor artwork/collision controls without generating any scene nodes.
func _validate_property(property: Dictionary) -> void:
    if property.name == "color_variant":
        property.hint_string = "Deep green,Muted sage,Autumn"
