import AppKit
import ApplicationServices
import Foundation

func die(_ message: String, _ code: Int32 = 1) -> Never {
    fputs("airdrop-cli: \(message)\n", stderr)
    exit(code)
}

let deviceFile: URL = {
    if let directory = ProcessInfo.processInfo.environment["AIRDROP_CLI_CONFIG_DIR"] {
        return URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent("device")
    }
    return FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/airdrop-cli/device")
}()

func saveDevice(_ name: String) -> Never {
    guard !name.isEmpty, !name.contains("\n"), !name.contains("\r") else { die("invalid device name", 2) }
    do {
        try FileManager.default.createDirectory(at: deviceFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try name.write(to: deviceFile, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: deviceFile.path)
    } catch { die("could not save device: \(error.localizedDescription)") }
    print("Default device: \(name)")
    exit(0)
}

func setup(_ args: [String]) -> Never {
    if args.count == 3, args[1] == "--device" { saveDevice(args[2]) }
    guard args.count == 1 else { die("usage: airdrop-cli setup [--device \"Device Name\"]", 2) }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
    process.arguments = ["devices"]
    let output = Pipe()
    process.standardOutput = output
    process.standardError = FileHandle.standardError
    do { try process.run() } catch { die("could not discover devices: \(error.localizedDescription)") }
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { exit(process.terminationStatus) }
    let data = output.fileHandleForReading.readDataToEndOfFile()
    let names = String(decoding: data, as: UTF8.self).split(separator: "\n").map(String.init)
    guard !names.isEmpty else { die("no devices found", 4) }
    for (index, name) in names.enumerated() { print("\(index + 1). \(name)") }
    print("Choose a default device number: ", terminator: "")
    fflush(stdout)
    guard let input = readLine(), let number = Int(input), names.indices.contains(number - 1) else {
        die("choose one of the listed numbers", 2)
    }
    saveDevice(names[number - 1])
}

enum Mode {
    case devices
    case send(String, [URL])
}

func parse() -> Mode {
    var args = Array(CommandLine.arguments.dropFirst())
    guard !args.isEmpty else { print("Usage: airdrop-cli setup | devices | clear | [send] [--to NAME] FILE_OR_URL..."); exit(0) }
    switch args[0] {
    case "help", "-h", "--help":
        print("Usage: airdrop-cli setup [--device NAME] | devices | clear | [send] [--to NAME] FILE_OR_URL... | doctor")
        exit(0)
    case "doctor":
        let available = NSSharingService(named: .sendViaAirDrop) != nil
        let trusted = AXIsProcessTrusted()
        print("AirDrop service: \(available ? "available" : "unavailable")")
        print("Accessibility: \(trusted ? "authorized" : "authorization required")")
        exit(available && trusted ? 0 : 3)
    case "setup": setup(args)
    case "clear":
        guard args.count == 1 else { die("clear takes no arguments", 2) }
        do {
            if FileManager.default.fileExists(atPath: deviceFile.path) { try FileManager.default.removeItem(at: deviceFile) }
        } catch { die("could not clear default: \(error.localizedDescription)") }
        print("Default device: none")
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
    guard !paths.isEmpty else { die("give at least one file or URL to send", 2) }
    if target == nil { target = try? String(contentsOf: deviceFile, encoding: .utf8) }
    guard let target, !target.isEmpty else { die("no default device; run `airdrop-cli setup` or pass `--to NAME`", 2) }
    let urls = paths.map { path -> URL in
        if path.hasPrefix("https://") || path.hasPrefix("http://") {
            guard let url = URL(string: path), url.host != nil else { die("invalid URL: \(path)", 2) }
            return url
        }
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
    var service: NSSharingService
    var temporaryFile: URL?
    var pending: [[URL]] = []
    var current: [URL] = []
    var sentCount = 0
    var timer: Timer?
    var deadline = Date.distantFuture
    var lastNames: [String] = []
    var stableReads = 0
    var selected = false
    var resultCode: Int32 = 0

    init(_ mode: Mode, _ service: NSSharingService) { self.mode = mode; self.service = service }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        switch mode {
        case .devices:
            let file = FileManager.default.temporaryDirectory.appendingPathComponent("airdrop-cli-\(UUID()).txt")
            do { try "Discover AirDrop devices".write(to: file, atomically: true, encoding: .utf8) }
            catch { finish("could not start discovery: \(error.localizedDescription)", 1); return }
            temporaryFile = file
            pending = [[file]]
        case .send(_, let items):
            if service.canPerform(withItems: items) { pending = [items] }
            else if items.allSatisfy({ service.canPerform(withItems: [$0]) }) {
                pending = items.map { [$0] }
            } else { finish("AirDrop cannot share one or more items", 2); return }
        }
        startNext()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in self?.poll(timer) }
    }

    func startNext() {
        guard !pending.isEmpty, let nextService = NSSharingService(named: .sendViaAirDrop) else {
            finish("AirDrop service is unavailable", 3)
            return
        }
        current = pending.removeFirst()
        service = nextService
        service.delegate = self
        selected = false
        if case .devices = mode { deadline = Date().addingTimeInterval(12) }
        else { deadline = Date().addingTimeInterval(25) }
        let items = current
        DispatchQueue.main.async { self.service.perform(withItems: items) }
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
        guard case .send(let target, _) = mode else { finish(nil, 0); return }
        sentCount += items.count
        if pending.isEmpty {
            print("Sent \(sentCount) item\(sentCount == 1 ? "" : "s") to \(target)")
            finish(nil, 0)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.startNext() }
        }
    }
    func sharingService(_ service: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        finish("AirDrop failed: \(error.localizedDescription)", 1)
    }
    func finish(_ error: String?, _ code: Int32) {
        timer?.invalidate()
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
