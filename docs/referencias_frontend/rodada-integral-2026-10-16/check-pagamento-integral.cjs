const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base = process.env.PREVIEW_DIR || __dirname;
const tests = [], layouts = [], errors = [];

(async () => {
  const browser = await chromium.launch({ channel: 'msedge', headless: true });
  try {
    const context = await browser.newContext({ locale: 'pt-BR', viewport: { width: 780, height: 1800 }, reducedMotion: 'reduce' });
    await context.addInitScript(() => {
      globalThis.__journeyTweaks = [];
      globalThis.Tweak = class {
        constructor(options) { Object.assign(this, options); this.controls = []; globalThis.__journeyTweaks.push(this); }
        addSelect(object, property, options) { this.controls.push({ object, property, options }); }
        addSlider(object, property, options) { this.controls.push({ object, property, options }); }
      };
    });
    const page = await context.newPage();
    page.on('pageerror', error => errors.push(error.message));
    await page.goto('file:///' + path.join(base, 'jornada-pagar-integral-zm-preview.html').replaceAll('\\', '/'));
    const frame = page.frames().find(item => item.parentFrame());
    const mobile = frame.locator('.app.mobile');
    await mobile.getByRole('heading', { name: 'Registrar pagamento', exact: true }).waitFor();
    const source = fs.readFileSync(path.join(base, 'jornada-pagar-integral-zm.html'), 'utf8').match(/<script>([\s\S]*?)<\/script>/)[1];
    await frame.evaluate(source => {
      for (const app of document.querySelectorAll('#zm-payment-integral-journey .app')) app.replaceWith(app.cloneNode(false));
      globalThis.__journeyTweaks = [];
      globalThis.Tweak = class {
        constructor(options) { Object.assign(this, options); this.controls = []; globalThis.__journeyTweaks.push(this); }
        addSelect(object, property, options) { this.controls.push({ object, property, options }); }
        addSlider(object, property, options) { this.controls.push({ object, property, options }); }
      };
      (0, eval)(source);
    }, source);
    await frame.evaluate(() => {
      globalThis.__journeySaved = [];
      const host = window.openai || {};
      window.openai = { ...host, setWidgetState(value) { globalThis.__journeySaved.push(value); return Promise.resolve(); } };
    });
    const compact = text => text.replaceAll('\u00a0', ' ');
    const text = async locator => compact(await locator.innerText());
    const show = async device => frame.evaluate(device => { for (const section of document.querySelectorAll('[data-variant]')) section.hidden = section.querySelector('.app').dataset.device !== device; }, device);
    const audit = async (label, device = 'mobile') => {
      for (const width of [780, 412, 360, 320]) {
        await page.setViewportSize({ width, height: 1800 });
        await frame.waitForFunction(expected => innerWidth === expected - 32, width);
        const measurement = await frame.evaluate(({ label, device }) => {
          const app = document.querySelector('.app.' + device), rect = app.getBoundingClientRect();
          const overflow = document.documentElement.scrollWidth > innerWidth + 1;
          const controlsOutside = [...app.querySelectorAll('button,input,select,textarea')].filter(el => {
            if (!el.getClientRects().length) return false;
            const box = el.getBoundingClientRect();
            return box.left < rect.left - 1 || box.right > rect.right + 1;
          }).map(el => el.getAttribute('aria-label') || el.textContent.trim());
          return { label, device, width: innerWidth, overflow, controlsOutside };
        }, { label, device });
        assert.equal(measurement.overflow, false, JSON.stringify(measurement));
        assert.deepEqual(measurement.controlsOutside, [], JSON.stringify(measurement));
        layouts.push(measurement);
      }
      await page.setViewportSize({ width: 780, height: 1800 });
      await frame.waitForFunction(() => innerWidth === 748);
    };
    const fill = async (app, amount, method = 'PIX') => {
      await app.getByRole('radio', { name: 'Parcial', exact: true }).check();
      await app.getByRole('textbox', { name: 'Quanto você pagou?', exact: true }).fill(amount);
      await app.getByLabel('Data do pagamento', { exact: true }).fill('2026-10-16');
      await app.getByLabel('Como você pagou?', { exact: true }).selectOption(method);
    };
    const confirm = async app => {
      await app.getByRole('button', { name: 'Confirmar registro', exact: true }).click();
      await app.getByRole('heading', { name: 'Pagamento registrado', exact: true }).first().waitFor();
    };

    assert.equal(await mobile.getByRole('radio', { name: 'Integral', exact: true }).isChecked(), true);
    assert.equal(await mobile.getByRole('textbox', { name: 'Quanto você pagou?', exact: true }).count(), 0);
    assert.equal(await mobile.locator('[data-field=amount]').isDisabled(), true);
    assert.equal(await text(mobile.locator('[data-remaining]')), 'R$ 0,00');
    await mobile.getByRole('radio', { name: 'Integral', exact: true }).focus();
    await page.keyboard.press('Tab');
    assert.equal(await frame.evaluate(() => document.activeElement.dataset.field), 'date');
    await audit('integral_inicial');
    await mobile.screenshot({ path: path.join(base, 'integral-padrao-mobile.png') });
    const geometry = await mobile.evaluate(app => ({ panel: getComputedStyle(app.querySelector('.form-panel')).borderRadius, field: getComputedStyle(app.querySelector('[data-field=date]')).borderRadius, primary: getComputedStyle(app.querySelector('.primary')).borderRadius }));
    assert.equal(geometry.panel, '32px');assert.equal(geometry.field, '28px');assert.equal(geometry.primary, '999px');
    await mobile.getByLabel('Como você pagou?', { exact: true }).selectOption('PIX');
    await mobile.getByRole('button', { name: 'Revisar pagamento', exact: true }).click();
    assert.equal(await text(mobile.locator('.review-list')).then(v => v.includes('R$ 680,00')), true);
    await confirm(mobile);
    await mobile.getByRole('button', { name: 'Ver conta e histórico', exact: true }).click();
    assert.equal(await text(mobile.locator('[data-balance]')), 'R$ 0,00');
    assert.equal(await mobile.locator('.history-entry').count(), 2);
    tests.push('integral selecionado por padrão, campo de valor oculto/inativo e quitação sem digitar; painéis 32, campos 28 e botões cápsula');

    await mobile.getByRole('button', { name: 'Recomeçar exemplo', exact: true }).click();
    await page.emulateMedia({ reducedMotion: 'no-preference' });
    const closed = await mobile.locator('.partial-reveal').evaluate(el => el.getBoundingClientRect().height);
    assert.equal(closed, 0);
    await mobile.getByRole('radio', { name: 'Parcial', exact: true }).check();
    await frame.waitForFunction(() => document.querySelector('.app.mobile .partial-reveal').getBoundingClientRect().height > 100);
    assert.match(await mobile.locator('.partial-reveal').evaluate(el => getComputedStyle(el).transitionDuration), /0\.26s/);
    assert.equal(await mobile.locator('[data-field=amount]').isDisabled(), false);
    await mobile.getByRole('radio', { name: 'Parcial', exact: true }).focus();
    await page.keyboard.press('Tab');
    assert.equal(await frame.evaluate(() => document.activeElement.dataset.field), 'amount');
    await mobile.getByRole('textbox', { name: 'Quanto você pagou?', exact: true }).fill('999');
    await mobile.getByLabel('Como você pagou?', { exact: true }).selectOption('PIX');
    await mobile.getByRole('button', { name: 'Revisar pagamento', exact: true }).click();
    assert.equal(await mobile.locator('[data-field=amount][aria-invalid=true]').count(), 1);
    await mobile.getByRole('radio', { name: 'Integral', exact: true }).check();
    await frame.waitForFunction(() => document.querySelector('.app.mobile .partial-reveal').getBoundingClientRect().height === 0);
    assert.equal(await mobile.locator('.error-box').count(), 0);
    await mobile.getByRole('button', { name: 'Revisar pagamento', exact: true }).click();
    assert.equal(await text(mobile.locator('.review-list')).then(v => v.includes('R$ 680,00') && !v.includes('R$ 999,00')), true);
    await mobile.getByRole('button', { name: 'Voltar aos dados', exact: true }).click();
    await mobile.getByRole('radio', { name: 'Parcial', exact: true }).check();
    assert.equal(await mobile.getByRole('textbox', { name: 'Quanto você pagou?', exact: true }).inputValue(), '999,00');
    await page.emulateMedia({ reducedMotion: 'reduce' });
    assert.equal(await mobile.locator('.partial-reveal').evaluate(el => getComputedStyle(el).transitionDuration), '0s');
    await audit('parcial_revelado');
    tests.push('campo parcial expande/recolhe com transição de altura; valor anterior preservado, mas ignorado no integral; redução de movimento sem transição');
    await mobile.getByRole('button', { name: 'Recomeçar exemplo', exact: true }).click();
    await mobile.getByRole('button', { name: 'Voltar', exact: true }).click();
    await mobile.getByRole('button', { name: 'Voltar', exact: true }).click();
    assert.equal(await text(mobile.locator('[data-total]')), 'R$ 1.280,00');
    await audit('lista');
    await mobile.screenshot({ path: path.join(base, 'integral-lista-mobile.png') });
    await mobile.getByRole('button', { name: /Fornecedor de alimentos/ }).click();
    assert.equal(await text(mobile.locator('[data-balance]')), 'R$ 680,00');
    await mobile.screenshot({ path: path.join(base, 'integral-detalhe-mobile.png') });
    await mobile.getByRole('button', { name: 'Registrar pagamento', exact: true }).click();
    await mobile.getByRole('radio', { name: 'Parcial', exact: true }).check();
    await mobile.getByRole('button', { name: 'Revisar pagamento', exact: true }).click();
    assert.equal(await mobile.locator('[aria-invalid=true]').count(), 2);
    assert.equal(await mobile.locator('[data-field=amount]').evaluate(el => el === document.activeElement), true);
    await mobile.getByLabel('Como você pagou?', { exact: true }).selectOption('PIX');
    for (const invalid of ['0', '-1', '681', '300.50', 'valor inválido']) {
      await mobile.getByRole('textbox', { name: 'Quanto você pagou?', exact: true }).fill(invalid);
      await mobile.getByRole('button', { name: 'Revisar pagamento', exact: true }).click();
      assert.equal(await mobile.locator('[data-field=amount][aria-invalid=true]').count(), 1);
      assert.equal(await mobile.getByRole('heading', { name: 'Registrar pagamento', exact: true }).count(), 1);
    }
    await audit('validacao');
    tests.push('valor vazio, zero, negativo, acima do saldo e formato ambíguo não avançam; foco e mensagens de erro');

    await fill(mobile, '300');
    await mobile.getByLabel('Observação (opcional)').fill('Pedido <exemplo> 25');
    await mobile.locator('[data-area=inicio]').click();
    await mobile.locator('[data-area=financeiro]').click();
    assert.equal(await mobile.getByRole('textbox', { name: 'Quanto você pagou?', exact: true }).inputValue(), '300,00');
    assert.equal(await mobile.getByLabel('Como você pagou?', { exact: true }).inputValue(), 'PIX');
    assert.equal(await mobile.getByLabel('Observação (opcional)').inputValue(), 'Pedido <exemplo> 25');
    assert.equal(await mobile.locator('.error-box').count(), 0, 'erro antigo deve desaparecer depois de corrigir e sair do campo');
    assert.equal(await mobile.locator('[aria-invalid=true]').count(), 0);
    await audit('formulario');
    await mobile.screenshot({ path: path.join(base, 'integral-formulario-mobile.png') });
    await mobile.getByRole('button', { name: 'Revisar pagamento', exact: true }).click();
    assert.equal(await text(mobile.locator('.review-list').first()).then(v => v.includes('R$ 300,00')), true);
    assert.equal(await text(mobile.locator('.entry-summary strong')), 'R$ 380,00');
    await mobile.getByRole('button', { name: 'Alterar valor pago', exact: true }).click();
    assert.equal(await mobile.getByRole('textbox', { name: 'Quanto você pagou?', exact: true }).inputValue(), '300,00');
    await mobile.getByRole('textbox', { name: 'Quanto você pagou?', exact: true }).fill('250');
    await mobile.getByRole('button', { name: 'Revisar pagamento', exact: true }).click();
    assert.equal(await text(mobile.locator('.entry-summary strong')), 'R$ 430,00');
    await mobile.getByRole('button', { name: 'Voltar aos dados', exact: true }).click();
    await fill(mobile, '300');
    await mobile.getByRole('button', { name: 'Revisar pagamento', exact: true }).click();
    await audit('conferencia');
    await mobile.screenshot({ path: path.join(base, 'integral-conferencia-mobile.png') });
    await mobile.locator('[data-action=confirm]').evaluate(button => { button.click(); button.click(); });
    assert.equal(await mobile.locator('[data-action=confirm]').isDisabled(), true);
    assert.equal(await mobile.locator('[data-area=inicio]').isDisabled(), true);
    await mobile.getByRole('heading', { name: 'Pagamento registrado', exact: true }).first().waitFor();
    await audit('conclusao');
    await mobile.getByRole('button', { name: 'Ver conta e histórico', exact: true }).click();
    assert.equal(await text(mobile.locator('[data-balance]')), 'R$ 380,00');
    assert.equal(await mobile.locator('.history-entry').count(), 2);
    assert.equal(await text(mobile.locator('.history')).then(v => v.includes('Pedido <exemplo> 25')), true);
    await mobile.screenshot({ path: path.join(base, 'integral-historico-mobile.png') });
    await mobile.getByRole('button', { name: 'Voltar', exact: true }).click();
    assert.equal(await text(mobile.locator('[data-total]')), 'R$ 980,00');
    tests.push('rascunho preservado ao alternar áreas; revisão editável; clique repetido gera um registro; 680 − 300 = 380; total 1.280 − 300 = 980');

    await mobile.locator('[data-filter]').selectOption('partial');
    await mobile.getByRole('button', { name: /Fornecedor de alimentos/ }).click();
    await mobile.getByRole('button', { name: 'Registrar pagamento', exact: true }).click();
    assert.equal(await mobile.getByRole('radio', { name: 'Integral', exact: true }).isChecked(), true);
    assert.equal(await text(mobile.locator('[data-mode-caption]')).then(value => value.includes('R$ 380,00')), true);
    await mobile.getByLabel('Como você pagou?', { exact: true }).selectOption('DINHEIRO');
    await mobile.getByRole('button', { name: 'Revisar pagamento', exact: true }).click();
    const tweakCount = await frame.evaluate(() => globalThis.__journeyTweaks?.length || 0);
    assert.equal(tweakCount, 2, 'painel de ajustes simulado deve estar ligado aos dois exemplos');
    await frame.evaluate(() => { const tweak = __journeyTweaks.find(t => t.container.dataset.device === 'mobile'); tweak.controls[0].object.scenario = 'failure'; tweak.onChange(); });
    await mobile.getByRole('button', { name: 'Confirmar registro', exact: true }).click();
    await mobile.getByRole('heading', { name: 'Não foi possível registrar', exact: true }).waitFor();
    assert.equal(await text(mobile.locator('.review-list')).then(v => v.includes('R$ 380,00') && v.includes('Dinheiro')), true);
    await audit('falha');
    await mobile.screenshot({ path: path.join(base, 'integral-falha-mobile.png') });
    await confirm(mobile);
    await mobile.getByRole('button', { name: 'Ver conta e histórico', exact: true }).click();
    assert.equal(await text(mobile.locator('[data-balance]')), 'R$ 0,00');
    assert.equal(await mobile.locator('.history-entry').count(), 3);
    assert.equal(await mobile.getByRole('button', { name: 'Registrar pagamento', exact: true }).count(), 0);
    await mobile.getByRole('button', { name: 'Voltar', exact: true }).click();
    assert.equal(await mobile.locator('[data-filter]').inputValue(), 'partial');
    assert.equal(await text(mobile.locator('[data-total]')), 'R$ 600,00');
    assert.equal(await mobile.locator('.result-message').count(), 1);
    await mobile.locator('[data-area=inicio]').click();
    assert.equal(await text(mobile.locator('[data-go="financeiro:pagar"] .title')), '1 conta a pagar');
    await mobile.locator('[data-area=financeiro]').click();
    tests.push('falha anterior à gravação mantém os dados e permite nova tentativa; quitação só uma vez; filtro preservado; estado sem resultados');

    const saved = await frame.evaluate(() => __journeySaved.at(-1));
    await mobile.getByRole('button', { name: 'Recomeçar exemplo', exact: true }).click();
    assert.equal(await mobile.getByRole('radio', { name: 'Integral', exact: true }).isChecked(), true);
    await frame.evaluate(saved => window.dispatchEvent(new CustomEvent('openai:set_globals', { detail: { globals: { widgetState: saved } } })), saved);
    assert.equal(await text(mobile.locator('[data-total]')), 'R$ 600,00');
    await frame.evaluate(() => { const tweak = __journeyTweaks.find(t => t.container.dataset.device === 'mobile'); tweak.controls[0].object.appearance = 'dark'; tweak.onChange(); });
    assert.equal(await mobile.evaluate(el => getComputedStyle(el).colorScheme), 'dark');
    await mobile.getByRole('button', { name: 'Recomeçar exemplo', exact: true }).click();
    await frame.evaluate(() => { const tweak = __journeyTweaks.find(t => t.container.dataset.device === 'mobile'); Object.assign(tweak.controls[0].object, { appearance: 'chat', scenario: 'normal' }); tweak.onChange(); });
    tests.push('estado restaurado sem recriar vínculo dos ajustes; dados e filtro restaurados; aparência continua ajustável');

    await show('desktop');
    const desktop = frame.locator('.app.desktop');
    await desktop.getByRole('button', { name: /Fornecedor de alimentos/ }).click();
    await audit('detalhe', 'desktop');
    await desktop.getByRole('button', { name: 'Registrar pagamento', exact: true }).click();
    await fill(desktop, '300');
    await audit('formulario', 'desktop');
    await desktop.screenshot({ path: path.join(base, 'integral-formulario-desktop.png') });
    await desktop.getByRole('button', { name: 'Revisar pagamento', exact: true }).click();
    await confirm(desktop);
    await desktop.getByRole('button', { name: 'Ver conta e histórico', exact: true }).click();
    await desktop.screenshot({ path: path.join(base, 'integral-historico-desktop.png') });
    await page.emulateMedia({ colorScheme: 'dark' });
    await desktop.screenshot({ path: path.join(base, 'integral-historico-desktop-escuro.png') });
    await page.emulateMedia({ colorScheme: 'light' });
    await show('mobile');
    assert.deepEqual(errors, []);
    tests.push('mesmo percurso no desktop; lista contextual em largura ampla e refluência no estreito; temas claro e escuro');
    const report = { date: '2026-10-16', result: 'passed', scope: 'Prévia de planejamento; sem API, banco ou aplicativo Flutter', browser: 'Edge headless', tests, layouts, javascriptErrors: errors, notes: 'Ajustes simulados pelo contrato Tweak; não automatiza o painel nativo do chat.' };
    fs.writeFileSync(path.join(base, 'pagamento-integral-verificacao.json'), JSON.stringify(report, null, 2) + '\n');
    console.log(JSON.stringify({ result: report.result, journeys: tests.length, layouts: layouts.length, javascriptErrors: errors }));
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
