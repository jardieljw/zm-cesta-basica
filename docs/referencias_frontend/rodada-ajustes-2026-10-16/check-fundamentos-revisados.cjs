const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
process.env.PLAYWRIGHT_BROWSERS_PATH||='C:/Users/jardi/AppData/Local/ms-playwright';
const {chromium,webkit}=require(process.env.PLAYWRIGHT_MODULE||'C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base=process.env.PREVIEW_DIR||__dirname;
const fragment=fs.readFileSync(path.join(base,'fundamentos-visuais-revisados-zm.html'),'utf8'),source=fragment.match(/<script>([\s\S]*?)<\/script>/)[1];new vm.Script(source);
const clean=value=>value.replaceAll('\u00a0',' ');
function ratio(a,b){const light=value=>value.match(/[\d.]+/g).slice(0,3).map(Number).map(v=>{v/=255;return v<=.04045?v/12.92:((v+.055)/1.055)**2.4;}).reduce((sum,v,i)=>sum+v*[.2126,.7152,.0722][i],0);const values=[light(a),light(b)].sort((x,y)=>y-x);return (values[0]+.05)/(values[1]+.05);}
async function run(engine){
 const browser=engine==='edge'?await chromium.launch({channel:'msedge',headless:true}):await webkit.launch({headless:true});
 try {
  const page=await browser.newPage({viewport:{width:390,height:1800},locale:'pt-BR',colorScheme:'light',reducedMotion:'no-preference',isMobile:true,hasTouch:true}),errors=[],groups=[],layouts=[],contrasts=[];
  page.on('pageerror',error=>errors.push(error.message));
  await page.goto('file:///'+path.join(base,'fundamentos-visuais-revisados-zm-preview.html').replaceAll('\\','/'));
  const frame=page.frames().find(f=>f.parentFrame());await frame.locator('[data-example=fields] [data-field=date]').waitFor();
  await frame.evaluate(code=>{
   document.querySelectorAll('.specimen').forEach(app=>{const clone=app.cloneNode(true);clone.querySelector('.product-content').innerHTML='';app.replaceWith(clone);});
   window.__bindings=[];window.__snapshots=[];
   window.openai={...window.openai,widgetState:null,setWidgetState(state){window.__snapshots.push(state);return Promise.resolve();}};
   globalThis.Tweak=class {constructor(options){Object.assign(this,options);this.controls=[];window.__bindings.push(this);}addSelect(object,property,options){this.controls.push({object,property,options});}addSlider(object,property,options){this.controls.push({object,property,options});}addColorPicker(object,property,options){this.controls.push({object,property,options});}};
   (0,eval)(code);
  },source);
  const app=example=>frame.locator(`[data-example=${example}]`);
  const show=example=>frame.evaluate(example=>{document.querySelectorAll('.viz-carousel > section').forEach(section=>section.hidden=!section.querySelector(`[data-example=${example}]`));},example);
  const tweak=(example,property,value)=>frame.evaluate(({example,property,value})=>{const b=window.__bindings.find(b=>example==='foundation'?b.container.id==='zm-visual-foundations-revised':b.container.dataset.example===example),c=b.controls.find(c=>c.property===property);c.object[property]=value;b.onChange();},{example,property,value});
  const idle=()=>frame.evaluate(()=>Promise.all(document.getAnimations().map(a=>a.finished.catch(()=>{}))));
  const shot=(example,name)=>app(example).screenshot({path:path.join(base,`fundamentos-revisados-${engine}-${name}.png`)});
  const fields=app('fields');
  const metrics=()=>frame.evaluate(()=>[...document.querySelectorAll('.specimen')].map(el=>{const style=getComputedStyle(el),panel=el.querySelector('.panel'),p=panel&&getComputedStyle(panel);return {example:el.dataset.example,panelRadius:style.getPropertyValue('--zm-panel-radius').trim(),fieldRadius:style.getPropertyValue('--zm-field-radius').trim(),gap:style.getPropertyValue('--zm-field-gap').trim(),panelGap:p?.gap,panelComputedRadius:p?.borderRadius};}));
  assert.equal(await frame.evaluate(()=>window.__snapshots.length),0,'nao grava estado ao carregar');
  let m=await metrics();assert.ok(m.every(item=>item.gap==='20px'&&item.panelRadius==='32px'&&item.fieldRadius==='28px'));
  await tweak('foundation','spacing',32);await tweak('foundation','panelRadius',40);await tweak('foundation','fieldRadius',32);
  m=await metrics();assert.ok(m.every(item=>item.gap==='32px'&&item.panelRadius==='40px'&&item.fieldRadius==='32px'));assert.equal(m[0].panelGap,'32px');assert.equal(m[0].panelComputedRadius,'40px');
  await tweak('foundation','spacing',16);await tweak('foundation','panelRadius',24);await tweak('foundation','fieldRadius',20);
  assert.equal(await fields.locator('.date-control').evaluate(el=>getComputedStyle(el).borderRadius),'20px');
  await tweak('foundation','spacing',20);await tweak('foundation','panelRadius',32);await tweak('foundation','fieldRadius',28);
  await fields.getByRole('radio',{name:'Parcial',exact:true}).check();await idle();await fields.locator('[data-field=amount]').fill('40');await fields.locator('[data-field=method]').selectOption('PIX');
  assert.equal(clean(await fields.locator('[data-remaining]').innerText()),'R$ 60,00');
  await fields.locator('[data-action=calendar]').click();await idle();
  await tweak('foundation','appearance','dark');await tweak('foundation','accent','#7543b3');await tweak('foundation','spacing',28);
  assert.equal(await fields.locator('.date-dialog').evaluate(el=>el.open),true);
  assert.equal(await fields.locator('[data-calendar-date="2026-10-16"]').evaluate(el=>el===document.activeElement),true);
  await fields.locator('[data-calendar-date="2026-10-17"]').click();await frame.waitForFunction(()=>document.querySelector('[data-field=date]').getAttribute('aria-expanded')==='false');
  assert.equal(await fields.locator('[data-field=date]').evaluate(el=>el===document.activeElement),true);
  assert.equal(await fields.locator('[data-field=amount]').inputValue(),'40');
  await fields.getByRole('radio',{name:'Integral',exact:true}).check();await idle();assert.equal(clean(await fields.locator('[data-remaining]').innerText()),'R$ 0,00');
  groups.push('Tokens alteram medidas reais em todas as amostras; tema/cor/espaco preservam rascunho e calendario aberto');

  const restored=await frame.evaluate(()=>{const saved=window.__snapshots.at(-1),b=window.__bindings.find(b=>b.container.id==='zm-visual-foundations-revised'),original=b.controls.find(c=>c.property==='spacing').object,before=window.__snapshots.length;window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:saved}}}));const during=window.__snapshots.length;original.spacing=20;original.panelRadius=36;original.fieldRadius=24;b.onChange();return {stable:b.controls.find(c=>c.property==='spacing').object===original,size:JSON.stringify(saved).length,savedOnRestore:during-before};});
  assert.equal(restored.stable,true);assert.equal(restored.savedOnRestore,0);assert.ok(restored.size<16384);
  m=await metrics();assert.ok(m.every(item=>item.gap==='20px'&&item.panelRadius==='36px'&&item.fieldRadius==='24px'));
  await tweak('foundation','motion','reduced');assert.equal(await fields.locator('.partial-reveal').evaluate(el=>getComputedStyle(el).transitionDuration),'0s');
  await page.emulateMedia({reducedMotion:'reduce'});await frame.waitForFunction(()=>matchMedia('(prefers-reduced-motion:reduce)').matches);await tweak('foundation','motion','standard');await frame.waitForFunction(()=>[...document.querySelectorAll('.specimen')].every(el=>el.dataset.motion==='false'));
  await page.emulateMedia({reducedMotion:'no-preference'});await frame.waitForFunction(()=>document.querySelector('[data-example=fields]').dataset.motion==='true');
  groups.push('Identidade do objeto de ajustes preservada apos restauracao; sem gravacao ao restaurar e reducao respeitada');

  async function colorPairs(){return frame.evaluate(()=>{const el=document.querySelector('[data-example=fields]'),probe=document.createElement('span');el.append(probe);const token=name=>{probe.style.color=`var(--zm-${name})`;return getComputedStyle(probe).color;};const c={};for(const name of ['page','surface','ink','sub','accent','accent-ink','soft','control-edge','field','ok','ok-fill','warn','warn-fill','bad','bad-fill'])c[name]=token(name);probe.remove();const input=el.querySelector('textarea');c.placeholder=getComputedStyle(input,'::placeholder').color;for(const [name,selector] of [['button','.primary'],['date','.date-control'],['selected','.kind-option:has(input:checked)']]){const style=getComputedStyle(el.querySelector(selector));c[name+'Text']=style.color;c[name+'Fill']=style.backgroundColor;}return c;});}
  for(const seed of ['#2866ae','#116b63','#7543b3','#f8e98b','#ffffff','#000000'])for(const pageStyle of ['soft','pure'])for(const theme of ['light','dark']){
   await tweak('foundation','accent',seed);await tweak('foundation','page',pageStyle);await tweak('foundation','appearance',theme);
   const c=await colorPairs();const pairs=[['ink','page',4.5],['ink','surface',4.5],['sub','page',4.5],['sub','surface',4.5],['placeholder','field',4.5],['accent','surface',4.5],['accent','soft',4.5],['accent-ink','accent',4.5],['ok','ok-fill',4.5],['warn','warn-fill',4.5],['bad','bad-fill',4.5],['control-edge','surface',3],['control-edge','field',3],['buttonText','buttonFill',4.5],['dateText','dateFill',4.5],['selectedText','selectedFill',4.5]];
   for(const [foreground,background,min] of pairs){const measured=ratio(c[foreground],c[background]);assert.ok(measured>=min,JSON.stringify({seed,pageStyle,theme,foreground,background,ratio:measured,min,colors:c}));contrasts.push({seed,pageStyle,theme,foreground,background,ratio:measured,min});}
  }
  groups.push('Cores resolvidas no navegador: 6 destaques x 2 fundos x 2 temas; texto e bordas medidos separadamente');

  await tweak('foundation','accent','#2866ae');await tweak('foundation','page','soft');await tweak('foundation','spacing',20);await tweak('foundation','panelRadius',32);await tweak('foundation','fieldRadius',28);await tweak('foundation','appearance','light');
  await shot('fields','formulario-claro');await tweak('foundation','appearance','dark');await shot('fields','formulario-escuro');
  await tweak('foundation','accent','#116b63');await tweak('foundation','page','pure');await shot('fields','destaque-petroleo');
  await tweak('foundation','appearance','light');await tweak('foundation','accent','#7543b3');await shot('fields','destaque-ametista');
  await tweak('foundation','accent','#2866ae');await tweak('foundation','page','soft');
  await fields.getByRole('radio',{name:'Parcial',exact:true}).check();await fields.locator('[data-field=amount]').fill('999');await fields.locator('[data-action=review]').click();await shot('fields','validacao');
  await show('actions');await tweak('actions','response','unknown');await app('actions').locator('[data-action=confirm]').click();await app('actions').getByRole('heading',{name:'Aguardando confirmação',exact:true}).waitFor();await idle();await shot('actions','confirmacao-pendente');
  await tweak('foundation','accent','#116b63');const statusColors=await app('actions').locator('.message.warning').evaluate(el=>({text:getComputedStyle(el).color,fill:getComputedStyle(el).backgroundColor}));assert.ok(ratio(statusColors.text,statusColors.fill)>=4.5);
  await tweak('foundation','accent','#2866ae');await show('query');await page.setViewportSize({width:780,height:1800});await shot('query','lista-ampla');
  await page.setViewportSize({width:390,height:1800});await tweak('foundation','appearance','dark');await shot('query','lista-celular-escura');
  groups.push('Mesmos dados, cores semanticas independentes do destaque e lista/tabela sem alterar significado financeiro');

  for(const example of ['fields','actions','query']){
   await show(example);await tweak('foundation','motion','reduced');
   for(const width of [320,360,390,780])for(const theme of ['light','dark'])for(const variant of ['base','ampliado']){
    const fontSize=variant==='base'?16:21;
    await page.setViewportSize({width,height:1900});await tweak('foundation','appearance',theme);await tweak('foundation','spacing',variant==='base'?20:32);await tweak('foundation','panelRadius',variant==='base'?32:40);await tweak('foundation','fieldRadius',variant==='base'?28:32);
    const result=await app(example).evaluate((el,fontSize)=>{for(const node of el.querySelectorAll('label,legend,button,select,input,textarea,.date-value,.review-line dt,.review-line dd'))node.style.fontSize=fontSize+'px';const r=el.getBoundingClientRect(),date=el.querySelector('.date-value');let dateFits=true;if(date){const range=document.createRange();range.selectNodeContents(date);const glyphs=range.getBoundingClientRect(),box=date.getBoundingClientRect();dateFits=glyphs.left>=box.left-1&&glyphs.right<=box.right+1&&glyphs.top>=box.top-1&&glyphs.bottom<=box.bottom+1;}const outside=[...el.querySelectorAll('input,select,textarea,.date-control,.panel,.message,.kind-options,.balance')].filter(node=>{if(!node.getClientRects().length||node.closest('[inert]'))return false;const b=node.getBoundingClientRect();return b.left<r.left-1||b.right>r.right+1;}).map(node=>node.className);return {viewport:innerWidth,width:r.width,height:r.height,horizontalOverflow:document.documentElement.scrollWidth>innerWidth+1,outside,dateFits};},fontSize);
    assert.equal(result.horizontalOverflow,false,JSON.stringify({example,width,theme,variant,...result}));assert.deepEqual(result.outside,[]);assert.equal(result.dateFits,true);layouts.push({example,width,theme,variant,fontSize,...result});
   }
  }
  assert.deepEqual(errors,[]);groups.push('Tres familias em quatro larguras, dois temas e geometria/texto base ou ampliados, sem corte de data');
  return {engine,groups,layouts,contrasts,javascriptErrors:errors,persistenceSnapshotBytes:restored.size};
 }finally{await browser.close();}
}
(async()=>{const engines=[];for(const engine of ['edge','webkit'])engines.push(await run(engine));const report={date:'2026-10-16',result:'passed',scope:'Proposta visual local; sem Flutter, API ou dados reais',layoutCases:engines.reduce((n,e)=>n+e.layouts.length,0),contrastPairs:engines.reduce((n,e)=>n+e.contrasts.length,0),engines,limits:['Amostras web em motores locais Windows; sem homologacao nativa iOS/Android ou leitor de tela.','Contraste cobre pares especificados em cores resolvidas, nao certifica WCAG integral nem foco/estados de toda a interface.','Tweak e persistencia instrumentados; painel nativo e restauracao real do hospedeiro nao automatizados.','Texto ampliado simulado em controles; nao equivale a Dynamic Type ou escala nativa.','Tempos, mensagens financeiras e recuperacao de confirmacao permanecem demonstracoes locais.']};fs.writeFileSync(path.join(base,'fundamentos-revisados-verificacao.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({result:report.result,layoutCases:report.layoutCases,contrastPairs:report.contrastPairs,engines:engines.map(e=>({engine:e.engine,groups:e.groups.length,javascriptErrors:e.javascriptErrors}))}));})().catch(error=>{console.error(error);process.exitCode=1;});
