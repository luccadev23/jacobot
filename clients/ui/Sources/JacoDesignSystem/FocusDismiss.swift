import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

extension View {
    /// Clicking outside a text field drops its focus (on macOS the field keeps focus until another takes it).
    public func jacoDismissFocusOnOutsideClick() -> some View {
        modifier(DismissFocusModifier())
    }
}

private struct DismissFocusModifier: ViewModifier {
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .onAppear {
                guard monitor == nil else { return }
                monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
                    guard let window = event.window,
                          let root = window.contentView?.superview,
                          let hit = root.hitTest(event.locationInWindow) else { return event }
                    var view: NSView? = hit
                    while let current = view {
                        if current is NSTextField || current is NSTextView { return event }  // click inside a field: keep focus
                        view = current.superview
                    }
                    if window.firstResponder is NSTextView || window.firstResponder is NSTextField {
                        window.makeFirstResponder(nil)
                    }
                    return event
                }
            }
            .onDisappear { if let m = monitor { NSEvent.removeMonitor(m); monitor = nil } }
        #else
        content
        #endif
    }
}
