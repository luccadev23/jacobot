import SwiftUI
import CoreText

public enum JacoWeight {
    case regular, medium, semibold, bold

    var postScriptSuffix: String {
        switch self {
        case .regular: return "Regular"
        case .medium: return "Medium"
        case .semibold: return "SemiBold"
        case .bold: return "Bold"
        }
    }
}

/// Design system fonts: Inter (UI) and JetBrains Mono (code). The files ship inside the package.
public enum JacoFont {
    private static var registered = false

    /// Registers the package fonts. Call once at app launch.
    public static func register() {
        guard !registered else { return }
        registered = true
        let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    public static func ui(_ size: CGFloat, _ weight: JacoWeight = .regular) -> Font {
        .custom("Inter-\(weight.postScriptSuffix)", fixedSize: size)
    }

    public static func mono(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Regular", fixedSize: size)
    }
}

/// Design type scale (size / line height · weight · tracking).
public enum JacoTextStyle {
    case largeTitle  // 34/41 · 600 · -0.8
    case title1      // 28/34 · 600 · -0.6
    case title2      // 22/28 · 600 · -0.3
    case headline    // 17/22 · 600 · -0.2
    case body        // 15/22 · 400
    case bodyStrong  // 15/22 · 600
    case subhead     // 13/18 · 400
    case caption     // 12/16 · 500 · +0.1
    case overline    // 11/14 · 600 · +1.1

    public var size: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title1: 28
        case .title2: 22
        case .headline: 17
        case .body, .bodyStrong: 15
        case .subhead: 13
        case .caption: 12
        case .overline: 11
        }
    }

    public var weight: JacoWeight {
        switch self {
        case .largeTitle, .title1, .title2, .headline, .bodyStrong, .overline: .semibold
        case .caption: .medium
        case .body, .subhead: .regular
        }
    }

    public var tracking: CGFloat {
        switch self {
        case .largeTitle: -0.8
        case .title1: -0.6
        case .title2: -0.3
        case .headline: -0.2
        case .caption: 0.1
        case .overline: 1.1
        default: 0
        }
    }
}

/// Inter's natural height (ascent + descent) as a multiple of the font size.
private let interNaturalLineHeight: CGFloat = 1.21

extension View {
    /// Applies the design's font, color and line height. `lineHeight` is a multiple of the size (e.g. 1.4).
    public func jacoText(
        _ size: CGFloat,
        _ weight: JacoWeight = .regular,
        _ color: Color,
        lineHeight: CGFloat? = nil,
        tracking: CGFloat = 0
    ) -> some View {
        self
            .font(JacoFont.ui(size, weight))
            .foregroundStyle(color)
            .tracking(tracking)
            .lineSpacing(lineHeight.map { max(0, size * ($0 - interNaturalLineHeight)) } ?? 0)
    }

    public func jacoText(_ style: JacoTextStyle, _ color: Color, lineHeight: CGFloat? = nil) -> some View {
        jacoText(style.size, style.weight, color, lineHeight: lineHeight, tracking: style.tracking)
    }
}
