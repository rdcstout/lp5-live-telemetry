const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, 'LP5LiveTelemetry.swift'), 'utf8');
const match = source.match(/private let dashboardHTML = #"""\n([\s\S]*?)\n"""#/);
if (!match) throw new Error('Could not extract the approved dashboard HTML.');
let html = match[1];
html = html.replace(
  /if \(location\.protocol === 'http:' \|\| location\.protocol === 'https:'\) \{[\s\S]*?\n\}/,
  `if (window.lp5Telemetry) {
  window.lp5Telemetry.onUpdate(payload => {
    if (payload.ok) window.renderTelemetry(payload.data);
    else window.feedLost(payload.message);
  });
}`,
);
fs.writeFileSync(path.join(__dirname, 'index.html'), html);
fs.copyFileSync(path.join(__dirname, 'lp5_slice_state.json'), path.join(__dirname, 'seed-slice-state.json'));
