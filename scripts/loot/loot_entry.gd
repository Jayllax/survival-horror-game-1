class_name LootEntry
extends Resource
## One item type and quantity inside a searchable container.
@export var item: InventoryItemDefinition
@export_range(1, 99) var quantity: int = 1
