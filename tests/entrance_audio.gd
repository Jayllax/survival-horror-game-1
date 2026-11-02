extends Node
var checks := 0
var failures := 0
const ROOM := "res://tests/fixtures/pushable_sandbox.tscn"

func check(ok: bool, description: String) -> void:
    checks += 1
    if ok: print("PASS: "+description)
    else:
        failures += 1
        push_error(description)

func frames(count: int = 3) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame

func voices() -> Array[Node]:
    return Transition.find_children("EntranceSound*", "AudioStreamPlayer", false, false)

func _ready() -> void:
    get_tree().current_scene = null
    run.call_deferred()

func run() -> void:
    Game.reset_run()
    var room: Node = load(ROOM).instantiate()
    get_tree().root.add_child(room)
    get_tree().current_scene = room
    await frames(8)
    var entrance: Area2D = load("res://scenes/objects/entrance.tscn").instantiate()
    var sample := AudioStreamWAV.new()
    sample.format = AudioStreamWAV.FORMAT_16_BITS
    sample.mix_rate = 22050
    sample.loop_mode = AudioStreamWAV.LOOP_FORWARD
    sample.loop_end = 66150
    var silence := PackedByteArray()
    silence.resize(132300)
    sample.data = silence
    entrance.entrance_sound = sample
    entrance.entrance_sound_volume_db = -13
    entrance.entrance_sound_pitch = 0.9
    entrance.destination_scene = ROOM
    entrance.required_key = "gate_key"
    room.add_child(entrance)
    entrance.interact(null)
    await frames(3)
    check(not Transition.busy and voices().is_empty(), "Locked entrances do not play their transition sound")
    entrance.required_key = ""
    entrance.destination_scene = "res://missing_destination.tscn"
    entrance.interact(null)
    await frames(3)
    check(not Transition.busy and voices().is_empty(), "Invalid destinations remain silent")
    entrance.destination_scene = ROOM
    entrance.required_key = "gate_key"
    Game.add_item("gate_key",1)
    entrance.interact(null)
    Game.take_item("gate_key",1)
    await get_tree().create_timer(0.9).timeout
    check(not Transition.busy and get_tree().current_scene==room and voices().is_empty(), "Losing a required key during the fade aborts silently and keeps the source scene")
    entrance.required_key = ""
    entrance.interact(null)
    entrance.interact(null)
    await get_tree().create_timer(0.45).timeout
    check(not is_instance_valid(entrance) and get_tree().current_scene!=room and voices().size()==1, "Successful travel frees the entrance but one persistent voice survives scene replacement")
    if voices().size()==1:
        var voice: AudioStreamPlayer = voices()[0]
        check(voice.playing and voice.bus==&"SFX" and voice.volume_db==-13 and is_equal_approx(voice.pitch_scale,0.9), "Entrance audio uses its assigned stream, volume, pitch and SFX bus")
        check(voice.stream.loop_mode==AudioStreamWAV.LOOP_DISABLED and sample.loop_mode==AudioStreamWAV.LOOP_FORWARD, "Entrance audio plays once without modifying the shared imported resource")
    await get_tree().create_timer(4.0).timeout
    check(voices().is_empty(), "Completed transition sounds free their persistent voice")
    room = get_tree().current_scene
    room.queue_free()
    await frames(5)
    GameAudio.stop_all()
    await get_tree().create_timer(0.2).timeout
    print("IGNOTUM ENTRANCE AUDIO: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures==0 else 1)
