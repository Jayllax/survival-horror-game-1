extends PointLight2D
@export var power_channel: String = "street"
@export var emergency_energy: float = 0.65
@export var powered_energy: float = 1.35

func _ready() -> void:
    Game.changed.connect(refresh)
    refresh()

func refresh() -> void:
    energy = powered_energy if bool(Game.world.get("power:" + power_channel, false)) else emergency_energy
