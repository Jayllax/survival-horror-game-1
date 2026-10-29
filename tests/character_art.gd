extends Node
var checks := 0
var failures := 0
func check(ok: bool,description: String) -> void:
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
    get_tree().current_scene=null
    run.call_deferred()
func run() -> void:
    Game.reset_run()
    var level: Node2D=load("res://tests/fixtures/fence_sandbox.tscn").instantiate()
    get_tree().root.add_child(level)
    get_tree().current_scene=level
    await frames(8)
    var player: CharacterBody2D=level.get_node("Actors/Player")
    var body: CharacterVisuals=player.get_node("Body")
    var rig: Node2D=player.get_node("WeaponArms")
    var gun: Sprite2D=player.get_node("Aim/Gun")
    check(player.move_speed==125 and player.jump_velocity==-200 and player.get_node("Camera2D").zoom==Vector2(1.4,1.4),"Designer movement, jump and camera tuning survive the art update")
    check(not player.use_crouch_placeholder_pose and not player.use_dodge_placeholder_pose and body.scale==Vector2(2,2),"Real native poses replace squash placeholders at consistent 2x pixel scale")
    var sprite_frames := body.sprite_frames
    var unique_clips := true
    for pair in [[&"walk",&"sprint"],[&"walk",&"crouch_walk"]]:
        var a: AtlasTexture=sprite_frames.get_frame_texture(pair[0],0)
        var b: AtlasTexture=sprite_frames.get_frame_texture(pair[1],0)
        unique_clips=unique_clips and a.region!=b.region
    check(unique_clips and sprite_frames.get_frame_count(&"walk")==6 and sprite_frames.get_frame_count(&"crouch_walk")==6,"Walk, run and crouch use distinct six-frame artwork")
    var crouch_image: Image=sprite_frames.get_frame_texture(&"crouch_idle",0).get_image()
    var idle_image: Image=sprite_frames.get_frame_texture(&"idle",0).get_image()
    check(crouch_image.get_used_rect().size.y<idle_image.get_used_rect().size.y,"Crouch has an actual lower drawn pose without shrinking the head via scale")
    player.set_physics_process(false)
    verify_motion_attachments(player)
    Input.action_press("aim")
    for crouched in [false,true]:
        player.is_crouching=crouched
        player.aim.position=player.standing_aim_position+Vector2(0,14 if crouched else 0)
        for angle in [0.0,-0.8,-1.57,2.4,3.14,0.9]:
            var target: Vector2=player.aim.global_position+Vector2.RIGHT.rotated(angle)*180
            var event:=InputEventMouseMotion.new()
            event.position=get_viewport().get_canvas_transform()*target
            event.global_position=event.position
            Input.parse_input_event(event)
            await frames(1)
            player.update_aim(1)
            player.update_animation()
            rig.update_pose()
            var mirror:=Vector2(1,-1 if gun.flip_v else 1)
            var near: Vector2=rig.get_node("Near/Hand").global_position
            var far: Vector2=rig.get_node("Far/Hand").global_position
            check(rig.visible and near.distance_to(gun.to_global(rig.near_grip*mirror))<0.01 and far.distance_to(gun.to_global(rig.far_grip*mirror))<0.01,"Both hands stay on their grips at angle %.2f, crouch=%s" % [angle,crouched])
    check(body.animation==&"crouch_aim_idle","Crouched aiming selects a torso without duplicate dangling hands")
    player.is_crouching=false
    player.velocity.x=-player.facing*30
    player.update_animation()
    check(body.animation==&"aim_walk" and body.speed_scale<0,"Aiming backwards uses the armed walk pose and reverses the gait")
    Input.action_release("aim")
    player.update_aim(0)
    rig.update_pose()
    check(not rig.visible and gun.texture==null and player.get_node("Aim/Gun/Flashlight").enabled,"Holstering hides aiming hands and gun while preserving the flashlight")
    var foe: CharacterBody2D=load("res://scenes/actors/enemy.tscn").instantiate()
    foe.position=Vector2(1100,588)
    level.get_node("Actors").add_child(foe)
    await frames()
    foe.set_physics_process(false)
    var enemy_body: CharacterVisuals=foe.get_node("Body")
    check(enemy_body.scale==Vector2(2,2) and not foe.use_sleep_placeholder_pose and not foe.use_attack_placeholder_pose and not foe.use_death_placeholder_pose,"Enemy uses matching native scale and real sleep/attack/death poses")
    for state in [&"idle",&"walk",&"sleep",&"wake",&"attack",&"hit",&"death"]:
        check(enemy_body.has_state(state) and enemy_body.sprite_frames.get_frame_count(state)>1,"Enemy has a multi-frame editable animation: "+str(state))
    foe.change_state(foe.State.ATTACK)
    enemy_body.play_state(&"attack",1,true)
    foe.attack_time=0.1
    foe.update_visuals()
    var warning_frame:=enemy_body.frame
    foe.attack_time=foe.attack_windup_seconds+0.01
    foe.update_visuals()
    var contact_frame:=enemy_body.frame
    foe.attack_time=foe.attack_windup_seconds+foe.attack_active_seconds+0.1
    foe.update_visuals()
    check(warning_frame<2 and contact_frame in [2,3] and enemy_body.frame>=4,"Attack windup, contact and recovery frames follow the gameplay phases")
    foe.attack_windup_seconds=0.8
    foe.attack_time=0.6
    foe.change_state(foe.State.ATTACK)
    foe.update_visuals()
    check(enemy_body.frame<2,"Changing windup duration keeps the visual strike out of the warning phase")
    var enemy_image: Image=enemy_body.sprite_frames.get_frame_texture(&"idle",0).get_image()
    check(abs(enemy_image.get_used_rect().size.y-idle_image.get_used_rect().size.y)<=2,"Enemy and player standing silhouettes remain the same height")
    level.queue_free()
    await frames(6)
    print("IGNOTUM CHARACTER ART: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures==0 else 1)

# Check the actual rendered pixels, not just equality with the attachment data.
func native_pixel(body: AnimatedSprite2D, world_point: Vector2) -> Color:
    var texture := body.sprite_frames.get_frame_texture(body.animation,body.frame)
    var point := body.to_local(world_point)-body.offset
    point *= Vector2(-1 if body.flip_h else 1,-1 if body.flip_v else 1)
    if body.centered:
        point += texture.get_size()/2
    var pixel := Vector2i(floori(point.x),floori(point.y))
    if pixel.x<0 or pixel.y<0 or pixel.x>=texture.get_width() or pixel.y>=texture.get_height():
        return Color.TRANSPARENT
    return texture.get_image().get_pixelv(pixel)

func verify_motion_attachments(player: CharacterBody2D) -> void:
    var body: AnimatedSprite2D=player.get_node("Body")
    var rig: Node2D=player.get_node("WeaponArms")
    var light: PointLight2D=player.get_node("Aim/Gun/Flashlight")
    var gun: Sprite2D=player.get_node("Aim/Gun")
    var original_position:=player.position
    var original_collision: Vector2=player.get_node("CollisionShape2D").position
    for facing in [1.0,-1.0]:
        player.facing=facing
        body.flip_h=facing<0
        rig.update_pose()
        for clip in [&"idle",&"walk",&"sprint",&"crouch_idle",&"crouch_walk",&"jump",&"fall",&"dodge"]:
            body.play_state(clip)
            body.pause()
            var hand_aligned:=true
            var direction_correct:=true
            for frame in body.sprite_frames.get_frame_count(clip):
                body.frame=frame
                # Frame signals update attachment transforms synchronously, even with physics stopped.
                var hand_world: Vector2=light.global_position-Vector2(rig.handheld_flashlight_offset.x*facing,rig.handheld_flashlight_offset.y)
                var pixel:=native_pixel(body,hand_world)
                hand_aligned=hand_aligned and (pixel.is_equal_approx(Color("ccbb98")) or pixel.is_equal_approx(Color("b0866c")))
                var direction:=Vector2.RIGHT.rotated(light.global_rotation)
                direction_correct=direction_correct and direction.distance_to(Vector2(facing,0))<0.001
            check(hand_aligned and direction_correct,"Every %s frame keeps the light on a drawn hand and facing horizontally (%s)" % [clip,facing])
    check(player.position==original_position and player.get_node("CollisionShape2D").position==original_collision,"Animation attachment alignment never moves the physics body or collision")
    Input.action_press("aim")
    player.sync_weapon()
    var shoulders_aligned:=true
    var barrel_aligned:=true
    var hands_aligned:=true
    for facing in [1.0,-1.0]:
        player.facing=facing
        body.flip_h=facing<0
        # Supply actual cursor events for both sides while the clips advance.
        var event:=InputEventMouseMotion.new()
        event.position=get_viewport().get_canvas_transform()*(player.global_position+Vector2(180*facing,-100))
        event.global_position=event.position
        Input.parse_input_event(event)
        rig.update_pose()
        for clip in [&"aim_idle",&"aim_walk",&"crouch_aim_idle",&"crouch_aim_walk",&"aim_jump",&"aim_fall"]:
            body.play_state(clip)
            body.pause()
            for frame in body.sprite_frames.get_frame_count(clip):
                body.frame=frame
                rig.update_pose()
                for arm_name in ["Near","Far"]:
                    var shoulder: Vector2=rig.get_node(arm_name+"/Upper").global_position
                    shoulders_aligned=shoulders_aligned and native_pixel(body,shoulder).is_equal_approx(Color("8f6c61"))
                var mirror:=Vector2(1,-1 if gun.flip_v else 1)
                barrel_aligned=barrel_aligned and light.global_position.distance_to(gun.to_global(Vector2(14,4)*mirror))<0.01
                hands_aligned=hands_aligned and rig.get_node("Near/Hand").global_position.distance_to(gun.to_global(rig.near_grip*mirror))<0.01
    check(shoulders_aligned,"Aiming arms attach to drawn shirt pixels throughout every armed animation")
    check(barrel_aligned and hands_aligned,"Moving aimed poses keep both the beam on the barrel and hand on the grip")
    var profile: CharacterAttachmentProfile=rig.attachment_profile
    rig.attachment_profile=null
    rig.update_pose()
    check(light.global_position.is_finite() and player.aim.position.is_finite(),"Custom art without an attachment profile keeps a safe fixed-position fallback")
    rig.attachment_profile=profile
    player.facing=1
    body.flip_h=false
    Input.action_release("aim")
    player.update_aim(0)
