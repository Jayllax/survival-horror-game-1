extends Node
## Two authored players preserve playback through changes and crossfade in linear amplitude.
var current_cue: AudioCue
var mix_gain: float = 1.0
var channels: Array[Dictionary] = []
var pending_cue: AudioCue
var pending_index := -1
var pending_fade := 1.5

func _ready() -> void:
	for player in [$A,$B]:
		channels.append({"player":player,"cue":null,"gain":0.0,"target":0.0,"speed":1.0})
		player.volume_db = -80.0

func set_target(channel: Dictionary, target: float, seconds: float) -> void:
	channel["target"] = target
	channel["speed"] = absf(target-float(channel["gain"]))/maxf(seconds,0.001)
	if seconds <= 0:
		channel["gain"] = target

func play_cue(cue: AudioCue, fade_override: float = -1.0) -> void:
	if cue != null and cue.stream == null:
		cue = null
	if current_cue == cue:
		return
	current_cue = cue
	pending_cue = null
	pending_index = -1
	var fade := fade_override if fade_override >= 0 else (cue.fade_seconds if cue else 1.5)
	var reuse := -1
	for i in channels.size():
		if cue != null and channels[i]["cue"] == cue and channels[i]["player"].playing:
			reuse = i
		set_target(channels[i],0.0,fade)
	if cue == null:
		return
	if reuse >= 0:
		set_target(channels[reuse],1.0,fade)
		return
	var index := 0 if float(channels[0]["gain"]) <= float(channels[1]["gain"]) else 1
	if float(channels[index]["gain"]) > 0.001 and fade > 0:
		# A third rapid change first retires the quieter voice without an abrupt cut.
		pending_cue = cue
		pending_index = index
		pending_fade = fade
		set_target(channels[index],0.0,minf(0.08,fade))
	else:
		start_channel(index,cue,fade)

func start_channel(index: int, cue: AudioCue, fade: float) -> void:
	var channel := channels[index]
	var player: AudioStreamPlayer = channel["player"]
	player.stop()
	channel["cue"] = cue
	channel["gain"] = 0.0
	player.stream = cue.playback_stream()
	player.volume_db = -80.0
	player.play()
	set_target(channel,1.0,fade)

func _process(delta: float) -> void:
	for index in channels.size():
		var channel := channels[index]
		channel["gain"] = move_toward(float(channel["gain"]),float(channel["target"]),float(channel["speed"])*delta)
		var player: AudioStreamPlayer = channel["player"]
		var cue: AudioCue = channel["cue"]
		var amplitude := float(channel["gain"])*mix_gain*(db_to_linear(cue.volume_db) if cue else 0.0)
		player.volume_db = linear_to_db(maxf(amplitude,0.0001))
		if float(channel["gain"]) <= 0.0001 and float(channel["target"]) == 0.0:
			player.stop()
			if pending_index == index and pending_cue != null:
				var next := pending_cue
				pending_cue = null
				pending_index = -1
				start_channel(index,next,pending_fade)

func stop_immediately() -> void:
	current_cue = null
	pending_cue = null
	pending_index = -1
	for channel in channels:
		channel["player"].stop()
		channel["player"].stream = null
		channel["cue"] = null
		channel["gain"] = 0.0
		channel["target"] = 0.0
