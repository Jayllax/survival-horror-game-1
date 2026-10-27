# Simplified asset direction

`simplified_reference.png` is the earlier generated visual reference. It contains an illustrative background, labels, and non-production size annotations.

**The usable individual assets now live in `art/pixel/` and are connected to the game.** Their native editable drawings are in `art/pixel/source/`. `art/pixel/STYLE_SHEET.png` is rebuilt from those real sprite files rather than being a generated mockup.

See `ART_STYLE_GUIDE.md` at the project root for actual canvas sizes, palette, consistent pixel-scale rules, and replacement instructions. The production sprites use broad flat colors, sparse wear, and a fixed 2× world pixel scale. Existing player and ammo files are preserved.
