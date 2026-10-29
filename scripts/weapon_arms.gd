extends Node2D
## Two simple articulated sleeves/hands follow the weapon's grip points.
## Colors, grip points, shoulder points and segment lengths remain editor-editable.
@export var attachment_profile: CharacterAttachmentProfile
## Missing tracks use the calibrated reference; custom nonempty tracks take priority.
@export var fallback_attachment_profile: CharacterAttachmentProfile = preload("res://data/animations/player_attachment_defaults.tres")
## Last resort for the current artwork if both exported profiles have empty lists.
@export var use_calibrated_reference_when_empty: bool = true
var calibrated_reference: CharacterAttachmentProfile = preload("res://scripts/animation/player_attachment_reference.gd").create_profile()
## Local barrel position while the equipped weapon is drawn. Y mirrors with the gun.
@export var barrel_flashlight_offset := Vector2(14,4)
## Small forward offset from the animated hand while the gun is holstered.
@export var handheld_flashlight_offset := Vector2(2,0)
@export var near_shoulder := Vector2(-3,-10)
@export var far_shoulder := Vector2(1,-12)
@export var crouch_shoulder_offset := Vector2(0,22)
@export var near_grip := Vector2(-4,4)
@export var far_grip := Vector2(-1,2)
@export var upper_arm_length: float = 12.0
@export var forearm_length: float = 12.0
@onready var player: CharacterBody2D = get_parent()
@onready var gun: Sprite2D = player.get_node("Aim/Gun")
@onready var body: CharacterVisuals = player.get_node("Body")
@onready var light: PointLight2D = gun.get_node("Flashlight")
var body_origin := Vector2.ZERO

func _ready() -> void:
    body_origin = body.position
    body.frame_changed.connect(on_pose_changed)
    body.animation_changed.connect(on_pose_changed)

func on_pose_changed() -> void:
    # Child nodes become ready before the player's cached transforms are initialized.
    if player.is_node_ready():
        update_pose()

func _process(_delta: float) -> void:
    update_pose()

func update_pose() -> void:
    var shoulder_offset := update_attachments()
    visible = player.is_aiming() and gun.texture != null and player.dodge_remaining <= 0 and Game.health > 0
    if not visible:
        return
    var mirror := Vector2(player.facing,1)
    # Sprite2D.flip_v mirrors pixels, not child transforms or coordinates.
    var grip_mirror := Vector2(1,-1 if gun.flip_v else 1)
    var definition := Game.active_weapon()
    var far_point := definition.far_grip if definition and definition.custom_weapon_pose else far_grip
    var near_point := definition.near_grip if definition and definition.custom_weapon_pose else near_grip
    pose_arm($Far,far_shoulder*mirror+shoulder_offset,to_local(gun.to_global(far_point*grip_mirror)),player.facing)
    pose_arm($Near,near_shoulder*mirror+shoulder_offset,to_local(gun.to_global(near_point*grip_mirror)),player.facing)

func frame_point_world(point: Vector2) -> Vector2:
    var texture := body.sprite_frames.get_frame_texture(body.animation,body.frame)
    var local := point-texture.get_size()/2 if body.centered else point
    local *= Vector2(-1 if body.flip_h else 1,-1 if body.flip_v else 1)
    return body.to_global(local+body.offset)

func update_attachments() -> Vector2:
    var track := attachment_profile.track_for(body.animation) if attachment_profile else null
    var fallback := fallback_attachment_profile.track_for(body.animation) if fallback_attachment_profile else null
    var reference := calibrated_reference.track_for(body.animation) if use_calibrated_reference_when_empty else null
    var candidates: Array[CharacterAttachmentTrack] = [track, fallback, reference]
    var center_track := track_with_points(candidates, &"body_centers")
    var aim_track := track_with_points(candidates, &"aim_origins")
    var hand_track := track_with_points(candidates, &"flashlight_hands")
    body.position = body_origin
    if center_track and not center_track.body_centers.is_empty():
        var texture := body.sprite_frames.get_frame_texture(body.animation,body.frame)
        var center := center_track.body_centers[clampi(body.frame,0,center_track.body_centers.size()-1)]
        var half_width := texture.get_width()/2.0 if body.centered else 0.0
        body.position.x -= (center-half_width)*body.scale.x*(-1 if body.flip_h else 1)
    var lowered: float = (player.standing_shape.height-player.body_collision.shape.height)/2 if player.standing_shape else 0.0
    var shoulder_offset := crouch_shoulder_offset if player.is_crouching else Vector2.ZERO
    player.aim.position = player.standing_aim_position+Vector2(0,lowered)
    if aim_track and not aim_track.aim_origins.is_empty():
        var chest := frame_point_world(aim_track.point_at(aim_track.aim_origins,body.frame))
        var baseline := Vector2(0,-9)
        if attachment_profile:
            baseline = attachment_profile.reference_aim_position
        elif fallback_attachment_profile:
            baseline = fallback_attachment_profile.reference_aim_position
        shoulder_offset = player.to_local(chest)-baseline
        player.aim.position = player.standing_aim_position+shoulder_offset
    # Animation affects the origin only. Cursor direction remains exclusive to held aim.
    player.aim.rotation = (player.get_global_mouse_position()-player.aim.global_position).angle() if Input.is_action_pressed("aim") else (PI if player.facing<0 else 0.0)
    gun.flip_v = cos(player.aim.rotation)<0
    var definition := Game.active_weapon()
    var grip_mirror := Vector2(1,-1 if gun.flip_v else 1)
    if definition and definition.custom_weapon_pose:
        player.muzzle.position = definition.muzzle_offset * grip_mirror
    if player.is_aiming() and gun.texture != null and player.dodge_remaining<=0:
        var barrel_point := definition.flashlight_offset if definition and definition.custom_weapon_pose else barrel_flashlight_offset
        light.position = barrel_point * grip_mirror
    else:
        var hand: Vector2 = player.aim.global_position
        if hand_track and not hand_track.flashlight_hands.is_empty():
            hand = frame_point_world(hand_track.point_at(hand_track.flashlight_hands,body.frame))
        var light_origin := hand+Vector2(handheld_flashlight_offset.x*player.facing,handheld_flashlight_offset.y)
        if Input.is_action_pressed("aim"):
            # With no drawn weapon, aim from the actual handheld emitter.
            player.aim.position = player.to_local(light_origin)
            player.aim.rotation = (player.get_global_mouse_position()-light_origin).angle()
            gun.flip_v = cos(player.aim.rotation)<0
        light.global_position = light_origin
    return shoulder_offset

func track_with_points(candidates: Array[CharacterAttachmentTrack], field: StringName) -> CharacterAttachmentTrack:
    for candidate in candidates:
        if candidate and not candidate.get(field).is_empty():
            return candidate
    return null

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
