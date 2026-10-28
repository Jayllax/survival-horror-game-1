class_name CharacterAttachmentTrack
extends Resource
## Native frame coordinates, measured from the top-left of the sprite image.
@export var animation: StringName = &"idle"
## Horizontal pelvis centers keep the drawn body centered over its collider.
@export var body_centers: PackedFloat32Array = []
## Chest attachment for the aim pivot and shoulder rig, one point per frame.
@export var aim_origins: PackedVector2Array = []
## Visible handheld flashlight attachment, one point per unarmed frame.
@export var flashlight_hands: PackedVector2Array = []

func point_at(points: PackedVector2Array, frame: int) -> Vector2:
    return points[clampi(frame,0,points.size()-1)]
