# House heights

All eight existing house colours have matching one- and three-storey sprites.

| Height | PNG folder | Native dimensions | Size at the usual 2x sprite scale |
| --- | --- | --- | --- |
| One storey | `1_storey/` | 96 x 92 | 192 x 184 |
| Two storeys (original) | This folder | 96 x 128 | 192 x 256 |
| Three storeys | `3_storey/` | 96 x 164 | 192 x 328 |

Each subfolder contains `house_cream.png`, `house_dusty_rose.png`,
`house_pale_olive.png`, `house_plum.png`, `house_sage.png`,
`house_slate_blue.png`, `house_teal.png`, and `house_terracotta.png`.

These are actual pixel copies from the original two-storey PNGs. One floor is
removed or repeated at its original 36-pixel pitch. The roof, chimney, door,
windows, colour values, shading and pixel scale come directly from each source.
The corner bricks are copied beside each window row at the original offset.
The original two-storey files remain byte-for-byte identical to the upload.

Use the PNGs directly as Sprite2D textures, with nearest-neighbour filtering and
the same 2x scale as the existing native house variations. To place a centred
Sprite2D with its bottom at its node origin, set its offset to `(0, -46)` for
one storey or `(0, -82)` for three storeys. The height changes by 72 world pixels
per floor at 2x scale; the width stays fixed. Level placements and collision
shapes are authored separately.

To rebuild the new sprites after deliberately editing the original PNGs, run
`bash tools/build_house_heights.sh` from the project. It requires ImageMagick 7
and overwrites the one- and three-storey exports using the existing pixels.
