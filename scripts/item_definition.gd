class_name InventoryItemDefinition
extends Resource
## Create/duplicate a .tres in data/items; identity must stay stable in saved games.
@export var id: String = "item"
@export var display_name: String = "Item"
@export_enum("Ammunition", "Key", "Puzzle object", "Supply", "Material", "Tool", "Weapon") var category: String = "Puzzle object"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_range(1, 99) var max_stack: int = 1

@export_range(0, 100) var heal_amount: int = 0
@export_group("Inventory footprint")
@export var grid_size := Vector2i(1, 1)
@export var can_rotate := true
@export_group("Weapon")
@export var is_weapon := false
@export var weapon_texture: Texture2D
@export var ammunition_id := "ammo"
@export_range(1, 99) var magazine_size := 6
@export_range(1, 500) var bullet_damage := 26
@export_range(0.05, 3.0) var shot_interval := 0.28
@export_range(0.1, 10.0) var reload_seconds := 1.35
