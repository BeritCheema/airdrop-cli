import AppKit
import ApplicationServices
import Foundation

func die(_ message: String, _ code: Int32 = 1) -> Never {
    fputs("airdrop-cli: \(message)\n", stderr)
    exit(code)
}

let deviceFile = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/airdrop-cli/device")

enum Mode {
    case devices
    case send(String, [URL])
}

func parse() -> Mode {
    var args = Array(CommandLine.arguments.dropFirst())
    guard !args.isEmpty else { print("Usage: airdrop-cli devices | use NAME | [send] [--to NAME] FILE..."); exit(0) }
    switch args[0] {
    case "help", "-h", "--help":
        print("Usage: airdrop-cli devices | use NAME | [send] [--to NAME] FILE... | doctor")
        exit(0)
    case "doctor":
        let available = NSSharingService(named: .sendViaAirDrop) != nil
        let trusted = AXIsProcessTrusted()
        print("AirDrop service: \(available ? "available" : "unavailable")")
        print("Accessibility: \(trusted ? "authorized" : "authorization required")")
        exit(available && trusted ? 0 : 3)
    case "use":
        guard args.count == 2, !args[1].isEmpty, !args[1].contains("\n"), !args[1].contains("\r") else { die("usage: airdrop-cli use \"Device Name\"", 2) }
        do {
            try FileManager.default.createDirectory(at: deviceFile.deletingLastPathComponent(), withIntermediateDirectories: true)
            try args[1].write(to: deviceFile, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: deviceFile.path)
        } catch { die("could not save device: \(error.localizedDescription)") }
        print("Default device: \(args[1])")
        exit(0)
    case "devices":
        guard args.count == 1 else { die("devices takes no arguments", 2) }
        return .devices
    case "send": args.removeFirst()
    default: break
    }

    var target: String?
    var paths: [String] = []
    var i = 0
    while i < args.count {
        if args[i] == "--to" {
            guard i + 1 < args.count, !args[i + 1].isEmpty else { die("--to needs a device name", 2) }
            target = args[i + 1]
            i += 2
        } else if args[i] == "--" {
            paths.append(contentsOf: args.dropFirst(i + 1))
            break
        } else if args[i].hasPrefix("-") { die("unknown option: \(args[i])", 2) }
        else { paths.append(args[i]); i += 1 }
    }
    guard !paths.isEmpty else { die("give at least one file to send", 2) }
    if target == nil { target = try? String(contentsOf: deviceFile, encoding: .utf8) }
    guard let target, !target.isEmpty else { die("run `airdrop-cli devices`, then `airdrop-cli use \"Device Name\"`", 2) }
    let urls = paths.map { path -> URL in
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { die("file not found: \(url.path)", 2) }
        return url
    }
    return .send(target, urls)
}

func axAttribute(_ node: AXUIElement, _ name: String) -> AnyObject? {
    var result: CFTypeRef?
    return AXUIElementCopyAttributeValue(node, name as CFString, &result) == .success ? result : nil
}

func axString(_ node: AXUIElement, _ name: String) -> String? { axAttribute(node, name) as? String }

func recipientButtons() -> [(String, AXUIElement)] {
    let process = AXUIElementCreateApplication(getpid())
    guard let windows = axAttribute(process, kAXWindowsAttribute) as? [AXUIElement] else { return [] }
    var result: [(String, AXUIElement)] = []
    for window in windows where axString(window, kAXTitleAttribute) == "AirDrop" {
        var stack = [window]
        var count = 0
        while let node = stack.popLast(), count < 400 {
            count += 1
            if axString(node, kAXRoleAttribute) == kAXButtonRole as String,
               let name = axString(node, kAXHelpAttribute), !name.isEmpty,
               !result.contains(where: { $0.0 == name }) {
                result.append((name, node))
            }
            if let children = axAttribute(node, kAXChildrenAttribute) as? [AXUIElement] {
                stack.append(contentsOf: children)
            }
        }
    }
    return result.sorted { $0.0.localizedStandardCompare($1.0) == .orderedAscending }
}

final class AirDropApp: NSObject, NSApplicationDelegate, NSSharingServiceDelegate {
    let mode: Mode
    let service: NSSharingService
    var temporaryFile: URL?
    var deadline = Date.distantFuture
    var lastNames: [String] = []
    var stableReads = 0
    var selected = false
    var resultCode: Int32 = 0

    init(_ mode: Mode, _ service: NSSharingService) { self.mode = mode; self.service = service }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        service.delegate = self
        let files: [URL]
        switch mode {
        case .devices:
            let file = FileManager.default.temporaryDirectory.appendingPathComponent("airdrop-cli-\(UUID()).txt")
            do { try "Discover AirDrop devices".write(to: file, atomically: true, encoding: .utf8) }
            catch { finish("could not start discovery: \(error.localizedDescription)", 1); return }
            temporaryFile = file
            files = [file]
            deadline = Date().addingTimeInterval(12)
        case .send(_, let items): files = items; deadline = Date().addingTimeInterval(25)
        }
        guard service.canPerform(withItems: files) else { finish("AirDrop cannot share these files", 2); return }
        DispatchQueue.main.async { self.service.perform(withItems: files) }
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in self?.poll(timer) }
    }

    func poll(_ timer: Timer) {
        let buttons = recipientButtons()
        switch mode {
        case .devices:
            let names = buttons.map(\.0)
            if !names.isEmpty && names == lastNames { stableReads += 1 }
            else { lastNames = names; stableReads = 0 }
            if stableReads >= 3 || Date() >= deadline {
                timer.invalidate()
                if lastNames.isEmpty { finish("no discoverable AirDrop devices found", 4) }
                else { lastNames.forEach { print($0) }; finish(nil, 0) }
            }
        case .send(let target, _):
            if !selected, let button = buttons.first(where: { $0.0 == target }) {
                let status = AXUIElementPerformAction(button.1, kAXPressAction as CFString)
                guard status == .success else { timer.invalidate(); finish("could not select \(target)", 3); return }
                selected = true
                deadline = Date().addingTimeInterval(120)
                print("Sending to \(target)…")
            }
            if Date() >= deadline {
                timer.invalidate()
                finish(selected ? "AirDrop transfer timed out" : "device not found: \(target)", selected ? 5 : 4)
            }
        }
    }

    func sharingService(_ service: NSSharingService, didShareItems items: [Any]) {
        if case .send(let target, _) = mode { print("Sent \(items.count) item\(items.count == 1 ? "" : "s") to \(target)") }
        finish(nil, 0)
    }
    func sharingService(_ service: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        finish("AirDrop failed: \(error.localizedDescription)", 1)
    }
    func finish(_ error: String?, _ code: Int32) {
        if let error { fputs("airdrop-cli: \(error)\n", stderr) }
        resultCode = code
        NSApp.terminate(nil)
    }
    func applicationWillTerminate(_ notification: Notification) {
        if let temporaryFile { try? FileManager.default.removeItem(at: temporaryFile) }
        exit(resultCode)
    }
}

let mode = parse()
guard let service = NSSharingService(named: .sendViaAirDrop) else { die("AirDrop is unavailable on this Mac", 3) }
let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
guard AXIsProcessTrustedWithOptions(prompt) else { die("allow AirDrop CLI in System Settings → Privacy & Security → Accessibility, then retry", 3) }
let app = NSApplication.shared
let delegate = AirDropApp(mode, service)
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
