const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
if (!process.env.PLAYWRIGHT_BROWSERS_PATH) process.env.PLAYWRIGHT_BROWSERS_PATH = 'C:/Users/jardi/AppData/Local/ms-playwright';
const { chromium, webkit, devices } = require(process.env.PLAYWRIGHT_MODULE || 'C:/Users/jardi/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const base = process.env.PREVIEW_DIR || __dirname;
const fileUrl = name => 'file:///' + path.join(base, name).replaceAll('\\', '/');

async function measure(frame, forcedBoxSizing, fontSize) {
  return frame.evaluate(({ forcedBoxSizing, fontSize }) => {
    const app = document.querySelector('.app.mobile');
    const input = app.querySelector('[data-field=date]');
    input.style.boxSizing = forcedBoxSizing ? 'content-box' : '';
    input.style.fontSize = fontSize + 'px';
    const outer = input.closest('.date-control') || input;
    const reference = app.querySelector('.select-wrap');
    const field = input.closest('.field');
    const rect = el => { const r = el.getBoundingClientRect(); return { left: r.left, right: r.right, width: r.width, height: r.height }; };
    const date = rect(outer), ref = rect(reference), parent = rect(field), inner = rect(input);
    return {
      width: innerWidth, fontSize, forcedBoxSizing,
      date, reference: ref, field: parent, input: inner,
      aligned: Math.abs(date.left - ref.left) < 1 && Math.abs(date.right - ref.right) < 1,
      fitsField: date.left >= parent.left - 1 && date.right <= parent.right + 1,
      inputContained: inner.left >= date.left - 1 && inner.right <= date.right + 1,
      declaredType: input.getAttribute('type'), inputType: input.type,
      inputPadding: getComputedStyle(input).padding,
      documentOverflow: document.documentElement.scrollWidth > innerWidth + 1
    };
  }, { forcedBoxSizing, fontSize });
}

async function runEngine(engine) {
  const browser = engine === 'webkit' ? await webkit.launch({ headless: true }) : await chromium.launch({ channel: 'msedge', headless: true });
  const errors = [];
  try {
    const context = await browser.newContext({
      locale: 'pt-BR', viewport: { width: 390, height: 1800 },
      isMobile: true, hasTouch: true, deviceScaleFactor: 1,
      ...(engine === 'webkit' ? { userAgent: devices['iPhone 13'].userAgent } : {}),
      colorScheme: 'dark', reducedMotion: 'reduce'
    });
    const page = await context.newPage();
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(fileUrl('jornada-pagar-integral-zm-preview.html'));
    let frame = page.frames().find(item => item.parentFrame());
    await frame.locator('.app.mobile [data-field=date]').waitFor();
    const nativeBefore = await measure(frame, false, 16);
    const stressBefore = await measure(frame, true, 16);
    assert.equal(stressBefore.aligned, false, 'a condição de estresse deve detectar o excesso dentro do painel antigo');

    await page.goto(fileUrl('jornada-pagar-data-alinhada-zm-preview.html'));
    frame = page.frames().find(item => item.parentFrame());
    const app = frame.locator('.app.mobile');
    await app.getByRole('heading', { name: 'Registrar pagamento', exact: true }).waitFor();
    await frame.evaluate(() => {
      const host = window.openai || {};
      window.openai = { ...host, setWidgetState() { return Promise.resolve(); } };
    });
    const cases = [];
    for (const mode of ['Integral', 'Parcial']) {
      await app.getByRole('radio', { name: mode, exact: true }).check();
      for (const width of [320, 360, 390, 412]) {
        await page.setViewportSize({ width, height: 1800 });
        await frame.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
        for (const fontSize of [16, 20]) for (const forcedBoxSizing of [false, true]) {
          const result = { engine, mode, ...await measure(frame, forcedBoxSizing, fontSize) };
          assert.equal(result.aligned, true, JSON.stringify(result));
          assert.equal(result.fitsField, true, JSON.stringify(result));
          assert.equal(result.inputContained, true, JSON.stringify(result));
          assert.equal(result.documentOverflow, false, JSON.stringify(result));
          assert.equal(result.declaredType, 'date');
          if (engine === 'edge') assert.equal(result.inputType, 'date');
          assert.ok(result.date.height >= 56 && result.input.width > 80, JSON.stringify(result));
          cases.push(result);
        }
      }
    }
    await page.setViewportSize({ width: 390, height: 1800 });
    await measure(frame, false, 16);
    await app.getByLabel('Data do pagamento', { exact: true }).fill('');
    const emptyDate = await measure(frame, false, 16);
    assert.equal(emptyDate.aligned, true);assert.ok(emptyDate.date.height >= 56);
    await app.getByLabel('Data do pagamento', { exact: true }).fill('2026-10-16');
    await app.getByRole('radio', { name: 'Integral', exact: true }).check();
    await app.screenshot({ path: path.join(base, `data-${engine}-integral.png`) });
    await app.getByRole('radio', { name: 'Parcial', exact: true }).check();
    await app.getByRole('textbox', { name: 'Quanto você pagou?', exact: true }).fill('300');
    await app.getByLabel('Como você pagou?', { exact: true }).selectOption('DINHEIRO');
    await app.getByLabel('Data do pagamento', { exact: true }).fill('2026-11-02');
    await app.screenshot({ path: path.join(base, `data-${engine}-parcial.png`) });
    await app.getByRole('button', { name: 'Revisar pagamento', exact: true }).click();
    const pageState = await app.locator('.page-title').innerText();
    assert.equal(pageState, 'Conferir pagamento', JSON.stringify({ engine, pageState, errors: await app.locator('.error-box').allTextContents() }));
    const review = await app.locator('.review-list').innerText();
    assert.match(review, /02 de novembro de 2026/);
    assert.match(review.replaceAll('\u00a0', ' '), /R\$ 300,00/);
    await app.getByRole('button', { name: 'Alterar data do pagamento', exact: true }).click();
    assert.equal(await app.getByLabel('Data do pagamento', { exact: true }).inputValue(), '2026-11-02');
    assert.equal(await app.getByRole('radio', { name: 'Parcial', exact: true }).isChecked(), true);
    assert.deepEqual(errors, []);
    return {
      engine,
      profile: engine === 'webkit' ? 'WebKit no Windows, viewport móvel e identificação iPhone; não é um iPhone físico' : 'Edge com viewport móvel',
      nativeDateSupported: cases.every(item => item.inputType === 'date'),
      nativeBefore, stressBefore, cases, emptyDate,
      interaction: 'data selecionada preservada na revisão e ao editar; pagamento parcial mantido',
      javascriptErrors: errors
    };
  } finally { await browser.close(); }
}

(async () => {
  const results = await Promise.allSettled(['edge', 'webkit'].map(runEngine));
  const failed = results.filter(result => result.status === 'rejected');
  if (failed.length) throw new AggregateError(failed.map(result => result.reason), 'Falha na verificação de data');
  const engines = results.map(result => result.value);
  const report = {
    date: '2026-10-16', result: 'passed',
    scope: 'Correção da prévia; sem aplicativo Flutter, API ou banco',
    cases: engines.reduce((total, result) => total + result.cases.length, 0),
    engines,
    limitation: 'WebKit desktop com perfil móvel não reproduz UIKit/Safari no iPhone. Nesta instalação o WebKit apresenta type=date como fallback text; sua cobertura é de layout e fluxo, sem validar o seletor nativo iOS. A condição content-box é estresse explícito, não reprodução comprovada do defeito nativo.'
  };
  fs.writeFileSync(path.join(base, 'data-alinhada-verificacao.json'), JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify({ result: report.result, cases: report.cases, engines: engines.map(result => ({ engine: result.engine, nativeDateSupported: result.nativeDateSupported, nativeBeforeAligned: result.nativeBefore.aligned, stressBeforeAligned: result.stressBefore.aligned, afterAligned: result.cases.every(item => item.aligned) })) }));
})().catch(error => { console.error(error); if (error.errors) for (const detail of error.errors) console.error(detail); process.exitCode = 1; });
