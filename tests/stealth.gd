extends Node
var checks := 0
var failures := 0
var level: Node2D
var player: CharacterBody2D
var serial := 0

func check(ok: bool, description: String) -> void:
    checks += 1
    if ok: print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)

func frames(count: int = 3) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame

func place_player(point: Vector2, crouched: bool = false) -> void:
    for foe in get_tree().get_nodes_in_group("enemy"):
        foe.set_physics_process(false)
    player.set_physics_process(true)
    for action in ["move_left","move_right","sprint","jump","dodge","aim","shoot","crouch"]:
        Input.action_release(action)
    if crouched:
        Input.action_press("crouch")
    player.position = point
    player.velocity = Vector2.ZERO
    player.invulnerable_remaining = 0
    player.dodge_remaining = 0
    player.dodge_cooldown = 0
    player.footstep_remaining = 0
    Game.health = 100
    await frames()

func add_foe(point: Vector2, behaviour: int = 0, settings: Dictionary = {}) -> CharacterBody2D:
    var foe: CharacterBody2D = load("res://scenes/actors/enemy.tscn").instantiate()
    serial += 1
    foe.name = "TestEnemy%d" % serial
    foe.position = point
    foe.initial_behaviour = behaviour
    foe.facing_direction = 1
    for key in settings:
        foe.set(key,settings[key])
    level.get_node("Actors").add_child(foe)
    await frames()
    return foe

func fresh_foe(point: Vector2, behaviour: int = 0, settings: Dictionary = {}) -> CharacterBody2D:
    for foe in get_tree().get_nodes_in_group("enemy"):
        foe.queue_free()
    await frames(2)
    return await add_foe(point,behaviour,settings)

func wall(enabled: bool, x: float = 1050) -> void:
    $SightWall.position.x = x
    $SightWall/Shape.set_deferred("disabled",not enabled)
    await frames()

