import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

extension View {
    /// Makes this area drag the window (macOS), like the title bar. Buttons inside it stay clickable.
    /// Only headers should use it: dragging a list, bubble or panel does not move the window.
    public func jacoWindowDragHandle() -> some View {
        #if os(macOS)
        background(WindowDragView())
        #else
        self
        #endif
    }
}

#if os(macOS)
private struct WindowDragView: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView { DragView() }
    func updateNSView(_ nsView: DragView, context: Context) {}

    final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2 { window?.performZoom(nil) } else { window?.performDrag(with: event) }
        }
    }
}
#endif
