#!/usr/bin/env bash
set -euo pipefail
/usr/bin/time -p bash -c ': "${CAPTURE_URL:?Set CAPTURE_URL and CAPTURE_DIR.}"'
/usr/bin/time -p bash -c ': "${CAPTURE_DIR:?Set CAPTURE_URL and CAPTURE_DIR.}"'
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
/usr/bin/time -p node - <<'NODE'
import { mkdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { createRequire } from 'node:module';
import { homedir, platform } from 'node:os';

const url = process.env.CAPTURE_URL;
const output = process.env.CAPTURE_DIR;
if (!url || !output) { console.error('Set CAPTURE_URL and CAPTURE_DIR.'); process.exit(1); }
try { new URL(url); } catch { console.error(`Invalid CAPTURE_URL: ${url}`); process.exit(1); }
mkdirSync(output, { recursive: true });

const runtime = join(homedir(), '.local/share/omgithub-playwright');
const require = createRequire(join(runtime, 'package.json'));
const { chromium } = require('playwright');
let launchOpts = {};
try {
  const cfgPath = join(runtime, platform() === 'darwin' ? 'metal.json' : 'linux.json');
  const cfg = JSON.parse(readFileSync(cfgPath, 'utf8'));
  launchOpts = cfg.browser?.launchOptions || {};
} catch (e) { console.error('Failed to read playwright config (script defect):', e.message); process.exit(1); }
if (platform() === 'linux') {
  try { process.env.DISPLAY ||= ':' + readFileSync(join(runtime, 'display'), 'utf8').trim(); }
  catch (e) { console.error('Failed to read display (script defect):', e.message); process.exit(1); }
}
const transientStatus = new Set([408, 429, 500, 502, 503, 504]);
const fail = (code, msg) => { console.error(msg); process.exit(code); };

let browser;
try {
  try {
    browser = await chromium.launch({ ...launchOpts, timeout: 30000 });
  } catch (e) { fail(75, `browser launch failed (transient): ${e.message}`); }
  for (const [name, width, height] of [['desktop', 1440, 900], ['mobile', 390, 844]]) {
    let page;
    try {
      page = await browser.newPage({ viewport: { width, height } });
    } catch (e) { fail(75, `newPage ${name} failed (transient): ${e.message}`); }
    page.setDefaultTimeout(30000);
    page.on('pageerror', (e) => console.error(`pageerror ${name}:`, e.message));
    let response;
    try {
      response = await page.goto(url, { waitUntil: 'load', timeout: 45000 });
    } catch (e) { fail(75, `goto ${name} failed (transient): ${e.message}`); }
    if (!response) fail(75, `goto ${name}: no response (transient)`);
    const status = response.status();
    const ok = response.ok();
    if (!ok) {
      if (!status || transientStatus.has(status)) fail(75, `HTTP ${status} loading preview (transient)`);
      else fail(1, `HTTP ${status} loading preview (rendering defect)`);
    }
    try {
      await page.locator('body').waitFor({ state: 'visible', timeout: 30000 });
      await page.waitForFunction(() => document.fonts.status === 'loaded', null, { timeout: 30000 });
    } catch (e) {
      if (!browser.isConnected()) fail(75, `wait ready ${name} lost browser (transient): ${e.message}`);
      fail(1, `wait ready ${name} failed (rendering defect): ${e.message}`);
    }
    await page.waitForTimeout(1000);
    try {
      await page.screenshot({ path: join(output, `final-${name}.png`), timeout: 30000 });
      console.log(`captured final-${name}.png`);
    } catch (e) {
      if (e.name === 'TimeoutError' || !browser.isConnected()) fail(75, `screenshot ${name} failed (transient): ${e.message}`);
      fail(1, `screenshot ${name} failed (script defect): ${e.message}`);
    }
    await page.close().catch(() => {});
  }
} finally {
  try { await browser?.close(); } catch (e) { console.error(`browser close failed: ${e.message}`); process.exitCode ||= 75; }
}
NODE
STATUS=$?
/usr/bin/time -p echo "capture exit: $STATUS"
exit $STATUS
