#!/usr/bin/env python3
"""Build exact-grid production sprites, not crops of the illustrated design sheet.
Optional art tooling: Python + Pillow. Godot does not need either.
Run with --write to replace the scenery/prop/item PNGs; player and ammo are excluded.
"""
from pathlib import Path
import hashlib,json,sys
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'art/pixel'
# Small explicit color set derived from the approved visual direction.
PALETTE={
 'ink':'#342b3d','roof':'#513b50','roof_light':'#705065',
 'brick_shadow':'#74464e','brick':'#9a4f51','brick_light':'#b77566',
 'wood_shadow':'#75545a','wood':'#a17767','tan':'#c39b7d',
 'cream':'#ded1a5','ivory':'#e5dfbb','plaster':'#d4cba8',
 'metal_dark':'#405b59','metal':'#5b7c6e','metal_light':'#8ca896',
 'glass':'#354358','glass_light':'#536e80','mint':'#b4d1bd',
 'lavender':'#a49bb3','paving':'#73717b','paving_dark':'#585463'}
ASSETS={}
def color(v):return PALETTE.get(v,v)
def box(d,xy,c):d.rectangle(xy,fill=color(c))
def line(d,xy,c,width=1):d.line(xy,fill=color(c),width=width)
def poly(d,xy,c):d.polygon(xy,fill=color(c))
def make(name,w,h,draw,**notes):
 im=Image.new('RGBA',(w,h),(0,0,0,0));draw(ImageDraw.Draw(im),w,h)
 ASSETS[name]=(im,notes)
