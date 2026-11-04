import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// Color from 0xRRGGBBAA.
    public init(rgba: UInt32) {
        let r = Double((rgba >> 24) & 0xFF) / 255
        let g = Double((rgba >> 16) & 0xFF) / 255
        let b = Double((rgba >> 8) & 0xFF) / 255
        let a = Double(rgba & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Color that switches by itself between light and dark (system appearance or `preferredColorScheme`).
    public static func jacoDynamic(light: UInt32, dark: UInt32) -> Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor.jaco(rgba: isDark ? dark : light)
        })
        #else
        return Color(uiColor: UIColor { traits in
            UIColor.jaco(rgba: traits.userInterfaceStyle == .dark ? dark : light)
        })
        #endif
    }
}

#if os(macOS)
extension NSColor {
    static func jaco(rgba: UInt32) -> NSColor {
        NSColor(
            srgbRed: CGFloat((rgba >> 24) & 0xFF) / 255,
            green: CGFloat((rgba >> 16) & 0xFF) / 255,
            blue: CGFloat((rgba >> 8) & 0xFF) / 255,
            alpha: CGFloat(rgba & 0xFF) / 255
        )
    }
}
#else
extension UIColor {
    static func jaco(rgba: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((rgba >> 24) & 0xFF) / 255,
            green: CGFloat((rgba >> 16) & 0xFF) / 255,
            blue: CGFloat((rgba >> 8) & 0xFF) / 255,
            alpha: CGFloat(rgba & 0xFF) / 255
        )
    }
}
#endif
