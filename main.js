const { app, BrowserWindow, dialog, ipcMain, shell } = require('electron');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { compareVersions, eligibleStableRelease } = require('./updater');

const RELEASES_API = 'https://api.github.com/repos/rdcstout/lp5-live-telemetry/releases/latest';
const RELEASES_PAGE = 'https://github.com/rdcstout/lp5-live-telemetry/releases/latest';
const UPDATE_INTERVAL_MS = 7 * 24 * 60 * 60 * 1000;

const FIELDS = ['w_state', 'rate', 'laser', 'speed', 'error', 'name', 'temp', 'print_times', 'u_b_cnn', 'stop', 'safe_key', 'cover'];
const RECORD_PATTERN = /\[(\d{4}-\d{1,2}-\d{1,2} \d{2}:\d{2}:\d{2})\] \[info\]\s+\[\s*'WorkStatusResult',\s*\{([\s\S]*?)\n  \}\s*\]/g;

function platformPaths() {
  if (process.platform === 'win32') {
    return {
      logsRoot: path.join(app.getPath('appData'), 'laserpecker_design_spaces', 'logs', 'web'),
    };
  }
  return {
    logsRoot: path.join(os.homedir(), 'Library', 'Application Support', 'laserpecker_design_spaces', 'logs', 'web'),
  };
}

function integerField(field, text) {
  const match = text.match(new RegExp(`\\b${field}:\\s*(-?\\d+)`));
  return match ? Number(match[1]) : null;
}

function newestLogDirectory(logsRoot) {
  const candidates = fs.readdirSync(logsRoot, { withFileTypes: true })
    .filter(entry => entry.isDirectory())
    .map(entry => path.join(logsRoot, entry.name))
    .filter(directory => fs.existsSync(path.join(directory, 'info.log')))
    .map(directory => ({ directory, modified: fs.statSync(path.join(directory, 'info.log')).mtimeMs }));
  if (!candidates.length) throw new Error('No LaserPecker Design Space telemetry log was found.');
  candidates.sort((a, b) => b.modified - a.modified);
  return candidates[0].directory;
}

function statePath() {
  return path.join(app.getPath('userData'), 'slice-state.json');
}

function loadSliceMap() {
  const values = {};
  // Load the writable cache first, then let verified anchors shipped with the
  // app correct any conflicting IDs left by an earlier unanchored session.
  for (const file of [statePath(), path.join(__dirname, 'seed-slice-state.json')]) {
    try {
      const parsed = JSON.parse(fs.readFileSync(file, 'utf8'));
      if (parsed.slice_by_job_id) Object.assign(values, parsed.slice_by_job_id);
    } catch (_) {}
  }
  return values;
}

function saveSliceMap(values) {
  fs.mkdirSync(path.dirname(statePath()), { recursive: true });
  fs.writeFileSync(statePath(), `${JSON.stringify({ slice_by_job_id: values }, null, 2)}\n`);
}

function updateStatePath() {
  return path.join(app.getPath('userData'), 'update-state.json');
}

function loadUpdateState() {
  try { return { automatic: true, ...JSON.parse(fs.readFileSync(updateStatePath(), 'utf8')) }; }
  catch (_) { return { automatic: true, lastAutomaticAttempt: 0, notifiedVersion: null }; }
}

function saveUpdateState(state) {
  fs.mkdirSync(path.dirname(updateStatePath()), { recursive: true });
  fs.writeFileSync(updateStatePath(), `${JSON.stringify(state, null, 2)}\n`);
}

