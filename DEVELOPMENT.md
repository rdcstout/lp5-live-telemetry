# Developing LP5 Live Telemetry

## Prerequisites

Use Node.js 24 and npm 11. The lockfile pins the dependency versions. The Electron app targets Apple-silicon macOS and Windows x64; Linux is used for source checks, not an advertised application target.

Icon generation and the supplied packaging scripts require macOS, zsh, Python 3, and the Apple tools `qlmanage`, `sips`, `iconutil`, and `codesign`. `scripts/make-ico.py` uses the Python standard library. Building a Windows installer from macOS also requires electron-builder's downloaded Windows packaging tools.

## Set up and run

From the repository root:

```sh
npm ci
npm start
```

Dependency installation downloads Electron. Keep LaserPecker Design Space open and connected to the LP5 for live telemetry. The Electron app reads LDS's logs under the current user's application-data directory; it does not control the laser. Starting the application can update its local slice-state cache.

`LP5LiveTelemetry.swift` supplies the dashboard HTML used by `prepare-ui.js`. Edit the dashboard there, then run `npm run prepare-ui` to regenerate `index.html`. The preparation step also copies the checked-in slice anchors to `seed-slice-state.json`. Do not commit personal LDS logs or runtime caches.

## Validation

For source checks without downloading or running Electron:

```sh
npm ci --ignore-scripts
npm test
npm audit --audit-level=high
```

`npm test` regenerates the UI and runs the three existing layout, desktop-configuration, and icon tests. These tests do not exercise live hardware or prove packaged runtime behavior. Run `node node_modules/electron/install.js` before launching or packaging if dependencies were installed with `--ignore-scripts`.

For UI or telemetry changes, also inspect the running app with controlled data and verify relevant behavior on the affected supported platforms. Keep real-device tests read-only and under the operator's control. Report unavailable platform/device checks as unverified.

## Automated checks

The `Source checks` workflow runs on pushes to `main`, pull requests, or a manual workflow run. Its matrix uses Ubuntu 24.04, Windows, and macOS runners with Node.js 24. It installs dependencies without lifecycle scripts, runs `npm test`, and fails on high-severity dependency advisories. These are source checks; they do not package or publish installers and do not automatically merge pull requests.

## Packaging and release

On macOS, from the repository root:

```sh
npm run dist:mac -- --publish never
npm run dist:win -- --publish never
```

Outputs are written to `dist/`: a macOS application directory, DMG and ZIP, and Windows NSIS and portable EXEs. The supplied macOS script uses ad-hoc signing for local validation; that is not notarization or public distribution approval. No Linux application package is defined.

Merging source and publishing an application update are separate maintainer decisions. Before a release, verify the intended source revision and version, affected-platform runtime behavior, appropriate signing/notarization, installer assets, and checksums. Reuse valid CI evidence, but do not treat source checks as packaged-application acceptance. Uploads, release tags, and publication require maintainer authorization. Record the source revision used for each release; the version string alone does not establish that an existing installer matches the latest source.

No workflow in this repository publishes installers automatically. Official downloads remain on the [GitHub Releases page](https://github.com/rdcstout/lp5-live-telemetry/releases/latest).
