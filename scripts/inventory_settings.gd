class_name InventorySettings
extends Resource
## Starting capacity; individual save slots retain any later upgrades.
@export_range(4, 12) var columns := 8
@export_range(2, 8) var rows := 4
@export var starting_weapon := "pistol"
@export var starting_ammo := 12
