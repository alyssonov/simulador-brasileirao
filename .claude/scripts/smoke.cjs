// Abre <dir>/index.html num servidor local e falha se houver erro de JS na página.
// Requisições externas são bloqueadas (CDNs, fontes, Supabase) para não dar falso vermelho.
const http = require('http'), fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const dir = path.resolve(process.argv[2] || '.');
// Cópias fixas de APIs externas: .claude/fixtures/routes.json mapeia prefixo de URL → arquivo.
const fxDir = path.resolve('.claude/fixtures');
const fixtures = fs.existsSync(path.join(fxDir, 'routes.json'))
  ? Object.entries(JSON.parse(fs.readFileSync(path.join(fxDir, 'routes.json'), 'utf8'))) : [];
const types = { '.html':'text/html', '.js':'text/javascript', '.css':'text/css', '.png':'image/png',
  '.jpg':'image/jpeg', '.svg':'image/svg+xml', '.json':'application/json', '.webp':'image/webp' };
const srv = http.createServer((req, res) => {
  let p = path.join(dir, decodeURIComponent(req.url.split('?')[0]));
  if (p.endsWith(path.sep)) p = path.join(p, 'index.html');
  fs.readFile(p, (e, b) => { if (e) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { 'content-type': types[path.extname(p)] || 'application/octet-stream' }); res.end(b); });
});
srv.listen(0, async () => {
  const base = `http://127.0.0.1:${srv.address().port}/`;
  const browser = await chromium.launch(); const errors = [];
  for (const vp of [{ width: 1280, height: 800 }, { width: 390, height: 844 }]) {
    const page = await browser.newPage({ viewport: vp });
    await page.route('**/*', r => {
      const u = r.request().url();
      if (u.startsWith(base)) return r.continue();
      const fx = fixtures.find(([prefix]) => u.startsWith(prefix));
      if (fx) { console.log(`[${vp.width}px] cópia fixa: ${fx[1]}`);
        return r.fulfill({ status: 200, contentType: 'application/json', body: fs.readFileSync(path.join(fxDir, fx[1])),
          headers: { 'access-control-allow-origin': '*' } }); }
      return r.abort();
    });
    page.on('pageerror', e => errors.push(`[${vp.width}px] pageerror: ${e.message}`));
    page.on('console', m => { if (m.type() === 'error' && !/Failed to load resource|net::ERR/.test(m.text()))
      errors.push(`[${vp.width}px] console.error: ${m.text()}`); });
    await page.goto(base + 'index.html', { waitUntil: 'load' });
    await page.waitForTimeout(1500);
    console.log(`[${vp.width}px] título: ${await page.title()} | elementos no body: ${await page.locator('body *').count()}`);
    await page.close();
  }
  await browser.close(); srv.close();
  if (errors.length) { console.log(errors.join('\n')); process.exit(1); }
  console.log('sem erros de JS');
});
