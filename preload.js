const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('lp5Telemetry', {
  platform: process.platform,
  onUpdate(callback) {
    ipcRenderer.on('telemetry', (_event, payload) => callback(payload));
  },
  checkForUpdates() {
    return ipcRenderer.invoke('update:check');
  },
  getUpdatePreferences() {
    return ipcRenderer.invoke('update:preferences');
  },
  setAutomaticUpdates(automatic) {
    return ipcRenderer.invoke('update:set-automatic', Boolean(automatic));
  },
});
