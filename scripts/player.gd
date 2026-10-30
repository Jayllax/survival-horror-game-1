extends CharacterBody2D
## Movement and weapon tuning is exposed here for designers.
@export var acceleration: float = 1400.0
@export var coyote_seconds: float = 0.10
@export var jump_buffer_seconds: float = 0.12
@export var move_speed: float = 205.0
@export var jump_velocity: float = -390.0
@export var gravity: float = 1050.0
@export var magazine_size: int = 6
@export var bullet_damage: int = 26
@export var shot_interval: float = 0.28
@export var reload_seconds: float = 1.35
@export_group("Sprint and Crouch")
@export_range(1.0, 3.0) var sprint_multiplier: float = 1.55
@export_range(0.1, 1.0) var crouch_speed_multiplier: float = 0.45
@export var crouch_height: float = 36.0
@export_group("Short Dodge")
@export var dodge_speed: float = 260.0
@export_range(0.05, 1.0) var dodge_seconds: float = 0.18
@export_range(0.0, 1.0) var dodge_invulnerability_seconds: float = 0.12
@export var dodge_cooldown_seconds: float = 0.65
@export_group("Animation Placeholders")
## Disable these once your crouch/dodge frames contain the real poses.
@export var use_crouch_placeholder_pose: bool = true
@export var use_dodge_placeholder_pose: bool = true
@export_group("Stealth Noise")
@export var walking_noise_radius: float = 135.0
@export var sprinting_noise_radius: float = 255.0
@export var crouch_noise_radius: float = 0.0
@export var landing_noise_radius: float = 200.0
@export var jump_noise_radius: float = 160.0
@export var dodge_noise_radius: float = 180.0
@export var gunshot_noise_radius: float = 850.0
@export var reload_noise_radius: float = 70.0
@export_group("")
var invulnerable_remaining: float = 0.0
var dodge_remaining: float = 0.0
var dodge_cooldown: float = 0.0
var shot_cooldown: float = 0.0
var reload_remaining: float = 0.0
var facing := 1.0
var dodge_direction := 1.0
var nearest: Area2D
var feedback_time := 0.0
var is_crouching := false
var is_sprinting := false
var footstep_remaining := 0.0
var standing_shape: CapsuleShape2D
var standing_collision_position := Vector2.ZERO
var standing_aim_position := Vector2.ZERO
var standing_art_scale := Vector2.ONE
var coyote_remaining := 0.0
var jump_buffer := 0.0
var combat_remaining := 0.0
var weapon_uid := -2
var default_light_scale := Vector2.ONE
var default_muzzle_scale := Vector2.ONE
var default_muzzle_position := Vector2.ZERO
var default_shot_sound: AudioStream
var story_interact_held := false
var story_shoot_held := false
var story_jump_held := false
var is_pushing := false
var pushed_body: PhysicsBody2D
@export var combat_feedback_seconds: float = 1.8
@export_range(0.1, 1.0) var aiming_move_multiplier: float = 0.55
@onready var body_art: CharacterVisuals = $Body
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var aim: Node2D = $Aim
@onready var flashlight_light: PointLight2D = $Aim/Gun/Flashlight
@onready var muzzle: PointLight2D = $Aim/Gun/Muzzle

func _ready() -> void:
    add_to_group("player")
    standing_shape = body_collision.shape.duplicate() as CapsuleShape2D
    body_collision.shape = standing_shape.duplicate()
    standing_collision_position = body_collision.position
    standing_aim_position = aim.position
    standing_art_scale = body_art.scale
    default_light_scale = flashlight_light.scale
    default_muzzle_scale = muzzle.scale
    default_muzzle_position = muzzle.position
    default_shot_sound = $ShotSound.stream
    update_animation()
    Game.changed.connect(sync_weapon)
    sync_weapon()
    Game.magazine = mini(Game.magazine, magazine_size)
    Game.changed.emit()
    flashlight_light.enabled = Game.flashlight_on

