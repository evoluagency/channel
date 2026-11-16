"""Poda um GLB do KayKit: tira as armas medievais e deixa só as animações usadas no PvP."""
import json,struct,sys
MANTER = ["Idle","2H_Melee_Idle","2H_Ranged_Aiming","2H_Ranged_Shooting","2H_Ranged_Shoot","2H_Ranged_Reload",
  "Walking_A","Walking_Backwards","Running_A","Running_Strafe_Left","Running_Strafe_Right",
  "Hit_A","Death_A","Death_A_Pose","Jump_Idle","Cheer"]
ARMAS = ("Crossbow","Knife","Throwable","Shield","Sword","Axe","Mug","Spellbook","Wand","Staff","Cape","Hat","Helmet")
src,dst=sys.argv[1],sys.argv[2]
b=open(src,'rb').read(); n=struct.unpack('<I',b[12:16])[0]; j=json.loads(b[20:20+n])
off=20+n; bn=struct.unpack('<I',b[off:off+4])[0]; BIN=b[off+8:off+8+bn]
tirar=set(a for a in sys.argv[3:])  # nomes extras de nós a tirar
for nd in j['nodes']:
    nm=nd.get('name','')
    if 'mesh' in nd and (any(k in nm for k in ARMAS) or nm in tirar):
        nd.pop('mesh'); nd.pop('skin',None)
j['animations']=[a for a in j['animations'] if a['name'] in MANTER]
# acessores usados
usados=set()
meshes_usadas=sorted(set(nd['mesh'] for nd in j['nodes'] if 'mesh' in nd))
remap_mesh={m:i for i,m in enumerate(meshes_usadas)}
j['meshes']=[j['meshes'][m] for m in meshes_usadas]
for nd in j['nodes']:
    if 'mesh' in nd: nd['mesh']=remap_mesh[nd['mesh']]
for m in j['meshes']:
    for p in m['primitives']:
        usados.update(p['attributes'].values())
        if 'indices' in p: usados.add(p['indices'])
        for t in p.get('targets',[]): usados.update(t.values())
for s in j.get('skins',[]):
    if 'inverseBindMatrices' in s: usados.add(s['inverseBindMatrices'])
for a in j['animations']:
    for s in a['samplers']: usados.update([s['input'],s['output']])
usados=sorted(usados); ra={o:i for i,o in enumerate(usados)}
bvs=sorted(set(j['accessors'][i]['bufferView'] for i in usados)|set(im['bufferView'] for im in j.get('images',[]) if 'bufferView' in im))
rb={o:i for i,o in enumerate(bvs)}
novo=bytearray(); nbv=[]
for o in bvs:
    v=dict(j['bufferViews'][o]); s=v.get('byteOffset',0)
    while len(novo)%4: novo.append(0)
    novo+=BIN[s:s+v['byteLength']]; v['byteOffset']=len(novo)-v['byteLength']; nbv.append(v)
while len(novo)%4: novo.append(0)
j['accessors']=[dict(j['accessors'][i],bufferView=rb[j['accessors'][i]['bufferView']]) for i in usados]
j['bufferViews']=nbv; j['buffers']=[{'byteLength':len(novo)}]
for im in j.get('images',[]):
    if 'bufferView' in im: im['bufferView']=rb[im['bufferView']]
for m in j['meshes']:
    for p in m['primitives']:
        p['attributes']={k:ra[v] for k,v in p['attributes'].items()}
        if 'indices' in p: p['indices']=ra[p['indices']]
        if 'targets' in p: p['targets']=[{k:ra[v] for k,v in t.items()} for t in p['targets']]
for s in j.get('skins',[]):
    if 'inverseBindMatrices' in s: s['inverseBindMatrices']=ra[s['inverseBindMatrices']]
for a in j['animations']:
    for s in a['samplers']: s['input']=ra[s['input']]; s['output']=ra[s['output']]
js=json.dumps(j,separators=(',',':')).encode()
while len(js)%4: js+=b' '
out=struct.pack('<III',0x46546C67,2,12+8+len(js)+8+len(novo))+struct.pack('<II',len(js),0x4E4F534A)+js+struct.pack('<II',len(novo),0x004E4942)+bytes(novo)
open(dst,'wb').write(out); print(dst,len(out)//1024,'KB',len(j['animations']),'anims',len(j['meshes']),'malhas')
