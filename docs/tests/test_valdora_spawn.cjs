const fs=require('fs'), vm=require('vm'), assert=require('node:assert/strict');
const source=fs.readFileSync(require('path').join(__dirname,'../addon/Channel_BP/scripts/main.js'),'utf8');
const code=source.replace(/^import .*;\s*$/gm,'')+'\n globalThis.__vtest={constructValdora,storedValdora,goValdora,valdoraSpawnLocation,openValdoraEntry};';
const calls=[];let replies=[];const store=new Map();
class Player { constructor(name){this.id=name;this.name=name;this.isValid=true;this.dimension=dimension;this.location={x:48.5,y:64,z:48.5};this.dyn={};this.messages=[];}
 sendMessage(x){this.messages.push(x)}
 getDynamicProperty(k){return this.dyn[k]}
 setDynamicProperty(k,v){this.dyn[k]=v}
 setSpawnPoint(where){calls.push(['playerSpawn',this.name,where]);this.personalSpawn=where}
 teleport(where,opts){calls.push(['teleport',this.name,where,opts]);this.location=where}
 getComponent(){return {container:{size:36,getItem(){return undefined},addItem(){return undefined}}}}
}
const dimension={id:'minecraft:overworld',runCommand(cmd){calls.push(['worldCommand',cmd]);return {successCount:1};}};
const world={getDynamicProperty(k){return store.get(k)},setDynamicProperty(k,v){store.set(k,v)},getDimension(name){assert.equal(name,'overworld');return dimension},structureManager:{place(id,dim,loc){assert.equal(dim,dimension);calls.push(['structure',id,loc]);}},afterEvents:{playerSpawn:{subscribe(){}},entityDie:{subscribe(){}}}};
const system={beforeEvents:{startup:{subscribe(){}}},run(){},runTimeout(){}};
class ActionFormData { title(){return this} body(){return this} button(){return this} async show(){assert.ok(replies.length,'No UI reply');return {canceled:false,selection:replies.shift()}} }
class ModalFormData {title(){return this}textField(){return this}async show(){return {canceled:true}}}
class ItemStack {constructor(id){this.typeId=id}}
const ctx={world,system,ActionFormData,ModalFormData,Player,ItemStack,Number,String,Math,Set,JSON,Error,Date};
vm.runInNewContext(code,ctx,{filename:'main.js'});
const api=ctx.__vtest;
(async()=>{
 const p=new Player('Primeiro');
 replies=[1];await api.constructValdora(p);
 assert.equal(calls.filter(x=>x[0]==='structure').length,8);
 assert.equal(calls.filter(x=>x[0]==='structure')[5][1],'channel:valdora/praca');
 const site=api.storedValdora();assert.deepEqual([site.x,site.y,site.z],[0,63,0]);
 assert.equal(calls.filter(x=>x[0]==='worldCommand')[0][1],'setworldspawn 47 65 61');
 assert.deepEqual([p.personalSpawn.x,p.personalSpawn.y,p.personalSpawn.z],[47,65,61]);
 assert.deepEqual([p.location.x,p.location.y,p.location.z],[47.5,65.05,61.5]);
 const n=calls.filter(x=>x[0]==='structure').length;
 await api.constructValdora(p);assert.equal(calls.filter(x=>x[0]==='structure').length,n,'no duplicate building');
 const q=new Player('Segundo');api.goValdora(q,site);
 assert.deepEqual([q.location.x,q.location.z],[47.5,61.5]);
 assert.deepEqual([q.personalSpawn.x,q.personalSpawn.z],[47,61]);
 console.log('PASS spawn tests: eight structures, safe entrance, world spawn, player respawn, one-time build, additional player');
})().catch(e=>{console.error(e);process.exit(1)});