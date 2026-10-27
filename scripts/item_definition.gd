class_name InventoryItemDefinition
extends Resource
## Create/duplicate a .tres in data/items; identity must stay stable in saved games.
@export var id: String = "item"
@export var display_name: String = "Item"
@export_enum("Ammunition", "Key", "Puzzle object", "Supply", "Material", "Tool") var category: String = "Puzzle object"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_range(1, 99) var max_stack: int = 1

@export_range(0, 100) var heal_amount: int = 0
