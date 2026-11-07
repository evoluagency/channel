from pathlib import Path
import json, zipfile, shutil, hashlib, io
ROOT=Path('/mnt/data/channel_valdora_v01b')
SOURCE=Path('/mnt/data/valdora_build/output/addon')
OUT=ROOT/'addon'
if OUT.exists(): shutil.rmtree(OUT)
shutil.copytree(SOURCE,OUT)
BP=OUT/'Channel_BP';RP=OUT/'Channel_RP'
VERSION=[1,3,0]
for pack in [BP,RP]:
    p=pack/'manifest.json'; data=json.loads(p.read_text('utf-8'))
    data['header']['version']=VERSION
    data['header']['description']='Evolu Channel | Valdora V-01B: entrada guiada, construcao e nascimento seguro'
    for mod in data['modules']:mod['version']=VERSION
    for dep in data.get('dependencies',[]):
        if 'uuid' in dep:dep['version']=VERSION
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

main=BP/'scripts'/'main.js'
code=main.read_text('utf-8')
start=code.index('world.afterEvents.playerSpawn.subscribe((ev)=>{')
end=code.index('world.afterEvents.entityDie.subscribe(',start)
old=code[start:end]
assert old == "world.afterEvents.playerSpawn.subscribe((ev)=>{\n  system.runTimeout(()=>handWallet(ev.player),20);\n});\n",old
new="""// Valdora V-01B: as estruturas sao construidas somente com confirmacao explicita.
// A instalacao do Add-on nao altera o mundo por conta propria.
const VALDORA_WORLD = 'channel:valdora.v01b.site';
const VALDORA_ENTRY = 'channel:valdora.v01b.entry';
const VALDORA_MODULES = Object.freeze([
  ['via_nw',0,0],['via_ne',48,0],['via_sw',0,48],['via_se',48,48],
  ['portao',31,2],['praca',32,32],['mercado',65,35],['guilda',1,35]
]);
let valdoraBuilding = false;
function storedValdora() {
  try {
    const raw = world.getDynamicProperty(VALDORA_WORLD);
    if (typeof raw !== 'string') return null;
    const value = JSON.parse(raw);
    if (value?.dimension !== 'minecraft:overworld') return null;
    if (![value.x,value.y,value.z].every(Number.isSafeInteger)) return null;
    return value;
  } catch { return null; }
}
function valdoraSpawnLocation(site) {
  return { x: site.x + 47, y: site.y + 2, z: site.z + 61 };
}
function giveValdoraSpawn(player, site) {
  // Apenas os jogadores deste mundo, preservando worlds sem Valdora.
  try {
    const pos = valdoraSpawnLocation(site);
    player.setSpawnPoint({ ...pos, dimension:world.getDimension('overworld') });
  } catch (e) { say(player,'Nao foi possivel definir o renascimento: '+String(e)); }
}
function goValdora(player, site) {
  if (!player?.isValid) return;
  const pos = valdoraSpawnLocation(site);
  giveValdoraSpawn(player,site);
  try {
    player.teleport({x:pos.x+0.5,y:pos.y+0.05,z:pos.z+0.5},
      {dimension:world.getDimension('overworld')});
    player.setDynamicProperty(VALDORA_ENTRY,true);
    say(player,'Voce chegou a Valdora. Seu ponto de renascimento fica na Praca Central.');
  } catch(e) { say(player,'Falha ao entrar em Valdora: '+String(e)); }
}
async function constructValdora(player) {
  if (valdoraBuilding) return say(player,'Construcao em andamento.');
  const existing = storedValdora();
  if (existing) return goValdora(player, existing);
  if (player.dimension.id !== 'minecraft:overworld')
    return say(player,'Volte para a superficie (Overworld) antes de construir Valdora.');
  const choice = await form(player,'Criar Valdora — confirmar',
    'A construcao ocupa aproximadamente 96 x 96 blocos e SUBSTITUI os blocos dessa area.\\n\\nUse exclusivamente um MUNDO NOVO E PLANO. Faca backup antes de confirmar. O processo nao pode ser desfeito.',
    ['Cancelar','Construir Valdora aqui']);
  if (choice !== 1 || !player?.isValid) return;
  // A segunda validacao impede a corrida entre jogadores com a caixa de confirmacao aberta.
  if (valdoraBuilding || storedValdora()) return say(player,'Valdora ja foi iniciada neste mundo.');
  if (player.dimension.id !== 'minecraft:overworld') return;
  const pos = player.location;
  const origin = {x:Math.floor(pos.x)-48,y:Math.floor(pos.y)-1,z:Math.floor(pos.z)-48};
  // A origem e registrada com o piso Y+1; o jogador nasce em Y+2.
  if (origin.y < -60 || origin.y > 295) return say(player,'Altura inadequada para Valdora.');
  valdoraBuilding = true;
  try {
    const dim = world.getDimension('overworld');
    const mgr = world.structureManager;
    for (const [name, dx, dz] of VALDORA_MODULES)
      mgr.place('channel:valdora/'+name,dim,
        {x:origin.x+dx,y:origin.y,z:origin.z+dz});
    // Depois de aceitar todos os oito posicionamentos, registramos um unico local.
    const site = {...origin,dimension:'minecraft:overworld'};
    world.setDynamicProperty(VALDORA_WORLD, JSON.stringify(site));
    const spawn = valdoraSpawnLocation(site);
    try { dim.runCommand(`setworldspawn ${spawn.x} ${spawn.y} ${spawn.z}`); }
    catch { say(player,'Nao foi possivel alterar o spawn geral; renascimento pessoal configurado.'); }
    goValdora(player, site);
    say(player,'Construcao enviada ao mundo. Aguarde a renderizacao dos setores.');
  } catch (e) {
    say(player,'Falha ao construir Valdora: '+String(e)+'. Partes do terreno podem ter sido alteradas. Use um mundo novo para tentar novamente.');
  } finally { valdoraBuilding = false; }
}
async function openValdoraEntry(player) {
  const site=storedValdora();
  if (site) {
    const choice=await form(player,'Valdora | Reino inicial',
      'O primeiro reino ja foi construido neste mundo.',
      ['Voltar a Praca Central','Cancelar']);
    if(choice===0) goValdora(player,site);
    return;
  }
  const choice=await form(player,'Valdora | Reino inicial',
    'Valdora ainda nao existe neste mundo. Construa uma unica vez em um mundo plano novo. Nenhum bloco sera substituido sem confirmar.',
    ['Preparar Valdora','Agora nao']);
  if(choice===0) await constructValdora(player);
}
world.afterEvents.playerSpawn.subscribe((ev)=>{
  system.runTimeout(()=>{
    if (!ev.player?.isValid) return;
    handWallet(ev.player);
    const site=storedValdora();
    if(site) {
      giveValdoraSpawn(ev.player,site);
      // Jogadores novos chegam a Valdora uma unica vez; veteranos mantem a posicao salva.
      if(ev.initialSpawn && ev.player.getDynamicProperty(VALDORA_ENTRY)!==true)
        system.runTimeout(()=>goValdora(ev.player,site),40);
    } else if(ev.initialSpawn && ev.player.dimension.id==='minecraft:overworld') {
      // Espera o carregamento do mundo para nao cancelar formularios na inicializacao.
      system.runTimeout(()=>openValdoraEntry(ev.player).catch(e=>say(ev.player,String(e))),100);
    }
  },20);
});
"""
code=code[:start]+new+code[end:]
# Convert existing economy menu's narrative option into access to the new city, without modifying accounting logic.
needle="if(sel===7) await form(p,'Valdora | Primeiro Reino','Valdora e o primeiro territorio de Channel. O Mercado, o Banco e as recompensas de combate formam sua economia inicial. Vilas, faccoes, novos NPCs e historia serao adicionados em versoes futuras.',['Voltar']);"
assert needle in code
code=code.replace(needle,"if(sel===7) await openValdoraEntry(p);")
main.write_text(code,encoding='utf-8')
# Keep optional manual command, now set spawn and teleport to accessible plaza entry, only when explicitly run.
fc=BP/'functions'/'valdora'/'construir_centro.mcfunction'
fc.write_text('''# V-01B: executar somente em MUNDO NOVO E PLANO, com comandos ativados.\n# Primeiro constroi a cidade, depois registra nascimento na praca.\nexecute positioned ~-48 ~ ~-48 run function valdora/construir\n# Spawn seguro: entrada sul da praca, fora da fonte central.\nsetworldspawn ~-1 ~1 ~13\nspawnpoint @s ~-1 ~1 ~13\ntp @s ~-0.5 ~1 ~13.5\n''',encoding='utf-8')
manual=BP/'functions'/'valdora'/'construir.mcfunction'
manual.write_text(manual.read_text('utf-8').replace('V-01A','V-01B'),encoding='utf-8')
# Create repack of same two independent mcpack files in one mcaddon.
TARGET=ROOT/'Channel_Valdora_V01B.mcaddon'
def build_mcpack(folder):
  buffer=io.BytesIO()
  with zipfile.ZipFile(buffer,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for f in sorted(folder.rglob('*')):
      if f.is_file():z.write(f, f.relative_to(folder).as_posix())
  return buffer.getvalue()
packs={'Channel_BP.mcpack':build_mcpack(BP),'Channel_RP.mcpack':build_mcpack(RP)}
with zipfile.ZipFile(TARGET,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
  for k,b in packs.items():z.writestr(k,b)
assert len(packs)==2
for k,b in packs.items():
  with zipfile.ZipFile(io.BytesIO(b)) as z:
    assert z.testzip() is None
    mf=json.loads(z.read('manifest.json'))
    assert mf['header']['version']==VERSION
with zipfile.ZipFile(TARGET) as z:
  assert z.testzip() is None and sorted(z.namelist())==sorted(packs)
print(json.dumps({'output':str(TARGET),'bytes':TARGET.stat().st_size,'sha256':hashlib.sha256(TARGET.read_bytes()).hexdigest(),'pack_versions':VERSION,'structures':len(list((BP/'structures').rglob('*.mcstructure')))},indent=2))