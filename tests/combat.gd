extends Node
var checks := 0
var failures := 0

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

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    for index in Game.SAVE_SLOT_COUNT:
        if FileAccess.file_exists(Game.slot_path(index)):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(index)))
    Game.reset_run()
    preload("res://tests/support/loadout.gd").handgun()
    var level: Node2D = load("res://tests/fixtures/combat_sandbox.tscn").instantiate()
    get_tree().root.add_child(level)
    get_tree().current_scene = level
    await frames(8)
    var player: CharacterBody2D = level.get_node("Actors/Player")
    var body: CharacterVisuals = player.get_node("Body")
    var enemy: CharacterBody2D = level.get_node("Actors/Enemy")
    var hud: CanvasLayer = level.get_node("HUD")
    check(not player.has_method("melee") and not player.has_node("MeleeArc") and not InputMap.has_action("melee"), "Melee code, graphic and input binding are removed")
    check(InputMap.action_get_events("sprint").any(func(event): return event is InputEventKey and event.physical_keycode == KEY_SHIFT), "Shift is bound to sprint")
    check(InputMap.action_get_events("crouch").any(func(event): return event is InputEventKey and event.physical_keycode == KEY_CTRL), "Control is bound to crouch")
    for state in [&"idle",&"walk",&"sprint",&"jump",&"fall",&"crouch_idle",&"crouch_walk",&"dodge"]:
        check(body.has_state(state), "Player animation is editable: " + str(state))
    check(body.sprite_frames.get_frame_texture("idle",0).get_size() == Vector2(32,40) and enemy.get_node("Body").sprite_frames.get_frame_texture("idle",0).get_size() == Vector2(32,40), "Player and enemy use matching native 32 by 40 frames at 2x scale")
    check(body.animation == &"idle" and player.is_on_floor(), "Player lands in the idle animation")
    Input.action_press("move_right")
    await frames(18)
    check(body.animation == &"walk" and is_equal_approx(player.velocity.x,player.move_speed), "Movement plays the walk animation")
    Input.action_press("sprint")
    await frames(24)
    check(player.is_sprinting and body.animation == &"sprint" and is_equal_approx(player.velocity.x,player.move_speed*player.sprint_multiplier), "Held sprint increases speed and selects sprint animation")
    Input.action_press("aim")
    await frames(18)
    check(not player.is_sprinting and body.animation == &"aim_walk" and player.velocity.x <= player.move_speed*player.aiming_move_multiplier+1, "Aiming overrides sprint with careful movement")
    Input.action_release("move_right")
    Input.action_release("sprint")
    Input.action_release("aim")
    await frames(12)
    Input.action_press("jump")
    await frames(3)
    Input.action_release("jump")
    check(body.animation == &"jump" and player.velocity.y < 0, "Takeoff selects the jump animation")
    check(not player.begin_dodge(1), "Short dodge cannot be started in midair")
    await frames(maxi(1,ceili(absf(player.jump_velocity)/player.gravity*60)-3+4))
    check(body.animation == &"fall" and player.velocity.y > 0, "Descending selects the fall animation")
    await frames(35)
    check(body.animation == &"idle" and player.is_on_floor(), "Landing returns to idle")
    var feet: float = player.global_position.y + player.get_node("CollisionShape2D").position.y + player.get_node("CollisionShape2D").shape.height/2
    Input.action_press("crouch")
    await frames()
    var crouch_feet: float = player.global_position.y + player.get_node("CollisionShape2D").position.y + player.get_node("CollisionShape2D").shape.height/2
    check(player.is_crouching and body.animation == &"crouch_idle" and player.get_node("CollisionShape2D").shape.height == player.crouch_height, "Crouch changes both animation and actual collision height")
    check(is_equal_approx(feet,crouch_feet) and player.get_node("Aim").position.y > player.standing_aim_position.y, "Crouching keeps feet planted and lowers gun/flashlight together")
    check(not player.begin_dodge(1), "Dodge does not stand the player up while crouched")
    Input.action_press("sprint")
    Input.action_press("move_right")
    await frames(8)
    check(not player.is_sprinting and body.animation == &"crouch_walk" and player.velocity.x <= player.move_speed*player.crouch_speed_multiplier+1, "Crouch walking stays slow even with sprint held")
    Input.action_release("crouch")
    Input.action_release("sprint")
    Input.action_release("move_right")
    player.global_position = Vector2(500,588)
    player.velocity = Vector2.ZERO
    await frames()
    Input.action_press("move_right")
    await frames(20)
    check(player.position.x < 509 and not player.is_crouching, "Standing collision cannot enter the authored low passage")
    Input.action_press("crouch")
    await frames(ceili(110/(player.move_speed*player.crouch_speed_multiplier)*60))
    check(player.position.x > 580 and player.is_crouching, "Crouched collision can pass under the ceiling")
    Input.action_release("crouch")
    await frames()
    check(player.is_crouching and not player.can_stand(), "Releasing crouch under a ceiling safely keeps the smaller capsule")
    Input.action_release("move_right")
    player.global_position = Vector2(760,588)
    player.velocity = Vector2.ZERO
    await frames()
    check(not player.is_crouching and player.get_node("CollisionShape2D").shape.height == player.standing_shape.height, "Standing height restores after clearing the ceiling")
    Game.health = 100
    player.set_physics_process(false)
    check(player.begin_dodge(1), "Grounded player can start a short dodge")
    check(player.invulnerable_remaining == player.dodge_invulnerability_seconds and player.dodge_seconds < 0.3, "Dodge exposes a brief duration and a separate shorter invulnerability")
    player._physics_process(player.dodge_invulnerability_seconds-0.001)
    player.take_damage(10)
    check(Game.health == 100 and body.animation == &"dodge", "Dodge animation and invulnerability are active before the boundary")
    player._physics_process(0.002)
    player.take_damage(10)
    check(Game.health == 90 and player.dodge_remaining > 0, "Damage resumes after invulnerability, before the dodge motion finishes")
    player._physics_process(player.dodge_seconds)
    player.set_physics_process(true)
    await frames(40)
    Game.health = 100
    var start_x: float = player.position.x
    Input.action_press("dodge")
    await frames(2)
    Input.action_release("dodge")
    check(body.animation == &"dodge" and not player.begin_dodge(1), "Dodge plays its clip and rejects repeat activation during cooldown")
    await frames(16)
    check(player.position.x-start_x > 35 and player.position.x-start_x < 60 and player.invulnerable_remaining == 0, "Actual dodge travels a short step instead of the former long dash")
    player.global_position = Vector2(14,588)
    player.velocity = Vector2.ZERO
    player.dodge_cooldown = 0
    await frames()
    player.begin_dodge(-1)
    await frames(16)
    check(player.position.x >= 11.8, "Dodge still respects world collision")
    var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
    check(not menu.has_node("Controls") and not hud.has_node("Root/ControlsPanel") and not hud.has_node("Root/PausePanel/Controls"), "Menu and pause control legends are removed")
    menu.free()
    check(hud.get_node("Root/InventoryPanel/Help").text.is_empty() and hud.get_node("Root/InventoryPanel/Rotate").text == "Rotate", "Inventory uses plain button labels without control instructions")
    var bike: Area2D = level.get_node("Interactables/SaveBicycle")
    player.global_position = bike.global_position + Vector2(-40,-32)
    player.velocity = Vector2.ZERO
    await frames()
    check(Game.save_slot(0,bike), "Earlier save records the living enemy")
    player.global_position = Vector2(1050,588)
    enemy.global_position = Vector2(1170,588)
    player.velocity = Vector2.ZERO
    enemy.velocity = Vector2.ZERO
    await frames()
    player.set_physics_process(false)
    player.aim.rotation = 0
    Input.action_press("aim")
    player.shoot()
    Input.action_release("aim")
    check(enemy.health == enemy.max_health-player.bullet_damage and enemy.get_node("Body").animation == &"hit", "A real gun ray damages the new enemy and starts its hit animation")
    var hit_x: float = enemy.position.x
    await frames(5)
    check(is_equal_approx(enemy.position.x,hit_x), "Hit reaction briefly interrupts enemy movement")
    await frames(16)
    check(enemy.get_node("Body").animation == &"walk" and enemy.position.x < hit_x, "Enemy resumes chasing after its hit reaction")
    enemy.leave_corpse = true
    for i in 2:
        player.shot_cooldown = 0
        player.aim.rotation = 0
        Input.action_press("aim")
        player.shoot()
        Input.action_release("aim")
    check(enemy.dead and enemy.health == 0 and enemy.get_node("Body").animation == &"death", "Lethal gun damage plays the death animation before removal")
    check(enemy.collision_layer == 0 and not enemy.is_in_group("enemy") and Game.world.get(Game.object_id(enemy),false), "Death immediately disables combat and records persistent defeat")
    var health_after: int = Game.health
    enemy.take_damage(100)
    await get_tree().create_timer(enemy.death_seconds+enemy.corpse_linger_seconds+0.1).timeout
    check(is_instance_valid(enemy) and enemy.get_node("Body").frame == enemy.get_node("Body").sprite_frames.get_frame_count("death")-1 and Game.health == health_after, "Optional corpse holds the last death frame and cannot attack or take more damage")
    player.set_physics_process(true)
    player.global_position = bike.global_position + Vector2(-40,-32)
    player.velocity = Vector2.ZERO
    await frames()
    check(Game.save_slot(1,bike) and Game.load_slot(0), "Later save records defeat independently; earlier slot can be loaded")
    await frames(10)
    level = get_tree().current_scene
    check(level.has_node("Actors/Enemy") and not level.get_node("Actors/Enemy").dead, "Earlier save restores the living enemy")
    check(Game.load_slot(1), "Later defeated-enemy save can be loaded")
    await frames(10)
    level = get_tree().current_scene
    check(not level.has_node("Actors/Enemy"), "Later save removes the defeated enemy instead of replaying death")
    var fallback: CharacterBody2D = load("res://scenes/actors/enemy.tscn").instantiate()
    fallback.name = "MissingClipEnemy"
    fallback.position = Vector2(1000,588)
    fallback.get_node("Body").sprite_frames = fallback.get_node("Body").sprite_frames.duplicate(true)
    fallback.get_node("Body").sprite_frames.remove_animation("hit")
    fallback.get_node("Body").sprite_frames.remove_animation("death")
    level.get_node("Actors").add_child(fallback)
    fallback.take_damage(1)
    check(fallback.get_node("Body").animation == &"idle", "Missing hit artwork uses a safe idle fallback")
    fallback.take_damage(100)
    await get_tree().create_timer(fallback.death_seconds+fallback.corpse_linger_seconds+0.1).timeout
    check(not is_instance_valid(fallback), "Missing death artwork cannot leave a live or immortal enemy behind")
    for audio in level.find_children("*", "AudioStreamPlayer", true, false):
        audio.stop()
    for audio in level.find_children("*", "AudioStreamPlayer2D", true, false):
        audio.stop()
    GameAudio.stop_all()
    await get_tree().create_timer(0.2).timeout
    level.queue_free()
    get_tree().current_scene = null
    await get_tree().create_timer(0.2).timeout
    print("IGNOTUM COMBAT: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures == 0 else 1)
