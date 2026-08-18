# LP5 Live Telemetry 1.0.3

LP5 Live Telemetry is a read-only companion for LaserPecker Design Space (LDS). Keep LDS open and connected to the LP5 while a job is running; this app reads the live LDS telemetry log and displays the available machine data.

Download the current Mac and Windows builds from the [GitHub Releases page](../../releases/latest).

LP5 Live Telemetry is free. If it helps in your shop, you can optionally [support future workshop tools](https://buy.stripe.com/fZu3cw2Mnfr0d7N3ws1kA00). Downloads remain available without payment.

## Mac

Open the DMG, drag **LP5 Live Telemetry** to Applications, and launch it. This build is for Apple-silicon Macs (M1 or newer).

## Windows

Use the Setup EXE for a normal installation, or the Portable EXE if you want to run it without installing.

Version 1.0.1 adds the branded LP5 Telemetry icon to the Windows application, installer, uninstaller, desktop shortcut, and Start menu shortcut. It also enlarges the dashboard inside the Windows client area to remove the excessive surrounding space.

Version 1.0.2 fixes a slice-anchor cache conflict that could make the desktop app's calculated overall progress restart near zero while the browser monitor remained accurate.

Version 1.0.3 translates the LP5's verified live state codes into useful labels. In particular, state 4 now displays as **PAUSED** instead of the unexplained raw label “STATE 4.”

## Display

The window keeps its designed aspect ratio. All dashboard contents scale proportionally with the window, and the full bottom edge remains visible without a vertical scrollbar.

The **Extrusion Therapy** subtitle links to <https://extrusiontherapy.com/> without changing its visual color.

## Telemetry notes

- **Calculated overall progress** combines the current 3D slice with LDS's reported progress within that slice.
- **Current slice progress** is LDS's raw percentage for the active slice.
- **Power command** is the commanded setting reported by LDS; it is not measured optical output.
- No inferred warning such as “advancing” is displayed. The dashboard shows only telemetry values or calculations that are explicitly labeled.

## Independent utility

Created by Extrusion Therapy as an independent workshop utility. This application is not affiliated with or endorsed by LaserPecker.
