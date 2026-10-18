const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
process.env.PLAYWRIGHT_BROWSERS_PATH||='C:/Users/jardi/AppData/Local/ms-playwright';
const {chromium,webkit}=require(process.env.PLAYWRIGHT_MODULE||'C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base=__dirname,source=fs.readFileSync(path.join(base,'acabamento-integrado-zm.html'),'utf8').match(/<script>([\s\S]*?)<\/script>/)[1];
const helper=fs.readFileSync(process.env.TWEAK_HELPER_PATH||'C:/Users/jardi/.codex/plugins/cache/openai-bundled/visualize/1.0.50/assets/tweak.js','utf8');
const lum=c=>c.slice(0,3).map(v=>{v/=255;return v<=.04045?v/12.92:((v+.055)/1.055)**2.4;}).reduce((sum,v,i)=>sum+v*[.2126,.7152,.0722][i],0);
const ratio=(a,b)=>{const [x,y]=[lum(a),lum(b)].sort((x,y)=>y-x);return(x+.05)/(y+.05);};
const over=(a,b,opacity=a[3]/255)=>a.slice(0,3).map((v,i)=>v*opacity+b[i]*(1-opacity));
async function run(engine){
 const browser=engine==='edge'?await chromium.launch({channel:'msedge',headless:true}):await webkit.launch({headless:true});
 try{
  const page=await browser.newPage({viewport:{width:422,height:1200},locale:'pt-BR',colorScheme:'light'}),errors=[],checks=[],layouts=[],colors=[];
  page.on('pageerror',e=>errors.push(e.message));
  await page.goto('file:///'+path.join(base,'acabamento-integrado-zm-preview.html').replaceAll('\\','/'));
  const frame=page.frames().find(f=>f.parentFrame()),app=frame.locator('.app');await app.locator('.page-title').waitFor();
  const idle=()=>frame.waitForFunction(()=>document.getAnimations().every(a=>a.playState!=='running'),null,{timeout:3000});
  const nav=async area=>{await app.locator(`.navigation [data-area=${area}]`).click();await idle();};
  const tab=async kind=>{await app.locator(`[data-finance=${kind==='pay'?'pagar':'receber'}]`).click();await idle();};
  const text=async()=>(await app.innerText()).replaceAll('\u00a0',' ');
  const choose=async filter=>{await app.locator('.finish-filter>summary').click();await app.locator(`.finish-filter [data-filter=${filter}]`).click();await idle();};
  const shot=async name=>{await idle();await app.screenshot({path:path.join(base,`${engine}-${name}.png`)});};
  await nav('financeiro');await tab('receive');
  assert.equal(await app.locator('.finish-filter').getAttribute('open'),null);
  const filterHeight=await app.locator('.finish-filter').evaluate(e=>e.offsetHeight);assert.ok(filterHeight>=48&&filterHeight<=50);
  assert.equal(await app.locator('.finish-filter [data-filter]:visible').count(),0);
  assert.equal(await app.locator('.finish-statement .row').count(),2);
  assert.match(await text(),/Original R\$ 900,00 · Recebido R\$ 200,00/);
  assert.match(await text(),/1 parcial/);assert.match(await text(),/1\.950,00/);
  await shot('receber-claro-celular');
  await app.locator('.finish-filter>summary').focus();await page.keyboard.press('Enter');
  assert.equal(await app.locator('.finish-filter [data-filter]:visible').count(),6);
  await shot('filtros-abertos');
  await app.locator('.finish-filter [data-filter=today]').click();
  assert.equal(await app.locator('.finish-filter').getAttribute('open'),null);
  assert.equal(await app.locator('.finish-filter>summary').evaluate(e=>e===document.activeElement),true);
  assert.match(await text(),/Nenhuma conta em aberto/);assert.match(await text(),/0,00/);
  await choose('next');assert.match(await text(),/1\.950,00/);
  await nav('estoque');await nav('financeiro');assert.equal(await app.locator('[data-filter=next]').getAttribute('aria-pressed'),'true');
  await app.locator('[data-go="financeiro:conta-bruno"]').click();await app.locator('.back').click();
  assert.equal(await app.locator('[data-filter=next]').getAttribute('aria-pressed'),'true');
  checks.push('Filtro fechado em até 50px, seis recortes acessíveis, teclado/foco, vazio legítimo e contexto ao retornar');

  // Use the bundled helper with a local host bridge, like the FE-049 regression check.
  await frame.evaluate(({source,helper})=>{
   const old=document.getElementById('zm-finish-demo'),clone=old.cloneNode(true);clone.querySelector('.app').replaceChildren();old.replaceWith(clone);
   window.__regs={};window.__saved=[];window.__changes=new Map();
   window.openai={...window.openai,widgetState:null,callTool(name,m){if(name!=='__codex_visualization_annotations__')throw Error(name);if(['register','update'].includes(m.type)){window.__regs[m.registrationId]=JSON.parse(JSON.stringify(m));return Promise.resolve({annotationControls:m.annotationControls});}return Promise.resolve({});},setWidgetState(s){window.__saved.push(JSON.parse(JSON.stringify(s)));return Promise.resolve();}};
   (0,eval)(helper);(0,eval)(source);
  },{source,helper});
  await frame.waitForFunction(()=>Object.values(window.__regs).some(r=>r.annotationControls.controls.length===7));
  const edit=async(label,value)=>{await frame.evaluate(({label,value})=>{
   const [registrationId,r]=Object.entries(window.__regs).find(([,r])=>r.annotationControls.controls.length===7),c=r.annotationControls.controls.find(c=>c.label===label);
   window.__changes.set(c.callback,{callback:c.callback,previousValue:c.currentValue,value});
   window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:window.__saved.at(-1)||null,visualizationAnnotation:{active:false,changes:[{registrationId,targetId:r.targets[0].id,annotationControlChanges:[...window.__changes.values()]}]}}}}));
  },{label,value});await idle();};
  await nav('financeiro');await tab('pay');await choose('today');
  await app.locator('[data-go="financeiro:conta-fornecedor"]').click();await app.locator('[data-action=form]').click();
  await app.getByRole('radio',{name:'Parcial',exact:true}).check();await app.locator('[data-field=amount]').fill('200');await app.locator('[data-field=method]').selectOption('PIX');await app.locator('[data-field=notes]').fill('Conferir material');
  await edit('Material da prévia','solid');await edit('Aparência','dark');
  assert.equal(await app.locator('[data-field=amount]').inputValue(),'200');assert.equal(await app.locator('[data-field=notes]').inputValue(),'Conferir material');
  await edit('Material da prévia','glass');await app.locator('[data-action=review]').click();await app.locator('[data-action=edit]').click();
  await shot('pagar-escuro-formulario');
  await app.locator('[data-action=review]').click();await app.locator('[data-action=confirm]').click();await app.getByRole('heading',{name:'Registro confirmado',exact:true}).waitFor();
  await app.locator('[data-action=return-list]').click();assert.match(await text(),/Original R\$ 680,00 · Pago R\$ 200,00/);assert.match(await text(),/480,00/);assert.match(await text(),/1 parcial/);
  await shot('pagar-escuro-parcial');
  checks.push('Troca de material/tema preserva rascunho; parcial confirmado volta ao mesmo recorte com saldo e pago corretos');

  for(const [format,width]of [['mobile',320],['mobile',390],['desktop',1024]])for(const theme of ['light','dark'])for(const scale of ['100','150','200'])for(const material of ['glass','solid']){
   await page.setViewportSize({width,height:1800});await edit('Formato da prévia',format);await edit('Aparência',theme);await edit('Texto do conteúdo',scale);await edit('Material da prévia',material);
   for(const kind of ['pay','receive']){
    await tab(kind);
    const metrics=await app.evaluate(e=>{
     const box=e.getBoundingClientRect(),bad=[...e.querySelectorAll('main *')].filter(n=>n.getClientRects().length&&n.clientWidth>0&&n.scrollWidth>n.clientWidth+2).map(n=>({tag:n.tagName,cls:n.className,scroll:n.scrollWidth,client:n.clientWidth}));
     return{width:box.width,height:box.height,client:e.clientWidth,scroll:e.scrollWidth,body:document.documentElement.scrollWidth,viewport:innerWidth,bad};
    });
    assert.ok(metrics.scroll<=metrics.client+1&&metrics.body<=metrics.viewport+1&&metrics.bad.length===0,JSON.stringify({engine,format,width,theme,scale,material,kind,metrics}));
    layouts.push({format,outerWidth:width,theme,scale,material,kind,...metrics});if(process.env.CHECK_DEBUG&&layouts.length%12===0)console.log(JSON.stringify({engine,layouts:layouts.length,format,width,theme,scale,material,kind}));
   }
  }
  checks.push('72 composições financeiras por motor: 320/390/1024, claro/escuro, texto 100/150/200%, vidro/sólido, Pagar/Receber, sem transbordamento observado');
  await edit('Texto do conteúdo','100');await edit('Formato da prévia','desktop');await page.setViewportSize({width:1024,height:1200});
  await tab('receive');await edit('Material da prévia','glass');await edit('Aparência','light');await shot('receber-computador');
  const declared=()=>app.evaluate(e=>{
   const probe=document.createElement('span');e.append(probe);const canvas=document.createElement('canvas'),ctx=canvas.getContext('2d');
   function resolve(value){probe.style.color=value;ctx.clearRect(0,0,1,1);ctx.fillStyle=getComputedStyle(probe).color;ctx.fillRect(0,0,1,1);return [...ctx.getImageData(0,0,1,1).data];}
   const v={page:resolve('var(--page)'),cool:resolve('var(--finish-cool)'),warm:resolve('var(--finish-warm)'),panel:resolve('var(--finish-panel)'),ink:resolve('var(--ink)'),sub:resolve('var(--sub)')};probe.remove();return v;
  });
  for(const theme of ['light','dark']){
   await edit('Aparência',theme);const c=await declared();
   for(const cool of [0,c.cool[3]/255])for(const warm of [0,c.warm[3]/255]){
    const pageColor=over(c.cool,over(c.warm,c.page,warm),cool),panel=over(c.panel,pageColor);
    for(const [name,foreground]of [['principal',c.ink],['secundário',c.sub]]){
     const value=ratio(foreground,panel);assert.ok(value>=4.5,JSON.stringify({theme,name,value}));colors.push({theme,name,cool,warm,ratio:value});
    }
   }
   await edit('Material da prévia','solid');assert.equal(await app.locator('.hero').evaluate(e=>getComputedStyle(e).backdropFilter||getComputedStyle(e).webkitBackdropFilter),'none');assert.equal(await app.evaluate(e=>getComputedStyle(e).backgroundImage),'none');
   await edit('Material da prévia','glass');assert.match(await app.locator('.hero').evaluate(e=>getComputedStyle(e).backdropFilter||getComputedStyle(e).webkitBackdropFilter),/blur/);
  }
  await shot('receber-escuro-computador');
  checks.push('Contraste calculado de principal/secundário em limites das camadas padrão >=4,5; alternativa sólida efetiva em ambos os temas');
  if(engine==='edge'){
   const cdp=await page.context().newCDPSession(page);
   await cdp.send('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-transparency',value:'reduce'}]});
   const matched=await frame.evaluate(()=>matchMedia('(prefers-reduced-transparency:reduce)').matches);
   if(matched)assert.equal(await app.locator('.hero').evaluate(e=>getComputedStyle(e).backdropFilter),'none');
   await cdp.send('Emulation.setEmulatedMedia',{features:[]});
   await page.emulateMedia({forcedColors:'active'});assert.equal(await frame.evaluate(()=>matchMedia('(forced-colors:active)').matches),true);assert.equal(await app.locator('.hero').evaluate(e=>getComputedStyle(e).backdropFilter),'none');await page.emulateMedia({forcedColors:'none'});
   checks.push(`Cores forçadas emuladas no Edge ativam superfície sólida; emulação de redução de transparência ${matched?'disponível':'indisponível neste ambiente'}. Sem homologação nativa`);
  }
  await page.emulateMedia({reducedMotion:'reduce'});await frame.waitForFunction(()=>document.querySelector('.app').dataset.motion==='false');
  await nav('inicio');await edit('Texto do conteúdo','100');await edit('Aparência','light');await edit('Formato da prévia','mobile');await page.setViewportSize({width:390,height:1200});await shot('inicio-acabamento');
  const saves=await frame.evaluate(()=>window.__saved.length);
  await frame.evaluate(()=>{const state=JSON.parse(JSON.stringify(window.__saved.at(-1)));state.privateContent.design.material='solid';window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:state}}}));});
  assert.equal(await app.getAttribute('data-material'),'solid');assert.equal(await frame.evaluate(()=>window.__saved.length),saves);
  assert.deepEqual(errors,[]);checks.push('Movimento reduzido respeitado; restauração de material sem gravação adicional; sem erro JavaScript observado');
  return{engine,result:'passed',checks,layouts,colors,javascriptErrors:errors,limits:'Prévia com dados fictícios. Contraste é cálculo das camadas padrão declaradas, não medição de todos os pixels/estados, cores personalizadas ou aparelho nativo. Cores forçadas emuladas somente no Edge; redução de transparência depende do suporte indicado nos checks.'};
 }finally{await browser.close();}
}
(async()=>{const results=await Promise.all((process.env.CHECK_ENGINES||'edge,webkit').split(',').map(run));fs.writeFileSync(path.join(base,'acabamento-verificacao.json'),JSON.stringify({date:'2026-10-16',results},null,2)+'\n');console.log(JSON.stringify(results.map(r=>({engine:r.engine,checks:r.checks.length,layouts:r.layouts.length,colors:r.colors.length}))));})().catch(e=>{console.error(e);process.exitCode=1;});
