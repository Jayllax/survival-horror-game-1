extends CharacterBody2D
## Ground-based patrol, detection, contact attack, and persistent defeat state.
@export var max_health: int = 78
@export var speed: float = 70.0
@export var detection_radius: float = 330.0
@export var damage: int = 15
@export var attack_interval: float = 1.1
@export var patrol_width: float = 100.0
var health: int
var home_x: float
var direction := -1.0
var attack_cooldown := 0.0
var flash_remaining := 0.0
var animation_time := 0.0

func _ready() -> void:
    if Game.world.get(Game.object_id(self), false):
        queue_free()
    health = max_health
    home_x = position.x
    add_to_group("enemy")

func _physics_process(delta: float) -> void:
    animation_time += delta
    $Body.frame = int(animation_time * 7.0) % 6 if absf(velocity.x) > 5 else 0
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    flash_remaining = maxf(0.0, flash_remaining - delta)
    $Body.modulate = Color(2, 0.7, 0.5) if flash_remaining > 0 else Color.WHITE
    velocity.y += 1050.0 * delta
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
    $Body.flip_h = direction < 0
    move_and_slide()

func take_damage(amount: int) -> void:
    health -= amount
    flash_remaining = 0.15
    if health <= 0:
        Game.world[Game.object_id(self)] = true
        remove_from_group("enemy")
        queue_free()
