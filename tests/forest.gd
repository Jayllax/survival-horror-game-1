extends Node
var checks := 0
var failures := 0
func check(ok: bool,description: String) -> void:
    checks+=1
    if ok:print('PASS: '+description)
    else:
        failures+=1
        push_error('FAIL: '+description)
func frames(count: int=1) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame
func _ready() -> void:
    run.call_deferred()
func run() -> void:
    for category in ['trees','wood','plants','rocks']:
        var directory:=DirAccess.open('res://scenes/objects/forest/'+category)
        for file in directory.get_files():
            if not file.ends_with('.tscn'):continue
            var prop:ForestProp=load('res://scenes/objects/forest/'+category+'/'+file).instantiate()
            add_child(prop)
            await frames()
            check(prop.get_node('Solid/Shape').disabled,'Forest decor starts passable: '+file)
            var variants_ok:=true
            var native_scale:bool=prop.get_node('Artwork').scale==Vector2(2,2)
            var symmetry:=true
            var distinct:Dictionary={}
            for variant in 3:
                prop.color_variant=variant
                await frames()
                var texture:Texture2D=prop.get_node('Artwork').texture
                variants_ok=variants_ok and texture==prop.variant_textures[variant]
                distinct[texture.resource_path]=true
                var image:=texture.get_image()
                for y in image.get_height():
                    for x in image.get_width()/2:
                        var a:=image.get_pixel(x,y)
                        var b:=image.get_pixel(image.get_width()-1-x,y)
                        symmetry=symmetry and is_equal_approx(a.a,b.a) and (a.a<0.5 or a.is_equal_approx(b))
            check(variants_ok and distinct.size()==3 and native_scale,'All forest palettes update at native 2x scale: '+file)
            check(symmetry,'Forest artwork has exact horizontal symmetry: '+file)
            prop.solid=true
            await frames()
            check(not prop.get_node('Solid/Shape').disabled,'Forest blocking can be enabled: '+file)
            if category=='trees':
                var trunk:RectangleShape2D=prop.get_node('Solid/Shape').shape
                check(trunk.size.x<prop.get_node('Artwork').texture.get_width(),'Tree collision follows the trunk rather than the canopy: '+file)
            var labels_ok:=false
            for property in prop.get_property_list():
                if property.name=='color_variant':labels_ok=property.hint_string=='Deep green,Muted sage,Autumn'
            check(labels_ok,'Forest Inspector names its own palette choices: '+file)
            prop.queue_free()
            await frames()
    print('IGNOTUM FOREST: %d checks, %d failures' % [checks,failures])
    get_tree().quit(0 if failures==0 else 1)
