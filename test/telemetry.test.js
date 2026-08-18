const test = require('node:test');
const assert = require('node:assert/strict');

test('approved interface is generated with clear progress labels', () => {
  const html = require('node:fs').readFileSync(require('node:path').join(__dirname, '..', 'index.html'), 'utf8');
  assert.match(html, /Calculated overall progress/);
  assert.match(html, /Current slice progress/);
  assert.match(html, /An <a[^>]+>Extrusion Therapy<\/a> workshop tool/);
  assert.match(html, /href="https:\/\/extrusiontherapy\.com\/"/);
  assert.match(html, /\.sub a \{ color: inherit; text-decoration: none; \}/);
  assert.match(html, /overflow: hidden/);
  assert.match(html, /zoom: var\(--ui-scale\)/);
  assert.match(html, /const windows = window\.lp5Telemetry\?\.platform === 'win32'/);
  assert.match(html, /const pagePad = windows \? 12 : 28/);
  assert.match(html, /2:'ACTIVE'/);
  assert.match(html, /4:'PAUSED'/);
  assert.doesNotMatch(html, /More device telemetry|Slice state|ADVANCING/);
});

test('desktop window preserves its layout ratio and avoids Documents access', () => {
  const source = require('node:fs').readFileSync(require('node:path').join(__dirname, '..', 'main.js'), 'utf8');
  assert.match(source, /setAspectRatio\(940 \/ 720\)/);
  assert.match(source, /process\.platform === 'win32'.*assets.*icon\.ico/);
  assert.match(source, /shell\.openExternal\(url\)/);
  assert.match(source, /Object\.assign\(values, parsed\.slice_by_job_id\)/);
  assert.match(source, /\[statePath\(\), path\.join\(__dirname, 'seed-slice-state\.json'\)\]/);
  assert.doesNotMatch(source, /projectRoot|app\.getPath\(['"]documents['"]\)/i);
});

test('Windows packages use the branded application and installer icon', () => {
  const fs = require('node:fs');
  const path = require('node:path');
  const root = path.join(__dirname, '..');
  const manifest = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
  assert.equal(manifest.build.win.icon, 'assets/icon.ico');
  assert.equal(manifest.build.nsis.installerIcon, 'assets/icon.ico');
  assert.equal(manifest.build.nsis.uninstallerIcon, 'assets/icon.ico');
  assert.ok(fs.statSync(path.join(root, 'assets', 'icon.ico')).size > 1024);
});
