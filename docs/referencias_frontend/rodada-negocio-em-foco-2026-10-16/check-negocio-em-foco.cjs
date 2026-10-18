const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
process.env.PLAYWRIGHT_BROWSERS_PATH||='C:/Users/jardi/AppData/Local/ms-playwright';
const {chromium,webkit}=require(process.env.PLAYWRIGHT_MODULE||'C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base=process.env.PREVIEW_DIR||__dirname,file='negocio-em-foco-zm';
const source=fs.readFileSync(path.join(base,file+'.html'),'utf8').match(/<script>([\s\S]*?)<\/script>/)[1];new vm.Script(source);
async function run(engine){
 const browser=engine==='edge'?await chromium.launch({channel:'msedge',headless:true}):await webkit.launch({headless:true});
 try{
  const page=await browser.newPage({viewport:{width:1024,height:2200},locale:'pt-BR',reducedMotion:'no-preference',colorScheme:'light'}),errors=[],checks=[],layouts=[];
  page.on('pageerror',error=>errors.push(error.message));
  await page.goto('file:///'+path.join(base,file+'-preview.html').replaceAll('\\','/'));
  const frame=page.frames().find(f=>f.parentFrame()),mobile=frame.locator('[data-device=mobile]');
  await mobile.locator('[data-action=financial]').first().waitFor();
  const clean=text=>text.replaceAll('\u00a0',' ');
  const txt=async loc=>clean(await loc.innerText());
  const show=device=>frame.evaluate(device=>document.querySelectorAll('.viz-carousel>section').forEach(s=>s.hidden=!s.querySelector(`[data-device=${device}]`)),device);
  const idle=()=>frame.evaluate(()=>Promise.all(document.getAnimations().map(a=>a.finished.catch(()=>{}))));
  const nav=async(area,app=mobile)=>{await app.locator(`.nav [data-area=${area}]`).click();await idle();};
  assert.match(await txt(mobile),/480,00/);assert.match(await txt(mobile),/240,00/);assert.match(await txt(mobile),/3 produtos/);
  assert.match(await txt(mobile),/Seu financeiro agora/);assert.match(await txt(mobile),/A receber/);assert.match(await txt(mobile),/Seu negócio hoje/);assert.match(await txt(mobile),/Cestas vendidas/);
  await idle();await mobile.screenshot({path:path.join(base,`foco-${engine}-inicio-celular.png`)});
  await mobile.locator('[data-action=sales-today]').first().click();await idle();assert.match(await txt(mobile),/860,00/);assert.match(await txt(mobile),/8 cestas/);await mobile.locator('.back').click();await idle();
  await mobile.locator('[data-action=financial][data-filter=today]').click();await idle();
  assert.match(await txt(mobile),/Vencem hoje/);assert.match(await txt(mobile),/480,00/);
  await mobile.locator('.mobile-list [data-id=alimentos]').click();await idle();
  assert.match(await txt(mobile),/680,00/);assert.match(await txt(mobile),/200,00/);
  await mobile.locator('.back').click();await idle();assert.equal(await mobile.locator('[data-action=filter][data-filter=today]').getAttribute('aria-pressed'),'true');
  await mobile.locator('.mobile-list [data-id=alimentos]').click();await idle();
  await mobile.locator('[data-action=form]').click();await idle();
  assert.equal(await mobile.locator('[data-field=amount]').isDisabled(),true);
  assert.equal(await mobile.locator('[data-field=date]').evaluate(e=>getComputedStyle(e).borderRadius),'24px');
  assert.deepEqual(await mobile.locator('[data-field=date]').evaluate(e=>({height:parseFloat(getComputedStyle(e).minHeight),border:getComputedStyle(e).borderTopWidth})),{height:56,border:'1px'});
  assert.equal(await mobile.locator('.panel.flow').evaluate(e=>getComputedStyle(e).gap),'20px');
  await page.setViewportSize({width:390,height:2200});await idle();await mobile.screenshot({path:path.join(base,`foco-${engine}-pagamento-celular.png`)});
  await mobile.getByRole('radio',{name:'Parcial',exact:true}).check();await idle();
  await mobile.locator('[data-field=amount]').fill('120');assert.match(await txt(mobile.locator('[data-remaining]')),/360,00/);
  await mobile.getByRole('radio',{name:'Integral',exact:true}).check();await idle();assert.match(await txt(mobile.locator('[data-remaining]')),/0,00/);
  await mobile.getByRole('radio',{name:'Parcial',exact:true}).check();await idle();assert.equal(await mobile.locator('[data-field=amount]').inputValue(),'120');
  const motion=await mobile.evaluate(app=>{app.querySelector('[data-action=calendar]').click();const d=app.querySelector('dialog');return {open:d.open,animations:d.getAnimations().map(a=>({duration:a.effect.getTiming().duration,frames:a.effect.getKeyframes()})),focused:document.activeElement?.dataset.date};});
  assert.equal(motion.open,true);assert.equal(motion.focused,'2026-10-16');assert.ok(motion.animations.some(a=>a.duration===240&&a.frames[0].opacity==='0'));
  await page.setViewportSize({width:320,height:2200});await idle();const calendarBox=await mobile.locator('dialog').boundingBox();assert.ok(calendarBox.x>=0&&calendarBox.x+calendarBox.width<=320);await mobile.locator('dialog').screenshot({path:path.join(base,`foco-${engine}-calendario-320.png`)});
  await mobile.locator('[data-date="2026-10-17"]').click();await frame.waitForFunction(()=>document.querySelector('[data-device=mobile] [data-action=calendar]').getAttribute('aria-expanded')==='false');
  await page.setViewportSize({width:1024,height:2200});
  assert.equal(await mobile.locator('[data-action=calendar]').evaluate(e=>e===document.activeElement),true);
  await mobile.locator('[data-action=review]').click();assert.equal(await mobile.locator('[data-field=method]').getAttribute('aria-invalid'),'true');
  await mobile.locator('[data-field=method]').selectOption('PIX');await mobile.locator('[data-field=notes]').fill('Conferência da prévia');
  await mobile.locator('[data-action=review]').click();await idle();assert.match(await txt(mobile),/360,00/);
  await mobile.locator('[data-action=edit]').click();await idle();assert.equal(await mobile.locator('[data-field=notes]').inputValue(),'Conferência da prévia');assert.equal(await mobile.locator('[data-field=method]').inputValue(),'PIX');
  await mobile.locator('[data-action=review]').click();await idle();await mobile.locator('[data-action=confirm]').click();
  await mobile.getByRole('heading',{name:'Registro confirmado',exact:true}).waitFor();await idle();assert.match(await txt(mobile),/120,00/);assert.match(await txt(mobile),/360,00/);
  await mobile.locator('[data-action=return-list]').click();await idle();assert.equal(await mobile.locator('[data-action=filter][data-filter=today]').getAttribute('aria-pressed'),'true');assert.match(await txt(mobile),/360,00/);
  checks.push('Jornada conectada de pagamento parcial; integral exclui valor oculto; calendário animado; validação; editar preserva rascunho; saldo e recorte atualizados');
  await nav('inicio');assert.match(await txt(mobile.locator('[data-filter=today]')),/360,00/);
  await mobile.locator('[data-action=financial][data-filter=next]').click();await idle();assert.match(await txt(mobile),/240,00/);assert.match(await txt(mobile),/17 a 19/);assert.doesNotMatch(await txt(mobile),/Materiais de limpeza/);
  await nav('inicio');await mobile.locator('[data-action=stock]').click();await idle();assert.equal(await mobile.locator('[data-action=stock-filter][data-value=low]').getAttribute('aria-pressed'),'true');assert.match(await txt(mobile),/3 produtos/);assert.doesNotMatch(await txt(mobile),/Açúcar/);
  await mobile.locator('[data-action=stock-filter][data-value=all]').click();await idle();assert.match(await txt(mobile),/Açúcar/);
  await nav('inicio');await mobile.locator('[data-action=explanation]').click();await idle();assert.match(await txt(mobile),/2 vendas/);assert.match(await txt(mobile),/não representa saldo bancário/);assert.equal(await mobile.getByRole('button',{name:/Corrigir/}).count(),0);
  checks.push('Três informações úteis levam ao recorte/detalhe ou explicação coerentes; horizonte inclui 17–19/10 e exclui 20/10');
  await nav('mais');await mobile.locator('[data-pref=appearance]').selectOption('dark');await mobile.locator('[data-pref=background]').selectOption('pure');await idle();
  await nav('inicio');await mobile.screenshot({path:path.join(base,`foco-${engine}-inicio-escuro.png`)});
  await nav('financeiro');await mobile.locator('[data-action=all-pay]').click();await idle();
  await show('desktop');const desktop=frame.locator('[data-device=desktop]');await idle();await desktop.screenshot({path:path.join(base,`foco-${engine}-inicio-windows.png`)});
  await desktop.locator('[data-action=financial][data-filter=today]').click();await idle();assert.match(await txt(desktop),/360,00/);
  await desktop.locator('.table [data-id=alimentos]').click();await idle();assert.match(await txt(desktop),/320,00/);
  checks.push('Pagamento simulado compartilhado entre composições; navegação e tabelas Windows; claro/escuro e preferências locais');
  await show('mobile');await nav('mais');await mobile.locator('[data-pref=appearance]').selectOption('light');await mobile.locator('[data-pref=background]').selectOption('soft');
  const helper=fs.readFileSync(process.env.TWEAK_HELPER_PATH||'C:/Users/jardi/.codex/plugins/cache/openai-bundled/visualize/1.0.50/assets/tweak.js','utf8');
  await frame.evaluate(({helper,source})=>{const old=document.querySelector('.viz-carousel'),clone=old.cloneNode(true);clone.querySelectorAll('.product').forEach(e=>e.innerHTML='');old.replaceWith(clone);window.__regs={};window.__saved=[];window.__changes=new Map();window.openai={...window.openai,widgetState:null,callTool(name,msg){if(name!=='__codex_visualization_annotations__')throw new Error('Unexpected test tool');if(['register','update'].includes(msg.type)){window.__regs[msg.registrationId]=JSON.parse(JSON.stringify(msg));return Promise.resolve({annotationControls:msg.annotationControls});}return Promise.resolve({});},setWidgetState(s){window.__saved.push(JSON.parse(JSON.stringify(s)));return Promise.resolve();}};(0,eval)(helper);(0,eval)(source);},{helper,source});
  await frame.waitForFunction(()=>Object.values(window.__regs).some(r=>r.annotationControls.controls.length===4));
  const edit=(label,value)=>frame.evaluate(({label,value})=>{const [registrationId,reg]=Object.entries(window.__regs).find(([,r])=>r.annotationControls.controls.length===4),control=reg.annotationControls.controls.find(c=>c.label===label||c.label.startsWith(label+' ('));if(!control)throw new Error('Missing control: '+label);window.__changes.set(control.callback,{callback:control.callback,previousValue:control.currentValue,value});window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:window.__saved.at(-1)||null,visualizationAnnotation:{active:false,changes:[{registrationId,targetId:reg.targets[0].id,annotationControlChanges:[...window.__changes.values()]}]}}}}));},{label,value});
  await edit('Movimento','reduced');assert.equal(await mobile.getAttribute('data-motion'),'false');await edit('Movimento','standard');
  await page.emulateMedia({reducedMotion:'reduce'});await frame.waitForFunction(()=>document.querySelector('[data-device=mobile]').dataset.motion==='false');
  await mobile.locator('[data-action=financial][data-filter=today]').click();await mobile.locator('.mobile-list [data-id=alimentos]').click();await mobile.locator('[data-action=form]').click();
  const count=await mobile.evaluate(app=>{app.querySelector('[data-action=calendar]').click();return app.querySelector('dialog').getAnimations().length;});assert.equal(count,0);
  await mobile.locator('[data-action=calendar-close]').last().click();await page.emulateMedia({reducedMotion:'no-preference'});await frame.waitForFunction(()=>document.querySelector('[data-device=mobile]').dataset.motion==='true');
  for(const device of ['mobile','desktop'])for(const width of [320,390,768,1024])for(const scale of [100,200]){
   await show(device);await page.setViewportSize({width,height:1200});await edit('Tamanho do texto',scale);await idle();
   const layout=await frame.locator(`[data-device=${device}]`).evaluate(app=>{const rect=app.getBoundingClientRect();return {width:rect.width,scroll:app.scrollWidth,client:app.clientWidth,body:document.documentElement.scrollWidth,viewport:innerWidth};});
   assert.ok(layout.scroll<=layout.client+1&&layout.body<=layout.viewport+1,JSON.stringify({engine,device,width,scale,layout}));layouts.push({device,width,scale,...layout});
  }
  for(const [device,width] of [['mobile',320],['desktop',1024]]){
   await show(device);await page.setViewportSize({width,height:1200});const app=frame.locator(`[data-device=${device}]`);await nav('inicio',app);
   for(const scale of [100,200]){await edit('Tamanho do texto',scale);await idle();const layout=await app.evaluate(app=>({width:app.getBoundingClientRect().width,scroll:app.scrollWidth,client:app.clientWidth,body:document.documentElement.scrollWidth,viewport:innerWidth}));assert.ok(layout.scroll<=layout.client+1&&layout.body<=layout.viewport+1,JSON.stringify({engine,device,width,scale,layout}));layouts.push({page:'home',device,width,scale,...layout});}
  }
  checks.push('Helper de ajustes original com provedor simulado; redução do sistema prevalece; 20 combinações de página/dispositivo/largura/texto sem transbordamento por motor');
  assert.deepEqual(errors,[]);
  return {engine,result:'passed',checks,layouts,calendar:motion,javascriptErrors:errors,limits:'Browser tests on Windows; actual host controls UI and iPhone/Android not tested. All business data/operations are local fixtures.'};
 }finally{await browser.close();}
}
(async()=>{const results=[];for(const engine of ['edge','webkit'])results.push(await run(engine));fs.writeFileSync(path.join(base,'negocio-em-foco-verificacao.json'),JSON.stringify({date:'2026-10-16',results},null,2)+'\n');console.log(JSON.stringify(results.map(r=>({engine:r.engine,result:r.result,checks:r.checks.length,layouts:r.layouts.length}))));})().catch(e=>{console.error(e);process.exitCode=1;});