func prepare_attack() -> CharacterBody2D:
    await wall(false)
    await place_player(Vector2(1040,588))
    var foe := await fresh_foe(Vector2(1000,588),1,{"max_health":500})
    foe.set_physics_process(false)
    player.set_physics_process(false)
    foe.attack_time = 0
    foe.attack_contact_attempted = false
    return foe

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    Game.reset_run()
    level = load("res://tests/fixtures/combat_sandbox.tscn").instantiate()
    get_tree().root.add_child(level)
    get_tree().current_scene = level
    await frames(8)
    player = level.get_node("Actors/Player")
    var default_foe: CharacterBody2D = level.get_node("Actors/Enemy")
    check(default_foe.state == default_foe.State.SLEEPING and default_foe.get_node("Body").animation == &"sleep", "Base enemy starts in an editable sleeping animation")
    check(default_foe.get_node("Body").has_state(&"wake") and default_foe.get_node("Body").has_state(&"attack"), "Wake and attack animation slots exist")
    await place_player(Vector2(750,588),true)
    var foe := await fresh_foe(Vector2(850,588))
    var rounds: int = Game.magazine
    Input.action_press("move_right")
    await frames(ceili(215/(player.move_speed*player.crouch_speed_multiplier)*60))
    Input.action_release("move_right")
    await frames(6)
    check(player.position.x > foe.position.x+100 and foe.state == foe.State.SLEEPING and Game.health == 100, "Actual crouch movement passes completely through a sleeping enemy without waking it")
    check(Game.magazine == rounds, "Quiet bypass spends no ammunition")
    Input.action_release("crouch")
    await frames()
    check(foe.state == foe.State.WAKING and Game.health == 100, "Standing up nearby wakes the sleeper with a safe warning phase")
    await frames(38)
    check(foe.state == foe.State.CHASE and foe.get_node("Body").animation == &"walk", "After waking the enemy sees and pursues the player")
    Input.action_press("crouch")
    await frames()
    check(foe.state != foe.State.SLEEPING, "Crouching after detection does not instantly erase hostility")
    await place_player(Vector2(850,588))
    foe = await fresh_foe(Vector2(1150,588))
    Input.action_press("move_right")
    Input.action_press("sprint")
    await frames(30)
    check(player.position.distance_to(foe.position) > foe.wake_proximity_radius and foe.state != foe.State.SLEEPING, "Real sprint footsteps wake a sleeper beyond standing proximity")
    await place_player(Vector2(250,588),true)
    foe = await fresh_foe(Vector2(850,588))
    player.set_physics_process(false)
    player.aim.rotation = -PI/2
    Game.magazine = 0
    player.shot_cooldown = 0
    Input.action_press("aim")
    player.shoot()
    check(foe.state == foe.State.SLEEPING, "An empty magazine does not emit a gunshot hearing event")
    Game.magazine = 1
    player.shot_cooldown = 0
    player.shoot()
    check(foe.state == foe.State.WAKING and foe.health == foe.max_health, "A real crouched gunshot wakes distant enemies even when its ray misses")
    Input.action_release("aim")
    Game.magazine = 6
    await place_player(Vector2(800,588),true)
    foe = await fresh_foe(Vector2(850,588))
    Game.add_item("ammo",3)
    Game.magazine = 3
    player.reload_weapon()
    check(foe.state == foe.State.WAKING, "Reload noise can disturb a nearby enemy while the player crouches")
    player.reload_remaining = 0
    Game.magazine = 6
    await wall(true)
    await place_player(Vector2(1200,588),true)
    foe = await fresh_foe(Vector2(1000,588))
    Game.emit_noise(player.global_position,300,player)
    check(foe.state == foe.State.SLEEPING, "A wall attenuates hearing instead of allowing full-strength sound through it")
    Game.emit_noise(player.global_position,600,player)
    check(foe.state == foe.State.WAKING, "A louder sound can still be heard through a wall")
    await frames(38)
    check(foe.state in [foe.State.INVESTIGATE,foe.State.SEARCH] and not foe.sees_player(player), "An unseen disturbance causes investigation rather than tracking through walls")
    await place_player(Vector2(900,588))
    foe = await fresh_foe(Vector2(1000,588),1)
    check(foe.state == foe.State.IDLE and not foe.sees_player(player), "An awake guard has a facing-dependent vision cone")
    foe.direction = -1
    await frames()
    check(foe.state == foe.State.CHASE, "Turning toward an exposed player acquires the target")
    await place_player(Vector2(780,588),true)
    foe = await fresh_foe(Vector2(1000,588),1,{"facing_direction":-1})
    check(foe.state == foe.State.IDLE, "Crouching reduces an awake enemy's visual detection range")
    Input.action_release("crouch")
    await frames()
    check(foe.state == foe.State.CHASE, "Standing in the same exposed place becomes visible")
    await place_player(Vector2(900,588),true)
    foe = await fresh_foe(Vector2(1000,588),1,{"facing_direction":-1})
    check(foe.state == foe.State.CHASE, "An awake enemy can still see a crouched player in front at close range")
    await place_player(Vector2(1100,588))
    foe = await fresh_foe(Vector2(1000,588),1)
    check(foe.state == foe.State.IDLE and not foe.sees_player(player), "Solid geometry blocks vision despite proximity")
    await wall(false)
    check(foe.state == foe.State.CHASE, "Removing the obstruction exposes the player")
    await place_player(Vector2(1150,588))
    foe = await fresh_foe(Vector2(950,588),1,{"memory_seconds":0.2,"search_seconds":0.3,"speed":180.0})
    check(foe.state == foe.State.CHASE, "Visible target establishes chase memory")
    await wall(true)
    Input.action_press("crouch")
    await frames(16)
    check(foe.state == foe.State.SEARCH, "Lost sight and expired memory lead to a search")
    await frames(60)
    check(foe.state == foe.State.IDLE and absf(foe.position.x-foe.home_position.x) <= 8, "Unsuccessful search returns the enemy to its original post")
    await wall(false)
    await place_player(Vector2(650,588))
    foe = await fresh_foe(Vector2(950,588),1,{"pursuit_distance":120.0,"facing_direction":-1})
    check(foe.state == foe.State.IDLE, "Territory limits prevent unlimited pursuit across a level")
    await place_player(Vector2(300,588),true)
    foe = await fresh_foe(Vector2(2000,588),2,{"patrol_width":20.0,"patrol_pause_seconds":0.1,"speed":150.0})
    await frames(100)
    check(absf(foe.position.x-2000) < 24 and foe.state == foe.State.PATROL, "Patrol turns at its boundaries and resumes after its pause")
    foe = await fresh_foe(Vector2(2000,588),2,{"patrol_width":200.0,"patrol_pause_seconds":0.05,"speed":150.0})
    await frames(180)
    check(foe.is_on_floor() and foe.position.x > 1950 and foe.position.x < 2050, "Ground probes prevent patrols walking off an authored platform")
    await place_player(Vector2(1000,588))
    foe = await fresh_foe(Vector2(965,588),1)
    var second := await add_foe(Vector2(1035,588),1,{"facing_direction":-1})
    check(foe.state == foe.State.ATTACK and second.state != second.State.ATTACK, "Nearby enemies stagger their attack starts instead of all striking at once")
    foe = await prepare_attack()
    check(foe.state == foe.State.ATTACK and foe.get_node("Body").animation == &"attack", "Entering range starts a committed attack animation")
    foe._physics_process(0.31)
    check(Game.health == 100, "Standing inside the hitbox during wind-up causes no contact damage")
    foe._physics_process(0.02)
    check(Game.health == 100-foe.damage, "The authored attack hitbox applies damage during its active window")
    foe._physics_process(0.04)
    check(Game.health == 100-foe.damage, "One attack attempts contact only once")
    foe._physics_process(0.1)
    check(foe.state == foe.State.RECOVER and Game.health == 100-foe.damage, "Recovery has no lingering touch damage")
    foe = await prepare_attack()
    player.position.x = 950
    await frames()
    foe._physics_process(0.33)
    check(Game.health == 100 and foe.attack_pivot.scale.x == 1 and not foe.get_node("Body").flip_h, "A committed swing cannot turn around to hit a player behind it")
    foe = await prepare_attack()
    player.position.x = 1150
    await frames()
    var attack_origin: Vector2 = foe.global_position
    foe._physics_process(0.33)
    check(Game.health == 100 and foe.global_position == attack_origin, "Leaving the hitbox makes an attack miss without a homing lunge")
    foe = await prepare_attack()
    player.dodge_cooldown = 0
    player.begin_dodge(1)
    foe._physics_process(0.33)
    check(Game.health == 100 and foe.attack_contact_attempted, "Dodge invulnerability defeats a timed enemy strike")
    player.invulnerable_remaining = 0
    foe._physics_process(0.05)
    check(Game.health == 100, "A dodged strike is consumed rather than repeatedly damaging the player")
    foe = await prepare_attack()
    player.position.x = 1045
    await wall(true,1028)
    foe._physics_process(0.33)
    check(foe.attack_hitbox.overlaps_body(player) and Game.health == 100, "Even an overlapping attack hitbox cannot damage through a solid wall")
    foe = await prepare_attack()
    foe.take_damage(10)
    foe._physics_process(0.4)
    check(Game.health == 100 and foe.state != foe.State.ATTACK, "A fresh stagger interrupts and cancels a pending strike")
    foe.attack_cooldown = 0
    foe.begin_attack(player)
    foe.take_damage(10)
    check(foe.state == foe.State.ATTACK and foe.health == foe.max_health-20, "Stagger resistance prevents repeated gunfire cancelling every swing while still applying damage")
    foe.take_damage(1000)
    foe._physics_process(0.33)
    check(foe.dead and Game.health == 100, "Death cancels a pending attack permanently")
    foe = await prepare_attack()
    foe.get_node("Body").sprite_frames = foe.get_node("Body").sprite_frames.duplicate(true)
    foe.get_node("Body").sprite_frames.remove_animation("attack")
    foe.attack_cooldown = 0
    foe.change_state(foe.State.CHASE)
    foe.begin_attack(player)
    foe._physics_process(0.33)
    check(foe.get_node("Body").animation == &"idle" and Game.health == 100-foe.damage, "Missing attack art safely falls back while timed combat remains functional")
    await wall(false)
    Input.action_release("crouch")
    player.set_physics_process(true)
    Game.health = 100
    player.get_node("HurtSound").stop()
    player.get_node("ShotSound").stop()
    # Let the audio server release playback before the test tears down its scene.
    await frames(6)
    level.queue_free()
    get_tree().current_scene = null
    await frames()
    print("IGNOTUM STEALTH: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures == 0 else 1)
