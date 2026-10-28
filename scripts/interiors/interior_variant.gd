@tool
class_name InteriorVariant
extends Node2D
## Three native PNG variants, applied to the existing editor-visible Artwork node.
@export_enum("Warm", "Sage", "Slate") var color_variant: int = 0:
    set(value):
        color_variant = clampi(value, 0, 2)
        refresh_when_ready()
@export var variant_textures: Array[Texture2D] = []:
    set(value):
        variant_textures = value
        refresh_when_ready()

func _ready() -> void:
    refresh_artwork()

func refresh_when_ready() -> void:
    if is_inside_tree():
        refresh_artwork.call_deferred()

func refresh_artwork() -> void:
    var artwork := get_node_or_null("Artwork") as Sprite2D
    if artwork and color_variant < variant_textures.size():
        artwork.texture = variant_textures[color_variant]
