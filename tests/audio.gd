extends Node
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
    checks += 1
    if ok: print("PASS: "+text)
    else:
        failures += 1
        push_error("FAIL: "+text)
func frames(count: int = 4) -> void:
    for i in count:
        await get_tree().physics_frame
        await get_tree().process_frame
func enter(path: String) -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file(path)
    await frames(6)
    for enemy in get_tree().get_nodes_in_group("enemy"):
        enemy.process_mode = Node.PROCESS_MODE_DISABLED
func voice_for(layer: Node, cue: AudioCue) -> AudioStreamPlayer:
    for channel in layer.channels:
        if channel["cue"]==cue and channel["player"].playing:
            return channel["player"]
    return null
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().current_scene = null
    run.call_deferred()
func run() -> void:
    Game.reset_run()
    check(AudioServer.get_bus_index("Music")>=0 and AudioServer.get_bus_index("Ambience")>=0 and AudioServer.get_bus_index("SFX")>=0, "Music, ambience and effects have separate buses beneath Master")
    var intro: AudioCue = load("res://data/audio/music/ambient_track_2.tres")
    var town: AudioCue = load("res://data/audio/music/ambient_track_1.tres")
    var safe: AudioCue = load("res://data/audio/music/save_room_1.tres")
    var forest: AudioCue = load("res://data/audio/ambience/forest.tres")
    var looped := intro.playback_stream() as AudioStreamMP3
    check(looped.loop and not (intro.stream as AudioStreamMP3).loop, "Music loops on a private playback resource without altering the imported recording")
    check(looped.get_length()>35 and safe.stream.get_length()>70, "The complete uploaded introduction and safe-room pieces load")
    var wav_cue := AudioCue.new()
    wav_cue.stream = load("res://audio/footsteps/concrete/step_01.wav")
    var wave := wav_cue.playback_stream() as AudioStreamWAV
    check(wave.loop_mode==AudioStreamWAV.LOOP_FORWARD and wave.loop_end>0, "The reusable cue also supports native WAV loops")
    await enter("res://scenes/levels/introduction_area_1.tscn")
    var intro_voice := voice_for(GameAudio.music,intro)
    check(GameAudio.music.current_cue==intro and intro_voice!=null, "The first introduction area starts ambient_track_2")
    if intro_voice == null:
        GameAudio.stop_all()
        print("IGNOTUM AUDIO: %d checks, %d failures" % [checks,failures])
        get_tree().quit(1)
        return
    intro_voice.seek(7.0)
    await frames(2)
    var stream_before: AudioStream = intro_voice.stream
    await enter("res://scenes/levels/introduction_area_2.tscn")
    check(voice_for(GameAudio.music,intro)==intro_voice and intro_voice.stream==stream_before and intro_voice.get_playback_position()>=6.9, "The second introduction area continues the same player, stream and position instead of restarting")
    check(not get_tree().current_scene.get_node("AmbientSound").playing, "The old scene drone does not play over the new soundtrack")
    await enter("res://scenes/levels/town_01.tscn")
    check(GameAudio.music.current_cue==town and voice_for(GameAudio.music,town)!=null and intro_voice.playing, "Entering town starts ambient_track_1 while the introduction fades away")
    await get_tree().create_timer(2.0).timeout
    check(not intro_voice.playing, "An outgoing music voice stops when its crossfade completes")
    await enter("res://tests/fixtures/audio_sandbox.tscn")
    var room: Node2D = get_tree().current_scene
    check(GameAudio.music.current_cue==town, "Unassigned connected rooms inherit the region theme")
    check(GameAudio.ambience.current_cue==forest and voice_for(GameAudio.ambience,forest)!=null, "Looping forest ambience plays independently of music")
    var music_voice := voice_for(GameAudio.music,town)
    get_tree().paused = true
    await frames()
    check(music_voice.playing and not music_voice.stream_paused, "Music continues through paused gameplay and dialogue")
    get_tree().paused = false
    GameAudio.use_location(room,safe,true,forest,false)
    await frames()
    check(GameAudio.music.current_cue==safe and GameAudio.region_music==town, "A local safe-room cue overrides the soundtrack without replacing the region theme")
    GameAudio.use_location(room,null,true,forest,true)
    await frames()
    check(GameAudio.music.current_cue==town, "Leaving the safe-room override returns to the region theme")
    # Sight and multiple enemies. AI movement is frozen; the actual vision queries remain live.
    GameAudio.combat_fade_in = 0.05
    GameAudio.combat_fade_out = 0.1
    GameAudio.lost_sight_grace = 0.05
    var player: CharacterBody2D = room.get_node("Actors/Player")
    var enemy: CharacterBody2D = room.get_node("Actors/Enemy")
    var second: CharacterBody2D = room.get_node("Actors/SecondSleeper")
    player.global_position = Vector2(750,588)
    player.velocity = Vector2.ZERO
    enemy.global_position = Vector2(850,588)
    enemy.direction = -1
    enemy.wake_proximity_radius = 0
    enemy.change_state(enemy.State.SLEEPING)
    await frames()
    check(not GameAudio.combat_active, "A sleeping enemy does not trigger combat music just because the player is nearby")
    enemy.change_state(enemy.State.IDLE)
    enemy.sense(player)
    await frames(7)
    check(GameAudio.combat_active and GameAudio.combat.current_cue==GameAudio.combat_music, "An enemy actually spotting the player starts scary_2")
    check(GameAudio.music.mix_gain<0.5 and voice_for(GameAudio.music,town)!=null, "Combat ducks the background track while preserving its playback")
    GameAudio.use_location(room,safe,true,forest,false)
    await frames(7)
    check(not GameAudio.combat_active, "A dedicated safe-room audio setting can suppress combat music")
    GameAudio.use_location(room,null,true,forest,true)
    await frames(7)
    var barrier: CollisionShape2D = room.get_node("Geometry/SightBlocker/Shape")
    barrier.set_deferred("disabled",false)
    await frames(14)
    check(enemy.state==enemy.State.CHASE and not GameAudio.combat_active, "Losing line of sight fades combat music even while the enemy remembers the player")
    check(GameAudio.music.mix_gain>0.95, "The normal soundtrack returns after sight is lost")
    enemy.change_state(enemy.State.INVESTIGATE)
    enemy.hear_noise(player.global_position,850,player)
    await frames()
    check(not GameAudio.combat_active, "Hearing an obstructed noise alone does not start combat music")
    barrier.set_deferred("disabled",true)
    enemy.change_state(enemy.State.CHASE)
    second.global_position = Vector2(880,588)
    second.direction = -1
    second.change_state(second.State.CHASE)
    await frames(7)
    enemy.take_damage(9999)
    await frames(8)
    check(GameAudio.combat_active, "Killing one enemy does not stop combat music while another enemy can still see the player")
    second.take_damage(9999)
    await frames(14)
    check(not GameAudio.combat_active and GameAudio.music.mix_gain>0.95, "Killing the last seeing enemy restores the location soundtrack")
    # Actual animation contacts, floor detection and material zones drive audible steps.
    var steps: Node2D = player.get_node("Footsteps")
    var concrete: FootstepSurface = load("res://data/audio/footsteps/concrete.tres")
    var dirt: FootstepSurface = load("res://data/audio/footsteps/dirt.tres")
    check(concrete.samples.size()==6 and dirt.samples.size()==6, "Each supplied footstep recording provides six short variations")
    player.global_position = Vector2(100,588)
    player.velocity = Vector2.ZERO
    await frames(6)
    check(steps.current_surface()==concrete, "Concrete is the default player footstep surface")
    var initial_steps: int = steps.steps_played
    await frames(20)
    check(steps.steps_played==initial_steps, "Standing still produces no footsteps")
    Input.action_press("move_right")
    await frames(50)
    Input.action_release("move_right")
    var walking_steps: int = steps.steps_played-initial_steps
    check(walking_steps>0 and concrete.samples.has(steps.last_sample), "Walking plays concrete samples at movement-animation contact frames")
    await frames(4)
    player.global_position = Vector2(1000,588)
    player.velocity = Vector2.ZERO
    await frames(4)
    initial_steps = steps.steps_played
    Input.action_press("sprint")
    Input.action_press("move_right")
    await frames(50)
    Input.action_release("sprint")
    Input.action_release("move_right")
    check(steps.steps_played-initial_steps>walking_steps, "The faster sprint animation naturally produces a faster step cadence")
    player.global_position = Vector2(260,588)
    player.velocity = Vector2.ZERO
    await frames(6)
    check(steps.current_surface()==dirt, "An authored dirt Area2D selects the matching footstep bank")
    initial_steps = steps.steps_played
    Input.action_press("move_right")
    await frames(40)
    Input.action_release("move_right")
    check(steps.steps_played>initial_steps and dirt.samples.has(steps.last_sample), "Walking within the dirt zone plays dirt samples")
    await frames(4)
    var noise_count := [0]
    Game.noise_emitted.connect(func(_position,_radius,source):
        if source==player:noise_count[0]+=1)
    initial_steps = steps.steps_played
    Input.action_press("crouch")
    Input.action_press("move_right")
    await frames(45)
    Input.action_release("move_right")
    Input.action_release("crouch")
    var recent: AudioStreamPlayer = steps.voices[(steps.next_player+steps.voices.size()-1)%steps.voices.size()]
    check(steps.steps_played>initial_steps and recent.volume_db<=dirt.volume_db-10, "Crouch footsteps follow the crouch animation and play more quietly")
    check(noise_count[0]==0, "Audible crouch steps do not change the player's existing zero-noise stealth rule")
    await frames(4)
    initial_steps = steps.steps_played
    Input.action_press("move_right")
    Input.action_press("jump")
    await frames(2)
    Input.action_release("jump")
    await frames(10)
    check(not player.is_on_floor() and steps.steps_played==initial_steps, "The player makes no walking sounds while airborne")
    Input.action_release("move_right")
    await frames(30)
    get_tree().paused = true
    initial_steps = steps.steps_played
    await frames(6)
    check(steps.voices.all(func(voice):return not voice.playing) and steps.steps_played==initial_steps, "Pause stops footstep voices without pausing the soundtrack")
    get_tree().paused = false
    GameAudio.music.play_cue(intro,0.1)
    GameAudio.music.play_cue(safe,0.1)
    GameAudio.music.play_cue(null,0.1)
    await frames(16)
    check(GameAudio.music.current_cue==null and not GameAudio.music.get_node("A").playing and not GameAudio.music.get_node("B").playing, "Rapid changes followed by silence cancel pending cues and retire both voices")
    GameAudio.use_location(room,town,true,forest,true)
    await frames()
    await enter("res://scenes/ui/main_menu.tscn")
    check(GameAudio.music.current_cue==null and GameAudio.ambience.current_cue==null and not GameAudio.combat_active, "Returning to the main menu fades gameplay music and ambience out")
    GameAudio.stop_all()
    await get_tree().create_timer(0.2).timeout
    print("IGNOTUM AUDIO: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures==0 else 1)
