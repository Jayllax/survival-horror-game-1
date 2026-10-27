extends Control
func _ready() -> void:
    $Start.pressed.connect(new_game)
    $SaveMenu.closed.connect(func(): $Continue.grab_focus())
    $Quit.pressed.connect(func(): get_tree().quit())
    $Continue.disabled = not Game.has_saves()
    $Continue.pressed.connect(func(): $SaveMenu.open_load())
    $Options.pressed.connect(func(): $OptionsPanel.show())
    $OptionsPanel/Close.pressed.connect(func(): $OptionsPanel.hide())
    $OptionsPanel/Volume.value = AudioServer.get_bus_volume_db(0)
    $OptionsPanel/Volume.value_changed.connect(set_volume)
    $OptionsPanel/Fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
    $OptionsPanel/Fullscreen.toggled.connect(set_fullscreen)
    $Start.grab_focus()

func new_game() -> void:
    # Starting a run never overwrites any of the four manual save files.
    Game.start_game()

func set_volume(value: float) -> void:
    AudioServer.set_bus_volume_db(0, value)
    AudioServer.set_bus_mute(0, value <= -60)
    Game.save_settings()

func set_fullscreen(enabled: bool) -> void:
    if DisplayServer.get_name() != "headless":
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
    Game.save_settings()

func _unhandled_input(event: InputEvent) -> void:
    if not $SaveMenu.is_open() and event.is_action_pressed("pause"):
        $OptionsPanel.hide()
