const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const {chromium}=require('C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base='C:/Users/jardi/.codex/visualizations/2026/10/14/01a13be2-5658-7881-a6a2-24d698fcc1cd';
const source=fs.readFileSync(base+'/mapa-navegavel-zm.html','utf8');new vm.Script(source.match(/<script>([\s\S]*?)<\/script>/)[1]);
(async()=>{
 const browser=await chromium.launch({channel:'msedge',headless:true});
 try{
  const page=await browser.newPage({viewport:{width:780,height:1800}});const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto('file:///'+base+'/mapa-navegavel-zm-preview.html');
  const frame=page.frames().find(f=>f.parentFrame());const mobile=frame.locator('.app.mobile');await mobile.getByRole('heading',{name:'Visão geral',exact:true}).waitFor();
  await mobile.getByRole('button',{name:'Abrir Financeiro',exact:true}).click();assert.equal(await mobile.locator('.page-title').innerText(),'Financeiro');
  await mobile.getByRole('button',{name:'Pagar',exact:true}).click();await mobile.getByRole('button',{name:/Fornecedor de alimentos/}).click();assert.equal(await mobile.locator('.page-title').innerText(),'Fornecedor de alimentos');
  await mobile.getByRole('button',{name:'Voltar',exact:true}).click();assert.equal(await mobile.getByRole('button',{name:/Fornecedor de alimentos/}).count(),1);
  await mobile.locator('[data-area=estoque]').click();await mobile.getByRole('button',{name:/Cestas e montagens/}).click();assert.equal(await mobile.locator('.page-title').innerText(),'Cestas e montagens');
  await mobile.getByRole('button',{name:/Cesta Básica Completa/}).click();assert.equal(await mobile.locator('.page-title').innerText(),'Cesta Básica Completa');
  await mobile.locator('[data-area=financeiro]').click();assert.equal(await mobile.getByRole('button',{name:/Fornecedor de alimentos/}).count(),1);
  await mobile.getByRole('button',{name:'Receber',exact:true}).click();assert.equal(await mobile.getByRole('button',{name:/Ana Souza/}).count(),1);
  await mobile.locator('[data-area=inicio]').click();
  const layouts=[];
  for(const width of [780,412,360,320]){
   await page.setViewportSize({width,height:1800});await frame.waitForFunction(w=>innerWidth===w-32,width);
   for(const device of ['mobile','desktop']){
    await frame.evaluate(device=>{for(const section of document.querySelectorAll('[data-variant]'))section.hidden=section.querySelector('.app').dataset.device!==device;},device);
    const result=await frame.evaluate(device=>{const app=document.querySelector('.app.'+device);return {device,width:innerWidth,overflow:document.documentElement.scrollWidth>innerWidth+1,navigation:getComputedStyle(app.querySelector('.navigation')).display};},device);
    assert.equal(result.overflow,false,JSON.stringify(result));layouts.push(result);
    if(width===780){await page.waitForTimeout(200);await frame.locator('.app.'+device).screenshot({path:base+'/navigation-'+device+'.png'});}
   }
  }
  await page.emulateMedia({colorScheme:'dark'});await frame.locator('.app.desktop').screenshot({path:base+'/navigation-dark-mobile.png'});
  assert.deepEqual(errors,[]);console.log(JSON.stringify({status:'passed',journeys:['inicio_financeiro_pagar_detalhe_voltar','estoque_cestas_montagens','preservar_area_financeira','receber','navegacao_responsiva'],layouts}));
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
