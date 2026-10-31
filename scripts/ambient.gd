extends AudioStreamPlayer
func _ready() -> void:
    if "use_legacy_ambience" in get_parent() and not get_parent().use_legacy_ambience:
        autoplay = false
        stop()
        return
    bus = &"Ambience"
    finished.connect(play)
