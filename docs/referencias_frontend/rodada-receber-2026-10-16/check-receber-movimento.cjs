const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
process.env.PLAYWRIGHT_BROWSERS_PATH||='C:/Users/jardi/AppData/Local/ms-playwright';
const {chromium,webkit}=require(process.env.PLAYWRIGHT_MODULE||'C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base=process.env.PREVIEW_DIR||__dirname;
const html=fs.readFileSync(path.join(base,'receber-e-movimento-zm.html'),'utf8'),source=html.match(/<script>([\s\S]*?)<\/script>/)[1];new vm.Script(source);
const clean=value=>value.replaceAll('\u00a0',' ');

async function run(engine){
 const browser=engine==='edge'?await chromium.launch({channel:'msedge',headless:true}):await webkit.launch({headless:true});
 try{
  const page=await browser.newPage({viewport:{width:390,height:1800},locale:'pt-BR',colorScheme:'light',reducedMotion:'no-preference',isMobile:true,hasTouch:true}),errors=[],groups=[],layouts=[];
  page.on('pageerror',error=>errors.push(error.message));
  await page.goto('file:///'+path.join(base,'receber-e-movimento-zm-preview.html').replaceAll('\\','/'));
  const frame=page.frames().find(f=>f.parentFrame());await frame.locator('[data-device=mobile] [data-total]').waitFor();
  await frame.evaluate(code=>{
   document.querySelectorAll('.app').forEach(app=>app.replaceWith(app.cloneNode(false)));
   window.__bindings=[];window.__snapshots=[];window.__motion=[];
   const animate=Element.prototype.animate;Element.prototype.animate=function(frames,options){window.__motion.push({duration:options.duration,frames});return animate.call(this,frames,options);};
   window.openai={...window.openai,widgetState:null,setWidgetState(state){window.__snapshots.push(state);return Promise.resolve();}};
   globalThis.Tweak=class{constructor(options){Object.assign(this,options);this.controls=[];window.__bindings.push(this);}addSelect(object,property,options){this.controls.push({object,property,options});}addSlider(object,property,options){this.controls.push({object,property,options});}};
   (0,eval)(code);
  },source);
  const app=device=>frame.locator(`[data-device="${device}"]`);
  const show=device=>frame.evaluate(device=>{for(const section of document.querySelectorAll('.viz-carousel > section'))section.hidden=!section.querySelector(`[data-device="${device}"]`);},device);
  const tweak=(device,property,value)=>frame.evaluate(({device,property,value})=>{const b=window.__bindings.find(b=>b.container.dataset.device===device),c=b.controls.find(c=>c.property===property);c.object[property]=value;b.onChange();},{device,property,value});
  const idle=()=>frame.evaluate(()=>Promise.all(document.getAnimations().map(a=>a.finished.catch(()=>{}))));
  const reset=async device=>{await show(device);await app(device).getByRole('button',{name:'Recomeçar exemplo',exact:true}).click();await idle();};
  const openAna=async device=>{await app(device).locator('[data-go="financeiro:conta-ana"]').first().click();await idle();};
  const register=async device=>{await app(device).getByRole('button',{name:'Registrar recebimento',exact:true}).click();await idle();};
  const review=async device=>{await app(device).getByRole('button',{name:'Revisar recebimento',exact:true}).click();await app(device).getByRole('heading',{name:'Conferir recebimento',exact:true}).waitFor();await idle();};
  const confirm=async device=>{await app(device).locator('[data-action=confirm]').evaluate(button=>{button.click();button.click();});await app(device).getByRole('heading',{name:'Recebimento registrado',level:2,exact:true}).waitFor();await idle();};
  assert.equal(await frame.evaluate(()=>window.__motion.length),0,'sem animacao de entrada inicial');
  await show('mobile');
  await app('mobile').locator('[data-area=inicio]').click();await idle();
  assert.deepEqual((await app('mobile').locator('.hero.finance .amount').allTextContents()).map(clean),['R$ 1.280,00','R$ 300,00']);
  await app('mobile').locator('[data-go="financeiro:pagar"]').click();await idle();
  assert.equal(await app('mobile').getByRole('heading',{name:'Contas a Pagar',exact:true}).count(),1);
  await reset('mobile');assert.equal(clean(await app('mobile').locator('[data-total]').innerText()),'R$ 300,00');
  await app('mobile').screenshot({path:path.join(base,`receber-${engine}-lista.png`)});
  await openAna('mobile');assert.equal(clean(await app('mobile').locator('[data-balance]').innerText()),'R$ 100,00');
  assert.match(clean(await app('mobile').locator('.summary-pair').innerText()),/R\$ 150,00[\s\S]*R\$ 50,00/);
  assert.equal(await app('mobile').locator('.history-entry').count(),2);
  await app('mobile').screenshot({path:path.join(base,`receber-${engine}-detalhe.png`)});
  await app('mobile').locator('[data-action=view-sale]').click();await idle();
  assert.equal(await app('mobile').getByRole('heading',{name:'Venda #1042',exact:true}).count(),1);
  assert.equal(clean(await app('mobile').locator('.detail-amount').innerText()),'R$ 150,00');
  await app('mobile').locator('[data-action=view-account]').click();await idle();await register('mobile');
  assert.equal(await app('mobile').getByRole('radio',{name:'Integral',exact:true}).isChecked(),true);
  assert.equal(await app('mobile').locator('[data-field=amount]').isDisabled(),true);
  assert.match(clean(await app('mobile').locator('[data-mode-caption]').innerText()),/R\$ 100,00/);
  groups.push('Origem na venda #1042; original 150, recebido 50 e integral do saldo atual 100');

  const durations=await frame.evaluate(()=>window.__motion.map(m=>m.duration));assert.ok(durations.includes(220));
  await app('mobile').getByRole('radio',{name:'Parcial',exact:true}).check();
  const transition=await app('mobile').locator('.partial-reveal').evaluate(el=>getComputedStyle(el).transitionDuration);assert.notEqual(transition,'0s');
  await app('mobile').getByRole('textbox',{name:'Quanto você recebeu?',exact:true}).fill('999');
  await app('mobile').getByRole('radio',{name:'Integral',exact:true}).check();
  await app('mobile').locator('[data-action=open-date]').click();await idle();
  assert.ok((await frame.evaluate(()=>window.__motion.map(m=>m.duration))).includes(180));
  await app('mobile').getByRole('button',{name:'15 de outubro de 2026',exact:true}).click();
  await app('mobile').locator('.date-dialog').waitFor({state:'hidden'});
  await app('mobile').getByLabel('Como você recebeu?',{exact:true}).selectOption('PIX');await idle();
  await app('mobile').screenshot({path:path.join(base,`receber-${engine}-integral.png`)});
  await review('mobile');assert.match(clean(await app('mobile').locator('.review-list').innerText()),/R\$ 100,00/);
  assert.match(await app('mobile').locator('.review-list').innerText(),/15 de outubro de 2026/);
  await confirm('mobile');
  await app('mobile').screenshot({path:path.join(base,`receber-${engine}-conclusao.png`)});
  await app('mobile').locator('[data-action=view-account]').click();await idle();
  assert.equal(await app('mobile').locator('.history-entry').count(),3);
  assert.equal(clean(await app('mobile').locator('[data-balance]').innerText()),'R$ 0,00');
  await app('mobile').locator('[data-action=view-sale]').click();await idle();assert.equal(clean(await app('mobile').locator('.detail-amount').innerText()),'R$ 150,00');
  await app('mobile').getByRole('button',{name:'Voltar',exact:true}).click();await idle();
  await app('mobile').getByRole('button',{name:'Voltar',exact:true}).click();await idle();
  assert.equal(clean(await app('mobile').locator('[data-total]').innerText()),'R$ 200,00');
  await app('mobile').locator('[data-filter]').selectOption('paid');assert.equal(await app('mobile').locator('[data-go="financeiro:conta-ana"]').count(),1);
  groups.push('Movimento de pagina 220 ms, calendario 180 ms; integral ignora parcial oculto, uma confirmacao, saldo e venda preservados');

  await reset('mobile');await openAna('mobile');await register('mobile');
  await app('mobile').getByRole('radio',{name:'Parcial',exact:true}).check();
  await app('mobile').getByRole('textbox',{name:'Quanto você recebeu?',exact:true}).fill('40');
  await app('mobile').getByLabel('Como você recebeu?',{exact:true}).selectOption('CASH');await idle();
  await app('mobile').screenshot({path:path.join(base,`receber-${engine}-parcial.png`)});
  await review('mobile');await confirm('mobile');await app('mobile').locator('[data-action=list]').click();await idle();
  assert.equal(clean(await app('mobile').locator('[data-total]').innerText()),'R$ 260,00');
  await app('mobile').locator('[data-filter]').selectOption('partial');assert.equal(clean(await app('mobile').locator('[data-total]').innerText()),'R$ 60,00');
  await openAna('mobile');await register('mobile');assert.equal(await app('mobile').getByRole('radio',{name:'Integral',exact:true}).isChecked(),true);
  assert.match(clean(await app('mobile').locator('[data-mode-caption]').innerText()),/R\$ 60,00/);
  groups.push('Parcial de 40 deixa 60, permanece em aberto; proximo integral usa o novo saldo');

  await reset('mobile');await tweak('mobile','motion','reduced');
  let before=await frame.evaluate(()=>window.__motion.length);await openAna('mobile');await register('mobile');
  assert.equal(await frame.evaluate(()=>window.__motion.length),before);
  await app('mobile').getByRole('radio',{name:'Parcial',exact:true}).check();
  assert.equal(await app('mobile').locator('.partial-reveal').evaluate(el=>getComputedStyle(el).transitionDuration),'0s');
  await page.emulateMedia({reducedMotion:'reduce'});
  await frame.waitForFunction(()=>window.matchMedia('(prefers-reduced-motion:reduce)').matches);
  await tweak('mobile','motion','standard');
  await frame.waitForFunction(()=>document.querySelector('[data-device=mobile]').dataset.motion==='false');
  assert.equal(await app('mobile').getAttribute('data-motion'),'false');
  await app('mobile').locator('[data-action=open-date]').click();assert.equal(await frame.evaluate(()=>window.__motion.length),before);
  await app('mobile').getByRole('button',{name:'Cancelar',exact:true}).click();
  await page.emulateMedia({reducedMotion:'no-preference'});await frame.waitForFunction(()=>document.querySelector('[data-device=mobile]').dataset.motion==='true');
  groups.push('Reducao por controle e por sistema; sem animacoes opcionais, com os mesmos dados e acoes');

  await reset('mobile');await tweak('mobile','scenario','failure');await openAna('mobile');await register('mobile');
  await app('mobile').getByLabel('Como você recebeu?',{exact:true}).selectOption('PIX');await review('mobile');
  await app('mobile').locator('[data-action=confirm]').click();await app('mobile').getByRole('heading',{name:'Não foi possível registrar',exact:true}).waitFor();await idle();
  assert.match(clean(await app('mobile').locator('.review-list').innerText()),/R\$ 100,00/);
  await app('mobile').screenshot({path:path.join(base,`receber-${engine}-falha.png`)});
  await confirm('mobile');groups.push('Falha conhecida preserva dados; repeticao conclui sem recebimento duplicado');

  const restored=await frame.evaluate(()=>{const saved=window.__snapshots.at(-1);window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:saved}}}));const binding=window.__bindings.find(b=>b.container.dataset.device==='mobile'),control=binding.controls.find(c=>c.property==='radius');control.object.radius=40;binding.onChange();return {radius:getComputedStyle(binding.container).getPropertyValue('--radius'),size:JSON.stringify(saved).length};});
  assert.equal(restored.radius,'40px');assert.ok(restored.size<16384);groups.push('Estado restaurado sem desconectar ajustes de forma e movimento');

  for(const device of ['mobile','desktop']){
   await reset(device);await tweak(device,'scenario','normal');await tweak(device,'motion','reduced');
   for(const width of [320,360,390,780])for(const theme of ['light','dark']){
    await page.setViewportSize({width,height:1800});await tweak(device,'appearance',theme);
    const measured=await frame.evaluate(device=>{const app=document.querySelector(`[data-device="${device}"]`),r=app.getBoundingClientRect();return {viewport:innerWidth,width:r.width,overflow:document.documentElement.scrollWidth>innerWidth+1};},device);
    assert.equal(measured.overflow,false);layouts.push({device,width,theme,...measured});
   }
   await page.setViewportSize({width:device==='mobile'?390:780,height:1800});await tweak(device,'appearance','light');
   if(device==='desktop'){assert.equal(await app(device).locator('tbody tr').count(),2);await app(device).screenshot({path:path.join(base,`receber-${engine}-windows.png`)});}
  }
  assert.deepEqual(errors,[]);groups.push('Lista mobile e tabela Windows em quatro larguras e dois temas');
  return {engine,groups,layouts,motionDurations:durations,javascriptErrors:errors};
 }finally{await browser.close();}
}
(async()=>{const engines=[];for(const engine of ['edge','webkit'])engines.push(await run(engine));const report={date:'2026-10-16',result:'passed',scope:'Previa de Receber e movimento; sem Flutter/API/dados reais',layoutCases:engines.reduce((n,e)=>n+e.layouts.length,0),engines,limits:['Motores locais Windows, sem aparelho iOS/Android nem leitor de tela.','Tweak e persistencia instrumentados; painel nativo e restauracao real do hospedeiro nao automatizados.','Duracoes observadas nao medem fluidez nem taxa de quadros do Flutter.','Retorno desconhecido ao salvar, estornos e horario/fuso da futura API continuam pendentes.']};fs.writeFileSync(path.join(base,'receber-movimento-verificacao.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({result:report.result,layoutCases:report.layoutCases,engines:engines.map(e=>({engine:e.engine,groups:e.groups.length,javascriptErrors:e.javascriptErrors}))}));})().catch(error=>{console.error(error);process.exitCode=1;});
