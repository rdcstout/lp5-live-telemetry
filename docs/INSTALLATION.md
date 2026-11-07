# Installing LP5 Live Telemetry

## macOS

The macOS download supports Apple-silicon Macs. Open `LP5-Live-Telemetry-macOS-arm64.dmg`, drag LP5 Live Telemetry to Applications, then open it normally. The public disk image and application are signed with Extrusion Therapy's Apple Developer ID and notarized by Apple.

To remove the app, quit it and move LP5 Live Telemetry from Applications to the Trash. Its small local slice and update-preference cache can remain without affecting the computer.

## Windows

The Windows download is an x64 one-click installer. It upgrades an existing LP5 Live Telemetry installation in place and provides an uninstaller through Windows Installed apps and the Start menu.

The Windows installer is currently unsigned, so Windows may show an unrecognized-app warning. Verify the SHA-256 checksum against `SHA256SUMS.txt` on the latest release before running it.

## Using the app

Keep LaserPecker Design Space open and connected to the LP5 while a job runs. LP5 Live Telemetry reads the local LDS telemetry log; it does not control the laser or modify the job.

Use **Check for updates** in the app for an immediate check. Quiet weekly checks are enabled by default and can be turned off independently. Update checks contact GitHub Releases and never install anything automatically.

Official downloads and checksums are on the [latest release](https://github.com/rdcstout/lp5-live-telemetry/releases/latest). Report reproducible bugs in the [issue tracker](https://github.com/rdcstout/lp5-live-telemetry/issues) and security concerns through [private vulnerability reporting](https://github.com/rdcstout/lp5-live-telemetry/security/advisories/new).
