extends Control
func _ready() -> void:
    $Start.pressed.connect(Game.start_game)
    $Quit.pressed.connect(func(): get_tree().quit())
    $Start.grab_focus()
