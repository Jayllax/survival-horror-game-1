extends SceneTree
## Optional: godot --headless --path . --script tools/build_bicycle.gd -- --write
## Builds one native-resolution PNG. The scene displays it at 2x; no enlarged duplicate.
const COLORS := ["#24222e", "#344f69", "#4e6474", "#8f6c61", "#ccbb98", "#b0866c"]
var artwork := Image.create(32, 28, false, Image.FORMAT_RGBA8)

func rect(x: int, y: int, width: int, height: int, color: int) -> void:
    artwork.fill_rect(Rect2i(x, y, width, height), Color(COLORS[color]))

func pair(x: int, y: int, width: int, height: int, color: int) -> void:
    rect(x, y, width, height, color)
    rect(32 - x - width, y, width, height, color)

func _initialize() -> void:
    if not "--write" in OS.get_cmdline_user_args():
        print("Add -- --write to generate the bicycle sprite.")
        quit()
        return
    artwork.fill(Color.TRANSPARENT)
    # Front elevation: every pair and central rectangle is exactly mirrored.
    pair(1, 2, 9, 3, 0)
    pair(2, 3, 6, 1, 3)
    pair(8, 3, 3, 3, 1)
    pair(10, 5, 3, 3, 1)
    pair(12, 7, 3, 3, 1)
    pair(9, 3, 2, 1, 2)
    pair(11, 5, 2, 1, 2)
    rect(14, 7, 4, 9, 0)
    rect(15, 8, 2, 8, 2)
    # Saddle, centered bell and lamp.
    rect(11, 10, 10, 3, 0)
    rect(12, 10, 8, 2, 3)
    rect(14, 0, 4, 3, 0)
    rect(14, 1, 4, 2, 5)
    rect(15, 0, 2, 1, 4)
    rect(12, 12, 8, 4, 0)
    rect(13, 11, 6, 6, 0)
    rect(13, 12, 6, 4, 5)
    rect(14, 12, 4, 3, 4)
    # Equal forks and pedals around the centered front tire.
    pair(10, 17, 3, 9, 1)
    pair(10, 18, 1, 7, 2)
    pair(5, 23, 8, 2, 1)
    pair(4, 22, 7, 4, 0)
    pair(5, 23, 5, 1, 3)
    rect(13, 18, 6, 9, 0)
    rect(14, 17, 4, 11, 0)
    rect(15, 19, 2, 7, 1)
    var error := artwork.save_png("res://art/pixel/bicycle.png")
    print("Bicycle PNG: ", error_string(error))
    quit(error)
