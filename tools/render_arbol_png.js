// Renderiza docs/arbol_evoluciones.html a docs/arbol_evoluciones.png (full-page, 2x).
// Uso:
//   npm i puppeteer-core   (usa el Chrome del sistema, no descarga Chromium)
//   node tools/render_arbol_png.js
// Requiere Chrome/Chromium instalado. Override con env CHROME_PATH si hace falta.

const path = require('path');
const fs = require('fs');
const puppeteer = require('puppeteer-core');

const REPO = path.resolve(__dirname, '..');
const HTML = path.join(REPO, 'docs', 'arbol_evoluciones.html');
const OUT = path.join(REPO, 'docs', 'arbol_evoluciones.png');

const CHROME_CANDIDATES = [
  process.env.CHROME_PATH,
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
].filter(Boolean);

const chrome = CHROME_CANDIDATES.find(p => { try { return fs.existsSync(p); } catch { return false; } });
if (!chrome) { console.error('No se encontró Chrome. Definí CHROME_PATH.'); process.exit(1); }

(async () => {
  const browser = await puppeteer.launch({
    executablePath: chrome,
    headless: 'new',
    args: ['--no-sandbox', '--force-color-profile=srgb'],
    defaultViewport: { width: 1200, height: 900, deviceScaleFactor: 2 },
  });
  const page = await browser.newPage();
  await page.goto('file:///' + HTML.replace(/\\/g, '/'), { waitUntil: 'networkidle0', timeout: 60000 });
  await page.evaluateHandle('document.fonts.ready');
  await new Promise(r => setTimeout(r, 1500));
  await page.evaluate(() => { if (typeof drawLines === 'function') drawLines(); });
  await new Promise(r => setTimeout(r, 400));
  await page.screenshot({ path: OUT, fullPage: true, type: 'png' });
  await browser.close();
  console.log('OK →', OUT);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
