#!/usr/bin/env bash
# Requires ImageMagick 7. Copies original sprite pixels; never redraws or resizes.
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
houses="$project_root/art/pixel/house_variants"
parts="$(mktemp -d)"
trap 'rm -rf "$parts"' EXIT
mkdir -p "$houses/1_storey" "$houses/3_storey"
for source_sprite in "$houses"/house_*.png; do
    name="$(basename "$source_sprite")"
    size="$(magick identify -format '%wx%h' "$source_sprite")"
    if [[ "$size" != '96x128' ]]; then
        echo "Expected a 96x128 source: $source_sprite ($size)" >&2
        exit 1
    fi
    # The 36-pixel floor begins at row 49. Keep the door header with ground.
    magick "$source_sprite" -crop 96x49+0+0 +repage PNG32:"$parts/roof.png"
    magick "$source_sprite" -crop 96x36+0+49 +repage PNG32:"$parts/floor.png"
    magick "$source_sprite" -crop 96x43+0+85 +repage PNG32:"$parts/ground.png"
    magick "$source_sprite" -crop 10x10+4+77 +repage PNG32:"$parts/brick_left.png"
    magick "$source_sprite" -crop 8x10+84+77 +repage PNG32:"$parts/brick_right.png"
    magick "$parts/roof.png" "$parts/ground.png" -append PNG32:"$parts/one.png"
    magick "$parts/roof.png" "$parts/floor.png" "$parts/floor.png" "$parts/ground.png" -append PNG32:"$parts/three.png"
    # Repeat both complete corner-brick patches at the same window-relative offset.
    magick "$parts/one.png" \
        "$parts/brick_left.png" -geometry +4+77 -compose Over -composite \
        "$parts/brick_right.png" -geometry +84+77 -compose Over -composite \
        PNG32:"$houses/1_storey/$name"
    magick "$parts/three.png" \
        "$parts/brick_left.png" -geometry +4+77 -compose Over -composite \
        "$parts/brick_right.png" -geometry +84+77 -compose Over -composite \
        "$parts/brick_left.png" -geometry +4+149 -compose Over -composite \
        "$parts/brick_right.png" -geometry +84+149 -compose Over -composite \
        PNG32:"$houses/3_storey/$name"
    echo "Built 1-storey and 3-storey $name"
done
