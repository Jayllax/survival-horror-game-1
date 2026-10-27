@tool
extends StaticBody2D
## Resizes the existing, authored visual/collision nodes in the editor. Creates no nodes.
@export var platform_size: Vector2 = Vector2(160, 20):
    set(value):
        platform_size = Vector2(maxf(16, value.x), maxf(8, value.y))
        if is_node_ready():
            update_geometry()

func _ready() -> void:
    update_geometry()

func update_geometry() -> void:
    var half := platform_size / 2
    var outline := PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
    var shape: RectangleShape2D = $CollisionShape2D.shape
    shape.size = platform_size
    $Surface.polygon = outline
    $TopEdge.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, -half.y + 4), Vector2(-half.x, -half.y + 4)])
    $LightOccluder2D.occluder.polygon = outline
