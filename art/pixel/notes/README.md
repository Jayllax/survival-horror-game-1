# Side-view notes

Five native transparent PNGs, all on a **20×12 pixel canvas**, displayed at **2×** by the note scenes. Edit these PNGs directly in Pixilart; there are no enlarged runtime copies.

| PNG | Appearance |
| --- | --- |
| `note_flat.png` | Almost-flat single sheet, two native pixels high |
| `note_folded.png` | Folded letter |
| `note_crumpled.png` | Small crumpled paper ball |
| `note_creased.png` | Low sheet with a slight crease and level ends |
| `note_stack.png` | Small paper stack |

The sprites use only `#3b2d30`, `#ccbb98`, `#b0917d` and `#e6ebd6` from `art/pixel/ignotum.gpl`. Silhouettes and color placement are horizontally symmetric. Alpha is hard 0/255, without antialiased edges. The last canvas row rests on the common surface baseline; keep the canvas size and bottom alignment when editing.

Reusable scenes are in `scenes/objects/notes/`. See the [setup guide](../../../docs/guides/NOTE_VARIANTS_GUIDE.md) and [native/game-scale preview](../../../docs/previews/side-view-notes.png). The preview is documentation, not another set of game assets.
