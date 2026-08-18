const { app, BrowserWindow, shell } = require('electron');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

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
}

app.whenReady().then(() => {
  if (process.argv.includes('--self-test')) {
    try { process.stdout.write(`${JSON.stringify(latestTelemetry(), null, 2)}\n`); app.exit(0); }
    catch (error) { process.stderr.write(`${error.message}\n`); app.exit(1); }
    return;
  }
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});

app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });

module.exports = { allRecords, integerField, sliceProgress };
