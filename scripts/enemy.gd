extends CharacterBody2D
## Sleeping/aware enemies with hearing, sight, memory and committed attacks.
signal state_changed(previous: int, current: int)
enum State { SLEEPING, WAKING, IDLE, PATROL, INVESTIGATE, CHASE, ATTACK, RECOVER, SEARCH, RETURN_HOME, HIT, DEAD }
@export var max_health: int = 78
@export var speed: float = 70.0
@export var damage: int = 15
@export_group("Initial Behaviour")
@export_enum("Sleeping", "Idle", "Patrol") var initial_behaviour: int = 0
@export_enum("Left:-1", "Right:1") var facing_direction: int = -1
@export var patrol_width: float = 100.0
@export var patrol_pause_seconds: float = 0.8
@export_group("Awareness")
## Standing/walking within this clear radius disturbs a sleeper. Crouching bypasses it.
@export var wake_proximity_radius: float = 140.0
@export var wake_seconds: float = 0.5
@export var detection_radius: float = 330.0
@export_range(1,360) var view_angle_degrees: float = 140.0
@export_range(0.1,1) var crouched_visibility_multiplier: float = 0.5
@export var awake_close_radius: float = 42.0
@export var hearing_multiplier: float = 1.0
@export_range(0,1) var obstructed_hearing_multiplier: float = 0.4
@export_group("Search and Movement")
@export var memory_seconds: float = 1.6
@export var search_seconds: float = 3.0
@export var pursuit_distance: float = 650.0
@export var avoid_ledges: bool = true
@export var personal_space: float = 34.0
@export_group("Attack")
@export var attack_trigger_range: float = 40.0
@export var attack_windup_seconds: float = 0.32
@export var attack_active_seconds: float = 0.10
@export var attack_recovery_seconds: float = 0.58
## Minimum start-to-start interval, also limited by the full attack duration.
@export var attack_interval: float = 1.1
@export var nearby_attack_spacing: float = 110.0
## Frames before and during contact; remaining frames play during recovery.
@export_range(0,64) var attack_windup_frames: int = 2
@export_range(1,64) var attack_contact_frames: int = 2
@export_group("Hit and Death")
@export var hit_reaction_seconds: float = 0.18
## Limits interruptions by repeated gunfire; damage still applies on every hit.
@export var stagger_cooldown_seconds: float = 0.85
@export var death_seconds: float = 0.6
@export var corpse_linger_seconds: float = 0.35
@export var leave_corpse: bool = false
@export_group("Animation Placeholders")
@export var use_sleep_placeholder_pose: bool = true
@export var use_attack_placeholder_pose: bool = true
@export var use_death_placeholder_pose: bool = true
var state: State = State.SLEEPING
var health: int
var home_x: float
var home_position := Vector2.ZERO
var direction := -1.0
var attack_cooldown := 0.0
var flash_remaining := 0.0
var hit_remaining := 0.0
var hit_visual_remaining := 0.0
var stagger_remaining := 0.0
var death_remaining := 0.0
var dead := false
var state_elapsed := 0.0
var memory_remaining := 0.0
var last_known_position := Vector2.ZERO
var attack_time := 0.0
var attack_facing := 1.0
var attack_contact_attempted := false
var patrol_pause_remaining := 0.0
var blocked_seconds := 0.0
var search_facing := -1.0
var visual_origin := Vector2.ZERO
var visual_scale := Vector2.ONE
@onready var body_art: CharacterVisuals = $Body
@onready var attack_pivot: Node2D = $AttackPivot
@onready var attack_hitbox: Area2D = $AttackPivot/Hitbox

func _ready() -> void:
    if Game.world.get(Game.object_id(self), false):
        queue_free()
        return
    health = max_health
    home_x = position.x
    home_position = global_position
    last_known_position = home_position
    direction = -1.0 if facing_direction < 0 else 1.0
    visual_origin = body_art.position
    visual_scale = body_art.scale
    add_to_group("enemy")
    Game.noise_emitted.connect(hear_noise)
    settle()
    update_visuals()

func state_name() -> String:
    return State.keys()[state].to_lower()

func is_attacking() -> bool:
    return state == State.ATTACK and not dead

func is_music_threat(player: Node2D) -> bool:
    return not dead and state in [State.WAKING,State.CHASE,State.ATTACK,State.RECOVER,State.HIT] and sees_player(player)

func change_state(next: State) -> void:
    if state == next:
        return
    var previous := state
    state = next
    state_elapsed = 0
    blocked_seconds = 0
    state_changed.emit(previous,state)