func sync_weapon() -> void:
    var definition := Game.active_weapon()
    if Game.equipped_uid != weapon_uid:
        reload_remaining = 0
        combat_remaining = 0
        shot_cooldown = 0
        muzzle.energy = 0
        weapon_uid = Game.equipped_uid
    $Aim/Gun.texture = definition.weapon_texture if definition and Input.is_action_pressed("aim") and dodge_remaining <= 0 else null
    var art_scale := definition.weapon_scale if definition else Vector2.ONE
    art_scale = Vector2(maxf(0.01, absf(art_scale.x)), maxf(0.01, absf(art_scale.y)))
    $Aim/Gun.scale = art_scale
    # Artwork size must not change the designer's flashlight width/reach.
    flashlight_light.scale = default_light_scale / art_scale
    muzzle.scale = default_muzzle_scale / art_scale
    muzzle.position = definition.muzzle_offset * Vector2(1, -1 if $Aim/Gun.flip_v else 1) if definition and definition.custom_weapon_pose else default_muzzle_position
    $ShotSound.stream = definition.shot_sound if definition and definition.shot_sound else default_shot_sound
    if definition:
        magazine_size = definition.magazine_size
        bullet_damage = Game.inventory.weapon_damage(Game.equipped_uid)
        shot_interval = definition.shot_interval
        reload_seconds = definition.reload_seconds

func _physics_process(delta: float) -> void:
    is_pushing = false
    pushed_body = null
    if not Input.is_action_pressed("interact"):
        story_interact_held = false
    if not Input.is_action_pressed("shoot"):
        story_shoot_held = false
    if not Input.is_action_pressed("jump"):
        story_jump_held = false
    combat_remaining = maxf(0, combat_remaining - delta)
    invulnerable_remaining = maxf(0.0, invulnerable_remaining - delta)
    var was_dodging := dodge_remaining > 0
    dodge_remaining = maxf(0.0, dodge_remaining - delta)
    if was_dodging and dodge_remaining <= 0:
        velocity.x = 0.0
    dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
    shot_cooldown = maxf(0.0, shot_cooldown - delta)
    feedback_time = maxf(0.0, feedback_time - delta)
    footstep_remaining = maxf(0,footstep_remaining-delta)
    body_art.modulate = Color(1.5, 0.6, 0.5) if feedback_time > 0 else Color.WHITE
    muzzle.energy = maxf(0.0, muzzle.energy - delta * 30.0)
    if Game.health <= 0 or Game.transitioning:
        velocity = Vector2.ZERO
        return
    if reload_remaining > 0:
        reload_remaining = maxf(0.0, reload_remaining - delta)
        if reload_remaining == 0:
            var definition := Game.active_weapon()
            if not definition:
                return
            var ammo_id := definition.ammunition_id
            var needed: int = mini(magazine_size - Game.magazine, Game.count_item(ammo_id))
            if definition.reload_one_at_a_time:
                needed = mini(needed, 1)
            if needed > 0:
                Game.take_item(ammo_id, needed)
                Game.magazine += needed
                Game.changed.emit()
            if definition.reload_one_at_a_time and Game.magazine < magazine_size and Game.count_item(ammo_id) > 0:
                reload_remaining = reload_seconds
                combat_remaining = reload_seconds + 1.0
    $Aim/Gun.position.x = move_toward($Aim/Gun.position.x, 18.0, delta * 40.0)
    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0:
        facing = direction
    update_crouch()
    update_aim(direction)
    if not is_on_floor():
        velocity.y += gravity * delta
    coyote_remaining = coyote_seconds if is_on_floor() else maxf(0, coyote_remaining - delta)
    jump_buffer = jump_buffer_seconds if Input.is_action_just_pressed("jump") and not story_jump_held else maxf(0, jump_buffer - delta)
    if jump_buffer > 0 and coyote_remaining > 0 and dodge_remaining <= 0 and not is_crouching:
        velocity.y = jump_velocity
        Game.emit_noise(global_position,jump_noise_radius,self)
        jump_buffer = 0
        coyote_remaining = 0
    if Input.is_action_just_pressed("dodge"):
        begin_dodge(direction if direction != 0 else facing)
    is_sprinting = Input.is_action_pressed("sprint") and direction != 0 and not is_crouching and not Input.is_action_pressed("aim") and dodge_remaining <= 0
    var speed_multiplier := crouch_speed_multiplier if is_crouching else (aiming_move_multiplier if is_aiming() else (sprint_multiplier if is_sprinting else 1.0))
    velocity.x = dodge_direction * dodge_speed if dodge_remaining > 0 else move_toward(velocity.x, direction * move_speed * speed_multiplier, acceleration * delta)
    var was_grounded := is_on_floor()
    var fall_speed := velocity.y
    apply_pushable_movement(delta, direction)
    # Follow only the distance the object really moved. Its broadphase collider
    # may still occupy its old position this tick; every other obstacle stays solid.
    if is_instance_valid(pushed_body):
        add_collision_exception_with(pushed_body)
    move_and_slide()
    if is_instance_valid(pushed_body):
        remove_collision_exception_with(pushed_body)
    if is_pushing:
        # A side contact can zero velocity.x even though both bodies travelled.
        # Keep that actual motion for acceleration and walk animation next frame.
        velocity.x = get_real_velocity().x
    if not was_grounded and is_on_floor() and fall_speed > 100:
        Game.emit_noise(global_position,landing_noise_radius,self)
    if is_on_floor() and absf(get_real_velocity().x) > 10 and footstep_remaining <= 0 and dodge_remaining <= 0:
        var noise_radius := crouch_noise_radius if is_crouching else (sprinting_noise_radius if is_sprinting else walking_noise_radius)
        Game.emit_noise(global_position,noise_radius,self)
        footstep_remaining = 0.5 if is_crouching else (0.2 if is_sprinting else 0.32)
    update_animation()
    if Input.is_action_just_pressed("flashlight"):
        flashlight_light.enabled = not flashlight_light.enabled
        Game.flashlight_on = flashlight_light.enabled
    if Input.is_action_pressed("shoot"):
        shoot()
    if Input.is_action_just_pressed("reload"):
        reload_weapon()
    update_interaction()
    if Input.is_action_just_pressed("interact") and not story_interact_held and is_instance_valid(nearest):
        nearest.interact(self)

