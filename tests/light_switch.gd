extends Node
var checks := 0
var failures := 0
var room: Node2D
var player: CharacterBody2D
var hud: CanvasLayer
var bike: Area2D

func check(ok: bool, description: String) -> void:
    checks += 1
    if ok:
        print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)

func frames(count: int = 3) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame

func key(code: Key, pressed: bool = true, echo: bool = false, release_after: bool = true) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = pressed
    event.echo = echo
    Input.parse_input_event(event)
    await frames(2)
    if pressed and not echo and release_after:
        await key(code, false)

func refresh_room() -> void:
    room = get_tree().current_scene
    player = room.get_node("Actors/Player")
    hud = room.get_node("HUD")
    bike = room.get_node("Interactables/SaveBicycle")

func make_switch(id: String, targets: Array[NodePath], start_on: bool = true) -> RoomLightSwitch:
    var result: RoomLightSwitch = load("res://scenes/objects/lighting/light_switch.tscn").instantiate()
    result.persistent_id = id
    result.connected_lights.assign(targets)
    result.starting_on = start_on
    result.position = Vector2(150, 588)
    room.get_node("Interactables").add_child(result)
    return result

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    Game.reset_run()
    room = load("res://tests/fixtures/story_sandbox.tscn").instantiate()
    get_tree().root.add_child(room)
    get_tree().current_scene = room
    refresh_room()
    await frames(6)
    await verify_interaction_and_connections()
    await verify_order_and_linked_switches()
    await verify_saves()
    for audio in room.find_children("*", "AudioStreamPlayer", true, false):
        audio.stop()
    room.queue_free()
    await frames(5)
    print("IGNOTUM LIGHT SWITCH: %d checks, %d failures" % [checks, failures])
    get_tree().quit(0 if failures == 0 else 1)

func verify_interaction_and_connections() -> void:
    var ceiling: Node2D = load("res://scenes/objects/interiors/lighting/ceiling_lamp.tscn").instantiate()
    ceiling.name = "TestCeiling"
    room.get_node("Props").add_child(ceiling)
    var floor_lamp: Node2D = load("res://scenes/objects/interiors/lighting/floor_lamp.tscn").instantiate()
    floor_lamp.name = "TestFloorLamp"
    room.get_node("Props").add_child(floor_lamp)
    var clue := Label.new()
    clue.name = "HiddenClue"
    room.add_child(clue)
    var targets: Array[NodePath] = [NodePath("../../RoomLight"), NodePath("../../Props/TestCeiling"), NodePath("../../Props/TestFloorLamp/Light"), NodePath("../../Props/Streetlamp/WarmLight")]
    var switch := make_switch("test_room_lights", targets)
    switch.reveal_when_off.assign([NodePath("../../HiddenClue")])
    var emitted := [0]
    switch.toggled.connect(func(_on: bool): emitted[0] += 1)
    await frames()
    var light: PointLight2D = room.get_node("RoomLight")
    var powered: PointLight2D = room.get_node("Props/Streetlamp/WarmLight")
    var energy := light.energy
    var tint := light.color
    var radius := light.texture_scale
    var ambient: Color = room.get_node("AmbientTint").color
    var flashlight: PointLight2D = player.get_node("Aim/Gun/Flashlight")
    var flashlight_on := flashlight.enabled
    check(switch.is_on and light.enabled and ceiling.light_enabled and floor_lamp.light_enabled and not clue.visible, "Default switch powers all assigned native/root/child lights and hides the optional dark-only clue")
    check(switch.is_in_group("interactable") and bool(Game.world.get(switch.state_key(), false)), "Switch participates in interactions and records its initial state")
    player.global_position = switch.global_position + Vector2(20, 0)
    await frames()
    check(hud.get_node("Root/Prompt").text == "Turn lights off", "Nearby interaction offers the current switch action")
    await key(KEY_E, true, false, false)
    check(not switch.is_on and not light.enabled and not ceiling.get_node("Light").enabled and not floor_lamp.get_node("Light").enabled and not powered.enabled, "E turns off every connected light")
    check(not ceiling.light_enabled and not floor_lamp.light_enabled and clue.visible and emitted[0] == 1, "Lamp root settings synchronize, clue appears and toggle signal fires once")
    check(switch.get_node("Artwork/Lever").position.y == 2 and hud.get_node("Root/Prompt").text == "Turn lights on", "Off position and nearby prompt update immediately")
    check(flashlight.enabled == flashlight_on and room.get_node("AmbientTint").color == ambient, "Switch does not change the player's flashlight or global ambient lighting")
    check(light.energy == energy and light.color == tint and light.texture_scale == radius, "Native light color, energy and range are preserved")
    ceiling.color_variant = 1
    floor_lamp.light_energy = 1.25
    Game.changed.emit()
    await frames()
    check(not ceiling.get_node("Light").enabled and not floor_lamp.get_node("Light").enabled and not powered.enabled, "Art refreshes and power-channel notifications cannot turn switched-off lights back on")
    await key(KEY_E, true, true)
    check(not switch.is_on and emitted[0] == 1, "Keyboard repeat does not repeatedly toggle a held interaction")
    await key(KEY_E, false)
    await key(KEY_E)
    check(switch.is_on and light.enabled and ceiling.get_node("Light").enabled and floor_lamp.get_node("Light").enabled and powered.enabled and not clue.visible, "A second interaction restores lights and hides the clue")
    check(switch.get_node("Artwork/Lever").position.y == -2 and emitted[0] == 2 and not get_tree().paused, "On pose, signal and uninterrupted exploration remain consistent")
    get_tree().paused = true
    switch.interact(player)
    check(switch.is_on, "Paused gameplay cannot toggle a switch")
    get_tree().paused = false
    Game.transitioning = true
    switch.interact(player)
    check(switch.is_on, "Scene transitions cannot toggle a switch")
    Game.transitioning = false
    Game.health = 0
    switch.interact(player)
    check(switch.is_on and not switch.is_available(), "A defeated player cannot use a switch")
    Game.health = 100
    switch.queue_free()
    await frames()
    ceiling.queue_free()
    floor_lamp.queue_free()
    clue.queue_free()
    await frames()

