const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('lp5Telemetry', {
  platform: process.platform,
  onUpdate(callback) {
    ipcRenderer.on('telemetry', (_event, payload) => callback(payload));
  },
});
