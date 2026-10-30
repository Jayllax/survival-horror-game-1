# Ignotum fonts

| Role | Font / resource |
| --- | --- |
| Main title | `styles/main_title.tres`: Cormorant Garamond, weight 600, 2 px letter spacing |
| All general UI, menus, dialogue, buttons, inventory numbers and prompts | `styles/ui_text.tres`: Marcellus |
| Menu, inventory and puzzle headings; speaker names | `marcellus/Marcellus-Regular.ttf` |
| Save-slot records | `styles/typewritten_document.tres`: Special Elite |
| Note and examination titles | `im_fell_english/IMFellEnglish-Regular.ttf` |
| Note contents only | Designer's existing `lakeside-castle.regular.ttf`, preserved by request |
| Optional individual typewritten documents | `styles/typewritten_document.tres`: Special Elite |

The existing font files, colors and layout are retained. Old fonts are no longer referenced by the interface, except Lakeside Castle in note contents. General interface fonts share the `ui_text.tres` resource; save-slot text uses the typewriter preset. The four new fonts were downloaded unmodified from the official [Google Fonts repository](https://github.com/google/fonts). Cormorant Garamond, IM Fell English and Marcellus use SIL OFL 1.1; Special Elite uses Apache 2.0. Each family folder contains its license.

`styles/main_title.tres` references `third_party_notices.tres`, containing the complete licenses and Special Elite's embedded copyright notice. This dependency includes the notices in Godot's exported resource pack even when plain text files are excluded. Keep this dependency when replacing the title font. These notices cover the four added font families.

See [FONT_GUIDE.md](../../docs/guides/FONT_GUIDE.md) for Inspector instructions.