func settle() -> void:
    direction = -1.0 if facing_direction < 0 else 1.0
    memory_remaining = 0
    change_state([State.SLEEPING,State.IDLE,State.PATROL][clampi(initial_behaviour,0,2)])

func player_node() -> Node2D:
    return get_tree().get_first_node_in_group("player") as Node2D

func within_territory(point: Vector2) -> bool:
    return pursuit_distance <= 0 or absf(point.x-home_position.x) <= pursuit_distance

func clear_path(point: Vector2) -> bool:
    var query := PhysicsRayQueryParameters2D.create(global_position+Vector2(0,-12),point,1)
    query.exclude = [get_rid()]
    return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func sees_player(player: Node2D) -> bool:
    if player == null or not within_territory(player.global_position):
        return false
    var offset := player.global_position-global_position
    var radius := detection_radius * (crouched_visibility_multiplier if player.is_crouching else 1.0)
    if offset.length() > maxf(radius,awake_close_radius):
        return false
    if not clear_path(player.global_position+Vector2(0,10 if player.is_crouching else -12)):
        return false
    if offset.length() <= awake_close_radius:
        return true
    return Vector2(direction,0).dot(offset.normalized()) >= cos(deg_to_rad(view_angle_degrees/2))

func remember(point: Vector2) -> void:
    last_known_position = point
    memory_remaining = memory_seconds

func wake_towards(point: Vector2) -> void:
    remember(point)
    if not is_equal_approx(point.x,global_position.x):
        direction = signf(point.x-global_position.x)
    change_state(State.WAKING)
    body_art.play_state(&"wake",maxf(wake_seconds,0.01),true)

func hear_noise(origin: Vector2, radius: float, source: Node) -> void:
    if dead or Game.health <= 0 or Game.transitioning or get_tree().paused or source == self or not within_territory(origin):
        return
    if source != null:
        if not is_instance_valid(source):
            return
        if source is CanvasItem and source.get_world_2d() != get_world_2d():
            return
    var heard_radius := radius*hearing_multiplier
    if global_position.distance_to(origin) > heard_radius:
        return
    if not clear_path(origin):
        heard_radius *= obstructed_hearing_multiplier
    if global_position.distance_to(origin) > heard_radius:
        return
    remember(origin)
    if state == State.SLEEPING:
        wake_towards(origin)
    elif state not in [State.WAKING,State.ATTACK,State.RECOVER,State.HIT]:
        change_state(State.INVESTIGATE)

func sense(player: Node2D) -> void:
    if player == null:
        return
    if state == State.SLEEPING:
        if not player.is_crouching and global_position.distance_to(player.global_position) <= wake_proximity_radius and clear_path(player.global_position):
            wake_towards(player.global_position)
        return
    if sees_player(player):
        remember(player.global_position)
        if state not in [State.WAKING,State.ATTACK,State.RECOVER,State.HIT]:
            change_state(State.CHASE)

func begin_search() -> void:
    change_state(State.SEARCH)
    search_facing = direction

func attack_total_seconds() -> float:
    return maxf(0.01,attack_windup_seconds+attack_active_seconds+attack_recovery_seconds)

func attack_lane_available() -> bool:
    if nearby_attack_spacing <= 0:
        return true
    for other in get_tree().get_nodes_in_group("enemy"):
        if other != self and other.has_method("is_attacking") and other.is_attacking() and global_position.distance_to(other.global_position) < nearby_attack_spacing:
            return false
    return true

func begin_attack(player: Node2D) -> bool:
    if dead or player == null or attack_cooldown > 0 or not attack_lane_available():
        return false
    if not sees_player(player) or global_position.distance_to(player.global_position) > attack_trigger_range:
        return false
    attack_facing = -1.0 if player.global_position.x < global_position.x else 1.0
    direction = attack_facing
    attack_pivot.scale.x = attack_facing
    attack_time = 0
    attack_contact_attempted = false
    attack_cooldown = maxf(attack_interval,attack_total_seconds())
    change_state(State.ATTACK)
    body_art.play_state(&"attack",attack_total_seconds(),true)
    return true

func update_attack(delta: float, player: Node2D) -> void:
    var previous := attack_time
    attack_time += delta
    var active_end := attack_windup_seconds+attack_active_seconds
    # A missed swing stays a miss; the strike never follows the player mid-attack.
    if not attack_contact_attempted and previous < active_end and attack_time >= attack_windup_seconds and player != null:
        if attack_hitbox.overlaps_body(player) and clear_path(player.global_position):
            attack_contact_attempted = true
            player.take_damage(damage)
    if state == State.ATTACK and attack_time >= active_end:
        change_state(State.RECOVER)
    if attack_time >= attack_total_seconds() and attack_cooldown <= 0:
        if player != null and sees_player(player):
            change_state(State.CHASE)
        else:
            begin_search()

