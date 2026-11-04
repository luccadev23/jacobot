import SwiftUI
import AppKit
import JacoDesignSystem
import JacoUI

/// macOS shell: 1512 × 982 window (design size), hidden title bar.
///
/// Visual verification mode (does not need the screen recording permission):
///   JacoMac --snapshot output.png [--dark] [--overlay newBot|apps] [--account]
@main
struct JacoMacApp: App {
    init() {
        JacoFont.register()
        NSApplication.shared.setActivationPolicy(.regular)
        if let request = SnapshotRequest(arguments: CommandLine.arguments) {
            DispatchQueue.main.async { Snapshot.render(request); exit(0) }
        }
    }

    var body: some Scene {
        WindowGroup("Jaco") {
            JacoMainView()
                .frame(minWidth: 1100, minHeight: 700)
                .background(WindowChrome())
                .onAppear { NSApplication.shared.activate(ignoringOtherApps: true) }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1512, height: 982)
    }
}

struct SnapshotRequest {
    let path: String
    let dark: Bool
    let overlay: JacoOverlay?
    let account: Bool
    let picker: Bool
    let error: Bool

    init?(arguments a: [String]) {
        guard let i = a.firstIndex(of: "--snapshot"), a.indices.contains(i + 1) else { return nil }
        path = a[i + 1]
        dark = a.contains("--dark")
        account = a.contains("--account")
        picker = a.contains("--picker")
        error = a.contains("--error")
        if let o = a.firstIndex(of: "--overlay"), a.indices.contains(o + 1) { overlay = JacoOverlay(rawValue: a[o + 1]) } else { overlay = nil }
    }
}

@MainActor
enum Snapshot {
    static func render(_ r: SnapshotRequest) {
        let size = NSSize(width: 1512, height: 982)
        let appearance = NSAppearance(named: r.dark ? .darkAqua : .aqua)
        let root = JacoMainView(overlay: r.overlay, accountMenuOpen: r.account, pickerOpen: r.picker, nameError: r.error)
            .frame(width: size.width, height: size.height)
        let host = NSHostingView(rootView: root)
        host.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = appearance
        window.contentView = host
        window.orderFrontRegardless()
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(1.2))
        host.layoutSubtreeIfNeeded()
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        appearance?.performAsCurrentDrawingAppearance { host.cacheDisplay(in: host.bounds, to: rep) }
        if let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: r.path))
        }
    }
}
