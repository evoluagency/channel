#!/usr/bin/env python3
"""Valdora V-01A: offline Bedrock .mcstructure builder, no external services."""
from __future__ import annotations
import collections, copy, hashlib, json, math, shutil, struct, zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parent
SOURCE=Path('/mnt/data/channel_project')
OUT=ROOT/'output'
BP=OUT/'addon'/'Channel_BP'
RP=OUT/'addon'/'Channel_RP'
if OUT.exists(): shutil.rmtree(OUT)
shutil.copytree(SOURCE/'addon'/'Channel_BP',BP)
shutil.copytree(SOURCE/'addon'/'Channel_RP',RP)

VERSION=[1,2,0]
for manifest in [BP/'manifest.json',RP/'manifest.json']:
    d=json.loads(manifest.read_text())
    d['header']['version']=VERSION
    d['header']['description']='Channel V1.2 | Economia e primeiro setor arquitetonico de Valdora'
    for mod in d['modules']: mod['version']=VERSION
    for dep in d.get('dependencies',[]):
        if 'uuid' in dep: dep['version']=VERSION
    manifest.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

# RGB keys and NBT types are explicitly stable for Bedrock structure palette.
AIR='minecraft:air'; STONE='minecraft:stone_bricks'; DIORITE='minecraft:polished_diorite'
ANDESITE='minecraft:polished_andesite'; SPRUCE='minecraft:spruce_planks'
DARK='minecraft:dark_oak_planks'; OAK='minecraft:oak_planks'
PURPLE='minecraft:purple_wool'; GOLD='minecraft:gold_block'; YELLOW='minecraft:yellow_wool'
LEAVES='minecraft:oak_leaves'; LOG='minecraft:oak_log'; GLOW='minecraft:glowstone'
GLASS='minecraft:glass'; BLUE='minecraft:blue_stained_glass'
BOOK='minecraft:bookshelf'; WORK='minecraft:crafting_table'; FURNACE='minecraft:furnace'
COBBLE='minecraft:cobblestone'; WHITE='minecraft:white_wool'; RED='minecraft:red_wool'
HAY='minecraft:hay_block'; TARGET='minecraft:target'
BRICK='minecraft:bricks'
BLOCK_VERSION=18168865

class Voxel:
    def __init__(self,w,h,d,transparent=False):
        self.size=(w,h,d)
        self.default=None if transparent else AIR
        self.blocks={}
        self.transparent=transparent
        self.shapes=collections.Counter()
    def set(self,x,y,z,name,states=None):
        w,h,d=self.size
        if not(0<=x<w and 0<=y<h and 0<=z<d):
            raise ValueError(f'Out of bounds {(x,y,z)} in {self.size}')
        self.blocks[(x,y,z)]=(name,tuple(sorted((states or {}).items())))
    def fill(self,x1,y1,z1,x2,y2,z2,name,states=None):
        xa,xb=sorted((x1,x2));ya,yb=sorted((y1,y2));za,zb=sorted((z1,z2))
        for x in range(xa,xb+1):
            for y in range(ya,yb+1):
                for z in range(za,zb+1): self.set(x,y,z,name,states)
    def frame(self,x1,x2,z1,z2,y,name):
        self.fill(x1,y,z1,x2,y,z1,name);self.fill(x1,y,z2,x2,y,z2,name)
        self.fill(x1,y,z1,x1,y,z2,name);self.fill(x2,y,z1,x2,y,z2,name)
    def walls(self,x1,x2,z1,z2,y0,y1,name):
        for y in range(y0,y1+1):self.frame(x1,x2,z1,z2,y,name)
    def box_frame(self,x1,x2,z1,z2,y0,y1,wall=STONE,roof=SPRUCE):
        self.walls(x1,x2,z1,z2,y0,y1,wall)
        for x,z in [(x1,z1),(x1,z2),(x2,z1),(x2,z2)]:self.fill(x,y0,z,x,y1,z,ANDESITE)
        self.fill(x1-1,y1+1,z1-1,x2+1,y1+1,z2+1,roof)
        for offset in range(2):
            xs=x1+offset;xe=x2-offset;zs=z1+offset;ze=z2-offset
            if xs<=xe and zs<=ze:self.frame(xs,xe,zs,ze,y1+2+offset,roof)
    def tile(self):
        w,h,d=self.size
        # Solid foundation + walkway slab, with tasteful geometric border.
        self.fill(0,0,0,w-1,0,d-1,STONE)
        self.fill(0,1,0,w-1,1,d-1,DIORITE)
        for x in range(w):
            for z in range(d):
                if x in(0,w-1) or z in (0,d-1): self.set(x,1,z,ANDESITE)
                elif (x+z)%11==0:self.set(x,1,z,STONE)
    def coords(self):return self.size

