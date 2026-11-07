import { world, system, ItemStack, Player } from "@minecraft/server";
import { ActionFormData, ModalFormData } from "@minecraft/server-ui";

// Channel v1.0 - toda a economia roda no mundo, sem servico externo.
const P = "erpg:";
const LIMIT = 1_000_000_000;
const CASH = [
  { id: "erpg:moeda_1", name: "Moeda de 1", face: 1 },
  { id: "erpg:moeda_10", name: "Moeda de 10", face: 10 },
  { id: "erpg:nota_100", name: "Nota de 100", face: 100 },
];
const SELL = [
  { id: "minecraft:cobblestone", name: "16 Pedregulhos", qty: 16, value: 8 },
  { id: "minecraft:wheat", name: "16 Trigos", qty: 16, value: 20 },
  { id: "minecraft:raw_iron", name: "4 Ferros brutos", qty: 4, value: 40 },
  { id: "minecraft:cod", name: "4 Bacalhaus", qty: 4, value: 20 },
  { id: "minecraft:diamond", name: "1 Diamante", qty: 1, value: 100 },
];
const SHOP = [
  { id: "minecraft:bread", name: "4 Paes", qty: 4, value: 24 },
  { id: "minecraft:torch", name: "16 Tochas", qty: 16, value: 25 },
  { id: "minecraft:iron_sword", name: "Espada de ferro", qty: 1, value: 180 },
  { id: "minecraft:shield", name: "Escudo", qty: 1, value: 140 },
  { id: "minecraft:iron_pickaxe", name: "Picareta de ferro", qty: 1, value: 220 },
];
const REWARD = {
  "minecraft:zombie": 5, "minecraft:husk": 5, "minecraft:drowned": 5,
  "minecraft:skeleton": 7, "minecraft:stray": 7,
  "minecraft:spider": 6, "minecraft:creeper": 10,
};
const viewing = new Set();
const money = (n) => `${n} moedas`;
const safeInt = (x) => Number.isSafeInteger(x) && x >= 0 && x <= LIMIT;
const parseAmount = (v) => {
  const s = String(v ?? "").trim();
  if (!/^[1-9][0-9]{0,8}$/.test(s)) return null;
  const n = Number(s);
  return safeInt(n) && n > 0 ? n : null;
};
const get = (p, k) => {
  const n = p.getDynamicProperty(P + k);
  return safeInt(n) ? n : 0;
};
const set = (p, k, n) => {
  if (!safeInt(n)) throw Error("Limite de saldo excedido.");
  p.setDynamicProperty(P + k, n);
};
const inv = (p) => p.getComponent("minecraft:inventory")?.container;
const itemCount = (c, id) => {
  let total = 0;
  for (let i = 0; i < c.size; i++) {
    const it = c.getItem(i);
    if (it?.typeId === id) total += it.amount;
  }
  return total;
};
const take = (c, id, qty) => {
  if (itemCount(c,id) < qty) return false;
  let left = qty;
  for (let i=0; i<c.size && left > 0; i++) {
    const it = c.getItem(i);
    if (!it || it.typeId !== id) continue;
    const removing = Math.min(left, it.amount);
    if (it.amount === removing) c.setItem(i, undefined);
    else { it.amount -= removing; c.setItem(i, it); }
    left -= removing;
  }
  return left === 0;
};
// Nao altera o inventario ate confirmar espaco para o novo item.
const spaceFor = (c, id, qty) => {
  let capacity=0;
  for (let i=0; i<c.size; i++) {
    const it=c.getItem(i);
    if (!it) capacity += 64;
    else if (it.typeId === id && it.isStackable) capacity += Math.max(0, it.maxAmount - it.amount);
    if (capacity >= qty) return true;
  }
  return false;
};
const add = (c, id, qty) => {
  let left=qty;
  while (left > 0) {
    const n = Math.min(left, 64);
    const overflow = c.addItem(new ItemStack(id,n));
    if (overflow) return false;
    left -= n;
  }
  return true;
};
const record = (p, action) => {
  try {
    let old=[];
    try { old=JSON.parse(p.getDynamicProperty(P+'history') || '[]'); } catch {}
    old.unshift(`${new Date().toISOString().slice(0,16)} | ${action}`);
    p.setDynamicProperty(P+'history',JSON.stringify(old.slice(0,10)));
  } catch {}
};
const say = (p,msg) => p.sendMessage('§6[Channel] §r'+msg);
function ensure(p) {
  if (p.getDynamicProperty(P+'created') !== true) {
    set(p,'wallet',100);
    set(p,'bank',0);
    p.setDynamicProperty(P+'created',true);
    record(p,'Boas-vindas: +100 na carteira');
    say(p,'Conta criada! Bonus inicial: 100 moedas digitais.');
  }
}
function handWallet(p) {
  try {
    ensure(p);
    const c=inv(p); if(!c || itemCount(c,'erpg:carteira')>0) return;
    const overflow=c.addItem(new ItemStack('erpg:carteira',1));
    if (overflow) say(p,'Abra espaco no inventario para receber a Carteira Channel.');
    else say(p,'Use o item Carteira Channel para abrir o menu.');
  } catch (e) { say(p,'Erro de inicializacao: '+String(e)); }
}
async function form(p, title, body, buttons) {
  const ui=new ActionFormData().title(title).body(body);
  for(const b of buttons) ui.button(b);
  try { const r=await ui.show(p); return r.canceled ? null : r.selection; }
  catch (e) { say(p,'Nao foi possivel abrir menu (feche o chat).'); return null; }
}
async function amountForm(p, title, hint='Quantidade inteira') {
  try {
    const r=await new ModalFormData().title(title).textField('Quantidade',hint,{defaultValue:'1'}).show(p);
    if(r.canceled) return null;
    const n=parseAmount(r.formValues?.[0]);
    if (!n) say(p,'Informe um numero inteiro positivo ate 999.999.999.');
    return n;
  } catch { say(p,'Falha ao abrir formulario.'); return null; }
}
async function openMenu(p) {
  if (!p?.isValid) return;
  ensure(p);
  if (viewing.has(p.id)) return;
  viewing.add(p.id);
  try {
    const sel=await form(p,'Channel | Economia',`Carteira: §a${money(get(p,'wallet'))}§r\nBanco: §b${money(get(p,'bank'))}§r\nDinheiro fisico: §e${money(physicalTotal(p))}`,['Vender recursos','Mercado Channel','Banco (digital)','Depositar moedas fisicas','Sacar dinheiro fisico','Transferir dinheiro','Extrato','Conhecer Valdora','Fechar']);
    if (sel===null || sel===8) return;
    if(sel===0) await sellMenu(p);
    if(sel===1) await shopMenu(p);
    if(sel===2) await bankMenu(p);
    if(sel===3) await depositCashMenu(p);
    if(sel===4) await withdrawCashMenu(p);
    if(sel===5) await transferMenu(p);
    if(sel===6) await historyMenu(p);
    if(sel===7) await form(p,'Valdora | Primeiro Reino','Valdora e o primeiro territorio de Channel. O Mercado, o Banco e as recompensas de combate formam sua economia inicial. Vilas, faccoes, novos NPCs e historia serao adicionados em versoes futuras.',['Voltar']);
  } finally { viewing.delete(p.id); }
}
function physicalTotal(p) {
  const c=inv(p); if(!c) return 0;
  return CASH.reduce((sum,unit)=>sum+itemCount(c,unit.id)*unit.face,0);
}
async function sellMenu(p) {
  const choice=await form(p,'Vender recursos','Receba moedas na carteira digital. Cada operacao consome os itens indicados.',SELL.map(x=>`${x.name} => +${x.value}`));
  if(choice===null) return;
  const s=SELL[choice], c=inv(p);
  if(!s || !c) return;
  if(get(p,'wallet')+s.value>LIMIT) return say(p,'Limite de saldo atingido.');
  if(!take(c,s.id,s.qty)) return say(p,'Itens insuficientes.');
  set(p,'wallet',get(p,'wallet')+s.value);
  record(p,`Venda: ${s.name} +${s.value}`);
  say(p,`Venda concluida: +${money(s.value)}.`);
}
async function shopMenu(p) {
  const choice=await form(p,'Mercado Channel','Compre itens com saldo da carteira digital.',SHOP.map(x=>`${x.name} | ${x.value} moedas`));
  if(choice===null) return;
  const s=SHOP[choice], c=inv(p);
  if(!s||!c) return;
  const bal=get(p,'wallet');
  if(bal<s.value) return say(p,'Saldo insuficiente.');
  if(!spaceFor(c,s.id,s.qty)) return say(p,'Inventario sem espaco.');
  set(p,'wallet',bal-s.value);
  if (!add(c,s.id,s.qty)) {
    set(p,'wallet',bal); // defesa; o inventario ja foi prevalidado
    return say(p,'Falha ao entregar. Saldo restaurado.');
  }
  record(p,`Compra: ${s.name} -${s.value}`);
  say(p,`Compra realizada: ${s.name}.`);
}
async function bankMenu(p) {
  const choice=await form(p,'Banco Channel',`Carteira digital: ${money(get(p,'wallet'))}\nConta bancaria: ${money(get(p,'bank'))}`,['Depositar na conta','Retirar da conta','Voltar']);
  if(choice===null||choice===2) return;
  const n=await amountForm(p,choice===0?'Depositar no banco':'Retirar do banco');
  if(n===null) return;
  const source=choice===0?'wallet':'bank', target=choice===0?'bank':'wallet';
  if(get(p,source)<n) return say(p,'Saldo insuficiente.');
  if(get(p,target)+n>LIMIT) return say(p,'Limite de saldo atingido.');
  set(p,source,get(p,source)-n);
  set(p,target,get(p,target)+n);
  record(p,`${choice===0?'Deposito':'Retirada'} bancaria: ${n}`);
  say(p,`Operacao realizada: ${money(n)}.`);
}
async function depositCashMenu(p) {
  const c=inv(p); if(!c) return;
  const ch=await form(p,'Depositar dinheiro fisico','Selecione a especie. Voce depositara a quantidade informada em sua carteira digital.',CASH.map(x=>`${x.name} | voce tem ${itemCount(c,x.id)}`));
  if(ch===null) return;
  const coin=CASH[ch]; if(!coin) return;
  const n=await amountForm(p,'Quantas unidades depositar?'); if(n===null) return;
  const total=n*coin.face;
  if(!Number.isSafeInteger(total) || total>LIMIT-get(p,'wallet')) return say(p,'Limite de saldo atingido.');
  if(!take(c,coin.id,n)) return say(p,'Moedas fisicas insuficientes.');
  set(p,'wallet',get(p,'wallet')+total);
  record(p,`Dinheiro fisico depositado: +${total}`);
  say(p,`Deposito de ${money(total)} realizado.`);
}
async function withdrawCashMenu(p) {
  const c=inv(p); if(!c) return;
  const ch=await form(p,'Sacar dinheiro fisico',`Saldo da carteira: ${money(get(p,'wallet'))}`,CASH.map(x=>`${x.name} | valor ${x.face}`));
  if(ch===null) return;
  const coin=CASH[ch]; if(!coin) return;
  const n=await amountForm(p,'Quantas unidades sacar?'); if(n===null) return;
  const total=n*coin.face;
  if(!Number.isSafeInteger(total) || total>get(p,'wallet')) return say(p,'Saldo insuficiente.');
  if(!spaceFor(c,coin.id,n)) return say(p,'Inventario sem espaco.');
  const bal=get(p,'wallet'); set(p,'wallet',bal-total);
  if(!add(c,coin.id,n)) {
    set(p,'wallet',bal);
    return say(p,'Falha no saque. Saldo restaurado.');
  }
  record(p,`Saque fisico: -${total} (${n}x ${coin.name})`);
  say(p,`Saque realizado: ${n}x ${coin.name}.`);
}
async function transferMenu(p) {
  const other=world.getAllPlayers().filter(x=>x.id!==p.id);
  if(!other.length) return say(p,'Nao ha outros jogadores online.');
  const sel=await form(p,'Transferencia','Selecione o jogador que recebera dinheiro digital.',other.map(x=>x.name));
  if(sel===null) return;
  const receiver=other[sel]; if(!receiver?.isValid) return say(p,'Jogador desconectado.');
  const n=await amountForm(p,`Enviar para ${receiver.name}`); if(n===null) return;
  ensure(receiver);
  if(get(p,'wallet')<n) return say(p,'Saldo insuficiente.');
  if(get(receiver,'wallet')+n>LIMIT) return say(p,'Destinatario atingiu limite de saldo.');
  set(p,'wallet',get(p,'wallet')-n);
  set(receiver,'wallet',get(receiver,'wallet')+n);
  record(p,`Envio a ${receiver.name}: -${n}`);
  record(receiver,`Recebido de ${p.name}: +${n}`);
  say(p,`Transferiu ${money(n)} para ${receiver.name}.`);
  say(receiver,`Recebeu ${money(n)} de ${p.name}.`);
}
async function historyMenu(p) {
  let hist=[];
  try { hist=JSON.parse(p.getDynamicProperty(P+'history') || '[]'); } catch {}
  await form(p,'Extrato - ultimas 10',hist.length?hist.join('\n'):'Sem movimentacoes',['Voltar']);
}

system.beforeEvents.startup.subscribe(({itemComponentRegistry})=>{
  itemComponentRegistry.registerCustomComponent('erpg:open',{
    onUse(event){system.run(()=>{openMenu(event.source).catch(e=>say(event.source,`Erro: ${String(e)}`));});}
  });
});
world.afterEvents.playerSpawn.subscribe((ev)=>{
  system.runTimeout(()=>handWallet(ev.player),20);
});
world.afterEvents.entityDie.subscribe((ev)=>{
  try {
    const killer=ev.damageSource?.damagingEntity;
    const amount=REWARD[ev.deadEntity.typeId];
    if(!amount || !(killer instanceof Player)) return;
    ensure(killer);
    if(get(killer,'wallet')+amount>LIMIT) return;
    set(killer,'wallet',get(killer,'wallet')+amount);
    record(killer,`Recompensa monstro: +${amount}`);
    say(killer,`Monstro derrotado: +${money(amount)}.`);
  } catch {}
});
