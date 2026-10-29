@tool
extends InteriorProp
## Lamp artwork and actual Godot 2D illumination are independently editable.
@export var light_enabled: bool = true:
    set(value):
        light_enabled = value
        refresh_when_ready()
@export_range(0.0, 4.0, 0.05) var light_energy: float = 0.9:
    set(value):
        light_energy = value
        refresh_when_ready()
@export var light_color: Color = Color(1.0, 0.88, 0.65):
    set(value):
        light_color = value
        refresh_when_ready()
@export_range(0.1, 4.0, 0.05) var light_radius_scale: float = 0.9:
    set(value):
        light_radius_scale = value
        refresh_when_ready()

func refresh_artwork() -> void:
    super.refresh_artwork()
    var light := get_node_or_null("Light") as PointLight2D
    if light:
        light.enabled = light_enabled
        light.energy = light_energy
        light.color = light_color
        light.texture_scale = light_radius_scale

func set_switch_enabled(value: bool) -> void:
    # Keep the Inspector-facing property and the real light synchronized.
    light_enabled = value
    var light := get_node_or_null("Light") as PointLight2D
    if light:
        light.enabled = value
