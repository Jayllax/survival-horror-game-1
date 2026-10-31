# Changing fonts

The main title uses Cormorant Garamond; menu headings and speaker names use Marcellus; note titles use IM Fell English. Your existing Lakeside Castle note-content font and transparent note panels are preserved. General dialogue and all other interface text now use the new fonts. Save-slot records use Special Elite.

## Make one note typewritten

1. Select a placed note in your level.
2. Expand its **Document** resource. Use a separate saved NoteDocument for each independently editable note.
3. Under **Text Appearance (optional)**, drag `art/fonts/styles/typewritten_document.tres` into **Body Font**.
4. Set **Body Font Size** to **20** as a starting point.

This uses Special Elite only for that document. Any imported `.ttf`/`.otf` can be assigned here instead. Clear **Body Font** to use the shared reader font; set **Body Font Size** to **0** to use its size. An override never carries over to the next ordinary note. Existing documents require no changes; text and saved read status are unaffected.

## Shared note and conversation fonts

Open `scenes/ui/story_ui.tscn` directly in the FileSystem dock.

| Node | Inspector setting |
| --- | --- |
| `NotePanel/Title` | Theme Overrides → Fonts → Font |
| `NotePanel/Body` | Theme Overrides → Fonts → Normal Font |
| `DialoguePanel/Speaker` | Theme Overrides → Fonts → Font |
| `DialoguePanel/Body` | Theme Overrides → Fonts → Normal Font |

Drag a font into the corresponding field. Font sizes are under **Theme Overrides → Font Sizes**. These shared settings apply whenever a document leaves its override empty. Speaker colors still come from DialogueSpeaker resources.

## Main title and other headings

The main-menu `Title` in `scenes/ui/main_menu.tscn` references `art/fonts/styles/main_title.tres`. In this FontVariation, **Variation OpenType → wght** is **600** and **Spacing → Glyph** is **2**. The Label's Font Size is **96**.

| Scene | Heading nodes |
| --- | --- |
| `scenes/ui/main_menu.tscn` | `Title`, `OptionsPanel/Title`, `Station/TownName` |
| `scenes/ui/hud.tscn` | `Root/InventoryPanel/Title`, `Root/InventoryPanel/ItemName`, `Root/PausePanel/Title`, `Root/PuzzlePanel/Title` |
| `scenes/ui/code_lock_ui.tscn` | `Center/Panel/Margin/Content/Title` |
| `scenes/ui/save_menu.tscn` | `Shade/Center/Panel/Margin/Content/Title` |

Other headings use **Theme Overrides → Fonts → Font**, with sizes in **Font Sizes**. No chapter or location-title overlay was added; the station's TownName remains blank unless you provide text.

The older **Examine** message uses `Root/NotePanel/Title` and `Root/NotePanel/Text` in `hud.tscn`. Its body now uses the shared Marcellus interface font.

General labels, buttons, dialogue, tooltips and code-drawn inventory counts share `art/fonts/styles/ui_text.tres`. Open that FontVariation and change **Base Font** to update the general interface in one place. `art/ui_theme.tres` references it for the default font and text-control types. It no longer uses Silkscreen, Copy Photo or Madawaska.

Save-slot buttons reference `art/fonts/styles/typewritten_document.tres`; change its **Base Font** to change those records. The main title and decorative headings keep their separate role-specific fonts listed above. Lakeside Castle is used only for the shared note-content reader. A note can still deliberately override its font through its Document resource.

## Licenses and preview

All four new fonts allow commercial game use. License files are beside the fonts; exportable copies are referenced by the main-title resource. See [art/fonts/README.md](../../art/fonts/README.md).

Run the main menu with **F5**, then read a note and talk to Jax in your own level. To compare typewriter text, assign the preset to one note and open an ordinary note afterwards. Long documents remain scrollable.

## Screenshots

These previews use the actual game interface; sample typography text exists only in the documentation images.

- [Main menu](../previews/fonts-main-menu.png)
- [Default note reader](../previews/fonts-note-reader.png)
- [Optional typewritten note](../previews/fonts-typewritten-note.png)
- [Conversation with Continue only](../previews/fonts-conversation.png)

- [Save-slot records](../previews/fonts-save-menu.png)
- [Inventory, buttons and item counts](../previews/fonts-inventory.png)
