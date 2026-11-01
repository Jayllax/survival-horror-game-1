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
    preload("res://tests/support/loadout.gd").handgun()
    var level: Node2D=load("res://tests/fixtures/fence_sandbox.tscn").instantiate()
    get_tree().root.add_child(level)
    get_tree().current_scene=level
    await frames(8)
    var player: CharacterBody2D=level.get_node("Actors/Player")
    var body: CharacterVisuals=player.get_node("Body")
    var rig: Node2D=player.get_node("WeaponArms")
    var gun: Sprite2D=player.get_node("Aim/Gun")
    check(player.move_speed==90 and player.jump_velocity==-250 and player.get_node("Camera2D").zoom==Vector2(2,2),"Designer movement, jump and camera tuning survive the art update")
    check(not player.use_crouch_placeholder_pose and not player.use_dodge_placeholder_pose and body.scale==Vector2(2,2),"Real native poses replace squash placeholders at consistent 2x pixel scale")
    var sprite_frames := body.sprite_frames
    # Templates are intentionally excluded from the runtime importer.
    var reference := Image.load_from_file("res://art/templates/characters/player_style_reference.png")
    var atlas := preload("res://art/pixel/player_motion.png").get_image()
    var row_names := [&"idle",&"walk",&"sprint",&"crouch_idle",&"crouch_walk",&"jump",&"fall",&"dodge",&"aim_idle",&"aim_walk",&"crouch_aim_idle",&"crouch_aim_walk",&"aim_jump",&"aim_fall"]
    var sheet_order := true
    for row in row_names.size():
        sheet_order = sheet_order and sprite_frames.get_frame_count(row_names[row])==6
        for column in 6:
            var tile := sprite_frames.get_frame_texture(row_names[row],column) as AtlasTexture
            sheet_order = sheet_order and tile!=null and tile.region==Rect2(column*32,row*40,32,40)
    check(sheet_order,"Every animation uses all six designer cells in their sheet order")
    check(same_visible_pixels(reference, atlas.get_region(Rect2i(0,0,32,40))), "The designer's top-left reference frame remains pixel-for-pixel unchanged")
    var authored := Image.load_from_file("res://art/templates/characters/player_authored_frames.png")
    check(same_visible_pixels(authored,atlas), "All 84 finished designer frames remain pixel-for-pixel unchanged")
    var palette := {}
    for y in authored.get_height():
        for x in authored.get_width():
            var pixel := authored.get_pixel(x,y)
            if pixel.a>0:
                palette[pixel.to_rgba32()] = true
    var same_palette := true
    for y in atlas.get_height():
        for x in atlas.get_width():
            var pixel := atlas.get_pixel(x,y)
            if pixel.a>0 and not palette.has(pixel.to_rgba32()):
                same_palette = false
    check(same_palette, "The imported sheet retains the finished designer palette exactly")
    var head := reference.get_region(Rect2i(9,5,12,10))
    var consistent_head := true
    var no_extra_hands := true
    for row in 14:
        for column in 6:
            var cell := atlas.get_region(Rect2i(column*32,row*40,32,40))
            var top := cell.get_used_rect().position.y
            # The designer's completed frames deliberately shift within their cells.
            var head_x := -1
            for x in range(21):
                if same_visible_pixels(head,cell.get_region(Rect2i(x,top,12,10))):
                    head_x = x
                    break
            consistent_head = consistent_head and head_x>=0
            if row>=8:
                var head_rect := Rect2i(head_x,top,12,10)
                for y in 40:
                    for x in 32:
                        var pixel := cell.get_pixel(x,y)
                        var skin := pixel.a>0.99 and pixel.r>0.57 and pixel.g>0.47 and pixel.b<pixel.g and pixel.r-pixel.g<0.24
                        no_extra_hands = no_extra_hands and (not skin or head_rect.has_point(Vector2i(x,y)))
    check(consistent_head, "All 84 cells use the exact designer-drawn head without rescaling or changing its shading")
    check(no_extra_hands, "All armed poses omit dangling hands so the weapon rig supplies the only aiming hands")
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
    await verify_weapon_frames(player)
    await verify_weapon_actions(player)
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
    check(enemy_image.get_size()==Vector2i(32,40) and idle_image.get_size()==enemy_image.get_size(),"Enemy and player retain shared 32x40 animation canvases, including the authored head effects")
    level.queue_free()
    await frames(6)
    GameAudio.stop_all()
    await get_tree().create_timer(0.2).timeout
    print("IGNOTUM CHARACTER ART: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures==0 else 1)

# Check the actual rendered pixels, not just equality with the attachment data.
func same_visible_pixels(a: Image, b: Image) -> bool:
    if a.get_size()!=b.get_size():
        return false
    for y in a.get_height():
        for x in a.get_width():
            var first := a.get_pixel(x,y)
            var second := b.get_pixel(x,y)
            if first.a!=second.a or (first.a>0 and first!=second):
                return false
    return true

func verify_weapon_frames(player: CharacterBody2D) -> void:
    var body: AnimatedSprite2D=player.get_node("Body")
    var rig: Node2D=player.get_node("WeaponArms")
    var gun: Sprite2D=player.get_node("Aim/Gun")
    var light: PointLight2D=gun.get_node("Flashlight")
    for id in ["pistol","shotgun"]:
        if Game.count_item(id)==0:
            Game.add_item(id)
        var uid := Game.inventory.first_uid(id)
        if Game.equipped_uid!=uid:
            Game.equip_weapon(uid)
        var definition := Game.active_weapon()
        var grips := true
        var shoulders := true
        var beam := true
        var muzzle := true
        Input.action_press("aim")
        player.sync_weapon()
        for facing in [1.0,-1.0]:
            player.facing=facing
            body.flip_h=facing<0
            for angle in [0.0,-0.8,-1.4,0.9]:
                var event := InputEventMouseMotion.new()
                event.position=get_viewport().get_canvas_transform()*(player.global_position+Vector2(180*cos(angle)*facing,180*sin(angle)))
                event.global_position=event.position
                Input.parse_input_event(event)
                await frames(1)
                for clip in [&"aim_idle",&"aim_walk",&"crouch_aim_idle",&"crouch_aim_walk",&"aim_jump",&"aim_fall"]:
                    player.is_crouching=str(clip).begins_with("crouch_")
                    body.play_state(clip)
                    body.pause()
                    for frame in body.sprite_frames.get_frame_count(clip):
                        body.frame=frame
                        rig.update_pose()
                        var mirror := Vector2(1,-1 if gun.flip_v else 1)
                        var near: Vector2=definition.near_grip if definition.custom_weapon_pose else rig.near_grip
                        var far: Vector2=definition.far_grip if definition.custom_weapon_pose else rig.far_grip
                        grips=grips and rig.visible and rig.get_node("Near/Hand").global_position.distance_to(gun.to_global(near*mirror))<0.01
                        grips=grips and rig.get_node("Far/Hand").global_position.distance_to(gun.to_global(far*mirror))<0.01
                        for arm in ["Near","Far"]:
                            var pixel := native_pixel(body,rig.get_node(arm+"/Upper").global_position)
                            shoulders=shoulders and pixel.a>0.99 and pixel.r>pixel.g and pixel.g>pixel.b and pixel.r<0.71
                        var beam_point: Vector2=definition.flashlight_offset if definition.custom_weapon_pose else rig.barrel_flashlight_offset
                        beam=beam and light.global_position.distance_to(gun.to_global(beam_point*mirror))<0.01 and light.global_scale.is_equal_approx(player.default_light_scale)
                        var muzzle_point: Vector2=definition.muzzle_offset if definition.custom_weapon_pose else player.default_muzzle_position
                        muzzle=muzzle and player.muzzle.global_position.distance_to(gun.to_global(muzzle_point*mirror))<0.01
        check(grips,"Both %s grips align in every armed frame, both directions and four aim elevations" % id)
        check(shoulders,"Both %s sleeves attach to drawn shirt pixels in every armed pose" % id)
        check(beam,"The %s flashlight follows its barrel without changing beam size" % id)
        check(muzzle,"The %s firing origin and muzzle flash stay on the mirrored barrel" % id)
        Input.action_release("aim")
    player.is_crouching=false

func verify_weapon_actions(player: CharacterBody2D) -> void:
    for id in ["pistol","shotgun"]:
        var uid := Game.inventory.first_uid(id)
        if Game.equipped_uid!=uid:
            Game.equip_weapon(uid)
        var definition := Game.active_weapon()
        Game.add_item(definition.ammunition_id,6)
        Game.magazine=2
        player.shot_cooldown=0
        player.reload_remaining=0
        Input.action_press("aim")
        player.sync_weapon()
        player.update_aim(0)
        player.shoot()
        player.get_node("WeaponArms").update_pose()
        check(Game.magazine==1 and player.muzzle.energy>0,"The %s fires and shows a muzzle flash using the imported poses" % id)
        var reserve := Game.count_item(definition.ammunition_id)
        player.reload_weapon()
        player.set_physics_process(true)
        await get_tree().create_timer(player.reload_seconds+0.15).timeout
        player.set_physics_process(false)
        check(Game.magazine>1 and Game.count_item(definition.ammunition_id)<reserve,"The %s reload transfers its own ammunition with the new artwork" % id)
        player.reload_remaining=0
        Input.action_release("aim")
        player.update_aim(0)

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
                # The complete approved redraw includes shaded skin, not the two
                # old flat colours. Still require an opaque, skin-coloured pixel.
                hand_aligned=hand_aligned and pixel.a>0.99 and pixel.r>0.57 and pixel.g>0.47 and pixel.b<pixel.g and pixel.r-pixel.g<0.24
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
                    # The approved polo has several shirt shades. Its silhouette
                    # and shoulder positions remain the attachment reference.
                    var shoulder_pixel:=native_pixel(body,shoulder)
                    var on_shirt:=shoulder_pixel.a>0.99 and shoulder_pixel.r>shoulder_pixel.g and shoulder_pixel.g>shoulder_pixel.b and shoulder_pixel.r<0.71
                    shoulders_aligned=shoulders_aligned and on_shirt
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
