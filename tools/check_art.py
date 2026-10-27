#!/usr/bin/env python3
"""Optional art check. Requires Pillow; never changes project files."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parents[1]
m=json.loads((root/'art/pixel/simple_assets.json').read_text())
allowed={tuple(bytes.fromhex(c[1:]))+(255,) for c in m['palette'].values()} | {(0,0,0,0)}
for name,entry in m['assets'].items():
    with Image.open(root/f'art/pixel/source/{name}.png') as original:
        im=original.convert('RGBA')
        assert list(im.size)==entry['native_size'],name+' native dimensions'
        pixels=set(im.getdata())
        assert pixels <= allowed,name+' palette'
        assert {p[3] for p in pixels} <= {0,255},name+' partial alpha'
        if not entry.get('tile') and not entry.get('solid_rectangle'):
            assert any(p[3]==0 for p in pixels),name+' transparent canvas'
        with Image.open(root/f'art/pixel/{name}.png') as export:
            assert list(export.size)==entry['game_size'],name+' game dimensions'
            expected=im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST)
            assert export.convert('RGBA').tobytes()==expected.tobytes(),name+' exact 2x pixels'
print(f'PASS: {len(m["assets"])} native/export pairs use the palette and exact 2x nearest-neighbor pixels.')
