#!/usr/bin/env python3
"""Independent NBT and ZIP verifier: deliberately does not import generator code."""
import struct,zipfile,json,collections,sys,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parent/'output'
class Reader:
 def __init__(self,data):self.data=data;self.p=0
 def get(self,n):
  if self.p+n>len(self.data):raise ValueError('truncated NBT at '+str(self.p))
  b=self.data[self.p:self.p+n];self.p+=n;return b
 def u8(self):return self.get(1)[0]
 def i8(self):return struct.unpack('<b',self.get(1))[0]
 def i16(self):return struct.unpack('<h',self.get(2))[0]
 def u16(self):return struct.unpack('<H',self.get(2))[0]
 def i32(self):return struct.unpack('<i',self.get(4))[0]
 def str(self):return self.get(self.u16()).decode('utf-8')
 def val(self,t):
  if t==1:return self.i8()
  if t==2:return self.i16()
  if t==3:return self.i32()
  if t==4:return struct.unpack('<q',self.get(8))[0]
  if t==5:return struct.unpack('<f',self.get(4))[0]
  if t==6:return struct.unpack('<d',self.get(8))[0]
  if t==7:return self.get(self.i32())
  if t==8:return self.str()
  if t==9:
   child=self.u8();length=self.i32()
   if length<0 or length>5_000_000:raise ValueError('bad list size')
   return [self.val(child) for _ in range(length)]
  if t==10:
   result={}
   while True:
    child=self.u8()
    if child==0:return result
    name=self.str()
    if name in result:raise ValueError('duplicate tag '+name)
    result[name]=self.val(child)
  if t==11:
   n=self.i32();return [self.i32() for _ in range(n)]
  if t==12:
   n=self.i32();return [struct.unpack('<q',self.get(8))[0] for _ in range(n)]
  raise ValueError('bad NBT tag '+str(t))
 def read(self):
  assert self.u8()==10,'root must be compound'
  assert self.str()==''
  v=self.val(10)
  assert self.p==len(self.data),f'extra trailing data {len(self.data)-self.p}'
  return v

report=json.loads((ROOT/'BUILD_REPORT.json').read_text())
path=ROOT/'addon'/'Channel_BP'/'structures'/'channel'/'valdora'
modules={}
for item in report['modules']:
 name=item['name'];p=path/f'{name}.mcstructure';b=p.read_bytes();v=Reader(b).read()
 assert v['format_version']==1
 size=v['size'];assert size==item['size'],(name,size,item['size'])
 s=v['structure'];w,h,d=size
 indices=s['block_indices'];assert len(indices)==2
 assert all(len(layer)==w*h*d for layer in indices)
 assert all(x==-1 for x in indices[1])
 palette=s['palette']['default']['block_palette']
 assert all(p['name'].startswith('minecraft:') and p['version']>0 for p in palette)
 assert all(i==-1 or 0<=i<len(palette) for i in indices[0])
 assert v['structure_world_origin']==[0,0,0]
 assert s['entities']==[]
 modules[name]=(v,palette)
 assert hashlib.sha256(b).hexdigest()==item['sha256']
 # no accidental out of bounds planned placements
 x,z=item['position'];assert 0<=x and x+w<=96 and 0<=z and z+d<=96,(name,x,z,size)
 print(f'PASS {name:9s} {w}x{h}x{d} palette={len(palette)} bytes={len(b)} active={sum(i>=0 for i in indices[0])}')
for name in ['via_nw','via_ne','via_sw','via_se']:
 a=modules[name][0]['structure']['block_indices'][0];assert any(n==-1 for n in a) and any(n>=0 for n in a)
for name in ['praca','mercado','guilda','portao']:
 a=modules[name][0]['structure']['block_indices'][0];assert all(n>=0 for n in a)
# exact names/order and no duplicate or unexpected mission content
f=(ROOT/'addon'/'Channel_BP'/'functions'/'valdora'/'construir.mcfunction').read_text()
loads=[l for l in f.splitlines() if l.startswith('structure load')]
assert len(loads)==8
assert len(set(x.split()[2] for x in loads))==8
assert loads[0].split()[2]=='channel:valdora/via_nw' and loads[-1].split()[2]=='channel:valdora/guilda'
for src in ['Channel_BP','Channel_RP']:
 with zipfile.ZipFile(ROOT/f'{src}.mcpack') as z:
  assert z.testzip() is None
  assert 'manifest.json' in z.namelist()
  mf=json.loads(z.read('manifest.json'))
  assert mf['header']['version']==[1,2,0]
with zipfile.ZipFile(ROOT/'Channel_Valdora_V01A.mcaddon') as z:
 assert z.testzip() is None
 assert set(z.namelist())=={'Channel_BP.mcpack','Channel_RP.mcpack'}
 with zipfile.ZipFile(__import__('io').BytesIO(z.read('Channel_BP.mcpack'))) as pb:
  found=[x for x in pb.namelist() if x.endswith('.mcstructure')]
  assert len(found)==8
print('PASS ZIP, UUID/manifests and 8 structure files; no live Minecraft test executed')
# Verify a connected pedestrian route on the union of planned flat-world blocks.
from collections import deque
blocks={}
coordinates={'via_nw':(0,0),'via_ne':(48,0),'via_sw':(0,48),'via_se':(48,48),'portao':(31,2),'praca':(32,32),'mercado':(65,35),'guilda':(1,35)}
for name in ['via_nw','via_ne','via_sw','via_se','portao','praca','mercado','guilda']:
 v,palette=modules[name];sx,sy,sz=v['size'];xx,zz=coordinates[name]
 ix=v['structure']['block_indices'][0]
 for x in range(sx):
  for y in [1,2,3]:
   for z in range(sz):
    i=(x*sy+y)*sz+z
    if i>=len(ix): continue
    n=ix[i]
    if n>=0:blocks[(xx+x,y,zz+z)]=palette[n]['name']
def openpos(x,z):return blocks.get((x,1,z),'minecraft:air') not in ['minecraft:air'] and all(blocks.get((x,y,z),'minecraft:air')=='minecraft:air' for y in [2,3])
start=(47,28)
assert openpos(*start)
q=deque([start]);seen={start}
while q:
 x,z=q.popleft()
 for nx,nz in [(x-1,z),(x+1,z),(x,z-1),(x,z+1)]:
  if 0<=nx<96 and 0<=nz<96 and (nx,nz) not in seen and openpos(nx,nz):
   seen.add((nx,nz));q.append((nx,nz))
for mark in [(47,20),(47,35),(47,61),(29,47),(66,47),(72,45),(82,42)]:
 assert mark in seen,f'Route unreachable {mark}'
print('PASS connected walking route: gate, plaza, guild, market, bank and forge')