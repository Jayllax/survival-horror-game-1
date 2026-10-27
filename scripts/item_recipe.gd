class_name InventoryRecipe
extends Resource
## An order-independent pair. No custom code is needed for additional recipes.
@export var input_a: String = "cloth"
@export var input_b: String = "antiseptic"
@export var output_id: String = "bandage"
@export_range(1, 99) var output_quantity: int = 1
