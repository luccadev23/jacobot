import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

extension View {
    /// Hand (pointer) cursor on everything clickable. Disabled views do not use it.
    /// Uses the SAME area as hover (the view's whole rectangle), so wherever the button lights up the cursor changes too.
    public func jacoPointer(_ enabled: Bool = true) -> some View {
        modifier(JacoCursorModifier(kind: enabled ? .pointer : nil))
    }

    /// Text (I-beam) cursor over the whole input area, not just over the text.
    public func jacoTextCursor() -> some View {
        modifier(JacoCursorModifier(kind: .text))
    }
}

enum JacoCursorKind { case pointer, text }

#if os(macOS)
/// How many areas with their own cursor are under the mouse. Only goes back to the arrow when there are none.
private enum JacoCursorState {
    static var activeAreas = 0
}

private struct JacoCursorModifier: ViewModifier {
    let kind: JacoCursorKind?
    @State private var inside = false

    func body(content: Content) -> some View {
        if let kind {
            content
                .onContinuousHover { phase in
                    switch phase {
                    case .active:
                        if !inside { inside = true; JacoCursorState.activeAreas += 1 }
                        (kind == .pointer ? NSCursor.pointingHand : NSCursor.iBeam).set()
                    case .ended:
                        guard inside else { return }
                        inside = false
                        JacoCursorState.activeAreas -= 1
                        // Defers one cycle: if the mouse entered another clickable area, that area keeps its own cursor.
                        DispatchQueue.main.async {
                            if JacoCursorState.activeAreas <= 0 { NSCursor.arrow.set() }
                        }
                    }
                }
                .onDisappear {
                    if inside { inside = false; JacoCursorState.activeAreas = max(0, JacoCursorState.activeAreas - 1) }
                }
        } else {
            content
        }
    }
}
#else
private struct JacoCursorModifier: ViewModifier {
    let kind: JacoCursorKind?
    func body(content: Content) -> some View { content }
}
#endif
