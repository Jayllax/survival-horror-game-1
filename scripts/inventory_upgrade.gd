class_name InventoryUpgrade
extends Resource
## Attach to an item definition. Combining consumes one kit, never the target item.
enum Effect { COMPACT, DAMAGE }
@export_enum("Reduce item footprint", "Increase weapon damage") var effect: int = Effect.COMPACT
## Empty allows every eligible target; otherwise list stable item IDs.
@export var target_item_ids: Array[String] = []
@export_range(1.01, 3.0, 0.01) var damage_multiplier: float = 1.25

func accepts(definition: InventoryItemDefinition) -> bool:
    if not definition or definition.max_stack != 1 or (not target_item_ids.is_empty() and definition.id not in target_item_ids):
        return false
    if effect == Effect.DAMAGE:
        return definition.is_weapon and is_finite(damage_multiplier) and damage_multiplier > 1.0
    if effect != Effect.COMPACT:
        return false
    var base := definition.grid_size
    var compact := definition.compact_grid_size
    return compact.x > 0 and compact.y > 0 and compact.x <= base.x and compact.y <= base.y and compact.x * compact.y < base.x * base.y