# Plaza 31x12x31
p=Voxel(31,12,31);p.tile()
# Axes and decorative cross, with room to walk around center
for v in range(31):
    for wid in range(13,18):
        p.set(wid,1,v,STONE);p.set(v,1,wid,STONE)
for side in [4,26]:
    for o in [0,1,2]:
        p.set(side+o,1,13,ANDESITE);p.set(side+o,1,17,ANDESITE)
# fountain plinth and reflective blue mosaic; safe non-flowing water
p.fill(10,2,10,20,2,20,STONE)
p.fill(11,2,11,19,2,19,BLUE)
p.frame(10,20,10,20,3,DIORITE)
for x,z in [(10,10),(10,20),(20,10),(20,20)]:p.set(x,4,z,GOLD)
# Guardian/hero monument over basin, geometric original figure with shield
p.fill(14,3,14,16,4,16,STONE)
p.fill(15,5,15,15,7,15,ANDESITE);p.fill(14,8,15,16,8,15,STONE)
p.fill(14,7,14,14,7,14,PURPLE);p.fill(16,7,14,16,7,14,GOLD)
p.fill(17,5,14,18,7,14,ANDESITE);p.set(17,6,14,PURPLE);p.set(17,7,14,GOLD)
# Landscaped corner garden planters, shrubs and low trees
for cx,cz in [(5,5),(25,5),(5,25),(25,25)]:
    p.fill(cx-3,2,cz-3,cx+3,2,cz+3,STONE)
    p.fill(cx-2,3,cz-2,cx+2,3,cz+2,'minecraft:grass_block')
    p.fill(cx,4,cz,cx,6,cz,LOG)
    p.fill(cx-2,7,cz-2,cx+2,7,cz+2,LEAVES,{'persistent_bit':1,'update_bit':0})
    p.fill(cx-1,8,cz-1,cx+1,8,cz+1,LEAVES,{'persistent_bit':1,'update_bit':0})
    for bx,bz in [(cx-3,cz),(cx+3,cz)]:p.set(bx,3,bz,SPRUCE)
# Lantern pillars in quad spaces, avoid tree canopies and paths
for x,z in [(9,4),(21,4),(9,26),(21,26)]:
    p.fill(x,2,z,x,4,z,ANDESITE);p.set(x,5,z,GLOW)

# Market 30x13x25
m=Voxel(30,13,25);m.tile()
# western entrance from central square and stone promenade
m.fill(0,1,11,29,1,14,STONE)
m.fill(14,1,0,15,1,24,STONE)
# Bank: north-west grand entrance from south at z11
m.box_frame(2,12,2,10,2,6,STONE,SPRUCE)
m.fill(6,2,10,8,4,10,AIR) # 3-wide bank door
# windows / signs
for x in [4,10]:m.fill(x,4,2,x+1,5,2,GLASS)
m.fill(4,2,7,10,2,7,DARK);m.set(9,3,7,GOLD)
m.fill(4,2,4,4,4,4,BOOK);m.set(10,2,4,GOLD)
m.fill(3,2,9,5,2,9,STONE)
# bank crest above doorway, original gold diamond, no text yet
m.set(7,7,10,GOLD)
# Forge north-east, open front side to central promenade
m.box_frame(17,27,2,10,2,6,BRICK,DARK)
m.fill(17,2,6,17,4,8,AIR)
m.fill(23,2,3,25,2,3,STONE)
m.set(24,3,4,FURNACE);m.set(25,3,4,WORK)
m.fill(25,2,7,26,3,7,ANDESITE);m.set(24,2,8,GOLD)
m.fill(20,4,10,21,5,10,GLASS)
# air lanes: west entry to three stalls; stalls south/east along border
for sx in [3,12,21]:
    m.fill(sx,2,18,sx+6,2,18,SPRUCE)
    m.fill(sx,2,21,sx+6,2,21,SPRUCE)
    for x in [sx,sx+6]:
        for z in [18,22]:m.fill(x,2,z,x,4,z,DARK)
    m.fill(sx,5,18,sx+6,5,22,PURPLE)
    for x in range(sx,sx+7):
        if x%2==0:m.set(x,5,18,YELLOW)
    m.fill(sx+1,2,20,sx+5,2,20,COBBLE)
    m.set(sx+1,3,20,HAY if sx==3 else (BOOK if sx==12 else GOLD))