func _physics_process(delta: float) -> void:
    if dead:
        update_death(delta)
        return
    if Game.health <= 0 or Game.transitioning:
        velocity.x = 0
        return
    state_elapsed += delta
    attack_cooldown = maxf(0,attack_cooldown-delta)
    flash_remaining = maxf(0,flash_remaining-delta)
    hit_remaining = maxf(0,hit_remaining-delta)
    hit_visual_remaining = maxf(0,hit_visual_remaining-delta)
    stagger_remaining = maxf(0,stagger_remaining-delta)
    memory_remaining = maxf(0,memory_remaining-delta)
    patrol_pause_remaining = maxf(0,patrol_pause_remaining-delta)
    var player := player_node()
    sense(player)
    var movement := 0.0
    match state:
        State.WAKING:
            if state_elapsed >= wake_seconds:
                change_state(State.CHASE if sees_player(player) else State.INVESTIGATE)
        State.PATROL:
            if absf(global_position.x-home_position.x) >= maxf(patrol_width,4) and (global_position.x-home_position.x)*direction > 0:
                direction = signf(home_position.x-global_position.x)
                patrol_pause_remaining = patrol_pause_seconds
            if patrol_pause_remaining <= 0:
                movement = direction*speed*0.4
        State.INVESTIGATE:
            if absf(last_known_position.x-global_position.x) <= 10 or state_elapsed > search_seconds+memory_seconds:
                begin_search()
            else:
                direction = signf(last_known_position.x-global_position.x)
                movement = direction*speed*0.65
        State.CHASE:
            if not within_territory(global_position) or memory_remaining <= 0:
                begin_search()
            elif absf(last_known_position.x-global_position.x) <= attack_trigger_range and sees_player(player):
                begin_attack(player)
            elif absf(last_known_position.x-global_position.x) <= 8:
                begin_search()
            else:
                direction = signf(last_known_position.x-global_position.x)
                movement = direction*speed
        State.ATTACK, State.RECOVER:
            update_attack(delta,player)
        State.SEARCH:
            direction = search_facing if state_elapsed < search_seconds/2 else -search_facing
            if state_elapsed >= search_seconds:
                change_state(State.RETURN_HOME)
        State.RETURN_HOME:
            if absf(home_position.x-global_position.x) <= 8:
                settle()
            else:
                direction = signf(home_position.x-global_position.x)
                movement = direction*speed*0.55
        State.HIT:
            if hit_remaining <= 0:
                change_state(State.CHASE if sees_player(player) else State.INVESTIGATE)
    move_ground(movement,delta)
    update_visuals()

func move_ground(movement: float, delta: float) -> void:
    if movement != 0:
        for other in get_tree().get_nodes_in_group("enemy"):
            if other != self and absf(other.global_position.y-global_position.y) < 40:
                var separation: float = other.global_position.x-global_position.x
                if absf(separation) < personal_space and separation*movement > 0:
                    movement = 0
                    break
    var requested := movement
    if avoid_ledges and is_on_floor() and movement != 0:
        var probe := global_position+Vector2(signf(movement)*24,16)
        var ground := PhysicsRayQueryParameters2D.create(probe,probe+Vector2(0,44),1)
        if get_world_2d().direct_space_state.intersect_ray(ground).is_empty():
            movement = 0
    velocity.x = movement
    velocity.y += 1050.0*delta
    move_and_slide()
    blocked_seconds = blocked_seconds+delta if requested != 0 and absf(get_real_velocity().x) < 1 else 0.0
    if blocked_seconds > 0.7:
        if state == State.PATROL:
            direction *= -1
            patrol_pause_remaining = patrol_pause_seconds
            blocked_seconds = 0
        elif state in [State.CHASE,State.INVESTIGATE]:
            begin_search()

