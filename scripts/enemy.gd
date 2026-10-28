extends CharacterBody2D
## Ground-based patrol, detection, contact attack, and persistent defeat state.
@export var max_health: int = 78
@export var speed: float = 70.0
@export var detection_radius: float = 330.0
@export var damage: int = 15
@export var attack_interval: float = 1.1
@export var patrol_width: float = 100.0
@export_group("Hit and Death")
@export var hit_reaction_seconds: float = 0.18
@export var death_seconds: float = 0.6
@export var corpse_linger_seconds: float = 0.35
@export var leave_corpse: bool = false
## Disable when your death frames contain the actual collapsing pose.
@export var use_death_placeholder_pose: bool = true
var health: int
var home_x: float
var direction := -1.0
var attack_cooldown := 0.0
var flash_remaining := 0.0
var hit_remaining := 0.0
var death_remaining := 0.0
var dead := false
@onready var body_art: CharacterVisuals = $Body

func _ready() -> void:
    if Game.world.get(Game.object_id(self), false):
        queue_free()
        return
    health = max_health
    home_x = position.x
    add_to_group("enemy")
    body_art.play_state(&"idle")

func _physics_process(delta: float) -> void:
    if dead:
        death_remaining = maxf(0,death_remaining-delta)
        if use_death_placeholder_pose:
            body_art.scale.y = lerpf(0.18,1.0,clampf((death_remaining-corpse_linger_seconds)/maxf(death_seconds,0.01),0,1))
        if death_remaining <= corpse_linger_seconds:
            body_art.stop()
            if body_art.has_state(&"death"):
                body_art.animation = &"death"
                body_art.frame = body_art.sprite_frames.get_frame_count(&"death")-1
        if death_remaining <= 0 and not leave_corpse:
            queue_free()
        return
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    flash_remaining = maxf(0.0, flash_remaining - delta)
    hit_remaining = maxf(0,hit_remaining-delta)
    body_art.modulate = Color(1.5, 0.8, 0.7) if flash_remaining > 0 else Color.WHITE
    velocity.y += 1050.0 * delta
    if hit_remaining > 0:
        velocity.x = 0
        move_and_slide()
        return
    var player := get_tree().get_first_node_in_group("player")
    if player and Game.health > 0 and not Game.transitioning:
        var offset: Vector2 = player.global_position - global_position
        if offset.length() < detection_radius:
            direction = signf(offset.x)
            velocity.x = direction * speed if absf(offset.x) > 35 else 0.0
            if offset.length() < 53 and attack_cooldown <= 0:
                player.take_damage(damage)
                attack_cooldown = attack_interval
        else:
            if absf(position.x - home_x) > patrol_width:
                direction = signf(home_x - position.x)
            velocity.x = direction * speed * 0.4
    else:
        velocity.x = 0.0
    body_art.flip_h = direction < 0
    move_and_slide()
    body_art.play_state(&"walk" if absf(velocity.x) > 5 else &"idle")

func take_damage(amount: int) -> void:
    if dead or amount <= 0:
        return
    health = maxi(0,health-amount)
    flash_remaining = 0.15
    if health <= 0:
        dead = true
        velocity = Vector2.ZERO
        hit_remaining = 0
        flash_remaining = 0
        body_art.modulate = Color.WHITE
        Game.world[Game.object_id(self)] = true
        remove_from_group("enemy")
        collision_layer = 0
        collision_mask = 0
        $CollisionShape2D.set_deferred("disabled",true)
        death_remaining = death_seconds + corpse_linger_seconds
        body_art.play_state(&"death",maxf(death_seconds,0.01),true)
    else:
        hit_remaining = maxf(hit_reaction_seconds,0.01)
        body_art.play_state(&"hit",hit_remaining,true)
