extends PointLight2D
@export var emergency_energy: float = 0.65
@export var powered_energy: float = 1.35

func _ready() -> void:
    Game.changed.connect(refresh)
    refresh()

func refresh() -> void:
    energy = powered_energy if Game.power_restored else emergency_energy