# Lamps at public lane corners
for x,z in [(2,13),(27,13),(14,15)]:
    m.fill(x,2,z,x,4,z,STONE);m.set(x,5,z,GLOW)

# Guild 30x15x25
g=Voxel(30,15,25);g.tile()
g.fill(0,1,11,29,1,14,STONE)
# Guild adventurer hall at western wing
g.box_frame(2,13,2,16,2,7,STONE,DARK)
g.fill(13,2,10,13,5,12,AIR)
g.fill(4,2,5,11,2,5,SPRUCE)
g.fill(4,2,8,8,2,8,BOOK)
g.fill(4,2,13,9,2,13,DARK)
for x in [3,12]:g.fill(x,4,6,x,5,8,GLASS)
g.set(12,6,11,PURPLE)
# Archery range targets, three defined safe lanes
for tz in [5,10,15]:
    g.fill(26,2,tz,26,5,tz,OAK)
    for y in [3,4,5]:
        for z in range(tz-1,tz+2):g.set(26,y,z,WHITE)
    g.set(26,4,tz,RED);g.set(26,3,tz,GOLD)
    g.fill(27,2,tz-2,27,5,tz+2,STONE)
# training courtyard, stone spars and equipment on floor
for x,z in [(17,18),(21,18),(25,18)]:
    g.fill(x,2,z,x,4,z,LOG);g.set(x,5,z,SPRUCE)
# Decorative weapon rack, non-interactive
for x in [5,7,9]:g.fill(x,2,18,x,3,18,SPRUCE)
g.fill(2,2,21,13,2,21,ANDESITE)
g.set(15,2,12,GOLD)
for x,z in [(16,2),(16,22)]:g.fill(x,2,z,x,4,z,STONE);g.set(x,5,z,GLOW)

# Castle gate 33x20x19
c=Voxel(33,20,19);c.tile()
# central open crossing (5 wide) with paved connection
c.fill(13,1,0,19,1,18,STONE)
# rear and face wall, 2-9, break central arch over passage
c.fill(0,2,8,32,10,11,STONE)
c.fill(14,2,8,18,8,11,AIR)
# tower twin shafts in side squares, raised pillars and ramparts
for x1,x2 in [(2,9),(23,30)]:
    c.fill(x1,2,4,x2,15,14,STONE)
    c.fill(x1+1,3,5,x2-1,13,13,AIR) # hollow vertical towers, inaccessible
    # merlons top, crenellated tops
    c.fill(x1-1,15,3,x2+1,15,15,ANDESITE)
    for x in range(x1-1,x2+2,2):
        c.fill(x,16,3,x,17,3,STONE);c.fill(x,16,15,x,17,15,STONE)
    for z in range(3,16,2):
        c.fill(x1-1,16,z,x1-1,17,z,STONE);c.fill(x2+1,16,z,x2+1,17,z,STONE)
    # square stone column accents, behind the wall
    for x,z in [(x1,4),(x2,4),(x1,14),(x2,14)]:c.fill(x,2,z,x,15,z,DIORITE)
# long outer-wall crenellations over arch, keeping front passage
for x in range(0,33,2):c.set(x,11,8,ANDESITE)
# Center keystone and banners on front facade
c.set(16,10,7,GOLD)
for x in [5,27]:
    c.fill(x-1,10,3,x+1,13,3,PURPLE)
    c.set(x,11,3,GOLD)
# high castle crown between towers (not obstructing walking)
c.fill(14,11,9,18,12,11,STONE)
c.set(16,13,9,GOLD)
for x,z in [(1,1),(31,1)]:c.fill(x,2,z,x,4,z,ANDESITE);c.set(x,5,z,GLOW)

