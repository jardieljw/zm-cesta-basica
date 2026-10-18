const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const {chromium}=require('C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base='C:/Users/jardi/.codex/visualizations/2026/10/14/01a13be2-5658-7881-a6a2-24d698fcc1cd';
const html=fs.readFileSync(base+'/direcoes-design-zm-ajustavel.html','utf8');
new vm.Script(html.match(/<script>([\s\S]*?)<\/script>/)[1]);
(async()=>{
 const browser=await chromium.launch({channel:'msedge',headless:true});
 try{
  const page=await browser.newPage({viewport:{width:780,height:2600}});const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.addInitScript(()=>{
   globalThis.__designTweaks=[];
   globalThis.Tweak=class{
    constructor(options){Object.assign(this,options);this.controls=[];globalThis.__designTweaks.push(this);}
    addSlider(object,property,options){this.controls.push({object,property,options,type:'slider'});}
    addSelect(object,property,options){this.controls.push({object,property,options,type:'select'});}
    addColorPicker(object,property,options){this.controls.push({object,property,options,type:'color'});}
    addToggle(object,property,options){this.controls.push({object,property,options,type:'toggle'});}
   };
  });
  await page.goto('file:///'+base+'/direcoes-design-zm-ajustavel-preview.html');
  const frame=page.frames().find(f=>f.parentFrame());await frame.locator('.product.soft .account').first().waitFor();
  await frame.evaluate(source=>{
   for(const p of document.querySelectorAll('.product'))p.replaceChildren();
   globalThis.__designTweaks=[];
   globalThis.Tweak=class{
    constructor(options){Object.assign(this,options);this.controls=[];globalThis.__designTweaks.push(this);}
    addSlider(object,property,options){this.controls.push({object,property,options,type:'slider'});}
    addSelect(object,property,options){this.controls.push({object,property,options,type:'select'});}
    addColorPicker(object,property,options){this.controls.push({object,property,options,type:'color'});}
    addToggle(object,property,options){this.controls.push({object,property,options,type:'toggle'});}
   };
   (0,eval)(source);
  },html.match(/<script>([\s\S]*?)<\/script>/)[1]);
  await page.emulateMedia({reducedMotion:'reduce'});
  const results=await frame.evaluate(()=>{
   const t=globalThis.__designTweaks.find(x=>x.container.dataset.style==='soft');const object=t.controls[0].object;
   const measure=()=>({gap:getComputedStyle(t.container.querySelector('.fields')).gap,radius:getComputedStyle(t.container.querySelector('.panel')).borderRadius,background:getComputedStyle(t.container).backgroundColor,scheme:getComputedStyle(t.container).colorScheme});
   const initial=measure();Object.assign(object,{space:40,radius:30});t.onChange();const changed=measure();
   const draft={status:'all',customer:'all',basket:'all',sale:null,due:null,minimum:'',maximum:''};
   window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:{privateContent:{variants:{soft:{draft,applied:draft,design:{space:24,radius:16}}}}}}}}));
   Object.assign(object,{space:12,radius:4});t.onChange();const afterRestore=measure();
   Object.assign(object,{appearance:'dark'});t.onChange();const dark=measure();
   Object.assign(object,{appearance:'custom',background:'#fffdf0',accent:'#237344'});t.onChange();const custom={...measure(),accent:getComputedStyle(t.container.querySelector('.apply')).backgroundColor};
   Object.assign(object,{appearance:'light',space:24,radius:16,background:'#ffffff',accent:'#2364aa'});t.onChange();
   const glass=globalThis.__designTweaks.find(x=>x.container.dataset.style==='glass');const gd=glass.controls[0].object;Object.assign(gd,{opacity:35,blur:20});glass.onChange();
   const material={fill:getComputedStyle(glass.container.querySelector('.picker-trigger')).backgroundColor,blur:getComputedStyle(glass.container.querySelector('.picker-trigger')).backdropFilter};
   Object.assign(gd,{opacity:56,blur:14});glass.onChange();
   return {initial,changed,afterRestore,dark,custom,material,controls:globalThis.__designTweaks.map(x=>x.controls.map(c=>c.property))};
  });
  assert.equal(results.changed.gap,'40px');assert.equal(results.changed.radius,'30px');assert.equal(results.afterRestore.gap,'12px');assert.equal(results.afterRestore.radius,'4px');
  assert.equal(results.dark.scheme,'dark');assert.equal(results.dark.background,'rgb(17, 17, 19)');assert.equal(results.custom.background,'rgb(255, 253, 240)');assert.equal(results.custom.accent,'rgb(35, 115, 68)');assert.match(results.material.fill,/0\.35/);assert.match(results.material.blur,/20px/);
  await frame.locator('.product.soft [data-field=status] .picker-trigger').click();await frame.getByRole('radio',{name:/^Vencidas/}).check();await frame.locator('.product.soft .apply').click();assert.equal(await frame.locator('.product.soft .account').count(),2);
  await frame.evaluate(()=>{for(const s of document.querySelectorAll('[data-variant]'))s.hidden=!s.querySelector('.glass');});
  await frame.locator('.product.glass').screenshot({path:base+'/controls-glass.png'});
  await page.setViewportSize({width:360,height:2600});await frame.waitForFunction(()=>innerWidth===328);assert.equal(await frame.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false);
  await frame.locator('.product.glass').screenshot({path:base+'/controls-glass-mobile.png'});
  assert.deepEqual(errors,[]);console.log(JSON.stringify({status:'passed',results}));
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