def window(d,x,y,w=18,h=25):
 box(d,(x-1,y-1,x+w,y+h),'tan');box(d,(x,y,x+w-1,y+h-1),'glass')
 box(d,(x+2,y+2,x+w//2-2,y+h//2-2),'glass_light')
 line(d,(x+w//2,y,x+w//2,y+h-1),'cream')
 line(d,(x,y+h//2,x+w-1,y+h//2),'cream')
 box(d,(x-2,y-3,x+w+1,y-2),'ivory');box(d,(x-2,y+h+1,x+w+1,y+h+2),'tan')
def door(d,x,y,w=22,h=42):
 box(d,(x,y,x+w-1,y+h-1),'tan');box(d,(x+2,y+2,x+w-3,y+h-1),'metal_dark')
 box(d,(x+4,y+4,x+w-5,y+14),'glass');line(d,(x+w//2,y+4,x+w//2,y+14),'metal')
 box(d,(x+5,y+19,x+8,y+h-5),'metal');box(d,(x+12,y+19,x+w-6,y+h-5),'metal')
 box(d,(x+w-5,y+23,x+w-4,y+24),'cream')
def chimney(d,x,y):
 box(d,(x,y,x+8,y+19),'brick');box(d,(x+1,y,x+2,y+16),'brick_light');box(d,(x-2,y-2,x+10,y),'tan')
def house(d,w,h,cream=False):
 wall='plaster' if cream else 'brick';wear='tan' if cream else 'brick_shadow'
 box(d,(4,35,w-5,h-3),wall)
 poly(d,[(0,37),(w//2,6),(w-1,37)],'roof')
 poly(d,[(w//2,6),(w-1,37),(w-8,37),(w//2,12)],'roof_light')
 chimney(d,w-22,9)
 box(d,(1,37,w-2,39),'cream');box(d,(4,40,w-5,42),'tan')
 window(d,17,53);window(d,w-35,53)
 window(d,w-35,h-38,h=23);door(d,15,h-44,h=42)
 for x,y in [(8,84),(w-17,89),(w-29,h-12)]:
  box(d,(x,y,x+3,y+1),wear);box(d,(x+3,y-2,x+5,y-1),wear)
 box(d,(4,h-3,w-5,h-1),'wood_shadow');box(d,(13,h-2,39,h-1),'paving')
make('house',96,128,lambda d,w,h:house(d,w,h),baseline=128)
make('house_cream',96,128,lambda d,w,h:house(d,w,h,True),baseline=128)
make('station',128,144,lambda d,w,h:house(d,w,h,True),baseline=144)
def shop(d,w,h):
 box(d,(5,34,w-6,h-1),'brick')
 poly(d,[(0,36),(19,10),(w-20,10),(w-1,36)],'roof');box(d,(1,36,w-2,39),'cream')
 chimney(d,92,8)
 window(d,22,47,h=21);window(d,88,47,h=21)
 box(d,(41,73,87,83),'ink');box(d,(43,75,85,81),'tan')
 poly(d,[(9,85),(w-10,85),(w-1,94),(0,94)],'metal');box(d,(1,95,w-2,97),'metal_dark')
 for x in [12,84]:
  box(d,(x,98,x+31,123),'tan');box(d,(x+2,100,x+29,121),'glass');box(d,(x+4,101,x+10,113),'glass_light')
  box(d,(x+3,119,x+12,121),'wood_shadow');box(d,(x+19,116,x+26,121),'wood')
 door(d,53,87,w=23,h=41)
 box(d,(5,126,w-6,127),'wood_shadow')
make('shop',128,128,shop,baseline=128)
make('door',24,44,lambda d,w,h:door(d,0,0,w,h),baseline=44,solid_rectangle=True)
def gate(d,w,h):
 for x in [1,w-5]:
  box(d,(x,2,x+3,h-1),'metal_dark');box(d,(x,2,x+1,h-1),'metal_light');box(d,(x-1,5,x+4,7),'metal')
 for x in range(10,w-6,8):box(d,(x,9,x+1,h-6),'metal')
 box(d,(4,12,w-5,14),'metal_light');box(d,(4,h-16,w-5,h-14),'metal')
 line(d,(7,38,15,43,26,47,38,43,47,38),'tan',2)
 for x,y in [(11,40),(19,44),(31,45),(41,41)]:box(d,(x,y,x+2,y+1),'ivory')
 box(d,(24,46,30,54),'cream');box(d,(26,49,27,51),'wood_shadow')
make('gate',55,85,gate,baseline=85)
def lamp(d,w,h):
 box(d,(10,22,12,h-4),'metal_dark');line(d,(10,24,10,h-6),'metal_light')
 box(d,(7,h-5,15,h-2),'metal');box(d,(5,h-2,17,h-1),'metal_dark')
 box(d,(8,2,20,5),'metal');box(d,(10,0,17,1),'metal_dark')
 poly(d,[(9,6),(19,6),(17,18),(11,18)],'cream');box(d,(13,7,15,16),'ivory')
 box(d,(8,5,20,6),'metal_dark');box(d,(10,18,18,20),'metal_dark')
make('lamp',24,96,lamp,baseline=96,light_center=[14,12])
def crate(d,w,h):
 box(d,(0,0,w-1,h-1),'wood_shadow');box(d,(2,2,w-3,h-3),'wood')
 box(d,(2,2,w-3,4),'tan');box(d,(2,h-5,w-3,h-3),'tan')
 line(d,(4,h-6,w-6,5),'wood_shadow',4);line(d,(5,h-6,w-5,5),'tan',2)
 for x,y in [(3,3),(w-5,3),(3,h-5),(w-5,h-5)]:box(d,(x,y,x+1,y+1),'ink')
make('crate',32,32,crate,baseline=32,solid_rectangle=True)
def bench(d,w,h):
 for y in [3,9]:box(d,(3,y,w-4,y+3),'wood')
 box(d,(1,17,w-2,20),'tan');box(d,(4,20,7,h-1),'metal_dark');box(d,(w-8,20,w-5,h-1),'metal_dark')
 for x in [5,w-7]:box(d,(x,4,x,5),'metal_light');box(d,(x,10,x,11),'metal_light')
make('bench',48,28,bench,baseline=28)
def bin_(d,w,h):
 box(d,(4,6,w-5,h-2),'metal');box(d,(3,5,w-4,8),'metal_light');box(d,(6,10,w-7,13),'metal_dark')
 box(d,(4,h-4,w-5,h-1),'metal_dark');box(d,(6,17,7,h-6),'metal_light')
make('bin',24,36,bin_,baseline=36)
def drain(d,w,h):
 box(d,(0,0,w-1,h-1),'paving_dark');box(d,(1,1,w-2,h-2),'ink')
 for x in range(4,w-2,5):box(d,(x,2,x+1,h-3),'paving')
make('drain',32,8,drain,baseline=8,solid_rectangle=True)
def pipe(d,w,h):
 box(d,(2,0,5,h-1),'glass');box(d,(2,0,3,h-1),'glass_light')
 for y in [12,h//2,h-14]:box(d,(0,y,7,y+2),'metal_dark')
make('pipe',8,100,pipe,baseline=100)
def sign(d,w,h):
 box(d,(1,1,w-2,h-2),'wood_shadow');box(d,(2,2,w-3,h-3),'tan')
 box(d,(2,2,w-3,3),'cream')
make('sign',50,22,sign)
def shelf(d,w,h):
 for x in [2,w-5]:box(d,(x,0,x+2,h-1),'wood_shadow')
 for y in [8,31,54,h-4]:box(d,(1,y,w-2,y+2),'wood')
 for x,y,c in [(7,18,'metal'),(25,13,'wood'),(45,21,'brick'),(10,42,'tan'),(37,38,'glass_light'),(49,61,'metal'),(17,60,'wood')]:
  box(d,(x,y,x+9,(y//23+1)*23+7),c)
make('shelf',64,72,shelf,baseline=72)
def radiator(d,w,h):
 for x in range(4,w-3,6):
  box(d,(x,2,x+3,h-4),'cream');line(d,(x,3,x,h-6),'ivory')
 box(d,(1,5,w-2,6),'tan');box(d,(1,h-6,w-2,h-5),'tan');box(d,(5,h-3,7,h-1),'wood_shadow');box(d,(w-8,h-3,w-6,h-1),'wood_shadow')
make('radiator',44,28,radiator,baseline=28)
def bollard(d,w,h):
 box(d,(3,2,6,h-2),'metal_dark');box(d,(2,1,7,3),'metal');box(d,(3,7,6,9),'cream');box(d,(1,h-2,8,h-1),'metal')
make('bollard',10,26,bollard,baseline=26)
def ground(d,w,h):
 box(d,(0,0,w-1,h-1),'paving_dark');line(d,(0,0,w-1,0),'paving');line(d,(16,0,16,15),'paving');line(d,(0,16,w-1,16),'paving');line(d,(0,17,0,31),'paving')
make('ground',32,32,ground,tile=True)
def plaster(d,w,h):
 box(d,(0,0,w-1,h-1),'plaster')
make('bricks',32,32,plaster,tile=True)
def floor(d,w,h):
 box(d,(0,0,w-1,h-1),'wood');line(d,(0,0,w-1,0),'wood_shadow');line(d,(0,8,w-1,8),'wood_shadow');line(d,(11,1,11,7),'wood_shadow');line(d,(26,9,26,15),'wood_shadow')
make('floor',32,16,floor,tile=True)
def gun(d,w,h):
 box(d,(1,1,16,4),'glass');box(d,(2,1,14,1),'glass_light');box(d,(4,4,7,7),'wood_shadow');box(d,(12,5,15,5),'tan')
make('gun',17,8,gun)
def item(name,draw,w=24,h=28):make(name,w,h,draw)
item('key',lambda d,w,h:(box(d,(3,4,8,10),'cream'),box(d,(5,6,6,8),'wood_shadow'),line(d,(8,10,16,19),'tan',2),box(d,(13,16,16,17),'cream')),20,24)
item('fuse',lambda d,w,h:(box(d,(3,4,14,8),'cream'),box(d,(2,3,4,9),'brick'),box(d,(13,3,15,9),'brick'),box(d,(5,4,6,7),'ivory')),18,12)
def cloth(d,w,h):
 poly(d,[(3,11),(14,7),(21,12),(17,20),(5,21),(1,16)],'mint');poly(d,[(1,16),(12,13),(21,12),(17,20),(5,21)],'metal_light');line(d,(5,17,13,15,17,16),'metal')
item('cloth',cloth)
def bottle(d,w,h):
 box(d,(9,2,14,5),'wood_shadow');box(d,(10,6,13,8),'tan');poly(d,[(9,8),(14,8),(17,12),(17,24),(6,24),(6,12)],'wood')
 box(d,(8,11,9,21),'tan');box(d,(7,15,16,21),'cream');box(d,(10,17,13,19),'wood_shadow')
item('antiseptic',bottle)
def dressing(d,w,h):
 poly(d,[(6,8),(16,7),(21,11),(19,21),(6,22),(2,18),(2,12)],'cream');box(d,(7,12,16,18),'ivory');line(d,(5,12,5,18,8,20,17,19),'tan');line(d,(8,13,8,17,14,17,14,13,10,13),'tan')
item('bandage',dressing)
def cutters(d,w,h):
 line(d,(4,25,11,12),'brick',3);line(d,(20,25,13,12),'brick',3)
 poly(d,[(10,14),(6,6),(8,3),(11,7),(13,7),(16,3),(18,6),(14,14)],'glass_light');box(d,(10,11,14,13),'glass')
item('bolt_cutters',cutters)
def notice(d,w,h):
 box(d,(2,1,w-3,h-2),'wood_shadow');box(d,(4,3,w-5,h-5),'cream')
 for y in [8,12,16,20]:line(d,(7,y,w-8-(3 if y==20 else 0),y),'tan')
make('notice',24,30,notice)
def switchboard(d,w,h):
 box(d,(1,1,w-2,h-2),'metal_dark');box(d,(3,3,w-4,h-4),'metal');box(d,(6,7,w-7,15),'glass')
 for x in [6,15,24]:
  box(d,(x,23,x+4,27),'cream');line(d,(x+2,23,x+2,25),'wood_shadow')
 box(d,(10,36,25,42),'metal_dark');box(d,(12,38,22,39),'metal_light')
make('switchboard',35,50,switchboard)
def enemy_frame(d,frame):
 shift=[0,1,2,0,-2,-1][frame]
 box(d,(8+shift,24,10+shift,34),'glass');box(d,(13-shift,24,15-shift,34),'glass')
 box(d,(6+shift,34,11+shift,35),'ink');box(d,(12-shift,34,17-shift,35),'ink')
 box(d,(7,13,15,26),'metal');box(d,(7,14,9,24),'metal_light')
 box(d,(8,4,14,12),'plaster');box(d,(7,3,14,5),'wood_shadow');box(d,(5,15,7,23),'metal_dark');box(d,(13,17,18,20),'metal_light')
sheet=Image.new('RGBA',(120,36))
for frame in range(6):
 cell=Image.new('RGBA',(20,36));enemy_frame(ImageDraw.Draw(cell),frame);sheet.paste(cell,(frame*20,0))
ASSETS['enemy']=(sheet,{'frames':6,'frame_size':[20,36]})

def write_assets():
 entries={}
 for name,(im,notes) in ASSETS.items():
  source=OUT/'source'/f'{name}.png';export=OUT/f'{name}.png'
  im.save(source)
  im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST).save(export)
  entries[name]={'native_size':list(im.size),'game_size':[im.width*2,im.height*2],**notes}
 (OUT/'simple_assets.json').write_text(json.dumps({'display_scale':2,'palette':PALETTE,'assets':entries,'preserved':['player','ammo']},indent=2)+'\n')
 (OUT/'ignotum.gpl').write_text('GIMP Palette\nName: Ignotum simplified\nColumns: 7\n#\n'+'\n'.join(f'{int(c[1:3],16)} {int(c[3:5],16)} {int(c[5:7],16)} {name}' for name,c in PALETTE.items())+'\n')
 # This contact sheet is built from the actual production files, not generated concept art.
 display=Image.new('RGB',(1000,2200),PALETTE['ink']);d=ImageDraw.Draw(display)
 font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',18);small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',12)
 d.text((24,20),'IGNOTUM / PRODUCTION SPRITES',fill=PALETTE['cream'],font=font)
 d.text((24,51),'Actual transparent PNG assets • shared 2x pixel grid • player / ammo preserved',fill=PALETTE['mint'],font=small)
 for i,(name,c) in enumerate(PALETTE.items()):
  x=24+i*45;d.rectangle((x,84,x+35,105),fill=c)
 x=24;y=140;row=0
 names=list(ASSETS)+['player','ammo']
 for name in names:
  im=Image.open(OUT/'source'/f'{name}.png').convert('RGBA');preview=im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST)
  if x+max(preview.width,105)>976:x=24;y+=row+38;row=0
  display.paste(preview,(x,y),preview);d.text((x,y+preview.height+4),f'{name} {im.width}x{im.height}',fill=PALETTE['cream'],font=small)
  x+=max(preview.width,105)+20;row=max(row,preview.height)
 display.crop((0,0,1000,y+row+45)).save(OUT/'STYLE_SHEET.png')
 print(f'Created {len(ASSETS)} production sprites and updated contact sheet/palette.')

if __name__=='__main__':
 if '--write' not in sys.argv:
  raise SystemExit('Pass --write to replace generated scenery, props and items. Player and ammo are never overwritten.')
 write_assets()