# Road quadrants; primary layer void outside paths; explicit stone paving y1
roads={}
for qx in range(2):
    for qz in range(2):
        v=Voxel(48,3,48,transparent=True)
        for x in range(48):
            for z in range(48):
                gx=qx*48+x;gz=qz*48+z
                along_x=(46<=gz<=49)
                along_z=(46<=gx<=49)
                if along_x or along_z:
                    v.set(x,1,z,STONE if (gx+gz)%9 else DIORITE)
                    # low border on edges of paths, only if no intersection
                    if (gx in (45,50) and 25<=gz<=90) or (gz in (45,50) and 25<=gx<=90):
                        pass
        roads[f'via_{["nw","ne"][qx] if qz==0 else ["sw","se"][qx]}']=v

# True Bedrock NBT little-endian serializer
TAG_END=0;TAG_BYTE=1;TAG_SHORT=2;TAG_INT=3;TAG_LONG=4;TAG_FLOAT=5;TAG_DOUBLE=6
TAG_BYTE_ARRAY=7;TAG_STRING=8;TAG_LIST=9;TAG_COMPOUND=10;TAG_INT_ARRAY=11;TAG_LONG_ARRAY=12

def namebytes(s):
    b=s.encode('utf-8');return struct.pack('<H',len(b))+b

def payload_int(n):return struct.pack('<i',n)

def tag(t,name,data):return bytes([t])+namebytes(name)+data

def tag_str(name,s):return tag(TAG_STRING,name,namebytes(s))

def tag_int(name,n):return tag(TAG_INT,name,payload_int(n))

def tag_compound(name,entries):return tag(TAG_COMPOUND,name,b''.join(entries)+b'\x00')

def list_tag(name,t,parts):return tag(TAG_LIST,name,bytes([t])+payload_int(len(parts))+b''.join(parts))

def list_int_payload(arr):return bytes([TAG_INT])+payload_int(len(arr))+struct.pack('<'+str(len(arr))+'i',*arr)

def structure_bytes(v):
    w,h,d=v.size
    blocks=v.blocks
    palette=[];palette_map={}
    # Zero is air for buildings. Sparse roads only emit palette blocks explicitly set.
    for key in sorted(set(blocks.values())|({(AIR,tuple())} if not v.transparent else set())):
        palette_map[key]=len(palette);palette.append(key)
    primary=[]; secondary=[]
    for x in range(w):
        for y in range(h):
            for z in range(d):
                key=blocks.get((x,y,z))
                primary.append(palette_map[key] if key is not None else (-1 if v.transparent else palette_map[(AIR,tuple())]))
                secondary.append(-1)
    pal=[]
    for block,states in palette:
        state_tags=[]
        for key,value in states:
            if isinstance(value,int):state_tags.append(tag(TAG_BYTE,key,struct.pack('<b',value)))
            else:state_tags.append(tag_str(key,str(value)))
        pal.append(b''.join([tag_str('name',block),tag_compound('states',state_tags),tag_int('version',BLOCK_VERSION),b'\x00']))
    # Normal compound list payloads consist of tags' contents only, no tag/name header
    idx_data=list_tag('block_indices',TAG_LIST,[list_int_payload(primary),list_int_payload(secondary)])
    palette_data=tag_compound('palette',[tag_compound('default',[
        list_tag('block_palette',TAG_COMPOUND,pal),tag_compound('block_position_data',[])])])
    struct_data=tag_compound('structure',[idx_data,list_tag('entities',TAG_COMPOUND,[]),palette_data])
    root_content=b''.join([tag_int('format_version',1),list_tag('size',TAG_INT,[payload_int(w),payload_int(h),payload_int(d)]),
                    list_tag('structure_world_origin',TAG_INT,[payload_int(0)]*3),struct_data])
    return b'\x0a\x00\x00'+root_content+b'\x00'

modules={'portao':c,'praca':p,'mercado':m,'guilda':g,**roads}
placements={'portao':(31,2),'praca':(32,32),'mercado':(65,35),'guilda':(1,35),
'via_nw':(0,0),'via_ne':(48,0),'via_sw':(0,48),'via_se':(48,48)}
ST=BP/'structures'/'channel'/'valdora'; ST.mkdir(parents=True)
reports=[]
for name,vox in modules.items():
    data=structure_bytes(vox);file=ST/f'{name}.mcstructure';file.write_bytes(data)
    cnt=collections.Counter(k[0] for k in vox.blocks.values())
    reports.append({'name':name,'size':vox.size,'position':placements[name], 'voxels_explicit':len(vox.blocks),
                    'blocks':dict(cnt.most_common()),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})