func apply_pushable_movement(delta: float, direction: float) -> void:
    if not is_on_floor() or velocity.y < 0 or dodge_remaining > 0 or direction * velocity.x <= 0:
        return
    if not get_tree().has_group("pushable"):
        return
    var motion := Vector2(velocity.x * delta, 0)
    var hit := KinematicCollision2D.new()
    if not test_move(global_transform, motion, hit, safe_margin, false):
        return
    var body := hit.get_collider()
    if not body is PhysicsBody2D or not body.is_in_group("pushable"):
        return
    if hit.get_normal().x * signf(motion.x) > -0.7:
        return # Standing/landing on top must not push the platform sideways.
    var approach := maxf(0.0, hit.get_travel().x * signf(motion.x))
    var remaining := maxf(0.0, absf(motion.x) - approach)
    var moved: float = body.push_from(self, signf(motion.x) * remaining, delta)
    is_pushing = moved * signf(motion.x) > 0.001
    var follow_distance := approach + maxf(0.0, moved * signf(motion.x))
    if is_pushing:
        # Leave the normal collision skin rather than causing sideways recovery
        # from the furniture's gravity step on the following frame.
        follow_distance = maxf(0.0, follow_distance - safe_margin)
        pushed_body = body
        is_sprinting = false
    velocity.x = signf(motion.x) * minf(absf(motion.x), follow_distance) / delta

func suppress_story_exit_input() -> void:
    story_interact_held = Input.is_action_pressed("interact")
    story_shoot_held = Input.is_action_pressed("shoot")
    story_jump_held = Input.is_action_pressed("jump")

