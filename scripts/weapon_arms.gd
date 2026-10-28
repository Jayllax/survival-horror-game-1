extends Node2D
## Two simple articulated sleeves/hands follow the weapon's grip points.
## Colors, grip points, shoulder points and segment lengths remain editor-editable.
@export var near_shoulder := Vector2(-3,-10)
@export var far_shoulder := Vector2(1,-12)
@export var crouch_shoulder_offset := Vector2(0,22)
@export var near_grip := Vector2(-4,4)
@export var far_grip := Vector2(-1,2)
@export var upper_arm_length: float = 12.0
@export var forearm_length: float = 12.0
@onready var player: CharacterBody2D = get_parent()
@onready var gun: Sprite2D = player.get_node("Aim/Gun")

func _process(_delta: float) -> void:
    update_pose()

func update_pose() -> void:
    visible = player.is_aiming() and gun.texture != null and player.dodge_remaining <= 0 and Game.health > 0
    if not visible:
        return
    var shoulder_offset := crouch_shoulder_offset if player.is_crouching else Vector2.ZERO
    var mirror := Vector2(player.facing,1)
    # Sprite2D.flip_v mirrors pixels, not child transforms or coordinates.
    var grip_mirror := Vector2(1,-1 if gun.flip_v else 1)
    pose_arm($Far,far_shoulder*mirror+shoulder_offset,to_local(gun.to_global(far_grip*grip_mirror)),player.facing)
    pose_arm($Near,near_shoulder*mirror+shoulder_offset,to_local(gun.to_global(near_grip*grip_mirror)),player.facing)

func pose_arm(arm: Node2D, shoulder: Vector2, hand: Vector2, facing: float) -> void:
    var offset := hand-shoulder
    var distance := maxf(offset.length(),0.001)
    var upper := maxf(upper_arm_length,1.0)
    var lower := maxf(forearm_length,1.0)
    # At extreme grip/weapon sizes, stretch just enough to keep the hand attached.
    var stretch := maxf(1.0,distance/(upper+lower-0.01))
    upper *= stretch
    lower *= stretch
    var along := (upper*upper-lower*lower+distance*distance)/(2*distance)
    var height := sqrt(maxf(0,upper*upper-along*along))
    var axis := offset/distance
    var elbow := shoulder+axis*along+Vector2(-axis.y,axis.x)*height*facing
    pose_segment(arm.get_node("Upper"),shoulder,elbow)
    pose_segment(arm.get_node("Lower"),elbow,hand)
    arm.get_node("Hand").position = hand

func pose_segment(segment: Polygon2D, start: Vector2, finish: Vector2) -> void:
    segment.position = start
    segment.rotation = (finish-start).angle()
    segment.scale.x = start.distance_to(finish)
