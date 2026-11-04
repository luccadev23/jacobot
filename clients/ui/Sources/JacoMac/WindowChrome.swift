import SwiftUI
import AppKit

/// Positions the window buttons (close, minimize, zoom) on the sidebar header line, as in the design:
/// 12 pt diameter, 8 gap between them, centered on the 56 pt header height and 20 from the left edge.
struct WindowChrome: NSViewRepresentable {
    static let headerHeight: CGFloat = 56
    static let leading: CGFloat = 20   // left edge of the first button
    static let pitch: CGFloat = 20     // 12 button + 8 gap
    static let diameter: CGFloat = 12

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            context.coordinator.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window { context.coordinator.attach(to: window) }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private weak var window: NSWindow?
        private var observers: [NSObjectProtocol] = []

        func attach(to window: NSWindow) {
            guard self.window !== window else { place(window); return }
            self.window = window
            window.styleMask.insert(.fullSizeContentView)
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = false  // only headers drag (jacoWindowDragHandle)
            let center = NotificationCenter.default
            for name in [NSWindow.didResizeNotification, NSWindow.didEndLiveResizeNotification, NSWindow.didExitFullScreenNotification, NSWindow.didBecomeKeyNotification] {
                observers.append(center.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                    guard let w = self?.window else { return }
                    self?.place(w)
                })
            }
            place(window)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in if let w = self?.window { self?.place(w) } }
        }

        private func place(_ window: NSWindow) {
            let kinds: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
            for (i, kind) in kinds.enumerated() {
                guard let button = window.standardWindowButton(kind), let parent = button.superview else { continue }
                let cx = WindowChrome.leading + WindowChrome.diameter / 2 + CGFloat(i) * WindowChrome.pitch
                let cy = window.frame.height - WindowChrome.headerHeight / 2
                let p = parent.convert(NSPoint(x: cx, y: cy), from: nil)
                button.setFrameOrigin(NSPoint(x: p.x - button.frame.width / 2, y: p.y - button.frame.height / 2))
            }
        }

        deinit { observers.forEach(NotificationCenter.default.removeObserver) }
    }
}