func can_stand() -> bool:
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = standing_shape
    query.transform = global_transform * Transform2D(0.0, standing_collision_position + Vector2(0,-0.1))
    query.collision_mask = collision_mask
    query.exclude = [get_rid()]
    return get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func update_crouch() -> void:
    var wants_crouch := Input.is_action_pressed("crouch") and is_on_floor() and dodge_remaining <= 0
    if is_crouching and not wants_crouch and not can_stand():
        wants_crouch = true
    is_crouching = wants_crouch
    var height := clampf(crouch_height,standing_shape.radius*2,standing_shape.height) if is_crouching else standing_shape.height
    (body_collision.shape as CapsuleShape2D).height = height
    var lowered := (standing_shape.height-height)/2.0
    body_collision.position = standing_collision_position + Vector2(0,lowered)
    aim.position = standing_aim_position + Vector2(0,lowered)

func update_animation() -> void:
    var state: StringName = &"idle"
    if dodge_remaining > 0:
        state = &"dodge"
    elif not is_on_floor():
        state = &"jump" if velocity.y < 0 else &"fall"
    elif is_crouching:
        state = &"crouch_walk" if absf(velocity.x) > 5 else &"crouch_idle"
    elif absf(velocity.x) > 5:
        state = &"sprint" if is_sprinting else &"walk"
    if is_aiming() and dodge_remaining <= 0:
        var aimed_state := StringName("crouch_aim_" + str(state).trim_prefix("crouch_")) if str(state).begins_with("crouch_") else StringName("aim_" + str(state))
        if body_art.has_state(aimed_state):
            state = aimed_state
    body_art.play_state(state,dodge_seconds if state == &"dodge" else 0.0)
    if state in [&"walk",&"sprint",&"crouch_walk",&"aim_walk",&"crouch_aim_walk"]:
        var reference_speed := move_speed * (crouch_speed_multiplier if is_crouching else (sprint_multiplier if is_sprinting else 1.0))
        body_art.speed_scale = clampf(absf(velocity.x)/maxf(reference_speed,1.0),0.2,1.75)
        if is_aiming() and velocity.x*facing < 0:
            body_art.speed_scale *= -1.0
    var pose_scale := 1.0
    if standing_shape and is_crouching and use_crouch_placeholder_pose:
        pose_scale = clampf(crouch_height/standing_shape.height,0.1,1.0)
    elif dodge_remaining > 0 and use_dodge_placeholder_pose:
        pose_scale = 0.8
    body_art.scale.y = standing_art_scale.y * pose_scale
    $WeaponArms.update_pose()

func update_aim(_direction: float) -> void:
    # Keep the Gun node active: its light children also work while holstered.
    var aiming := Input.is_action_pressed("aim")
    aim.rotation = (get_global_mouse_position() - aim.global_position).angle() if aiming else (PI if facing < 0 else 0.0)
    $Aim/Gun.flip_v = cos(aim.rotation) < 0
    if aiming:
        facing = -1.0 if cos(aim.rotation) < 0 else 1.0
    body_art.flip_h = facing < 0
    var definition := Game.active_weapon()
    $Aim/Gun.texture = definition.weapon_texture if definition and aiming and dodge_remaining <= 0 else null
    $WeaponArms.update_pose()

func begin_dodge(direction: float) -> bool:
    if not is_on_floor() or is_crouching or dodge_cooldown > 0 or dodge_remaining > 0 or Game.health <= 0 or Game.transitioning:
        return false
    dodge_direction = -1.0 if direction < 0 else 1.0
    dodge_remaining = dodge_seconds
    invulnerable_remaining = clampf(dodge_invulnerability_seconds,0,dodge_seconds)
    dodge_cooldown = dodge_cooldown_seconds
    jump_buffer = 0
    Game.emit_noise(global_position,dodge_noise_radius,self)
    return true