func verify_order_and_linked_switches() -> void:
    # Add the switch before its connected lamp to catch sibling _ready order bugs.
    var switch := make_switch("initially_off", [NodePath("../../Props/LaterLamp")], false)
    var lamp: Node2D = load("res://scenes/objects/interiors/lighting/table_lamp.tscn").instantiate()
    lamp.name = "LaterLamp"
    room.get_node("Props").add_child(lamp)
    await frames()
    check(not switch.is_on and not lamp.get_node("Light").enabled, "Starting Off takes effect even when the switch is earlier in the Scene tree than its lamp")
    var other := make_switch("independent", [NodePath("../../RoomLight")])
    await frames()
    other.interact(player)
    check(not other.is_on and not switch.is_on and not lamp.get_node("Light").enabled, "Separate switch IDs keep independent circuits")
    var linked := make_switch("initially_off", [NodePath("../../Props/LaterLamp")], false)
    await frames()
    switch.interact(player)
    check(switch.is_on and linked.is_on and lamp.get_node("Light").enabled, "Explicitly matching IDs link switch positions and circuit state")
    linked.interact(player)
    check(not switch.is_on and not linked.is_on and not lamp.get_node("Light").enabled, "Either linked switch can turn the shared circuit off")
    switch.connected_lights.append(NodePath("../../MissingLamp"))
    switch.connected_lights.append(NodePath("../../AmbientTint"))
    switch.reveal_when_off.append(NodePath("../../MissingClue"))
    check(switch._get_configuration_warnings().size() == 3, "Missing or invalid connections produce actionable editor warnings")
    switch.interact(player)
    await frames()
    check(switch.is_on and lamp.get_node("Light").enabled, "A missing optional connection does not break the remaining lights")
    var fallback := make_switch("", [NodePath("../../RoomLight")])
    await frames()
    check(fallback.state_key().contains(room.scene_file_path) and fallback.state_key().contains("Interactables/"), "Blank IDs fall back to stable scene and node paths")
    for node in [switch, linked, other, fallback, lamp]:
        node.queue_free()
    await frames()

func verify_saves() -> void:
    var switch := make_switch("saved_room", [NodePath("../../RoomLight")])
    await frames()
    player.global_position = bike.global_position + Vector2(-25, 0)
    await frames()
    check(Game.save_slot(0, bike), "Bicycle slot A saves lights on")
    switch.interact(player)
    await frames()
    check(Game.save_slot(1, bike), "Bicycle slot B saves lights off")
    var a: Dictionary = Game._read_slot(0)
    var b: Dictionary = Game._read_slot(1)
    check(bool(a["world"][switch.state_key()]) and not bool(b["world"][switch.state_key()]), "On-disk slots preserve independent true and false light states")
    check(Game.load_slot(0), "Slot A loads through the real save system")
    await frames(8)
    refresh_room()
    switch = make_switch("saved_room", [NodePath("../../RoomLight")], false)
    await frames()
    check(switch.is_on and room.get_node("RoomLight").enabled, "Saved On overrides the Inspector default when loading A")
    check(Game.load_slot(1), "Slot B loads through the real save system")
    await frames(8)
    refresh_room()
    switch = make_switch("saved_room", [NodePath("../../RoomLight")])
    await frames()
    check(not switch.is_on and not room.get_node("RoomLight").enabled, "Saved Off overrides the Inspector default when loading B")
    switch.queue_free()
    await frames()
    switch = make_switch("saved_room", [NodePath("../../RoomLight")])
    await frames()
    check(not switch.is_on and not room.get_node("RoomLight").enabled, "Returning to a room preserves the off state without another toggle")
