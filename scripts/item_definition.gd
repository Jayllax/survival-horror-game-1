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
@export_group("Use behavior")
## Remove one unit only after successful healing, upgrading, crafting or world use.
## Equipping, moving and transferring ammunition are not item-use actions.
@export var remove_after_use: bool = false
## Optional shared requirement ID. Different item variants can open the same locks.
## Example: a disposable cutter has its own ID but uses "bolt_cutters" here.
@export var use_as_item_id: String = ""
@export_group("Inventory footprint")
@export var grid_size := Vector2i(1, 1)
@export var can_rotate := true
## (0,0) disables size upgrades. Must fit inside the original unrotated footprint.
@export var compact_grid_size := Vector2i.ZERO
@export_group("Upgrade item")
## Set on a consumable upgrade kit, not on its target weapon/tool.
@export var upgrade: InventoryUpgrade
@export_group("Weapon")
@export var is_weapon := false
@export var weapon_texture: Texture2D
@export var ammunition_id := "ammo"
@export_range(1, 99) var magazine_size := 6
@export_range(1, 500) var bullet_damage := 26
@export_range(0.05, 3.0) var shot_interval := 0.28
@export_range(0.1, 10.0) var reload_seconds := 1.35
@export_range(1, 16) var pellets_per_shot: int = 1
## Full angle between the outside pellets. One projectile always fires straight.
@export_range(0.0, 60.0) var spread_degrees: float = 0.0
@export_range(32.0, 2000.0) var firing_range: float = 900.0
@export var reload_one_at_a_time: bool = false
@export var shot_sound: AudioStream
@export_range(0.0, 12.0) var recoil_distance: float = 3.0
@export_group("Weapon artwork and hands")
## Native artwork can display at 2x without resizing the beam or muzzle light.
@export var weapon_scale := Vector2.ONE
@export var custom_weapon_pose: bool = false
## Positions are local to the centered weapon texture, before Weapon Scale.
@export var near_grip := Vector2(-4, 4)
@export var far_grip := Vector2(-1, 2)
@export var muzzle_offset := Vector2(16, 0)
@export var flashlight_offset := Vector2(14, 4)