func shoot() -> void:
    if story_shoot_held or not Input.is_action_pressed("aim") or not Game.has_equipped_weapon() or shot_cooldown > 0 or dodge_remaining > 0:
        return
    var definition := Game.active_weapon()
    if reload_remaining > 0:
        if not definition.reload_one_at_a_time or Game.magazine <= 0:
            return
        reload_remaining = 0
    shot_cooldown = shot_interval
    if Game.magazine <= 0:
        combat_remaining = combat_feedback_seconds
        return
    combat_remaining = combat_feedback_seconds
    Game.magazine -= 1
    Game.changed.emit()
    Game.emit_noise(global_position,gunshot_noise_radius,self)
    $ShotSound.play()
    muzzle.energy = 2.5
    $Aim/Gun.position.x = 18.0 - definition.recoil_distance
    var origin: Vector2 = $Aim/Gun/Muzzle.global_position
    # A long gun can visually extend past a thin fence while the body is blocked.
    # Check shoulder-to-muzzle first so it cannot fire through that obstruction.
    var barrel_query := PhysicsRayQueryParameters2D.create(aim.global_position,origin,1)
    barrel_query.exclude = [get_rid()]
    barrel_query.hit_from_inside = true
    var obstruction := get_world_2d().direct_space_state.intersect_ray(barrel_query)
    var pellets := clampi(definition.pellets_per_shot, 1, 16)
    for pellet in pellets:
        var angle := 0.0 if pellets == 1 else lerpf(-0.5, 0.5, float(pellet) / float(pellets - 1)) * deg_to_rad(definition.spread_degrees)
        var target := origin + Vector2.RIGHT.rotated(aim.rotation + angle) * definition.firing_range
        var hit := obstruction
        var start := origin
        if hit.is_empty():
            var query := PhysicsRayQueryParameters2D.create(origin, target, 5)
            query.exclude = [get_rid()]
            query.hit_from_inside = true
            hit = get_world_2d().direct_space_state.intersect_ray(query)
        else:
            start = hit["position"]
        resolve_bullet(start, target, hit)

func resolve_bullet(origin: Vector2, target: Vector2, hit: Dictionary) -> void:
    var end: Vector2 = hit.get("position", target)
    if not hit.is_empty() and hit["collider"].has_method("take_damage"):
        hit["collider"].take_damage(bullet_damage)
    var tracer := Line2D.new()
    tracer.top_level = true
    tracer.width = 1.5
    tracer.default_color = Color(1.0, 0.77, 0.4, 0.85)
    tracer.points = PackedVector2Array([origin, end])
    get_parent().add_child(tracer)
    var tween := create_tween()
    tween.tween_property(tracer, "modulate:a", 0.0, 0.09)
    tween.tween_callback(tracer.queue_free)

func reload_weapon() -> void:
    if not Game.has_equipped_weapon() or reload_remaining > 0 or Game.magazine >= magazine_size:
        return
    if Game.count_item(Game.active_weapon().ammunition_id) == 0:
        Game.message.emit("No spare ammunition.")
        return
    reload_remaining = reload_seconds
    combat_remaining = reload_seconds + 1.0
    Game.emit_noise(global_position,reload_noise_radius,self)

func take_damage(amount: int) -> void:
    if invulnerable_remaining > 0 or Game.health <= 0 or Game.transitioning:
        return
    Game.health = maxi(0, Game.health - amount)
    feedback_time = 0.18
    $HurtSound.play()
    Game.changed.emit()
    if Game.health <= 0:
        Game.message.emit("Health depleted. Load a saved game to resume.")

func update_interaction() -> void:
    nearest = null
    var best := INF
    for object in get_tree().get_nodes_in_group("interactable"):
        if not bool(object.get_meta("story_interaction_enabled", true)):
            continue
        if object is CanvasItem and not object.is_visible_in_tree():
            continue
        if not object.is_available():
            continue
        var distance: float = global_position.distance_to(object.global_position)
        if distance < object.interaction_radius and distance < best:
            best = distance
            nearest = object
    var hud := get_tree().get_first_node_in_group("hud")
    if hud:
        hud.set_interaction(nearest)

func is_aiming() -> bool:
    return Game.has_equipped_weapon() and Input.is_action_pressed("aim")

func is_showing_combat_feedback() -> bool:
    return Game.has_equipped_weapon() and (is_aiming() or combat_remaining > 0 or reload_remaining > 0)
