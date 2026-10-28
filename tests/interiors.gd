extends Node2D
var checks := 0
var failures := 0
const VARIANTS := ["warm","sage","slate"]
func check(ok: bool, description: String) -> void:
    checks += 1
    if ok:
        print("PASS: "+description)
    else:
        failures += 1
        push_error("FAIL: "+description)
func frames(count: int = 2) -> void:
    for index in count:
        await get_tree().physics_frame
        await get_tree().process_frame
func _ready() -> void:
    run.call_deferred()
func run() -> void:
    Game.reset_run()
    await frames(6)
    await verify_props()
    await verify_stairs()
    print("IGNOTUM INTERIORS: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures==0 else 1)
func verify_props() -> void:
    var folders := ["living_room","kitchen","bathroom","bedroom","lighting"]
    for category in folders:
        var directory := DirAccess.open("res://scenes/objects/interiors/"+category)
        for file in directory.get_files():
            if not file.ends_with(".tscn"):
                continue
            var prop: InteriorProp=load("res://scenes/objects/interiors/"+category+"/"+file).instantiate()
            prop.position=Vector2(-1500,620)
            add_child(prop)
            await frames(1)
            check(prop.get_node("Solid/Shape").disabled,"Decoration starts passable: "+file)
            var all_variants := true
            var symmetric := true
            var different := true
            var previous: Texture2D
            for variant in 3:
                prop.color_variant=variant
                await frames(1)
                var texture: Texture2D=prop.get_node("Artwork").texture
                all_variants=all_variants and texture==prop.variant_textures[variant] and texture!=null
                different=different and texture!=previous
                previous=texture
                var image:=texture.get_image()
                for y in image.get_height():
                    for x in image.get_width()/2:
                        var a:=image.get_pixel(x,y)
                        var b:=image.get_pixel(image.get_width()-1-x,y)
                        symmetric=symmetric and is_equal_approx(a.a,b.a) and (a.a<0.5 or a.is_equal_approx(b))
            check(all_variants and different,"Inspector selects all three actual PNG variants: "+file)
            check(symmetric,"Native artwork is horizontally symmetrical: "+file)
            prop.solid=true
            await frames(1)
            check(not prop.get_node("Solid/Shape").disabled,"Optional solid collision enables: "+file)
            if prop.has_node("Light"):
                prop.light_enabled=false
                prop.light_energy=1.25
                prop.light_radius_scale=0.7
                await frames(1)
                check(not prop.get_node("Light").enabled and prop.get_node("Light").energy==1.25 and is_equal_approx(prop.get_node("Light").texture_scale,0.7),"Lamp controls update the real Godot light: "+file)
                prop.light_enabled=true
                await frames(1)
                check(prop.get_node("Light").enabled,"Lamp can be enabled again: "+file)
            prop.queue_free()
            await frames(1)
func foot_y(player: CharacterBody2D) -> float:
    var shape: CollisionShape2D=player.get_node("CollisionShape2D")
    return player.global_position.y+shape.position.y+shape.shape.height/2.0
func walk_to(target: float,maximum: int = 600) -> bool:
    var player: CharacterBody2D=$Player
    var right:=target>player.position.x
    var action: StringName=&"move_right" if right else &"move_left"
    Input.action_press(action)
    var reached:=false
    for i in maximum:
        await frames(1)
        if (right and player.position.x>=target) or (not right and player.position.x<=target):
            reached=true
            break
    Input.action_release(action)
    await frames(8)
    return reached
func verify_stairs() -> void:
    var player: CharacterBody2D=$Player
    check(player.floor_snap_length>=6,"Player floor snap supports descending the authored slopes")
    check(await walk_to(470),"Player walks up the right-rising stairs without jumping")
    check(absf(foot_y(player)-492)<3 and player.is_on_floor(),"Right-rising stairs connect to the upper landing at the authored height")
    check(await walk_to(880),"Player crosses the landing and walks down the mirrored stairs")
    check(absf(foot_y(player)-620)<3 and player.is_on_floor(),"Descending left-rising stairs returns to the ground")
    check(await walk_to(560),"Player walks up the left-rising stairs without jumping")
    check(absf(foot_y(player)-492)<3 and player.is_on_floor(),"Mirrored stair collision reaches the same upper floor")
    check(await walk_to(150),"Player can reverse and descend the right-rising stairs")
    check(absf(foot_y(player)-620)<3 and player.is_on_floor(),"Both descent directions remain grounded")
    player.position=Vector2(330,588)
    player.velocity=Vector2.ZERO
    await frames(6)
    check(await walk_to(375,90),"One-way stairs allow walking underneath the flight")
    check(absf(foot_y(player)-620)<3,"Walking underneath does not snap the player onto stairs above")
    player.position=Vector2(1460,588)
    player.velocity=Vector2.ZERO
    await frames(6)
    check(await walk_to(1650,180),"Half-height stairs can be walked up")
    check(absf(foot_y(player)-556)<3 and player.is_on_floor(),"Half-height stairs connect to a 64-pixel rise")
    check(await walk_to(1880,220),"Half-height mirrored flight can be descended")
    check(absf(foot_y(player)-620)<3,"Half-height stairs return to ground without a drop")
