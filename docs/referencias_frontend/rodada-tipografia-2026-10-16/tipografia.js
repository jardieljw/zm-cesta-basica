// This code is inserted inside the preserved integrated demo's closure.
const ordinaryAccounts=accounts.map(a=>({...a}));
let activeExample='everyday';
function changeReadingExample(){
 if(design.example===activeExample)return;
 if(views.some(v=>v.s.busy)){design.example=activeExample;return;}
 activeExample=design.example;
 accounts.forEach((a,i)=>Object.assign(a,ordinaryAccounts[i]));
 if(activeExample==='stress')Object.assign(accounts[0],{
  name:'Distribuidora de Alimentos São José e Filhos — Comércio e Abastecimento de Cestas Básicas Ltda.',
  original:123456789,initialPaid:23456789
 });
 for(const key of Object.keys(settled))delete settled[key];
 history.splice(0);
 for(const v of views){
  Object.assign(v.s,{area:'inicio',stacks:Object.fromEntries(Object.keys(areas).map(k=>[k,['resumo']])),filter:{pay:'week',receive:'week'},drafts:{},stockOnly:false,errors:{},review:null,last:null,busy:false});
  v.render();
 }
}
function wrapReadingMoney(container){
 const walker=document.createTreeWalker(container,NodeFilter.SHOW_TEXT);
 const nodes=[];while(walker.nextNode())nodes.push(walker.currentNode);
 for(const node of nodes){
  if(node.parentElement.closest('.type-money,input,textarea,select,script,style'))continue;
  const pattern=/(-?R\$)\s*([\d.]+,\d{2})/g;
  const matches=[...node.textContent.matchAll(pattern)];if(!matches.length)continue;
  const fragment=document.createDocumentFragment();let offset=0;
  for(const m of matches){
   fragment.append(node.textContent.slice(offset,m.index));
   const amount=document.createElement('span');amount.className='type-money';
   const currency=document.createElement('span');currency.className='type-chunk';currency.textContent=m[1];amount.append(currency,' ');
   const chunks=m[2].match(/\d+\.|\d+,\d{2}/g)||[m[2]];
   chunks.forEach((text,i)=>{if(i)amount.append(document.createElement('wbr'));const chunk=document.createElement('span');chunk.className='type-chunk';chunk.textContent=text;amount.append(chunk);});
   fragment.append(amount);offset=m.index+m[0].length;
  }
  fragment.append(node.textContent.slice(offset));node.replaceWith(fragment);
 }
}
function applyReading(){
 for(const v of views){
  const app=v.app,oriented=app.dataset.reading==='oriented';
  app.classList.toggle('desktop',design.format==='desktop');app.classList.toggle('mobile',design.format!=='desktop');
  app.style.setProperty('--type-scale',String(Number(design.textScale)/100));
  app.dataset.adapted=String(Number(design.textScale)>100||activeExample==='stress');
  app.dataset.expanded=String(Number(design.textScale)>100);
  app.querySelector('.demo-label').textContent=(oriented?'Leitura orientada':'Leitura recuperada')+' · '+(activeExample==='stress'?'Caso de teste com nome longo e quantias altas':'Dados de exemplo');
  const method=app.querySelector('[data-field=method]');
  app.querySelector('[data-type-method]')?.remove();
  if(method){
   const wrapper=method.closest('.type-select');
   if(app.dataset.adapted==='true'&&!wrapper){const box=document.createElement('div');box.className='type-select';method.before(box);box.append(method);const arrow=document.createElement('i');arrow.dataset.lucide='chevron-down';arrow.setAttribute('aria-hidden','true');box.append(arrow);}
   if(app.dataset.adapted!=='true'&&wrapper)wrapper.replaceWith(method);
   if(Number(design.textScale)>100&&method.value){const help=document.createElement('p');help.className='rec-help';help.dataset.typeMethod='true';help.textContent='Forma selecionada: '+method.selectedOptions[0].textContent;(method.closest('.type-select')||method).after(help);}
  }
  if(oriented||app.dataset.adapted==='true')wrapReadingMoney(app.querySelector('.content'));
 }
 globalThis.lucide?.createIcons({attrs:{width:18,height:18}});
}
