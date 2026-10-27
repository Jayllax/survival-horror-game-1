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
@export var melee_damage: int = 34
@export var melee_reach: float = 76.0
@export var dodge_speed: float = 440.0
const DODGE_INVULNERABILITY := 0.5
var invulnerable_remaining: float = 0.0
var dodge_remaining: float = 0.0
var dodge_cooldown: float = 0.0
var shot_cooldown: float = 0.0
var melee_cooldown: float = 0.0
var reload_remaining: float = 0.0
var facing := 1.0
var dodge_direction := 1.0
var nearest: Area2D
var feedback_time := 0.0
var animation_time := 0.0
var coyote_remaining := 0.0
var jump_buffer := 0.0
@onready var body_art: Sprite2D = $Body
@onready var aim: Node2D = $Aim
@onready var flashlight_light: PointLight2D = $Aim/Gun/Flashlight
@onready var muzzle: PointLight2D = $Aim/Gun/Muzzle

func _ready() -> void:
    add_to_group("player")
    Game.magazine = mini(Game.magazine, magazine_size)
    Game.changed.emit()
    flashlight_light.enabled = Game.flashlight_on

func _physics_process(delta: float) -> void:
    invulnerable_remaining = maxf(0.0, invulnerable_remaining - delta)
    dodge_remaining = maxf(0.0, dodge_remaining - delta)
    dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
    shot_cooldown = maxf(0.0, shot_cooldown - delta)
    melee_cooldown = maxf(0.0, melee_cooldown - delta)
    feedback_time = maxf(0.0, feedback_time - delta)
    body_art.modulate = Color(1.5, 0.6, 0.5) if feedback_time > 0 else Color.WHITE
    if dodge_remaining > 0:
        body_art.modulate = Color(0.5, 0.8, 1.1, 0.6)
    muzzle.energy = maxf(0.0, muzzle.energy - delta * 30.0)
    if Game.health <= 0 or Game.transitioning:
        velocity = Vector2.ZERO
        return
    if reload_remaining > 0:
        reload_remaining = maxf(0.0, reload_remaining - delta)
        if reload_remaining == 0:
            var needed: int = mini(magazine_size - Game.magazine, Game.count_item("ammo"))
            if needed > 0:
                Game.take_item("ammo", needed)
                Game.magazine += needed
                Game.changed.emit()
    $Aim/Gun.position.x = move_toward($Aim/Gun.position.x, 18.0, delta * 40.0)
    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0:
        facing = direction
    animation_time += delta
    body_art.frame = (int(animation_time * 10.0) % 6) if absf(velocity.x) > 5.0 else 0
    body_art.position.y = -3.0 + (sin(animation_time * 2.0) * 0.5 if absf(velocity.x) < 5.0 else 0.0)
    body_art.flip_h = facing < 0
    aim.rotation = (get_global_mouse_position() - aim.global_position).angle()
    $Aim/Gun.flip_v = cos(aim.rotation) < 0
    flashlight_light.position.y = -4 if $Aim/Gun.flip_v else 4
    if direction == 0:
        facing = signf(cos(aim.rotation))
        body_art.flip_h = facing < 0
    if not is_on_floor():
        velocity.y += gravity * delta
    coyote_remaining = coyote_seconds if is_on_floor() else maxf(0, coyote_remaining - delta)
    jump_buffer = jump_buffer_seconds if Input.is_action_just_pressed("jump") else maxf(0, jump_buffer - delta)
    if jump_buffer > 0 and coyote_remaining > 0 and dodge_remaining <= 0:
        velocity.y = jump_velocity
        jump_buffer = 0
        coyote_remaining = 0
    if Input.is_action_just_pressed("dodge") and dodge_cooldown <= 0:
        begin_dodge(direction if direction != 0 else facing)
    velocity.x = dodge_direction * dodge_speed if dodge_remaining > 0 else move_toward(velocity.x, direction * move_speed, acceleration * delta)
    move_and_slide()
    if Input.is_action_just_pressed("flashlight"):
        flashlight_light.enabled = not flashlight_light.enabled
        Game.flashlight_on = flashlight_light.enabled
    if Input.is_action_pressed("shoot"):
        shoot()
    if Input.is_action_just_pressed("reload"):
        reload_weapon()
    if Input.is_action_just_pressed("melee"):
        melee()
    update_interaction()
    if Input.is_action_just_pressed("interact") and is_instance_valid(nearest):
        nearest.interact(self)

func begin_dodge(direction: float) -> void:
    dodge_direction = direction
    dodge_remaining = DODGE_INVULNERABILITY
    invulnerable_remaining = DODGE_INVULNERABILITY
    dodge_cooldown = 1.05

func shoot() -> void:
    if shot_cooldown > 0 or reload_remaining > 0 or dodge_remaining > 0:
        return
    shot_cooldown = shot_interval
    if Game.magazine <= 0:
        Game.message.emit("Empty magazine. Press R to reload.")
        return
    Game.magazine -= 1
    Game.changed.emit()
    $ShotSound.play()
    muzzle.energy = 2.5
    $Aim/Gun.position.x = 15.0
    var origin: Vector2 = $Aim/Gun/Muzzle.global_position
    var target: Vector2 = origin + Vector2.RIGHT.rotated(aim.rotation) * 900
    var query := PhysicsRayQueryParameters2D.create(origin, target, 5)
    query.exclude = [get_rid()]
    var hit := get_world_2d().direct_space_state.intersect_ray(query)
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
    if reload_remaining > 0 or Game.magazine >= magazine_size:
        return
    if Game.count_item("ammo") == 0:
        Game.message.emit("No spare ammunition.")
        return
    reload_remaining = reload_seconds
    Game.message.emit("Reloading…")

func melee() -> void:
    if melee_cooldown > 0 or dodge_remaining > 0:
        return
    melee_cooldown = 0.65
    $MeleeArc.scale.x = facing
    $MeleeArc.visible = true
    get_tree().create_timer(0.14).timeout.connect(func(): $MeleeArc.visible = false)
    for enemy in get_tree().get_nodes_in_group("enemy"):
        var offset: Vector2 = enemy.global_position - global_position
        if offset.length() <= melee_reach and offset.x * facing >= -8:
            var query := PhysicsRayQueryParameters2D.create(global_position, enemy.global_position, 1)
            if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
                enemy.take_damage(melee_damage)

func take_damage(amount: int) -> void:
    if invulnerable_remaining > 0 or Game.health <= 0 or Game.transitioning:
        return
    Game.health = maxi(0, Game.health - amount)
    feedback_time = 0.18
    $HurtSound.play()
    Game.changed.emit()
    if Game.health <= 0:
        Game.message.emit("Health depleted. Load checkpoint to resume.")

func update_interaction() -> void:
    nearest = null
    var best := INF
    for object in get_tree().get_nodes_in_group("interactable"):
        if not object.is_available():
            continue
        var distance: float = global_position.distance_to(object.global_position)
        if distance < object.interaction_radius and distance < best:
            best = distance
            nearest = object
    var hud := get_tree().get_first_node_in_group("hud")
    if hud:
        hud.set_prompt("[E] " + nearest.prompt_text if is_instance_valid(nearest) else "")