func=BP/'functions'/'valdora';func.mkdir(parents=True)
cmd=['# Channel / Valdora V-01A — usar SOMENTE em mundo plano descartavel e com backup.',
     '# Posicione-se no CANTO NOROESTE do terreno (X0,Z0) com os pes no nivel Y0+1.',
     '# As estruturas serao inseridas em 96x96 blocos. O comando nao desfaz a operacao.']
for n in ['via_nw','via_ne','via_sw','via_se','portao','praca','mercado','guilda']:
    x,z=placements[n]
    cmd.append(f'structure load channel:valdora/{n} ~{x if x else ""} ~-1 ~{z if z else ""}')
func.joinpath('construir.mcfunction').write_text('\n'.join(cmd)+'\n',encoding='utf-8')
# Mobile-friendly alternative: place from the center so nearby chunks are loaded.
# World origin stays exactly the same 96x96 as when invoked from the NW corner.
func.joinpath('construir_centro.mcfunction').write_text(
    '# Execute em mundo plano de TESTE, parado no centro da area livre de 96x96.\n'
    'execute positioned ~-48 ~ ~-48 run function valdora/construir\n'
    '# Reposicione-se manualmente se o jogador ficar na fonte central.\n',
    encoding='utf-8')

install=OUT/'COMO_CONSTRUIR_VALDORA.md'
install.write_text('''# Instalação de Valdora — V-01A experimental

**Atenção:** este é um construtor de estruturas. Não é um mundo `.mcworld` e não oferece ainda NPCs programados nem missões.

1. Faça backup dos mundos existentes. Crie um **mundo NOVO, plano e descartável**, com cheats/comandos ativados.
2. Importe `Channel_Valdora_V01A.mcaddon` e ative o pacote de comportamento Channel.
3. Entre no mundo. Antes de executar, escolha área livre de **96 × 96 blocos**. Preferencialmente fique de pé no solo, **no centro dessa área**, em X0+48, Z0+48, com os arredores carregados. Não execute sobre edificações importantes.\n4. Digite no chat: `/function valdora/construir_centro`. Alternativamente, no canto noroeste (X0,Z0), use `/function valdora/construir` (pode exigir maior distância de renderização).
5. O comando carrega quatro vias e quatro módulos de construção em sequência, relativos à posição atual do operador. **Não execute duas vezes** nem rode enquanto caminha.
6. Comece pela estrada leste até o Mercado, depois Praça e Quartel, e siga ao norte até o Portão. Verifique caminho, iluminação e paredes.
7. Se ocorrer algum problema, descarte o mundo de teste. Não há botão de desfazer e `/function` não cria um mundo independente.
8. Se o comando não for reconhecido, verifique se cheats estão habilitados e o behavior pack está ativo. Teste `/structure load channel:valdora/praca ~10 ~-1 ~10` em um mundo descartável.

**Importação/versão:** mantenha os UUIDs dos dois pacotes anteriores. Esta compilação atualiza as versões para 1.2.0; propriedades de economia existentes não são removidas. Não atualize um mundo importante sem backup.

**Limitações:** a capa é arte conceitual; o cenário usa blocos vanilla. Não há homologação em aparelho Android real. Algumas texturas ou blocos poderão precisar de ajuste após a inspeção no jogo.

**Sem automações:** o gerador Python roda somente localmente. Nenhum GitHub Action, workflow, migration, job, Vercel ou Supabase é necessário para jogar.
''',encoding='utf-8')

report=OUT/'BUILD_REPORT.json'
report.write_text(json.dumps({'version':VERSION,'palette_block_version':BLOCK_VERSION,'modules':reports},indent=2,ensure_ascii=False)+'\n')

# Package binary: inner mcpack archives, outer mcaddon
paks=[]
for src in [BP,RP]:
    pack=OUT/f'{src.name}.mcpack'
    with zipfile.ZipFile(pack,'w',zipfile.ZIP_DEFLATED,compresslevel=8) as z:
        for f in sorted(src.rglob('*')):
            if f.is_file():z.write(f,f.relative_to(src).as_posix())
    paks.append(pack)
addon=OUT/'Channel_Valdora_V01A.mcaddon'
with zipfile.ZipFile(addon,'w',zipfile.ZIP_DEFLATED,compresslevel=8) as z:
    for pk in paks:z.write(pk,pk.name)
print(json.dumps({'addon':str(addon),'size':addon.stat().st_size,'modules':len(modules),'report':str(report)},indent=2))