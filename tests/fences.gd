extends Node
var checks := 0
var failures := 0
var level: Node2D
var player: CharacterBody2D
func check(ok: bool, description: String) -> void:
    checks += 1
    if ok: print("PASS: "+description)
    else:
        failures += 1
        push_error("FAIL: "+description)
func frames(count: int = 3) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame
func _ready() -> void:
    get_tree().current_scene = null
    run.call_deferred()
func run() -> void:
    Game.reset_run()
    level = load("res://scenes/levels/fence_sandbox.tscn").instantiate()
    get_tree().root.add_child(level)
    get_tree().current_scene = level
    await frames(8)
    player = level.get_node("Actors/Player")
    var fence: Area2D = level.get_node("Interactables/CuttableFence")
    var solid: StaticBody2D = level.get_node("Props/ReinforcedFence")
    var side: Area2D = level.get_node("Interactables/CuttableFenceSide")
    var bike := level.get_node("Interactables/SaveBicycle")
    check(fence.is_in_group("interactable") and not solid.is_in_group("interactable"),"Only cuttable fences offer an interaction")
    check(fence.interaction_action()=="Cut fence" and fence.is_available(),"Closed wire fence offers a generic nearby action")
    check(fence.get_node("Barrier/CollisionShape2D").shape.size==Vector2(96,64) and side.get_node("Barrier/CollisionShape2D").shape.size==Vector2(12,64),"Panel and end-view barriers match their native 2x artwork")
    player.position = bike.position+Vector2(-40,-32)
    await frames()
    check(Game.save_slot(0,bike),"Earlier bicycle save records the closed route without cutters")
    var earlier_file := FileAccess.get_file_as_string(Game.slot_path(0))
    player.position = Vector2(400,588)
    player.velocity = Vector2.ZERO
    Input.action_press("move_right")
    await frames(20)
    Input.action_release("move_right")
    check(player.position.x<=400.1,"Closed fence physically blocks the walking player")
    fence.interact(player)
    await frames()
    check(not fence.cutting and not fence.opened and not fence.get_node("Barrier/CollisionShape2D").disabled,"Missing cutters leave both art and collision intact")
    check(Game.add_item("bolt_cutters"),"Reusable bolt cutters fit in the inventory")
    player.position = Vector2(160,588)
    fence.interact(player)
    check(not fence.cutting,"Fence cannot be activated remotely")
    player.position = Vector2(400,588)
    player.set_physics_process(false)
    var heard := []
    var listener := func(origin: Vector2,radius: float,source: Node): heard.append([origin,radius,source])
    Game.noise_emitted.connect(listener)
    fence.interact(player)
    check(fence.cutting and not fence.is_available() and heard.size()==1,"Cut starts once, hides its prompt, and emits configurable AI noise")
    fence.interact(player)
    check(heard.size()==1 and not fence.get_node("Barrier/CollisionShape2D").disabled,"Repeated interaction cannot duplicate cuts; barrier stays until completion")
    check(not Game.world.get(fence.state_key(),false),"An unfinished cut is not recorded as an open route")
    await frames(ceili(fence.cut_seconds*60)+5)
    check(fence.opened and not fence.cutting and fence.get_node("Barrier/CollisionShape2D").disabled,"Completed cut releases the physical route")
    check(is_equal_approx(fence.get_node("LeftPanel").scale.x,fence.folded_panel_scale) and is_equal_approx(fence.get_node("RightPanel").scale.x,fence.folded_panel_scale),"Both authored wire halves fold symmetrically")
    check(Game.count_item("bolt_cutters")==1 and Game.world.get(fence.state_key(),false),"Cut persists and does not consume the reusable tool")
    player.set_physics_process(true)
    Input.action_press("move_right")
    await frames(85)
    Input.action_release("move_right")
    check(player.position.x>520,"Player can actually walk through the newly cut panel")
    player.position = bike.position+Vector2(-40,-32)
    player.velocity=Vector2.ZERO
    Game.health=66
    await frames()
    check(Game.save_slot(1,bike),"Later bicycle save records tool, health and opened route independently")
    check(FileAccess.get_file_as_string(Game.slot_path(0))==earlier_file,"Saving the open route never rewrites the earlier slot")
    check(Game.load_slot(0),"Earlier fence snapshot loads")
    await frames(10)
    level=get_tree().current_scene
    fence=level.get_node("Interactables/CuttableFence")
    check(not fence.opened and not fence.get_node("Barrier/CollisionShape2D").disabled and Game.count_item("bolt_cutters")==0 and Game.health==100,"Earlier load restores closed collision, no cutters and original health")
    check(Game.load_slot(1),"Later fence snapshot loads")
    await frames(10)
    level=get_tree().current_scene
    fence=level.get_node("Interactables/CuttableFence")
    player=level.get_node("Actors/Player")
    check(fence.opened and fence.get_node("Barrier/CollisionShape2D").disabled and Game.count_item("bolt_cutters")==1 and Game.health==66,"Later load restores open art/collision and its own tool and health")
    check(is_equal_approx(fence.get_node("LeftPanel").scale.x,fence.folded_panel_scale),"Restored fence is immediately in its final cut pose")
    side=level.get_node("Interactables/CuttableFenceSide")
    check(not side.opened,"A duplicate fence owns a separate persistent state")
    var foe: CharacterBody2D=load("res://scenes/actors/enemy.tscn").instantiate()
    foe.position=Vector2(650,588)
    level.get_node("Actors").add_child(foe)
    await frames()
    foe.set_physics_process(false)
    player.set_physics_process(false)
    player.position=Vector2(582,588)
    player.velocity=Vector2.ZERO
    player.aim.rotation=0
    player.shot_cooldown=0
    Game.magazine=2
    Input.action_press("aim")
    player.shoot()
    check(foe.health==foe.max_health and Game.magazine==1,"A muzzle extending past a narrow fence cannot shoot through it from the other side")
    side.interact(player)
    await frames(ceili(side.cut_seconds*60)+5)
    check(side.opened and side.get_node("Barrier/CollisionShape2D").disabled and is_equal_approx(side.get_node("LeftPanel").rotation,PI/2),"End-view fence folds down and opens with the same reusable tool")
    player.shot_cooldown=0
    player.shoot()
    check(foe.health==foe.max_health-player.bullet_damage and Game.magazine==0,"The same shot can reach its target after the narrow fence is cut")
    Input.action_release("aim")
    solid=level.get_node("Props/ReinforcedFence")
    var query := PhysicsRayQueryParameters2D.create(Vector2(800,588),Vector2(1000,588),1)
    var hit := player.get_world_2d().direct_space_state.intersect_ray(query)
    check(hit.get("collider")==solid and not solid.has_method("take_damage"),"Permanent fence remains a solid gun-ray barrier with cutters held")
    Game.noise_emitted.disconnect(listener)
    player.get_node("ShotSound").stop()
    await frames(6)
    level.queue_free()
    await frames(6)
    print("IGNOTUM FENCES: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures==0 else 1)
