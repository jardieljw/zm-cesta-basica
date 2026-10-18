const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
process.env.PLAYWRIGHT_BROWSERS_PATH ||= 'C:/Users/jardi/AppData/Local/ms-playwright';
const { chromium, webkit } = require(process.env.PLAYWRIGHT_MODULE || 'C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base = process.env.PREVIEW_DIR || __dirname;
const html = fs.readFileSync(path.join(base, 'financeiro-origem-e-data-zm.html'), 'utf8');
const source = html.match(/<script>([\s\S]*?)<\/script>/)[1];
new vm.Script(source);
assert.ok(Buffer.byteLength(html) < 1000000);
assert.equal(/<input[^>]+type="date"/.test(html), false);
assert.equal(/\btabindex\s*=/.test(html), false);
const clean = text => text.replaceAll('\u00a0', ' ');

async function runEngine(engine) {
  const browser = engine === 'edge' ? await chromium.launch({ channel: 'msedge', headless: true }) : await webkit.launch({ headless: true });
  const errors = [], groups = [], cases = [];
  try {
    const context = await browser.newContext({ locale: 'pt-BR', viewport: { width: 390, height: 1800 }, colorScheme: 'light', reducedMotion: 'reduce', hasTouch: true, isMobile: true });
    const page = await context.newPage();
    page.on('pageerror', error => errors.push(error.message));
    await page.goto('file:///' + path.join(base, 'financeiro-origem-e-data-zm-preview.html').replaceAll('\\', '/'));
    const frame = page.frames().find(f => f.parentFrame());
    await frame.locator('[data-device=payment] [data-action=open-date]').waitFor();
    await frame.evaluate(code => {
      for (const app of document.querySelectorAll('.app')) app.replaceWith(app.cloneNode(false));
      window.__bindings = []; window.__snapshots = [];
      window.openai = { ...window.openai, widgetState: null, setWidgetState(value) { window.__snapshots.push(value); return Promise.resolve(); } };
      globalThis.Tweak = class {
        constructor(options) { Object.assign(this, options); this.controls = []; window.__bindings.push(this); }
        addSelect(object, property, options) { this.controls.push({ object, property, options }); }
        addSlider(object, property, options) { this.controls.push({ object, property, options }); }
      };
      (0, eval)(code);
    }, source);
    const app = device => frame.locator(`.app[data-device="${device}"]`);
    const show = async device => frame.evaluate(device => { for (const section of document.querySelectorAll('.viz-carousel > section')) section.hidden = !section.querySelector(`[data-device="${device}"]`); }, device);
    const tweak = async (device, property, value) => frame.evaluate(({device, property, value}) => {
      const binding = window.__bindings.find(b => b.container.dataset.device === device);
      const control = binding.controls.find(c => c.property === property);
      if (!control) throw new Error(`Controle ausente: ${device}/${property}`);
      control.object[property] = value; binding.onChange();
    }, {device, property, value});
    const reset = async device => { await show(device); await app(device).getByRole('button', { name: 'Recomeçar exemplo', exact: true }).click(); };
    const openToday = async device => { await show(device); await app(device).locator('[data-action=today]').click(); };
    const openAccount = async device => app(device).locator('[data-go="financeiro:conta-fornecedor"]').first().click();
    const confirm = async device => {
      await app(device).locator('[data-action=review]').click();
      await app(device).getByRole('heading', { name: 'Conferir pagamento', exact: true }).waitFor();
      await app(device).locator('[data-action=confirm]').evaluate(button => { button.click(); button.click(); });
      await app(device).getByRole('heading', { name: 'Pagamento registrado', level: 2, exact: true }).waitFor();
    };
    const back = async device => app(device).getByRole('button', { name: 'Voltar', exact: true }).click();

    await show('payment');
    for (const mode of ['Integral', 'Parcial']) {
      await app('payment').getByRole('radio', { name: mode, exact: true }).check();
      for (const width of [320, 360, 390, 780]) {
        await page.setViewportSize({ width, height: 1800 });
        for (const theme of ['light', 'dark']) for (const font of [16, 20]) {
          await tweak('payment', 'appearance', theme);
          const measurement = await app('payment').locator('.date-control').evaluate((button, font) => {
            button.style.fontSize = font + 'px';
            const text = button.querySelector('.date-value'), icon = button.querySelector('svg'), reference = button.closest('.form-panel').querySelector('.select-wrap');
            const rect = element => { const r = element.getBoundingClientRect(); return { left:r.left, right:r.right, top:r.top, bottom:r.bottom, width:r.width, height:r.height }; };
            const range = document.createRange(); range.selectNodeContents(text);
            const b = rect(button), t = rect(text), r = rect(reference), i = icon ? rect(icon) : null;
            const glyphs = Array.from(range.getClientRects()).map(r => ({left:r.left,right:r.right,top:r.top,bottom:r.bottom}));
            return { viewport:innerWidth, button:b, text:t, reference:r, icon:i, glyphs, overflow:document.documentElement.scrollWidth > innerWidth + 1,
              centered:Math.abs((t.top+t.bottom)/2 - (b.top+b.bottom)/2) < 1,
              bounded:glyphs.every(g => g.left >= b.left + 8 && g.right <= b.right - 8 && g.top >= b.top + 6 && g.bottom <= b.bottom - 6),
              clipped:getComputedStyle(text).overflow === 'hidden', textContent:text.textContent };
          }, font);
          assert.equal(measurement.overflow, false, JSON.stringify(measurement));
          assert.equal(measurement.bounded, true, JSON.stringify(measurement));
          assert.equal(measurement.centered, true, JSON.stringify(measurement));
          assert.equal(measurement.clipped, false);
          assert.ok(Math.abs(measurement.button.left - measurement.reference.left) < 1 && Math.abs(measurement.button.right - measurement.reference.right) < 1);
          if (measurement.icon) assert.ok(measurement.text.right <= measurement.icon.left - 7);
          assert.match(measurement.textContent, /16 de outubro de 2026/);
          cases.push({engine, mode, width, theme, font, ...measurement});
        }
      }
    }
    groups.push('32 combinacoes por motor: limites dos glifos, centralizacao, icone, campos vizinhos, temas e modos');
    await page.setViewportSize({width:390,height:1800}); await tweak('payment','appearance','light');
    await app('payment').locator('.date-control').evaluate(button => button.style.fontSize = '16px');
    await app('payment').getByRole('radio',{name:'Integral',exact:true}).check();
    await app('payment').screenshot({path:path.join(base,`origem-data-${engine}-formulario.png`)});
    await app('payment').locator('[data-action=open-date]').click();
    const dialog = app('payment').locator('.date-dialog'); await dialog.waitFor({state:'visible'});
    assert.equal(await dialog.locator('[data-calendar-date]').count(),31);
    const dialogFits = await dialog.evaluate(dialog => {const r=dialog.getBoundingClientRect();return r.left>=0&&r.right<=innerWidth+1;}); assert.equal(dialogFits,true);
    await dialog.screenshot({path:path.join(base,`origem-data-${engine}-calendario.png`)});
    await dialog.locator('[data-calendar-step="1"]').click();
    await dialog.getByRole('button',{name:'02 de novembro de 2026',exact:true}).click();
    await dialog.waitFor({state:'hidden'});
    await frame.waitForFunction(()=>document.querySelector('[data-device=payment] [data-field=date]').getAttribute('aria-expanded')==='false');
    assert.equal(await app('payment').locator('[data-field=date]').getAttribute('aria-expanded'),'false');
    assert.equal(await app('payment').locator('[data-field=date]').evaluate(button=>button.value),'2026-11-02');
    assert.equal(await app('payment').locator('[data-field=date]').evaluate(button=>button===document.activeElement),true);
    await app('payment').locator('[data-action=open-date]').press('Enter');
    await dialog.locator('[data-calendar-date="2026-11-02"]').press('ArrowRight');
    await frame.locator(':focus').press('Enter');
    assert.equal(await app('payment').locator('[data-field=date]').evaluate(button=>button.value),'2026-11-03');
    await app('payment').locator('[data-action=open-date]').click();
    await dialog.locator('[data-calendar-step="1"]').click(); await frame.locator(':focus').press('Escape');
    assert.equal(await app('payment').locator('[data-field=date]').evaluate(button=>button.value),'2026-11-03');
    await app('payment').getByLabel('Como você pagou?',{exact:true}).selectOption('PIX');
    await app('payment').locator('[data-action=review]').click();
    assert.match(await app('payment').locator('.review-list').innerText(),/03 de novembro de 2026/);
    await app('payment').getByRole('button',{name:'Alterar data do pagamento',exact:true}).click();
    assert.equal(await app('payment').locator('[data-field=date]').evaluate(button=>button.value),'2026-11-03');
    groups.push('Calendario: selecionar, teclado, Escape, foco devolvido, revisar e editar preservando ISO');

    await reset('payment'); await app('payment').locator('[data-action=open-date]').click();
    await dialog.locator('[data-calendar-date="2026-10-16"]').press('PageUp');
    await frame.locator(':focus').press('Shift+PageUp'); await frame.locator(':focus').press('Shift+PageUp');
    for(let i=0;i<7;i++) await frame.locator(':focus').press('PageUp');
    await dialog.getByRole('button',{name:'29 de fevereiro de 2024',exact:true}).click();
    assert.equal(await app('payment').locator('[data-field=date]').evaluate(button=>button.value),'2024-02-29');
    groups.push('Calendario: navegacao de meses/anos e ano bissexto');

    await reset('mobile'); await tweak('mobile','appearance','dark');
    assert.equal(clean(await app('mobile').locator('[data-today-total]').innerText()),'R$ 680,00');
    await app('mobile').screenshot({path:path.join(base,`origem-data-${engine}-resumo.png`)});
    await openToday('mobile'); assert.equal(clean(await app('mobile').locator('[data-total]').innerText()),'R$ 680,00');
    assert.equal(await app('mobile').locator('[data-go="financeiro:conta-embalagens"]').count(),0);
    await openAccount('mobile'); await app('mobile').locator('.source-details summary').click();
    assert.match(await app('mobile').locator('.source-details').innerText(),/não há vínculo com uma compra/);
    await app('mobile').screenshot({path:path.join(base,`origem-data-${engine}-origem.png`)});
    await app('mobile').locator('[data-action=register]').click();
    assert.equal(await app('mobile').getByRole('radio',{name:'Integral',exact:true}).isChecked(),true);
    await app('mobile').getByLabel('Como você pagou?',{exact:true}).selectOption('PIX');
    await confirm('mobile');
    await app('mobile').locator('[data-action=view-account]').click();
    assert.equal(await app('mobile').locator('.history-entry').count(),2);
    assert.equal(clean(await app('mobile').locator('[data-balance]').innerText()),'R$ 0,00');
    await back('mobile'); assert.equal(await app('mobile').locator('[data-filter]').inputValue(),'open');
    assert.match(await app('mobile').locator('.range-label').innerText(),/16 de outubro/);
    await back('mobile'); assert.equal(await app('mobile').getByRole('heading',{name:'Nenhuma conta vence hoje',exact:true}).count(),1);
    await app('mobile').locator('[data-action=week]').click();
    assert.equal(clean(await app('mobile').locator('[data-total]').innerText()),'R$ 600,00');
    groups.push('Resumo de hoje, lista coerente, origem, integral sem digitar, uma confirmacao e filtros preservados');

    await reset('mobile'); await openToday('mobile'); await openAccount('mobile');
    await app('mobile').locator('[data-action=register]').click();
    await app('mobile').getByRole('radio',{name:'Parcial',exact:true}).check();
    await app('mobile').getByRole('textbox',{name:'Quanto você pagou?',exact:true}).fill('300');
    await app('mobile').getByLabel('Como você pagou?',{exact:true}).selectOption('DINHEIRO');
    await confirm('mobile'); await app('mobile').locator('[data-action=list]').click();
    assert.equal(clean(await app('mobile').locator('[data-total]').innerText()),'R$ 380,00');
    await back('mobile'); assert.equal(clean(await app('mobile').locator('[data-today-total]').innerText()),'R$ 380,00');
    groups.push('Pagamento parcial atualiza lista e resumo para o saldo restante, sem excluir o titulo em aberto');

    await reset('desktop'); await page.setViewportSize({width:780,height:1800});
    await openToday('desktop'); assert.equal(await app('desktop').locator('tbody tr').count(),1);
    await app('desktop').screenshot({path:path.join(base,`origem-data-${engine}-tabela.png`)});
    await openAccount('desktop'); await back('desktop');
    assert.equal(await app('desktop').locator('[data-filter]').inputValue(),'open');
    await back('desktop'); assert.equal(clean(await app('desktop').locator('[data-today-total]').innerText()),'R$ 680,00');
    groups.push('Windows: tabela comparavel, detalhe e retorno ao mesmo recorte');

    await reset('mobile'); await page.setViewportSize({width:390,height:1800});
    await tweak('mobile','query','empty');
    assert.equal(await app('mobile').getByRole('heading',{name:'Nenhuma conta vence hoje',exact:true}).count(),1);
    await app('mobile').screenshot({path:path.join(base,`origem-data-${engine}-vazio.png`)});
    await app('mobile').locator('[data-action=week]').click();
    assert.equal(await app('mobile').locator('[data-go="financeiro:conta-fornecedor"]').count(),0);
    assert.equal(clean(await app('mobile').locator('[data-total]').innerText()),'R$ 600,00');
    await tweak('mobile','query','unavailable');
    assert.equal(await app('mobile').locator('.amount').count(),0);
    assert.equal(await app('mobile').getByRole('alert').count(),1);
    await app('mobile').screenshot({path:path.join(base,`origem-data-${engine}-indisponivel.png`)});
    await app('mobile').locator('[data-action=retry-query]').click();
    await app('mobile').locator('[data-today-total]').waitFor();
    assert.equal(clean(await app('mobile').locator('[data-today-total]').innerText()),'R$ 680,00');
    groups.push('Vazio e indisponivel distintos; sem zero inventado e com recuperacao simulada');

    const restored = await frame.evaluate(() => {
      const saved = window.__snapshots.at(-1);
      window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:saved}}}));
      const binding=window.__bindings.find(b=>b.container.dataset.device==='mobile'),control=binding.controls.find(c=>c.property==='radius');
      control.object.radius=40;binding.onChange();
      return {radius:getComputedStyle(binding.container).getPropertyValue('--radius'),snapshots:window.__snapshots.length,size:JSON.stringify(saved).length};
    });
    assert.equal(restored.radius,'40px'); assert.ok(restored.size<16384);
    assert.equal(await app('mobile').locator('[data-today-total]').count(),1);
    groups.push('Controles simulados continuam ligados apos restaurar estado; captura abaixo de 16 KiB');

    for(const device of ['mobile','desktop']) {
      await show(device);
      for(const width of [320,360,390,780]) {
        await page.setViewportSize({width,height:1800});
        assert.equal(await frame.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false);
      }
    }
    assert.deepEqual(errors,[]);
    return {engine,groups,cases,restored,javascriptErrors:errors};
  } finally {await browser.close();}
}

(async()=>{
  const engines=[];
  for(const engine of ['edge','webkit']) engines.push(await runEngine(engine));
  const report={date:'2026-10-16',result:'passed',scope:'Previa com calendario proprio; sem Flutter/API/banco real',cases:engines.reduce((n,e)=>n+e.cases.length,0),engines,
    limits:['WebKit instalado no Windows; nao e Safari no iPhone. O calendario usa botoes reais e nao depende do input date nativo.', 'Tweak e persistencia instrumentados para isolar a logica local; painel nativo e restauracao real do hospedeiro nao automatizados.', 'Retorno conserva filtros e recorte; rolagem externa da conversa e resultado desconhecido de gravacao nao cobertos.']};
  fs.writeFileSync(path.join(base,'financeiro-origem-data-verificacao.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify({result:report.result,cases:report.cases,engines:engines.map(e=>({engine:e.engine,groups:e.groups.length,javascriptErrors:e.javascriptErrors}))}));
})().catch(error=>{console.error(error);process.exitCode=1;});