func update_visuals() -> void:
    body_art.position = visual_origin
    body_art.scale.y = visual_scale.y
    body_art.modulate = Color(1.5,0.8,0.7) if flash_remaining > 0 else Color.WHITE
    body_art.flip_h = direction < 0
    if state not in [State.ATTACK,State.RECOVER]:
        attack_pivot.scale.x = direction
    if state == State.SLEEPING:
        body_art.play_state(&"sleep")
        if use_sleep_placeholder_pose:
            body_art.scale.y = visual_scale.y * 0.72
    elif state == State.WAKING:
        body_art.play_state(&"wake",maxf(wake_seconds,0.01))
        if use_sleep_placeholder_pose:
            body_art.scale.y = visual_scale.y * lerpf(0.72,1.0,clampf(state_elapsed/maxf(wake_seconds,0.01),0,1))
    elif state in [State.ATTACK,State.RECOVER]:
        sync_attack_pose()
        if use_attack_placeholder_pose:
            var offset := 0.0
            if attack_time < attack_windup_seconds:
                offset = -2*attack_time/maxf(attack_windup_seconds,0.01)
            elif attack_time < attack_windup_seconds+attack_active_seconds:
                offset = 6
            else:
                offset = lerpf(6.0,0.0,clampf((attack_time-attack_windup_seconds-attack_active_seconds)/maxf(attack_recovery_seconds,0.01),0,1))
            body_art.position.x += attack_facing*offset
    elif state == State.HIT or hit_visual_remaining > 0:
        pass
    else:
        body_art.play_state(&"walk" if absf(velocity.x) > 5 else &"idle")

func take_damage(amount: int) -> void:
    if dead or amount <= 0:
        return
    $HurtSound.play()
    health = maxi(0,health-amount)
    flash_remaining = 0.15
    if health <= 0:
        dead = true
        change_state(State.DEAD)
        velocity = Vector2.ZERO
        hit_remaining = 0
        flash_remaining = 0
        body_art.position = visual_origin
        body_art.scale.y = visual_scale.y
        body_art.modulate = Color.WHITE
        Game.world[Game.object_id(self)] = true
        remove_from_group("enemy")
        collision_layer = 0
        collision_mask = 0
        $CollisionShape2D.set_deferred("disabled",true)
        attack_hitbox.set_deferred("monitoring",false)
        death_remaining = death_seconds+corpse_linger_seconds
        body_art.play_state(&"death",maxf(death_seconds,0.01),true)
        return
    var player := player_node()
    if player != null:
        remember(player.global_position)
        if player.global_position.x != global_position.x and (state not in [State.ATTACK,State.RECOVER] or stagger_remaining <= 0):
            direction = signf(player.global_position.x-global_position.x)
    if stagger_remaining <= 0 or state in [State.SLEEPING,State.WAKING]:
        stagger_remaining = stagger_cooldown_seconds
        hit_remaining = maxf(hit_reaction_seconds,0.01)
        change_state(State.HIT)
        body_art.play_state(&"hit",hit_remaining,true)
    elif state not in [State.ATTACK,State.RECOVER,State.HIT]:
        hit_visual_remaining = maxf(hit_reaction_seconds,0.01)
        body_art.play_state(&"hit",hit_visual_remaining,true)

func update_death(delta: float) -> void:
    death_remaining = maxf(0,death_remaining-delta)
    if use_death_placeholder_pose:
        body_art.scale.y = visual_scale.y * lerpf(0.18,1.0,clampf((death_remaining-corpse_linger_seconds)/maxf(death_seconds,0.01),0,1))
    if death_remaining <= corpse_linger_seconds:
        body_art.stop()
        if body_art.has_state(&"death"):
            body_art.animation = &"death"
            body_art.frame = body_art.sprite_frames.get_frame_count(&"death")-1
    if death_remaining <= 0 and not leave_corpse:
        queue_free()

func sync_attack_pose() -> void:
    if not body_art.has_state(&"attack"):
        return
    var count := body_art.sprite_frames.get_frame_count(&"attack")
    var windup := clampi(attack_windup_frames,0,count-1)
    var contact := clampi(attack_contact_frames,1,count-windup)
    var start := 0
    var length := windup
    var progress := attack_time/maxf(attack_windup_seconds,0.001)
    if attack_time >= attack_windup_seconds+attack_active_seconds:
        start = windup+contact
        length = count-start
        progress = (attack_time-attack_windup_seconds-attack_active_seconds)/maxf(attack_recovery_seconds,0.001)
    elif attack_time >= attack_windup_seconds:
        start = windup
        length = contact
        progress = (attack_time-attack_windup_seconds)/maxf(attack_active_seconds,0.001)
    var position_in_phase := clampf(progress,0,0.9999)*length
    var frame_index := clampi(start+int(position_in_phase),0,count-1)
    body_art.pause()
    body_art.set_frame_and_progress(frame_index,fmod(position_in_phase,1.0))