async function latestEligibleRelease() {
  const response = await fetch(RELEASES_API, {
    headers: { Accept: 'application/vnd.github+json', 'User-Agent': `LP5-Live-Telemetry/${app.getVersion()}` },
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw new Error(`GitHub returned ${response.status}.`);
  return eligibleStableRelease(await response.json());
}

async function checkForUpdates(window, manual) {
  const state = loadUpdateState();
  if (!manual) {
    if (!state.automatic || Date.now() - Number(state.lastAutomaticAttempt || 0) < UPDATE_INTERVAL_MS) return;
    state.lastAutomaticAttempt = Date.now();
    saveUpdateState(state);
  }
  try {
    const release = await latestEligibleRelease();
    const current = app.getVersion();
    if (compareVersions(release.version, current) <= 0) {
      if (manual) await dialog.showMessageBox(window, { type: 'info', title: 'LP5 Live Telemetry', message: `LP5 Live Telemetry ${current} is up to date.`, buttons: ['OK'] });
      return { status: 'current', version: current };
    }
    if (!manual && state.notifiedVersion === release.version) return { status: 'dismissed', version: release.version };
    const result = await dialog.showMessageBox(window, {
      type: 'info', title: 'Update available', message: `LP5 Live Telemetry ${release.version} is available.`,
      detail: `You are using ${current}. Downloading and installation remain under your control.`,
      buttons: ['Download Update', 'Later'], defaultId: 0, cancelId: 1,
    });
    state.notifiedVersion = release.version;
    saveUpdateState(state);
    if (result.response === 0) await shell.openExternal(release.url || RELEASES_PAGE);
    return { status: 'available', version: release.version };
  } catch (error) {
    if (manual) await dialog.showMessageBox(window, { type: 'warning', title: 'Unable to check for updates', message: 'LP5 Live Telemetry could not check for updates.', detail: error.message, buttons: ['OK'] });
    return { status: 'unknown', message: error.message };
  }
}

function allRecords(logDirectory) {
  const text = ['info.old.log', 'info.log']
    .map(name => path.join(logDirectory, name))
    .filter(fs.existsSync)
    .map(file => fs.readFileSync(file, 'utf8'))
    .join('');
  return [...text.matchAll(RECORD_PATTERN)].map(match => {
    const values = { timestamp: match[1] };
    for (const field of FIELDS) values[field] = integerField(field, match[2]);
    return values;
  });
}

function sliceProgress(records, range) {
  if (!range || !records.length) return { slice_available: false };
  const names = [];
  for (const record of records) {
    if (record.name !== null && names.at(-1) !== record.name) names.push(record.name);
  }
  if (!names.length) return { slice_available: false };

  const saved = loadSliceMap();
  let baseSlice = range[0];
  for (let index = names.length - 1; index >= 0; index -= 1) {
    if (saved[String(names[index])] !== undefined) {
      baseSlice = Number(saved[String(names[index])]) - index;
      break;
    }
  }
  const currentSlice = baseSlice + names.length - 1;
  const recent = {};
  const first = Math.max(0, names.length - 128);
  for (let index = first; index < names.length; index += 1) recent[String(names[index])] = baseSlice + index;
  saveSliceMap(recent);

  const rate = Math.max(0, Math.min(100, Number(records.at(-1).rate) || 0));
  const total = Math.max(1, range[1] - range[0] + 1);
  const overall = ((currentSlice - range[0]) + rate / 100) / total * 100;
  return {
    slice_available: true,
    slice_current: String(currentSlice),
    slice_range: `${range[0]}–${range[1]}`,
    overall_value: Math.round(overall * 100) / 100,
    overall_text: `${overall.toFixed(1)}%`,
  };
}

function latestTelemetry() {
  const locations = platformPaths();
  const directory = newestLogDirectory(locations.logsRoot);
  const records = allRecords(directory);
  if (!records.length) throw new Error('Waiting for an LP5 telemetry record…');
  const latest = records.at(-1);
  // LDS generates 3D emboss slices across the 8-bit height range, 0–255.
  // Keeping this inside the monitor avoids requesting access to Documents.
  return { ...latest, ...sliceProgress(records, [0, 255]) };
}

function createWindow() {
  const window = new BrowserWindow({
    width: 940,
    height: 720,
    minWidth: 720,
    minHeight: 560,
    icon: process.platform === 'win32' ? path.join(__dirname, 'assets', 'icon.ico') : undefined,
    backgroundColor: '#080b10',
    title: 'LP5 Live Telemetry',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });
  window.setAspectRatio(940 / 720);
  window.setMenuBarVisibility(false);
  window.webContents.setWindowOpenHandler(({ url }) => {
    if (url === 'https://extrusiontherapy.com/') shell.openExternal(url);
    return { action: 'deny' };
  });
  window.loadFile(path.join(__dirname, 'index.html'));
  const send = () => {
    try { window.webContents.send('telemetry', { ok: true, data: latestTelemetry() }); }
    catch (error) { window.webContents.send('telemetry', { ok: false, message: error.message }); }
  };
  window.webContents.once('did-finish-load', send);
  const timer = setInterval(send, 1000);
  window.on('closed', () => clearInterval(timer));
  setTimeout(() => checkForUpdates(window, false), 15000);
  const updateTimer = setInterval(() => checkForUpdates(window, false), 60 * 60 * 1000);
  window.on('closed', () => clearInterval(updateTimer));
}

app.whenReady().then(() => {
  if (process.argv.includes('--self-test')) {
    try { process.stdout.write(`${JSON.stringify(latestTelemetry(), null, 2)}\n`); app.exit(0); }
    catch (error) { process.stderr.write(`${error.message}\n`); app.exit(1); }
    return;
  }
  ipcMain.handle('update:check', event => checkForUpdates(BrowserWindow.fromWebContents(event.sender), true));
  ipcMain.handle('update:preferences', () => ({ automatic: loadUpdateState().automatic !== false }));
  ipcMain.handle('update:set-automatic', (_event, automatic) => {
    const state = loadUpdateState();
    state.automatic = Boolean(automatic);
    saveUpdateState(state);
    return { automatic: state.automatic };
  });
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});

app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });

module.exports = { allRecords, integerField, sliceProgress };
