const fs=require('fs'),vm=require('vm'),assert=require('assert');
const raw=fs.readFileSync(require('path').resolve(__dirname,'../addon/Channel_BP/scripts/main.js'),'utf8');
const code=raw.replace(/^import .*;\s*$/gm,'')+'\n globalThis.__eco={ensure,handWallet,openMenu,physicalTotal,inv,get,record,spaceFor};';
let startupCallback,spawnCallback,killCallback;
let actionQueue=[],modalQueue=[];
class ItemStack {
  constructor(typeId,amount=1){this.typeId=typeId;this.amount=amount;this.maxAmount=['minecraft:iron_sword','minecraft:shield','minecraft:iron_pickaxe','erpg:carteira'].includes(typeId)?1:64;this.isStackable=this.maxAmount>1;}
}
class Inventory {constructor(){this.items=Array(36).fill(undefined);this.size=36;}
  getItem(i){ const item=this.items[i];return item?Object.assign(new ItemStack(item.typeId,item.amount),{}):undefined; }
  setItem(i,it){this.items[i]=it?new ItemStack(it.typeId,it.amount):undefined;}
  addItem(it){let left=it.amount;for(let i=0;i<this.size;i++){let curr=this.items[i]; if(curr && curr.typeId===it.typeId && curr.maxAmount>curr.amount){let n=Math.min(left,curr.maxAmount-curr.amount);curr.amount+=n;left-=n;}if(!left)break;}
  for(let i=0;i<this.size && left>0;i++){if(!this.items[i]){const max=it.maxAmount;const n=Math.min(left,max);this.items[i]=new ItemStack(it.typeId,n);left-=n;}}
  return left ? new ItemStack(it.typeId,left) : undefined;
  }
}
class Player {constructor(name){this.id=name;this.name=name;this.isValid=true;this.dyn={};this.container=new Inventory();this.log=[];}
 getComponent(id){if(id==='minecraft:inventory')return {container:this.container};}
 getDynamicProperty(k){return this.dyn[k];}
 setDynamicProperty(k,v){this.dyn[k]=v;}
 sendMessage(m){this.log.push(m);}
}
class ActionFormData {
 title(){return this;} body(){return this;} button(){return this;}
 async show(){assert(actionQueue.length, 'no action mock');return {canceled:false,selection:actionQueue.shift()};}
}
class ModalFormData {
 title(){return this;} textField(_label,_hint,opts){assert(typeof opts==='object');return this;}
 async show(){assert(modalQueue.length, 'no modal mock');return {canceled:false,formValues:[String(modalQueue.shift())]};}
}
const world={afterEvents:{playerSpawn:{subscribe(fn){spawnCallback=fn}},entityDie:{subscribe(fn){killCallback=fn}}},players:[],getAllPlayers(){return this.players}};
const system={beforeEvents:{startup:{subscribe(fn){startupCallback=fn}}},run(fn){fn();},runTimeout(fn){fn();}};
const ctx={world,system,ItemStack,Player,ActionFormData,ModalFormData,Date,Number,String,Math,Set,JSON,Error,console};
vm.runInNewContext(code,ctx,{filename:'main.js'});
const api=ctx.__eco;
const compRegistry={registerCustomComponent(id,component){assert.equal(id,'erpg:open');assert(typeof component.onUse==='function')}};
startupCallback({itemComponentRegistry:compRegistry});
const p=new Player('JogadorA'),q=new Player('JogadorB');world.players=[p,q];
spawnCallback({player:p});spawnCallback({player:q});
assert.equal(api.get(p,'wallet'),100);assert.equal(api.get(q,'wallet'),100);
assert.equal(api.inv(p).getItem(0).typeId,'erpg:carteira');
killCallback({deadEntity:{typeId:'minecraft:zombie'},damageSource:{damagingEntity:p}});
assert.equal(api.get(p,'wallet'),105);
api.inv(p).addItem(new ItemStack('minecraft:cobblestone',16));
async function op(choices,amounts){actionQueue=choices.slice();modalQueue=amounts.slice(); await api.openMenu(p);assert.equal(actionQueue.length,0);assert.equal(modalQueue.length,0);}
(async()=>{
 await op([0,0],[]);assert.equal(api.get(p,'wallet'),113); // venda
 await op([2,0],[20]);assert.equal(api.get(p,'wallet'),93);assert.equal(api.get(p,'bank'),20); // banco
 await op([4,1],[2]);assert.equal(api.get(p,'wallet'),73);assert.equal(api.physicalTotal(p),20); // saque
 await op([3,1],[1]);assert.equal(api.get(p,'wallet'),83);assert.equal(api.physicalTotal(p),10); // deposito fisico
 await op([5,0],[15]);assert.equal(api.get(p,'wallet'),68);assert.equal(api.get(q,'wallet'),115); // transferencia
 await op([1,0],[]);assert.equal(api.get(p,'wallet'),44); // loja
 assert.equal(api.inv(p).getItem(0).typeId,'erpg:carteira');
 assert.equal(api.inv(p).items.some(i=>i?.typeId==='minecraft:bread'&&i.amount===4),true);
 // fundos insuficientes nao mudam inventario ou saldo
 await op([4,2],[1]);assert.equal(api.get(p,'wallet'),44);assert.equal(api.physicalTotal(p),10);
 await op([3,1],[10]);assert.equal(api.get(p,'wallet'),44);assert.equal(api.physicalTotal(p),10);
 assert.equal(p.dyn['erpg:history']!==undefined,true);
 console.log('PASS 11 tests: create, wallet item, combat, sale, deposit bank, cash withdrawal, physical deposit, transfer, shop, insufficient funds, history');
})().catch(e=>{console.error(e);process.exit(1)});
