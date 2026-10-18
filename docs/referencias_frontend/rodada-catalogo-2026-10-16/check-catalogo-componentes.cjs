const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
process.env.PLAYWRIGHT_BROWSERS_PATH||='C:/Users/jardi/AppData/Local/ms-playwright';
const {chromium,webkit}=require(process.env.PLAYWRIGHT_MODULE||'C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base=process.env.PREVIEW_DIR||__dirname;
const source=fs.readFileSync(path.join(base,'catalogo-componentes-zm.html'),'utf8').match(/<script>([\s\S]*?)<\/script>/)[1];new vm.Script(source);
const clean=value=>value.replaceAll('\u00a0',' ');

async function run(engine){
 const browser=engine==='edge'?await chromium.launch({channel:'msedge',headless:true}):await webkit.launch({headless:true});
 try {
  const page=await browser.newPage({viewport:{width:390,height:1800},locale:'pt-BR',colorScheme:'light',reducedMotion:'no-preference',isMobile:true,hasTouch:true}),errors=[],groups=[],layouts=[];
  page.on('pageerror',error=>errors.push(error.message));
  await page.goto('file:///'+path.join(base,'catalogo-componentes-zm-preview.html').replaceAll('\\','/'));
  const frame=page.frames().find(f=>f.parentFrame());await frame.locator('[data-example=fields] [data-field=date]').waitFor();
  await frame.evaluate(code=>{
   document.querySelectorAll('.specimen').forEach(app=>{const clone=app.cloneNode(true);clone.querySelector('.product-content').innerHTML='';app.replaceWith(clone);});
   window.__bindings=[];window.__snapshots=[];window.__motion=[];
   const animate=Element.prototype.animate;Element.prototype.animate=function(frames,options){window.__motion.push({duration:options.duration,frames});return animate.call(this,frames,options);};
   window.openai={...window.openai,widgetState:null,setWidgetState(state){window.__snapshots.push(state);return Promise.resolve();}};
   globalThis.Tweak=class {constructor(options){Object.assign(this,options);this.controls=[];window.__bindings.push(this);}addSelect(object,property,options){this.controls.push({object,property,options});}};
   (0,eval)(code);
  },source);
  const app=example=>frame.locator(`[data-example=${example}]`);
  const show=example=>frame.evaluate(example=>{document.querySelectorAll('.viz-carousel > section').forEach(section=>section.hidden=!section.querySelector(`[data-example=${example}]`));},example);
  const tweak=(example,property,value)=>frame.evaluate(({example,property,value})=>{const b=window.__bindings.find(b=>b.container.dataset.example===example),c=b.controls.find(c=>c.property===property);c.object[property]=value;b.onChange();},{example,property,value});
  const idle=()=>frame.evaluate(()=>Promise.all(document.getAnimations().map(a=>a.finished.catch(()=>{}))));
  const shot=(example,name)=>app(example).screenshot({path:path.join(base,`catalogo-${engine}-${name}.png`)});
  assert.equal(await frame.evaluate(()=>window.__motion.length),0);
  const fields=app('fields');
  assert.equal(await fields.getByRole('radio',{name:'Integral',exact:true}).isChecked(),true);
  assert.equal(await fields.locator('[data-field=amount]').isDisabled(),true);
  assert.equal(clean(await fields.locator('[data-remaining]').innerText()),'R$ 0,00');
  await shot('fields','integral');
  await fields.getByRole('radio',{name:'Parcial',exact:true}).check();await idle();
  await fields.locator('[data-field=amount]').fill('40');
  assert.equal(clean(await fields.locator('[data-remaining]').innerText()),'R$ 60,00');
  await fields.locator('[data-field=method]').selectOption('PIX');await shot('fields','parcial');
  await fields.locator('[data-action=review]').click();await idle();
  assert.match(clean(await fields.locator('.review-list').innerText()),/R\$ 40,00[\s\S]*R\$ 60,00/);
  await fields.locator('[data-action=edit]').click();await idle();
  await fields.locator('[data-field=amount]').fill('999');
  await fields.getByRole('radio',{name:'Integral',exact:true}).check();await idle();
  assert.equal(await fields.locator('[data-field=amount]').isDisabled(),true);
  assert.equal(await fields.locator('.partial-reveal').getAttribute('inert'),'');
  await fields.locator('[data-action=review]').click();await idle();
  assert.match(clean(await fields.locator('.review-list').innerText()),/R\$ 100,00[\s\S]*R\$ 0,00/);
  groups.push('Integral do saldo atual; parcial 40 deixa 60; valor parcial invalido oculto nao participa da revisao');

  await fields.locator('[data-action=edit]').click();await fields.getByRole('radio',{name:'Parcial',exact:true}).check();await idle();
  await fields.locator('[data-field=method]').selectOption('');await fields.locator('[data-action=review]').click();
  assert.equal(await fields.locator('[aria-invalid=true]').count(),2);
  assert.equal(await fields.locator('[data-field=amount]').evaluate(el=>el===document.activeElement),true);
  await fields.locator('[data-focus=method]').click();assert.equal(await fields.locator('[data-field=method]').evaluate(el=>el===document.activeElement),true);
  await shot('fields','erros');
  await fields.locator('[data-field=amount]').fill('40,00');await fields.locator('[data-field=method]').selectOption('PIX');
  assert.equal(await fields.locator('[aria-invalid=true]').count(),0);
  groups.push('Validacao associada aos campos, foco no primeiro erro e correcao sem perder os dados');

  await fields.locator('[data-action=calendar]').click();await idle();
  await fields.locator('[data-calendar-date="2026-10-16"]').press('ArrowRight');
  assert.equal(await fields.locator('[data-calendar-date="2026-10-17"]').evaluate(el=>el===document.activeElement),true);
  await fields.locator('[data-calendar-date="2026-10-17"]').click();
  await frame.waitForFunction(()=>document.querySelector('[data-field=date]').getAttribute('aria-expanded')==='false');
  assert.equal(await fields.locator('[data-field=date]').evaluate(el=>el===document.activeElement),true);
  assert.match(await fields.locator('.date-value').innerText(),/17 de outubro/);
  await fields.locator('[data-action=calendar]').click();await fields.locator('[data-calendar-date="2026-10-17"]').press('Escape');
  await frame.waitForFunction(()=>!document.querySelector('.date-dialog').open);
  groups.push('Calendario com botoes reais, selecao por teclado, Escape e retorno de foco');

  await tweak('fields','context','pay');
  assert.equal(clean(await fields.locator('.balance strong').first().innerText()),'R$ 680,00');
  assert.ok((await fields.locator('[data-field=method] option').evaluateAll(options=>options.map(o=>o.value))).includes('DINHEIRO'));
  await fields.locator('[data-field=method]').selectOption('CHEQUE');
  await tweak('fields','context','receive');
  assert.equal(await fields.locator('[data-field=method]').inputValue(),'');
  assert.deepEqual(await fields.locator('[data-field=method] option').evaluateAll(options=>options.map(o=>o.value)),['','PIX','CASH','CARD','OTHER']);
  groups.push('Reuso de apresentacao Pagar/Receber com opcoes e codigos de forma preservados por dominio');

  await show('actions');const actions=app('actions');
  await actions.locator('[data-action=confirm]').evaluate(button=>{button.click();button.click();});
  assert.equal(await actions.locator('[data-action=confirm]').isDisabled(),true);
  assert.match(await actions.locator('[data-operation-status]').innerText(),/Aguarde/);
  await actions.getByRole('heading',{name:'Recebimento registrado',exact:true}).waitFor();await idle();
  assert.match(clean(await actions.locator('.review-list').innerText()),/R\$ 0,00/);await shot('actions','sucesso');
  await tweak('actions','response','failure');await actions.locator('[data-action=confirm]').click();
  await actions.getByRole('heading',{name:'Recebimento não registrado',exact:true}).waitFor();await idle();
  assert.match(clean(await actions.locator('.review-list').innerText()),/R\$ 100,00/);await shot('actions','recusa');
  await actions.getByRole('button',{name:'Tentar novamente',exact:true}).click();
  await actions.getByRole('heading',{name:'Recebimento registrado',exact:true}).waitFor();
  await tweak('actions','response','unknown');await actions.locator('[data-action=confirm]').click();
  await actions.getByRole('heading',{name:'Aguardando confirmação',exact:true}).waitFor();await idle();
  assert.equal(await actions.locator('[data-action=confirm]').count(),0);
  assert.equal(await actions.getByRole('button',{name:'Verificar registro',exact:true}).count(),1);
  assert.match(await actions.locator('[data-operation-status]').innerText(),/ainda não foi atualizado/);
  await shot('actions','sem-confirmacao');
  await actions.locator('[data-action=verify]').evaluate(button=>{button.click();button.click();});
  await actions.getByRole('heading',{name:'Recebimento registrado',exact:true}).waitFor();
  groups.push('Envio unico enquanto ocupado; sucesso, recusa conhecida e resultado desconhecido com verificacao simulada sem novo envio');

  await show('query');const query=app('query');
  assert.equal(clean(await query.locator('[data-query-total]').innerText()),'R$ 300,00');
  await query.locator('[data-action=list]').click();
  assert.equal(await query.locator('.rows .row').count(),2);
  assert.match(await query.locator('.rows').innerText(),/Parcial · Vencida/);
  await query.locator('.rows [data-record=ana]').click();
  assert.match(clean(await query.locator('.review-list').innerText()),/Venda #1042[\s\S]*R\$ 100,00/);
  await query.locator('[data-action=list]').click();
  await tweak('query','query','empty');assert.equal(await query.locator('[data-query-total]').count(),0);
  assert.equal(await query.getByRole('button',{name:'Ver todos os vencimentos',exact:true}).count(),1);
  await query.locator('[data-action=all-dates]').click();assert.equal(clean(await query.locator('[data-query-total]').innerText()),'R$ 80,00');
  await query.locator('[data-action=list]').click();assert.match(await query.innerText(),/Carla Martins[\s\S]*21 out/);assert.match(await query.innerText(),/Todos os vencimentos/);
  await query.locator('.rows [data-record=carla]').click();assert.match(await query.locator('.review-list').innerText(),/21 de outubro de 2026/);await query.locator('[data-action=list]').click();
  await tweak('query','query','unavailable');assert.equal((await query.innerText()).includes('R$ 0,00'),false);await shot('query','indisponivel');
  await query.locator('[data-action=retry-query]').click();await query.locator('[data-query-total]').waitFor();
  await tweak('query','query','loading');assert.equal(await query.locator('[aria-busy=true]').count(),1);assert.equal(await query.locator('[data-query-total]').count(),0);
  await tweak('query','query','stale');assert.match(await query.innerText(),/Última consulta: 16 out., às 09:41/);assert.equal(await query.locator('[data-record]').count(),0);await shot('query','ultima-consulta');
  await tweak('query','query','loaded');await query.locator('[data-action=list]').click();
  await page.setViewportSize({width:780,height:1800});assert.equal(await query.locator('.table-wrap').isVisible(),true);await shot('query','tabela');
  groups.push('Resumo 300 corresponde aos dois registros; parcial vencida; vazio, indisponivel, carregando e ultima consulta distintos');

  await show('fields');await page.setViewportSize({width:390,height:1800});
  await tweak('fields','motion','reduced');await fields.locator('[data-action=calendar]').click();await idle();await fields.locator('[data-calendar-action=close]').last().click();
  const before=await frame.evaluate(()=>window.__motion.length);
  await fields.getByRole('radio',{name:'Parcial',exact:true}).check();
  assert.equal(await fields.locator('.partial-reveal').evaluate(el=>getComputedStyle(el).transitionDuration),'0s');
  await fields.locator('[data-action=calendar]').click();assert.equal(await frame.evaluate(()=>window.__motion.length),before);await fields.locator('[data-calendar-action=close]').last().click();
  await page.emulateMedia({reducedMotion:'reduce'});await frame.waitForFunction(()=>matchMedia('(prefers-reduced-motion:reduce)').matches);
  await tweak('fields','motion','standard');await frame.waitForFunction(()=>document.querySelector('[data-example=fields]').dataset.motion==='false');
  await page.emulateMedia({reducedMotion:'no-preference'});await frame.waitForFunction(()=>document.querySelector('[data-example=fields]').dataset.motion==='true');
  const restored=await frame.evaluate(()=>{const saved=window.__snapshots.at(-1),b=window.__bindings.find(b=>b.container.dataset.example==='fields'),original=b.controls.find(c=>c.property==='appearance').object;window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:saved}}}));original.appearance='dark';b.onChange();return {stable:b.controls.find(c=>c.property==='appearance').object===original,scheme:b.container.style.colorScheme,size:JSON.stringify(saved).length};});
  assert.equal(restored.stable,true);assert.equal(restored.scheme,'dark');assert.ok(restored.size<16384);
  groups.push('Reducao pelo sistema e controle; ajustes continuam ligados apos restauracao instrumentada');

  await tweak('fields','context','pay');await fields.getByRole('radio',{name:'Parcial',exact:true}).check();await fields.locator('[data-action=review]').click();
  await tweak('actions','response','success');await actions.locator('[data-action=restart]').count().then(async count=>{if(count)await show('actions');});
  for(const example of ['fields','actions','query']){
   await show(example);await tweak(example,'motion','reduced');
   for(const width of [320,360,390,780])for(const theme of ['light','dark'])for(const fontSize of [16,21]){
    await page.setViewportSize({width,height:1800});await tweak(example,'appearance',theme);
    const result=await app(example).evaluate((el,fontSize)=>{
     for(const node of el.querySelectorAll('label,legend,button,select,input,textarea,.date-value,.review-line dt,.review-line dd'))node.style.fontSize=fontSize+'px';
     const r=el.getBoundingClientRect(),date=el.querySelector('.date-value');let dateFits=true;
     if(date){const range=document.createRange();range.selectNodeContents(date);const glyphs=range.getBoundingClientRect(),box=date.getBoundingClientRect();dateFits=glyphs.left>=box.left-1&&glyphs.right<=box.right+1&&glyphs.top>=box.top-1&&glyphs.bottom<=box.bottom+1;}
     const overflow=[...el.querySelectorAll('input,select,textarea,.date-control,.panel,.message,.kind-options,.balance')].filter(node=>{if(!node.getClientRects().length||node.closest('[inert]'))return false;const b=node.getBoundingClientRect();return b.left<r.left-1||b.right>r.right+1;}).map(node=>node.className);
     return {viewport:innerWidth,productWidth:r.width,productHeight:r.height,stageHeight:el.closest('.stage').getBoundingClientRect().height,horizontalOverflow:document.documentElement.scrollWidth>innerWidth+1,overflow,dateFits};
    },fontSize);
    assert.equal(result.horizontalOverflow,false,JSON.stringify({example,width,theme,fontSize,...result}));assert.deepEqual(result.overflow,[]);assert.equal(result.dateFits,true);layouts.push({example,width,theme,fontSize,...result});
   }
  }
  assert.deepEqual(errors,[]);groups.push('Campos com erros e parcial, respostas e tabela/lista em quatro larguras, dois temas e texto 16/21');
  return {engine,groups,layouts,javascriptErrors:errors,persistenceSnapshotBytes:restored.size};
 } finally {await browser.close();}
}
(async()=>{const engines=[];for(const engine of ['edge','webkit'])engines.push(await run(engine));const report={date:'2026-10-16',result:'passed',scope:'Catalogo local; sem Flutter, API ou dados reais',layoutCases:engines.reduce((n,e)=>n+e.layouts.length,0),engines,limits:['Motores Edge e WebKit locais no Windows; sem aparelho iOS/Android, UIKit, leitor de tela ou desempenho Flutter.','Tweak e persistencia instrumentados; painel nativo e restauracao real do hospedeiro nao automatizados.','Resultados financeiros, consulta anterior e recuperacao de confirmacao sao simulacoes; nao demonstram contrato implementado no servidor.','Texto ampliado foi simulado nos controles; nao equivale a Dynamic Type ou escala nativa.']};fs.writeFileSync(path.join(base,'catalogo-componentes-verificacao.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({result:report.result,layoutCases:report.layoutCases,engines:engines.map(e=>({engine:e.engine,groups:e.groups.length,javascriptErrors:e.javascriptErrors}))}));})().catch(error=>{console.error(error);process.exitCode=1;});
