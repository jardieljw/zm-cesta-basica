const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
process.env.PLAYWRIGHT_BROWSERS_PATH||='C:/Users/jardi/AppData/Local/ms-playwright';
const {chromium,webkit}=require(process.env.PLAYWRIGHT_MODULE||'C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base=process.env.PREVIEW_DIR||__dirname;
const helper=fs.readFileSync(process.env.TWEAK_HELPER_PATH||'C:/Users/jardi/.codex/plugins/cache/openai-bundled/visualize/1.0.50/assets/tweak.js','utf8');
const probeOnly=process.argv.includes('--probe');
async function run(engine,file,revised){
 const fragment=fs.readFileSync(path.join(base,file+'.html'),'utf8'),source=fragment.match(/<script>([\s\S]*?)<\/script>/)[1];new vm.Script(source);
 const browser=engine==='edge'?await chromium.launch({channel:'msedge',headless:true}):await webkit.launch({headless:true});
 try{
  const page=await browser.newPage({viewport:{width:390,height:1850},locale:'pt-BR',colorScheme:'light'}),errors=[];
  page.on('pageerror',error=>errors.push(error.message));
  await page.goto('file:///'+path.join(base,file+'-preview.html').replaceAll('\\','/'));
  const frame=page.frames().find(f=>f.parentFrame());await frame.locator('[data-example=fields] [data-field=date]').waitFor();
  await frame.evaluate(({helper,source})=>{
   const old=document.querySelector('.viz-carousel'),clone=old.cloneNode(true);clone.querySelectorAll('.product-content').forEach(el=>el.innerHTML='');old.replaceWith(clone);
   window.__regs={};window.__saved=[];window.__changes=new Map();window.__rpc=[];
   window.openai={...window.openai,widgetState:null,callTool(name,message){window.__rpc.push({name,type:message.type});if(name!=='__codex_visualization_annotations__')throw new Error('Unexpected tool in local harness');if(['register','update'].includes(message.type)){window.__regs[message.registrationId]=JSON.parse(JSON.stringify(message));return Promise.resolve({annotationControls:message.annotationControls});}if(message.type==='dispose')delete window.__regs[message.registrationId];return Promise.resolve({});},setWidgetState(state){window.__saved.push(JSON.parse(JSON.stringify(state)));return Promise.resolve();}};
   (0,eval)(helper);(0,eval)(source);
  },{helper,source});
  await frame.waitForFunction(()=>Object.values(window.__regs).some(reg=>reg.targets[0].label.includes('compartilhados')&&reg.annotationControls.controls.length===7));
  const fields=frame.locator('[data-example=fields]');
  await fields.locator('[data-field=method]').selectOption('PIX');
  const baseline=await frame.evaluate(()=>window.__saved.at(-1));
  const edit=(key,value,echo=baseline)=>frame.evaluate(({key,value,echo})=>{
   const [registrationId,reg]=Object.entries(window.__regs).find(([,reg])=>reg.targets[0].label.includes('compartilhados'));
   const control=reg.annotationControls.controls.find(c=>c.reference===key||c.label===key);if(!control)throw new Error('Control not found: '+key);
   window.__changes.set(control.callback,{callback:control.callback,previousValue:control.currentValue,value});
   window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:echo,visualizationAnnotation:{active:false,changes:[{registrationId,targetId:reg.targets[0].id,annotationControlChanges:[...window.__changes.values()]}]}}}}));
  },{key,value,echo});
  const metrics=()=>fields.evaluate(el=>({panel:getComputedStyle(el.querySelector('.panel')).borderRadius,field:getComputedStyle(el.querySelector('.date-control')).borderRadius,gap:getComputedStyle(el.querySelector('.panel')).gap,page:getComputedStyle(el).backgroundColor,scheme:el.style.colorScheme,latest:window.__saved.at(-1)?.privateContent?.foundation}));
  const before=await metrics();
  await edit('--zm-panel-radius',24);await edit('--zm-field-radius',20);await edit('--zm-field-gap',28);
  const after=await metrics();
  if(!revised){assert.equal(after.panel,'32px');assert.equal(after.field,'28px');assert.equal(after.gap,'24px');return {engine,reproduced:true,before,after,javascriptErrors:errors,reason:'Edits published by the real Tweak helper are overwritten by the same globals event restoring an older widgetState'};}
  assert.equal(before.gap,'20px');assert.equal(after.panel,'24px');assert.equal(after.field,'20px');assert.equal(after.gap,'28px');
  await edit('Aparência compartilhada','dark');assert.equal((await metrics()).scheme,'dark');
  await edit('Fundo','pure');assert.equal((await metrics()).page,'rgb(0, 0, 0)');
  await edit('Aparência compartilhada','light');assert.equal((await metrics()).page,'rgb(255, 255, 255)');
  await edit('Movimento compartilhado','reduced');assert.equal(await fields.getAttribute('data-motion'),'false');
  await edit('Movimento compartilhado','standard');assert.equal(await fields.getAttribute('data-motion'),'true');
  await edit('--zm-accent','#116b63');assert.equal((await metrics()).latest.accent,'#116b63');
  await edit('--zm-field-gap',20);await edit('--zm-panel-radius',40);await edit('--zm-field-radius',32);
  const closing=await metrics();assert.equal(closing.gap,'20px');assert.equal(closing.panel,'40px');assert.equal(closing.field,'32px');
  const savesBeforeRestore=await frame.evaluate(()=>window.__saved.length);
  await frame.evaluate(saved=>{const reorder=value=>Array.isArray(value)?value.map(reorder):value&&typeof value==='object'?Object.fromEntries(Object.keys(value).sort().reverse().map(k=>[k,reorder(value[k])])):value;window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:reorder(saved)}}}));},baseline);
  assert.equal((await metrics()).panel,'40px');assert.equal(await frame.evaluate(()=>window.__saved.length),savesBeforeRestore);
  const external=structuredClone(baseline);external.privateContent.foundation.spacing=32;external.privateContent.foundation.panelRadius=36;external.privateContent.foundation.fieldRadius=24;external.privateContent.examples.fields.draft.notes='Rascunho externo conferido';
  await frame.evaluate(saved=>window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:saved}}})),external);
  await frame.waitForFunction(()=>getComputedStyle(document.querySelector('[data-example=fields] .panel')).gap==='32px',{},{timeout:1000}).catch(async error=>{const debug=await fields.evaluate(el=>({inline:el.getAttribute('style'),child:el.querySelector('.panel').getAttribute('style'),variable:getComputedStyle(el).getPropertyValue('--zm-field-gap'),childVariable:getComputedStyle(el.querySelector('.panel')).getPropertyValue('--zm-field-gap'),connected:el.isConnected,roots:document.querySelectorAll('.viz-carousel').length,body:el.querySelector('.product-content').innerText.slice(0,140)}));throw new Error(JSON.stringify({engine,debug,metrics:await metrics()}));});
  const externalMetrics=await metrics();assert.equal(externalMetrics.gap,'32px',JSON.stringify({engine,externalMetrics,expected:external.privateContent.foundation}));assert.equal(externalMetrics.panel,'36px');assert.equal(externalMetrics.field,'24px');assert.equal(await fields.locator('[data-field=notes]').inputValue(),'Rascunho externo conferido');
  await edit('--zm-panel-radius',28,external);await edit('--zm-field-radius',20,external);await edit('--zm-field-gap',24,external);await edit('--zm-field-gap',20,external);assert.equal((await metrics()).gap,'20px');assert.equal((await metrics()).panel,'28px');
  await fields.locator('[data-action=calendar]').click();
  await edit('Aparência compartilhada','dark',external);assert.equal(await fields.locator('dialog').evaluate(el=>el.open),true);
  await fields.locator('[data-calendar-action=close]').last().click();
  await frame.waitForFunction(()=>document.querySelector('[data-field=date]').getAttribute('aria-expanded')==='false');
  assert.equal(await fields.locator('[data-field=date]').evaluate(el=>el===document.activeElement),true);
  await page.screenshot({path:path.join(base,`ajustes-reais-${engine}-escuro.png`),fullPage:true});
  await edit('Aparência compartilhada','light',external);await fields.screenshot({path:path.join(base,`ajustes-reais-${engine}-claro.png`)});
  assert.deepEqual(errors,[]);
  return {engine,result:'passed',before,after,closing,externalMetrics,javascriptErrors:errors,controlsChecked:['spacing','panelRadius','fieldRadius','appearance','page','accent','motion'],limits:'Real bundled Tweak binding code with a simulated annotations provider; desktop controls UI not automated'};
 }finally{await browser.close();}
}
(async()=>{const original=await run('edge','fundamentos-visuais-zm',false);if(probeOnly){console.log(JSON.stringify(original));return;}const corrected=[];for(const engine of ['edge','webkit'])corrected.push(await run(engine,'fundamentos-visuais-revisados-zm',true));const report={date:'2026-10-16',original,corrected,scope:'Local reproduction with the unmodified bundled Tweak helper; no Flutter changes'};fs.writeFileSync(path.join(base,'ajustes-reais-verificacao.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({reproduced:original.reproduced,corrected:corrected.map(e=>({engine:e.engine,result:e.result,controls:e.controlsChecked.length}))}));})().catch(error=>{console.error(error);process.exitCode=1;});
