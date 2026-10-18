const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
process.env.PLAYWRIGHT_BROWSERS_PATH||='C:/Users/jardi/AppData/Local/ms-playwright';
const {chromium,webkit}=require(process.env.PLAYWRIGHT_MODULE||'C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base=process.env.PREVIEW_DIR||__dirname;
const probe=process.argv.includes('--probe');
const file=probe?'fundamentos-visuais-revisados-zm':'calendario-movimento-zm';
async function run(engine){
 const browser=engine==='edge'?await chromium.launch({channel:'msedge',headless:true}):await webkit.launch({headless:true});
 try{
  const page=await browser.newPage({viewport:{width:390,height:1100},locale:'pt-BR',reducedMotion:'no-preference',colorScheme:'light'}),errors=[];
  page.on('pageerror',error=>errors.push(error.message));
  await page.goto('file:///'+path.join(base,file+'-preview.html').replaceAll('\\','/'));
  const frame=page.frames().find(frame=>frame.parentFrame());
  const fields=frame.locator('[data-example=fields]');
  await fields.locator('[data-action=calendar]').waitFor();
  const result=await fields.evaluate(async app=>{
   const trigger=app.querySelector('[data-action=calendar]'),dialog=app.querySelector('.date-dialog');
   trigger.click();
   const animations=dialog.getAnimations(),samples=[];
   const start=performance.now();
   await new Promise(resolve=>{function sample(){const style=getComputedStyle(dialog);samples.push({time:performance.now()-start,opacity:Number(style.opacity),transform:style.transform,open:dialog.open});if(performance.now()-start<350)requestAnimationFrame(sample);else resolve();}requestAnimationFrame(sample);});
   return {effectiveMotion:app.dataset.motion,systemReduced:matchMedia('(prefers-reduced-motion:reduce)').matches,animations:animations.map(animation=>({timing:animation.effect.getTiming(),keyframes:animation.effect.getKeyframes()})),samples};
  });
  if(probe){assert.deepEqual(errors,[]);return {engine,...result};}
  const dialog=fields.locator('.date-dialog'),trigger=fields.locator('[data-action=calendar]');
  const measures=await fields.evaluate(app=>({field:getComputedStyle(app.querySelector('.date-control')).borderRadius,panel:getComputedStyle(app.querySelector('.panel')).borderRadius,gap:getComputedStyle(app.querySelector('.panel')).gap,calendar:getComputedStyle(app.querySelector('dialog')).borderRadius}));
  assert.deepEqual(measures,{field:'24px',panel:'32px',gap:'20px',calendar:'32px'});
  assert.equal(result.effectiveMotion,'true');
  const entrance=result.animations.find(animation=>animation.keyframes[0].transform?.includes('scale'));
  assert.equal(entrance.timing.duration,240);assert.equal(entrance.keyframes[0].opacity,'0');
  assert.ok(result.samples.some(sample=>sample.opacity>0&&sample.opacity<1),'computed intermediate opacity must be observable');
  assert.equal(result.samples.at(-1).opacity,1);assert.equal(result.samples.at(-1).transform,'none');
  assert.equal(await dialog.locator('[data-calendar-date="2026-10-16"]').evaluate(el=>el===document.activeElement),true);
  const close=async()=>{await dialog.locator('[data-calendar-action=close]').last().click();await frame.waitForFunction(()=>document.querySelector('[data-example=fields] [data-field=date]').getAttribute('aria-expanded')==='false');assert.equal(await trigger.evaluate(el=>el===document.activeElement),true);};
  await close();
  const intermediate=await fields.evaluate(async app=>{
   app.querySelector('[data-action=calendar]').click();
   const dialog=app.querySelector('dialog'),animation=dialog.getAnimations().find(animation=>animation.effect.getKeyframes()[0].transform?.includes('scale'));
   if(!animation)throw new Error('Repeated opening did not start an entrance');
   animation.pause();animation.currentTime=80;
   await new Promise(requestAnimationFrame);
   return {opacity:Number(getComputedStyle(dialog).opacity),transform:getComputedStyle(dialog).transform};
  });
  assert.ok(intermediate.opacity>0&&intermediate.opacity<1);
  await page.screenshot({path:path.join(base,`calendar-${engine}-intermediate.png`),fullPage:true,animations:'allow'});
  await dialog.evaluate(el=>{for(const animation of el.getAnimations())if(animation.playState==='paused')animation.finish();});
  await page.screenshot({path:path.join(base,`calendar-${engine}-complete.png`),fullPage:true,animations:'allow'});
  await close();
  await fields.evaluate(app=>{app.querySelector('[data-action=calendar]').click();app.querySelector('dialog').close();});
  await frame.waitForFunction(()=>document.querySelector('[data-example=fields] [data-field=date]').getAttribute('aria-expanded')==='false');
  await trigger.click();await dialog.locator('[data-calendar-date="2026-10-17"]').click();
  await frame.waitForFunction(()=>document.querySelector('[data-example=fields] [data-field=date]').getAttribute('aria-expanded')==='false');
  assert.match(await trigger.innerText(),/17 de outubro/);
  assert.equal(await trigger.evaluate(el=>el===document.activeElement),true);

  const helper=fs.readFileSync(process.env.TWEAK_HELPER_PATH||'C:/Users/jardi/.codex/plugins/cache/openai-bundled/visualize/1.0.50/assets/tweak.js','utf8');
  const source=fs.readFileSync(path.join(base,file+'.html'),'utf8').match(/<script>([\s\S]*?)<\/script>/)[1];
  await frame.evaluate(({helper,source})=>{
   const root=document.querySelector('.viz-carousel'),clone=root.cloneNode(true);clone.querySelectorAll('.product-content').forEach(el=>el.innerHTML='');root.replaceWith(clone);
   window.__regs={};window.__saved=[];window.__changes=new Map();
   window.openai={...window.openai,widgetState:null,callTool(name,message){if(name!=='__codex_visualization_annotations__')throw new Error('Unexpected tool in test');if(['register','update'].includes(message.type)){window.__regs[message.registrationId]=JSON.parse(JSON.stringify(message));return Promise.resolve({annotationControls:message.annotationControls});}return Promise.resolve({});},setWidgetState(state){window.__saved.push(JSON.parse(JSON.stringify(state)));return Promise.resolve();}};
   (0,eval)(helper);(0,eval)(source);
  },{helper,source});
  await frame.waitForFunction(()=>Object.values(window.__regs).some(reg=>reg.annotationControls.controls.length===7));
  const edit=(key,value)=>frame.evaluate(({key,value})=>{
   const [registrationId,reg]=Object.entries(window.__regs).find(([,reg])=>reg.annotationControls.controls.length===7);
   const control=reg.annotationControls.controls.find(control=>control.label===key);if(!control)throw new Error('Missing design control '+key);
   window.__changes.set(control.callback,{callback:control.callback,previousValue:control.currentValue,value});
   window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:window.__saved.at(-1)||null,visualizationAnnotation:{active:false,changes:[{registrationId,targetId:reg.targets[0].id,annotationControlChanges:[...window.__changes.values()]}]}}}}));
  },{key,value});
  const animationCount=()=>fields.evaluate(app=>{app.querySelector('[data-action=calendar]').click();const dialog=app.querySelector('dialog');return {count:dialog.getAnimations().length,opacity:getComputedStyle(dialog).opacity,transform:getComputedStyle(dialog).transform,backdrop:getComputedStyle(dialog,'::backdrop').animationName};});
  await edit('Movimento compartilhado','reduced');assert.equal(await fields.getAttribute('data-motion'),'false');
  const localReduced=await animationCount();assert.equal(localReduced.count,0);assert.equal(localReduced.opacity,'1');assert.equal(localReduced.transform,'none');assert.equal(localReduced.backdrop,'none');await close();
  await edit('Movimento compartilhado','standard');
  await page.emulateMedia({reducedMotion:'reduce'});await frame.waitForFunction(()=>document.querySelector('[data-example=fields]').dataset.motion==='false');
  const systemReduced=await animationCount();assert.equal(systemReduced.count,0);await close();
  await page.emulateMedia({reducedMotion:'no-preference'});await frame.waitForFunction(()=>document.querySelector('[data-example=fields]').dataset.motion==='true');
  assert.ok((await animationCount()).count>0);
  await page.emulateMedia({reducedMotion:'reduce'});await frame.waitForFunction(()=>document.querySelector('[data-example=fields] dialog').getAnimations().length===0);assert.equal(await dialog.evaluate(el=>getComputedStyle(el).opacity),'1');await close();
  await page.emulateMedia({reducedMotion:'no-preference'});await frame.waitForFunction(()=>document.querySelector('[data-example=fields]').dataset.motion==='true');

  const layouts=[];
  for(const width of [320,390,768])for(const theme of ['light','dark']){
   await page.setViewportSize({width,height:1100});await edit('Aparência compartilhada',theme);
   const layout=await fields.evaluate(async app=>{
    app.querySelector('[data-action=calendar]').click();const dialog=app.querySelector('dialog');await Promise.all(dialog.getAnimations().map(animation=>animation.finished.catch(()=>{})));
    const rect=dialog.getBoundingClientRect();return {left:rect.left,right:rect.right,width:rect.width,viewport:innerWidth,overflow:dialog.scrollWidth-dialog.clientWidth,opacity:getComputedStyle(dialog).opacity};
   });
   assert.ok(layout.left>=0&&layout.right<=layout.viewport+1&&layout.overflow<=1,JSON.stringify({engine,width,theme,layout}));
   layouts.push({width,theme,...layout});await close();
  }
  await fields.getByRole('radio',{name:'Parcial',exact:true}).check();
  await fields.locator('[data-field=amount]').fill('40');await fields.locator('[data-field=method]').selectOption('PIX');
  assert.match(await fields.locator('[data-remaining]').innerText(),/60,00/);
  await fields.locator('[data-action=review]').click();assert.match(await fields.innerText(),/40,00/);
  assert.deepEqual(errors,[]);
  return {engine,result:'passed',measures,entrance:result,intermediate,localReduced,systemReduced,layouts,javascriptErrors:errors,limits:'Unmodified Tweak helper with simulated annotation provider; Windows browser tests, no native controls UI or real iPhone/Android validation'};
 }finally{await browser.close();}
}
(async()=>{const results=[];for(const engine of ['edge','webkit'])results.push(await run(engine));fs.writeFileSync(path.join(base,probe?'calendar-motion-before.json':'calendar-motion-verification.json'),JSON.stringify({date:'2026-10-16',results},null,2)+'\n');console.log(JSON.stringify(results.map(result=>probe?{engine:result.engine,effectiveMotion:result.effectiveMotion,duration:result.animations.map(a=>a.timing.duration),first:result.samples[0],last:result.samples.at(-1)}:{engine:result.engine,result:result.result,geometry:result.measures,layouts:result.layouts.length,intermediate:result.intermediate,reduced:result.localReduced.count,systemReduced:result.systemReduced.count})));})().catch(error=>{console.error(error);process.exitCode=1;});
