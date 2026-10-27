# Simplified asset redesign / visual reference

`simplified_reference.png` explores the designer's supplied player, ammunition sprite, and palette. It is a visual direction sheet, not a pixel-exact production atlas: the background, lettering, and illustrative size labels are part of the image. Existing game textures and the designer's own replacements have not been overwritten.

## What to carry into the production sprites

- Use the supplied player as the scale and shape reference.
- Give walls large uninterrupted color areas. Use a few isolated 2–4-pixel wear clusters instead of drawing every brick.
- Give roofs one main color and one broad shadow area. Omit shingle grids.
- Reduce window frames and door panels to simple readable blocks.
- Use the designer's palette directly in the pixel editor. Limit each material to roughly 2–3 of those colors.
- Keep props and inventory icons equally simple. Small objects should not have finer texture than the character.

## One consistent pixel scale

Keep the player's production frame size at 20×36 native pixels, with six horizontal frames, unless the animation/collision layout is deliberately updated as well. A useful reduced architectural target is approximately 80–96 pixels wide and 112–128 pixels tall per building. Doors should be tall enough for the player, about 36–40 native pixels.

Use one consistent 2× nearest-neighbor display scale for native sprites. Reducing a building's native dimensions and then stretching it back to the old world dimensions would make its pixels larger than the player's. Reposition the building's baseline and surrounding decoration when adopting a smaller silhouette instead.

The original house textures were 160×170 native pixels. Larger buildings naturally contain more pixels than a character; the visual mismatch also came from dense brick/roof detailing. Reducing both the architectural footprint and surface noise produces a simpler kit without changing the player's drawing style.

Use this sheet beside the pixel editor while making the individual transparent PNGs. Take exact swatch values from the designer's original palette file rather than sampling the generated concept sheet, which can contain intermediate shades. The existing `art/pixel/source/` and `art/pixel/` files remain the current game assets.
