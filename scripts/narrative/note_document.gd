class_name NoteDocument
extends Resource
## Create a .tres per note, then assign it to a placed Note instance.
@export var title: String = "Untitled note"
@export_multiline var text: String = ""
@export_group("Text appearance (optional)")
## Leave empty to use the shared note reader's current font.
@export var body_font: Font
## Zero keeps the shared reader's font size.
@export_range(0, 72, 1) var body_font_size: int = 0
