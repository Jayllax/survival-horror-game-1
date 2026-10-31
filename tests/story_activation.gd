extends Node
const FIXTURE := "res://tests/fixtures/story_activation_sandbox.tscn"
const FLAG := "story:spoke_to_jax_1"
var checks := 0
var failures := 0
var room: Node2D
var player: CharacterBody2D
var enemy: CharacterBody2D

func check(ok: bool, label: String) -> void:
    checks += 1
    if ok:
        print("PASS: " + label)
    else:
        failures += 1
        push_error("FAIL: " + label)

func frames(count: int = 4) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame

func refresh() -> void:
    room = get_tree().current_scene
    player = room.get_node("Actors/Player")
    enemy = room.get_node_or_null("Actors/Enemy")

func enter(path: String, spawn: String = "default") -> void:
    await Transition.travel(path, spawn)
    refresh()
    await frames()

func set_flag(value: bool, id: String = FLAG) -> void:
    Game.world[id] = value
    Game.changed.emit()
    await frames()

func enemy_ray() -> Dictionary:
    var point := enemy.global_position + Vector2(0, -12)
    var ray := PhysicsRayQueryParameters2D.create(point + Vector2(-40, 0), point + Vector2(40, 0), 4)
    return room.get_world_2d().direct_space_state.intersect_ray(ray)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    Game.reset_run()
    await enter(FIXTURE, "from_alleyway_02")
    await verify_inactive_enemy()
    await verify_dialogue_completion()
    await enter(FIXTURE, "from_house_03_2")
    await verify_reactivation()
    await verify_opposite_and_child_controller()
    await verify_save_slots_and_defeat()
    GameAudio.stop_all()
    for audio in room.find_children("*", "AudioStreamPlayer", true, false):
        audio.stop()
    for audio in room.find_children("*", "AudioStreamPlayer2D", true, false):
        audio.stop()
    room.queue_free()
    await get_tree().create_timer(0.2).timeout
    print("IGNOTUM STORY ACTIVATION: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)

func verify_inactive_enemy() -> void:
    check(not enemy.visible and not enemy.story_active and enemy.process_mode == Node.PROCESS_MODE_DISABLED, "The real house_03_1 enemy starts hidden with its AI disabled until Jax's flag is set")
    check(not enemy.is_in_group("enemy") and not enemy.is_attacking() and not enemy.is_music_threat(player), "An inactive enemy participates in neither combat spacing nor danger music")
    check(enemy_ray().is_empty(), "The inactive enemy is absent from physics raycasts and cannot block bullets invisibly")
    var initial_health: int = enemy.health
    var initial_state: int = enemy.state
    Game.emit_noise(enemy.global_position, 1000, player)
    enemy.take_damage(30)
    check(enemy.health == initial_health and enemy.state == initial_state and not enemy.get_node("HurtSound").playing, "Signals and direct damage calls cannot wake or hurt the inactive enemy")
    check(not enemy.begin_attack(player), "A direct attack request cannot start an inactive enemy")
    var point := enemy.global_position
    player.global_position = point + Vector2(20, 0)
    player.velocity = Vector2.ZERO
    await frames(65)
    check(Game.health == 100 and enemy.global_position == point and enemy.state == initial_state, "Standing inside the hidden enemy for a full second causes no attack or movement")
    enemy.update_attack(1.0, player)
    enemy._physics_process(1.0)
    check(Game.health == 100 and enemy.global_position == point, "Manual AI updates cannot bypass story deactivation either")
    var condition: WorldFlagCondition = room.get_node("WorldFlagCondition")
    check(condition.activate_when_met == [NodePath("../Actors/Enemy")] and condition.visible_when_met.is_empty() and condition.enable_collision_when_met.is_empty(), "The uploaded house condition uses the whole enemy activation target instead of the three incorrect slots")

func verify_dialogue_completion() -> void:
    await enter("res://scenes/levels/house_03_2.tscn", "from_house_03_1")
    var npc: Area2D = room.get_node("Actors/NPC")
    var ui: Control = room.get_node("HUD/StoryUI")
    ui.characters_per_second = 0
    check(npc.completion_flag == FLAG and not bool(Game.world.get(FLAG, false)), "The uploaded Jax completion flag matches the enemy's activation condition")
    check(room.get_node("HUD").show_dialogue(npc.dialogue, npc), "The newest authored and voiced Jax conversation opens normally")
    var guard := 0
    var stayed_unset := true
    while ui.is_dialogue() and guard < 80:
        stayed_unset = stayed_unset and not bool(Game.world.get(FLAG, false))
        if not ui.active_choices.is_empty():
            ui.select_choice(0)
        else:
            ui.advance()
        guard += 1
    check(stayed_unset, "No original line or nested branch sets Jax's completion flag prematurely")
    check(not ui.is_open() and bool(Game.world.get(FLAG, false)), "Finishing all Jax lines and nested branches sets the actual activation flag")
    check(room.get_node("Interactables/LootContainer").visible, "The same flag still reveals the designer's existing loot container normally")

func verify_reactivation() -> void:
    check(enemy.visible and enemy.story_active and enemy.process_mode == Node.PROCESS_MODE_INHERIT and enemy.is_in_group("enemy"), "Returning from Jax restores enemy visibility, processing and enemy membership")
    check(enemy_ray().get("collider") == enemy, "An activated enemy returns to normal weapon collision")
    enemy.set_physics_process(false)
    player.global_position = enemy.global_position + Vector2(30, 0)
    player.velocity = Vector2.ZERO
    await frames()
    check(enemy.begin_attack(player), "The activated enemy can start its normal attack")
    await set_flag(false)
    enemy.update_attack(enemy.attack_windup_seconds + 0.05, player)
    check(Game.health == 100 and not enemy.is_attacking() and enemy_ray().is_empty(), "Turning the flag off during an attack disables contact and removes its collider")
    await set_flag(true)
    check(enemy.visible and enemy.story_active and enemy.is_in_group("enemy"), "The same actor can be enabled again without being recreated")
    enemy.settle()
    enemy.take_damage(1)
    check(enemy.get_node("HurtSound").playing, "Active enemy damage still plays the normal injury sound")
    await set_flag(false)
    check(not enemy.get_node("HurtSound").playing, "Deactivation stops injury audio instead of resuming an old grunt later")

func verify_opposite_and_child_controller() -> void:
    var opposite: CharacterBody2D = room.get_node("Actors/OppositeEnemy")
    var child: WorldFlagCondition = opposite.get_node("StoryCondition")
    check(opposite.visible and opposite.story_active, "Activate When Unmet enables its actor before its own flag is set")
    await set_flag(true, "story:remove_opposite")
    check(not opposite.visible and opposite.process_mode == Node.PROCESS_MODE_DISABLED and not opposite.story_active, "The inverse activation option hides and disables its whole actor")
    await set_flag(false, "story:remove_opposite")
    check(opposite.visible and opposite.process_mode == Node.PROCESS_MODE_INHERIT and opposite.story_active, "A controller inside a disabled actor still receives flag changes and reactivates its parent")
    child.activate_when_unmet = [NodePath("../Body")]
    check(not child._get_configuration_warnings().is_empty(), "Selecting only an enemy sprite produces an actionable editor warning")
    child.activate_when_unmet = [NodePath("..")]

func verify_save_slots_and_defeat() -> void:
    player.global_position = room.get_node("Interactables/TestBicycle").global_position + Vector2(-25, -32)
    player.velocity = Vector2.ZERO
    await frames()
    check(Game.save_slot(0, room.get_node("Interactables/TestBicycle")), "Save A captures the flag-off inactive enemy")
    await set_flag(true)
    check(Game.save_slot(1, room.get_node("Interactables/TestBicycle")), "Save B captures the same flag-on active enemy")
    var a: Dictionary = Game._read_slot(0)
    var b: Dictionary = Game._read_slot(1)
    check(not bool(a["world"].get(FLAG, false)) and bool(b["world"].get(FLAG, false)), "Save files store independent activation flags")
    check(Game.load_slot(0), "The inactive-enemy save loads")
    await frames(10)
    refresh()
    check(not enemy.story_active and not enemy.visible and enemy_ray().is_empty(), "Loading A restores invisible, harmless, non-colliding enemy state")
    check(Game.load_slot(1), "The active-enemy save loads")
    await frames(10)
    refresh()
    check(enemy.story_active and enemy.visible and enemy.is_in_group("enemy") and enemy_ray().get("collider") == enemy, "Loading B restores the living active enemy independently")
    enemy.set_physics_process(false)
    enemy.take_damage(enemy.max_health + 1)
    await set_flag(false)
    await set_flag(true)
    check(enemy.dead and not enemy.is_in_group("enemy") and not enemy.is_attacking(), "A flag change never resurrects or re-registers an already defeated enemy")
    player.global_position = room.get_node("Interactables/TestBicycle").global_position + Vector2(-25, -32)
    player.velocity = Vector2.ZERO
    await frames()
    check(Game.save_slot(2, room.get_node("Interactables/TestBicycle")), "A third slot saves the defeated enemy with its activation flag still true")
    check(Game.load_slot(2), "The defeated-enemy save loads")
    await frames(10)
    refresh()
    check(enemy == null and bool(Game.world.get(FLAG, false)), "Saved defeat takes priority over an activation flag when reconstructing the level")
