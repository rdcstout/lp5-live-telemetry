import AppKit
import Foundation
import WebKit

private let dashboardHTML = #"""
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>LP5 Live Telemetry</title>
<style>
  :root { color-scheme: dark; font-family: Inter, ui-sans-serif, system-ui, -apple-system, sans-serif; --ui-scale: 1; --page-pad: 28px; }
  * { box-sizing: border-box; }
  body { margin: 0; min-height: 100vh; background: #080b10; color: #edf3fa; display: grid; place-items: center; padding: var(--page-pad); overflow: hidden; }
  main { width: 880px; zoom: var(--ui-scale); }
  header { display: flex; justify-content: space-between; align-items: end; gap: 20px; margin-bottom: 22px; }
  h1 { margin: 0; font-size: clamp(28px, 5vw, 50px); letter-spacing: -.04em; }
  .sub { color: #8d9aac; margin-top: 7px; }
  .sub a { color: inherit; text-decoration: none; }
  .live { display: flex; align-items: center; gap: 9px; color: #74f6b4; font-weight: 750; letter-spacing: .08em; }
  .dot { width: 11px; height: 11px; border-radius: 50%; background: currentColor; box-shadow: 0 0 18px currentColor; animation: pulse 1.2s infinite; }
  @keyframes pulse { 50% { opacity: .35; } }
  .hero { border: 1px solid #283140; background: linear-gradient(145deg,#111720,#0c1118); border-radius: 20px; padding: 26px; }
  .row { display: grid; grid-template-columns: 1fr auto; align-items: baseline; gap: 16px; }
  .label { color: #8d9aac; font-size: 13px; letter-spacing: .11em; text-transform: uppercase; }
  .progress-number { font-size: clamp(54px, 10vw, 94px); font-weight: 820; letter-spacing: -.06em; line-height: .9; }
  .state { font-size: 20px; font-weight: 750; color: #74f6b4; }
  .track { height: 18px; background: #242c38; border-radius: 99px; overflow: hidden; margin-top: 22px; }
  .fill { height: 100%; width: 0; background: linear-gradient(90deg,#00c97c,#80ffc0); transition: width .5s ease; }
  .grid { display: grid; grid-template-columns: repeat(4,1fr); gap: 12px; margin-top: 12px; }
  .metric { min-height: 120px; border: 1px solid #283140; background: #0e141d; border-radius: 16px; padding: 18px; }
  .value { margin-top: 14px; font-size: 35px; font-weight: 780; letter-spacing: -.04em; }
  .status-grid { display: grid; grid-template-columns: repeat(5,1fr); gap: 10px; margin-top: 12px; }
  .status { border: 1px solid #283140; border-radius: 13px; padding: 13px; background: #0e141d; }
  .status-value { margin-top: 7px; font-weight: 760; }
  .slice-panel { display: none; margin-top: 12px; border: 1px solid #334053; background: linear-gradient(145deg,#101924,#0c131c); border-radius: 16px; padding: 18px; }
  .slice-panel.visible { display: block; }
  .slice-grid { display: grid; grid-template-columns: repeat(3,1fr); gap: 12px; }
  .slice-value { margin-top: 8px; font-size: 25px; font-weight: 780; letter-spacing: -.03em; }
  .overall-track { height: 10px; background: #242c38; border-radius: 99px; overflow: hidden; margin-top: 14px; }
  .overall-fill { height: 100%; width: 0; background: linear-gradient(90deg,#42a5ff,#8ed2ff); transition: width .5s ease; }
  .ok { color: #74f6b4; }
  .bad { color: #ff6f7b; }
  footer { color: #6e7c8f; font-size: 13px; margin-top: 15px; display: flex; justify-content: space-between; gap: 16px; }
</style>
</head>
<body>
<main>
  <header>
    <div><h1>LP5 Live Telemetry</h1><div class="sub">An <a href="https://extrusiontherapy.com/" target="_blank" rel="noopener noreferrer">Extrusion Therapy</a> workshop tool</div></div>
    <div class="live" id="live"><span class="dot"></span><span>WAITING</span></div>
  </header>
  <section class="hero">
    <div class="row"><div><div class="label" id="progress-label">Calculated overall progress</div><div class="progress-number" id="progress">—</div></div><div class="state" id="state">Waiting…</div></div>
    <div class="track"><div class="fill" id="fill"></div></div>
  </section>
  <section class="grid">
    <div class="metric"><div class="label">Pass</div><div class="value" id="pass">—</div></div>
    <div class="metric"><div class="label">Power command</div><div class="value" id="power">—</div></div>
    <div class="metric"><div class="label">Device speed</div><div class="value" id="speed">—</div></div>
    <div class="metric"><div class="label">Reported temp</div><div class="value"><span id="temp">—</span>°C</div></div>
  </section>
  <section class="status-grid">
    <div class="status"><div class="label">Error</div><div class="status-value" id="error">—</div></div>
    <div class="status"><div class="label">Stop flag</div><div class="status-value" id="stop">—</div></div>
    <div class="status"><div class="label">Safety key</div><div class="status-value" id="safe">—</div></div>
    <div class="status"><div class="label">Cover</div><div class="status-value" id="cover">—</div></div>
    <div class="status"><div class="label">Internal link</div><div class="status-value" id="usb">—</div></div>
  </section>
  <section class="slice-panel" id="slice-panel">
    <div class="slice-grid">
      <div><div class="label">Current slice</div><div class="slice-value" id="slice-current">—</div></div>
      <div><div class="label">Slice range</div><div class="slice-value" id="slice-range">—</div></div>
      <div><div class="label">Current slice progress</div><div class="slice-value" id="slice-progress">—</div></div>
    </div>
    <div class="overall-track"><div class="overall-fill" id="overall-fill"></div></div>
  </section>
  <footer><span id="timestamp">Waiting for telemetry…</span><span>Commanded telemetry—not optical wattage</span></footer>
</main>
<script>
const $ = id => document.getElementById(id);
const scaleInterface = () => {
  const windows = window.lp5Telemetry?.platform === 'win32';
  const pagePad = windows ? 12 : 28;
  const verticalReserve = windows ? pagePad * 2 : 72;
  const scale = Math.max(.65, Math.min(1.8, Math.min((innerWidth - pagePad * 2) / 880, (innerHeight - verticalReserve) / 677)));
  document.documentElement.style.setProperty('--page-pad', pagePad + 'px');
  document.documentElement.style.setProperty('--ui-scale', scale);
};
addEventListener('resize', scaleInterface);
scaleInterface();
const shown = value => (value === null || value === undefined) ? '—' : value;
const stateName = code => ({1:'ACTIVE',2:'ACTIVE',3:'PAUSED / TRANSITION',4:'PAUSED',5:'ACTIVE',6:'TRANSITION',12:'READY',255:'IDLE'})[code] || `STATE ${code}`;
const status = (id, value, good) => { const el=$(id); el.textContent=value; el.className='status-value '+(good?'ok':'bad'); };
window.renderTelemetry = d => {
  $('state').textContent=stateName(d.w_state); $('state').className='state '+(([1,2,5].includes(d.w_state))?'ok':'');
  $('pass').textContent=shown(d.print_times); $('power').textContent=shown(d.laser); $('speed').textContent=shown(d.speed); $('temp').textContent=shown(d.temp);
  status('error',d.error===0?'NONE':shown(d.error),d.error===0); status('stop',d.stop===0?'CLEAR':'SET',d.stop===0);
  status('safe',d.safe_key===1?'OK':'CHECK',d.safe_key===1); status('cover',d.cover===1?'OK':'CHECK',d.cover===1); status('usb',d.u_b_cnn===1?'OK':'CHECK',d.u_b_cnn===1);
  if (d.slice_available) {
    $('slice-panel').className='slice-panel visible';
    $('slice-current').textContent=d.slice_current; $('slice-range').textContent=d.slice_range;
    $('progress-label').textContent='Calculated overall progress'; $('progress').textContent=d.overall_text;
    $('fill').style.width=Math.max(0,Math.min(100,d.overall_value || 0))+'%';
    $('slice-progress').textContent=shown(d.rate)+'%'; $('overall-fill').style.width=Math.max(0,Math.min(100,d.rate || 0))+'%';
  } else {
    $('slice-panel').className='slice-panel'; $('progress-label').textContent='Current operation progress';
    $('progress').textContent=shown(d.rate)+'%'; $('fill').style.width=Math.max(0,Math.min(100,d.rate || 0))+'%';
  }
  $('timestamp').textContent='Last update: '+d.timestamp;
  $('live').className='live'; $('live').lastElementChild.textContent='LIVE';
};
window.feedLost = message => {
  $('live').className='live bad'; $('live').lastElementChild.textContent='FEED LOST';
  $('timestamp').textContent=message || 'Waiting for LDS telemetry…';
};
if (location.protocol === 'http:' || location.protocol === 'https:') {
  const refreshFromPreviewServer = async () => {
    try {
      const response = await fetch('/telemetry', {cache:'no-store'});
      window.renderTelemetry(await response.json());
    } catch (error) { window.feedLost('Preview telemetry feed unavailable.'); }
  };
  refreshFromPreviewServer();
  setInterval(refreshFromPreviewServer, 1000);
}
</script>
</body>
</html>
"""#

private enum TelemetryError: LocalizedError {
    case logDirectoryMissing
    case noLogFound
    case noRecordFound

    var errorDescription: String? {
        switch self {
        case .logDirectoryMissing: return "LDS telemetry folder was not found."
        case .noLogFound: return "No LDS telemetry log was found."
        case .noRecordFound: return "Waiting for an LP5 telemetry record…"
        }
    }
}

private final class TelemetryReader {
    private let fields = ["w_state", "rate", "laser", "speed", "error", "name", "temp", "print_times", "u_b_cnn", "stop", "safe_key", "cover"]
    private let maxTailBytes: UInt64 = 1_048_576

    private var logsRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/laserpecker_design_spaces/logs/web", isDirectory: true)
    }

    private var projectRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/LaserPecker/project", isDirectory: true)
    }

    private var stateURL: URL {
        let support = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/LP5 Live Telemetry", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        return support.appendingPathComponent("slice-state.json")
    }

    func latestLogURL() throws -> URL {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: logsRoot.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw TelemetryError.logDirectoryMissing
        }

        let children = try FileManager.default.contentsOfDirectory(
            at: logsRoot,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        let candidates = children.compactMap { child -> (URL, Date)? in
            let log = child.appendingPathComponent("info.log")
            guard FileManager.default.fileExists(atPath: log.path) else { return nil }
            let values = try? log.resourceValues(forKeys: [.contentModificationDateKey])
            return (log, values?.contentModificationDate ?? .distantPast)
        }

        guard let newest = candidates.max(by: { $0.1 < $1.1 })?.0 else {
            throw TelemetryError.noLogFound
        }
        return newest
    }

    func latestTelemetry() throws -> [String: Any] {
        let logURL = try latestLogURL()
        let handle = try FileHandle(forReadingFrom: logURL)
        defer { try? handle.close() }

        let size = try handle.seekToEnd()
        try handle.seek(toOffset: size > maxTailBytes ? size - maxTailBytes : 0)
        let data = try handle.readToEnd() ?? Data()
        let text = String(decoding: data, as: UTF8.self)

        guard let marker = text.range(of: "'WorkStatusResult'", options: .backwards) else {
            throw TelemetryError.noRecordFound
        }

        let prefix = String(text[..<marker.lowerBound])
        let blockEnd = text.index(marker.lowerBound, offsetBy: min(1800, text.distance(from: marker.lowerBound, to: text.endIndex)))
        let block = String(text[marker.lowerBound..<blockEnd])

        var result: [String: Any] = [:]
        let timestampPattern = #"\[(\d{4}-\d{1,2}-\d{1,2} \d{2}:\d{2}:\d{2})\]"#
        if let regex = try? NSRegularExpression(pattern: timestampPattern),
           let match = regex.matches(in: prefix, range: NSRange(prefix.startIndex..., in: prefix)).last,
           let range = Range(match.range(at: 1), in: prefix) {
            result["timestamp"] = String(prefix[range])
        } else {
            result["timestamp"] = ISO8601DateFormatter().string(from: Date())
        }

        for field in fields {
            let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: field) + #":\s*(-?\d+)"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
               let range = Range(match.range(at: 1), in: block),
               let value = Int(block[range]) {
                result[field] = value
            } else {
                result[field] = NSNull()
            }
        }
        addSliceProgress(to: &result, logDirectory: logURL.deletingLastPathComponent())
        return result
    }

    private func addSliceProgress(to result: inout [String: Any], logDirectory: URL) {
        guard let range = embossRange() else {
            result["slice_available"] = false
            return
        }

        var combined = ""
        for name in ["info.old.log", "info.log"] {
            let url = logDirectory.appendingPathComponent(name)
            if let text = try? String(contentsOf: url, encoding: .utf8) { combined += text }
        }

        let pattern = #"'WorkStatusResult',\s*\{(.*?)\n  \}\s*\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            result["slice_available"] = false
            return
        }
        var names: [Int] = []
        for match in regex.matches(in: combined, range: NSRange(combined.startIndex..., in: combined)) {
            guard let blockRange = Range(match.range(at: 1), in: combined) else { continue }
            let block = String(combined[blockRange])
            guard let name = integerField("name", in: block) else { continue }
            if names.last != name { names.append(name) }
        }
        guard !names.isEmpty else {
            result["slice_available"] = false
            return
        }

        var saved = loadSliceMap()
        var baseSlice = range.0
        for index in names.indices.reversed() {
            if let anchoredSlice = saved[String(names[index])] {
                baseSlice = anchoredSlice - index
                break
            }
        }

        let currentSlice = baseSlice + names.count - 1
        saved.removeAll(keepingCapacity: true)
        for (index, name) in names.suffix(128).enumerated() {
            let originalIndex = max(0, names.count - 128) + index
            saved[String(name)] = baseSlice + originalIndex
        }
        saveSliceMap(saved)

        let rate = result["rate"] as? Int ?? 0
        let total = max(1, range.1 - range.0 + 1)
        let overall = (Double(currentSlice - range.0) + Double(max(0, min(100, rate))) / 100.0) / Double(total) * 100.0
        result["slice_available"] = true
        result["slice_current"] = String(currentSlice)
        result["slice_range"] = "\(range.0)–\(range.1)"
        result["overall_value"] = (overall * 100).rounded() / 100
        result["overall_text"] = String(format: "%.1f%%", overall)
    }

    private func integerField(_ field: String, in text: String) -> Int? {
        let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: field) + #":\s*(-?\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return Int(text[range])
    }

    private func embossRange() -> (Int, Int)? {
        guard let projects = try? FileManager.default.contentsOfDirectory(
            at: projectRoot,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }
        let latest = projects.filter { $0.pathExtension.lowercased() == "lp2" }.max {
            let left = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let right = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return left < right
        }
        guard let latest else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-p", latest.path, ".lpproject"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do { try process.run(); process.waitUntilExit() } catch { return nil }
        guard process.terminationStatus == 0,
              let outer = try? JSONSerialization.jsonObject(with: pipe.fileHandleForReading.readDataToEndOfFile()) as? [String: Any],
              let innerText = outer["data"] as? String,
              let innerData = innerText.data(using: .utf8),
              let objects = try? JSONSerialization.jsonObject(with: innerData) as? [[String: Any]] else { return nil }
        for object in objects {
            if let values = object["embossRange"] as? [NSNumber], values.count == 2 {
                return (values[0].intValue, values[1].intValue)
            }
        }
        return nil
    }

    private func loadSliceMap() -> [String: Int] {
        let candidates = [stateURL, Bundle.main.url(forResource: "slice-seed", withExtension: "json")].compactMap { $0 }
        for url in candidates {
            guard let data = try? Data(contentsOf: url),
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let raw = root["slice_by_job_id"] as? [String: Any] else { continue }
            var values: [String: Int] = [:]
            for (key, value) in raw { if let number = value as? NSNumber { values[key] = number.intValue } }
            if !values.isEmpty { return values }
        }
        return [:]
    }

    private func saveSliceMap(_ values: [String: Int]) {
        guard let data = try? JSONSerialization.data(withJSONObject: ["slice_by_job_id": values], options: [.prettyPrinted, .sortedKeys]) else { return }
        try? data.write(to: stateURL, options: .atomic)
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    private var window: NSWindow!
    private var webView: WKWebView!
    private var timer: Timer?
    private let reader = TelemetryReader()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 940, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "LP5 Live Telemetry"
        window.minSize = NSSize(width: 720, height: 560)
        window.backgroundColor = NSColor(calibratedRed: 0.031, green: 0.043, blue: 0.063, alpha: 1)
        window.contentView = webView
        window.center()
        window.makeKeyAndOrderFront(nil)

        installMainMenu()
        NSApp.activate(ignoringOtherApps: true)
        webView.loadHTMLString(dashboardHTML, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateTelemetry()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTelemetry()
        }
    }

    private func updateTelemetry() {
        do {
            let telemetry = try reader.latestTelemetry()
            let data = try JSONSerialization.data(withJSONObject: telemetry, options: [])
            guard let json = String(data: data, encoding: .utf8) else { return }
            webView.evaluateJavaScript("window.renderTelemetry(\(json));")
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            let data = try? JSONSerialization.data(withJSONObject: [message], options: [])
            let encoded = data.flatMap { String(data: $0, encoding: .utf8) } ?? "[\"Waiting for LDS telemetry…\"]"
            webView.evaluateJavaScript("window.feedLost(\(encoded)[0]);")
        }
    }

    private func installMainMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About LP5 Live Telemetry", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit LP5 Live Telemetry", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

if CommandLine.arguments.contains("--self-test") {
    do {
        let result = try TelemetryReader().latestTelemetry()
        let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        print(String(decoding: data, as: UTF8.self))
        exit(EXIT_SUCCESS)
    } catch {
        fputs("Self-test failed: \(error.localizedDescription)\n", stderr)
        exit(EXIT_FAILURE)
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
