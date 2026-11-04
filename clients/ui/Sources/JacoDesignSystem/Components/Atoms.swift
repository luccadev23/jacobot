import SwiftUI

// MARK: - States (see section A7 of the design)
//
// Hover steps the background up one level (bg-hover → bg-active; brand → brand-hover). Pressed = 85% opacity.
// Focus = 2 pt ring in `focus-ring`. Disabled = 40% opacity, no hover. 120 ms transition.
// Shadow only on floating layers (menu, modal): buttons, fields and the chat pill have none.

let jacoStateAnimation = Animation.easeOut(duration: 0.12)
let jacoDisabledOpacity = 0.4

// MARK: - A1 · Actions

/// `ghostDanger` is the destructive Ghost variant (e.g. Sign out): red text, transparent background and a translucent red background on hover.
public enum JacoButtonKind { case primary, secondary, outline, ghost, ghostDanger, danger }

/// Button / Primary · Secondary · Outline · Ghost · Danger — height 40, radius 10, text 15/600.
public struct JacoButton: View {
    private let title: String
    private let icon: String?
    private let kind: JacoButtonKind
    private let onCard: Bool
    private let fullWidth: Bool
    private let leading: Bool
    private let action: () -> Void
    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled

    /// `onCard`: the button sits on a `bg-hover` card (approval, draft). There Secondary uses `bg-active`
    /// (otherwise it vanishes into the background) and the Ghost hover also steps up one level.
    /// `fullWidth` + `leading` make the button fill the width with content on the left (menu items).
    public init(_ title: String, icon: String? = nil, kind: JacoButtonKind = .primary, onCard: Bool = false,
                fullWidth: Bool = false, leading: Bool = false, action: @escaping () -> Void = {}) {
        self.title = title; self.icon = icon; self.kind = kind; self.onCard = onCard
        self.fullWidth = fullWidth; self.leading = leading; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: JacoSpace.space2) {
                if let icon { JacoIcon(icon, size: 16, color: foreground) }
                Text(title).jacoText(15, .semibold, foreground)
            }
            .padding(.horizontal, JacoSpace.space4)
            .frame(maxWidth: fullWidth ? .infinity : nil, alignment: leading ? .leading : .center)
            .frame(height: JacoControl.md)
            .background(background, in: RoundedRectangle(cornerRadius: JacoRadius.md, style: .continuous))
            .overlay {
                if kind == .outline {
                    RoundedRectangle(cornerRadius: JacoRadius.md, style: .continuous).strokeBorder(JacoColor.borderDefault, lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: JacoRadius.md, style: .continuous))
        }
        .buttonStyle(JacoPressStyle())
        .jacoPointer(isEnabled)
        .onHover { hovering = isEnabled && $0 }
        .opacity(isEnabled ? 1 : jacoDisabledOpacity)
        .animation(jacoStateAnimation, value: hovering)
    }

    private var foreground: Color {
        switch kind {
        case .primary: JacoColor.textOnBrand
        case .secondary, .outline: JacoColor.textPrimary
        case .ghost: hovering ? JacoColor.textPrimary : JacoColor.textSecondary
        case .ghostDanger: JacoColor.dangerText
        case .danger: JacoColor.onDanger
        }
    }

    private var background: Color {
        switch kind {
        case .primary: hovering ? JacoColor.brandHover : JacoColor.brand
        case .secondary: onCard ? (hovering ? JacoColor.borderStrong : JacoColor.bgActive) : (hovering ? JacoColor.bgActive : JacoColor.bgHover)
        case .danger: hovering ? JacoColor.dangerSolidHover : JacoColor.dangerSolid
        case .outline, .ghost: hovering ? (onCard ? JacoColor.bgActive : JacoColor.bgHover) : .clear
        case .ghostDanger: hovering ? JacoColor.dangerHover : .clear
        }
    }
}

/// Pressed = 85% opacity.
struct JacoPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Icon Button — 40 × 40, circle, icon 20. Hover `bg-hover`, pressed `bg-active`.
public struct JacoIconButton: View {
    private let icon: String
    private let pressed: Bool
    private let fill: Color?
    private let action: () -> Void
    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled

    public init(_ icon: String, pressed: Bool = false, fill: Color? = nil, action: @escaping () -> Void = {}) {
        self.icon = icon; self.pressed = pressed; self.fill = fill; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            JacoIcon(icon, size: 20, color: JacoColor.textSecondary)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(IconStyle(latched: pressed, fill: fill, hovering: hovering))
        .jacoPointer(isEnabled)
        .onHover { hovering = isEnabled && $0 }
        .opacity(isEnabled ? 1 : jacoDisabledOpacity)
        .animation(jacoStateAnimation, value: hovering)
    }

    private struct IconStyle: ButtonStyle {
        let latched: Bool
        let fill: Color?
        let hovering: Bool
        func makeBody(configuration: Configuration) -> some View {
            configuration.label.background(Circle().fill(
                configuration.isPressed || latched ? JacoColor.bgActive : (hovering ? JacoColor.bgHover : (fill ?? .clear))
            ))
        }
    }
}

// MARK: - A2 · Fields and selection

/// Toggle — 44 × 26, on in `success`, white 22 knob, no shadow. Hover: 90% opacity.
public struct JacoToggle: View {
    @Binding private var isOn: Bool
    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled
    public init(isOn: Binding<Bool>) { _isOn = isOn }

    public var body: some View {
        Button { withAnimation(.easeOut(duration: 0.15)) { isOn.toggle() } } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule().fill(isOn ? JacoColor.success : JacoColor.borderDefault)
                Circle().fill(JacoPalette.white).frame(width: 22, height: 22).padding(2)
            }
            .frame(width: 44, height: 26)
        }
        .buttonStyle(.plain)
        .jacoPointer(isEnabled)
        .onHover { hovering = isEnabled && $0 }
        .opacity(isEnabled ? (hovering ? 0.9 : 1) : jacoDisabledOpacity)
        .animation(jacoStateAnimation, value: hovering)
    }
}

/// Standard for every input: 44 high, radius 14, filled with `bg-hover`, no border. Hover: `bg-active`;
/// focus: 2 ring. The whole box activates the field, not just the text. Modals and menus use `bg-surface`
/// as background so `bg-hover` stays visible in dark.
private struct JacoInputBox<Content: View>: View {
    let hovering: Bool
    let focused: Bool
    var isError: Bool = false
    let onActivate: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: JacoSpace.space3) { content }
            .padding(.horizontal, JacoSpace.space4)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(hovering && !focused ? JacoColor.bgActive : JacoColor.bgHover, in: RoundedRectangle(cornerRadius: JacoRadius.lg, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: JacoRadius.lg, style: .continuous)
                .strokeBorder(isError ? JacoColor.danger : (focused ? JacoColor.focusRing : .clear), lineWidth: 2))
            .contentShape(RoundedRectangle(cornerRadius: JacoRadius.lg, style: .continuous))
            .onTapGesture(perform: onActivate)
            .jacoTextCursor()
            .animation(jacoStateAnimation, value: hovering)
            .animation(jacoStateAnimation, value: focused)
    }
}

/// Search — standard input. Hover: background steps up one level; focus: 2 ring.
public struct JacoSearchField: View {
    @Binding private var text: String
    private let placeholder: String
    private let isError: Bool
    @State private var hovering = false
    @FocusState private var focused: Bool
    @Environment(\.isEnabled) private var isEnabled

    /// `isError`: border, icon and text in red.
    public init(_ placeholder: String = "Search", isError: Bool = false, text: Binding<String>) {
        self.placeholder = placeholder; self.isError = isError; _text = text
    }

    public var body: some View {
        JacoInputBox(hovering: hovering, focused: focused, isError: isError, onActivate: { focused = true }) {
            JacoIcon("search", size: 18, color: isError ? JacoColor.dangerText : JacoColor.textTertiary)
            JacoPlaceholderField(placeholder, text: $text, size: 16, focused: $focused, isError: isError)
        }
        .onHover { hovering = isEnabled && $0 }
        .opacity(isEnabled ? 1 : jacoDisabledOpacity)
    }
}

/// Text field with the placeholder drawn by us, in `text-tertiary`
/// (SwiftUI's `prompt` ignores the color on macOS).
struct JacoPlaceholderField: View {
    let placeholder: String
    @Binding var text: String
    let size: CGFloat
    var focused: FocusState<Bool>.Binding
    var isError = false

    init(_ placeholder: String, text: Binding<String>, size: CGFloat, focused: FocusState<Bool>.Binding, isError: Bool = false) {
        self.placeholder = placeholder; _text = text; self.size = size; self.focused = focused; self.isError = isError
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder).font(JacoFont.ui(size)).foregroundStyle(isError ? JacoColor.dangerText.opacity(0.7) : JacoColor.textTertiary).allowsHitTesting(false)
            }
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .focusEffectDisabled()
                .focused(focused)
                .font(JacoFont.ui(size))
                .foregroundStyle(isError ? JacoColor.dangerText : JacoColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Field — label 13/500 and the same input as search, hint 12.
/// With `error`, EVERYTHING turns red: 2 border, label, text (typed and placeholder) and the message,
/// which takes the hint's place.
public struct JacoField: View {
    private let label: String
    private let placeholder: String
    private let hint: String?
    private let error: String?
    @Binding private var text: String
    @State private var hovering = false
    @FocusState private var focused: Bool
    @Environment(\.isEnabled) private var isEnabled

    public init(_ label: String, placeholder: String, hint: String? = nil, error: String? = nil, text: Binding<String>) {
        self.label = label; self.placeholder = placeholder; self.hint = hint; self.error = error; _text = text
    }

    public var body: some View {
        let isError = error != nil
        VStack(alignment: .leading, spacing: JacoSpace.space2) {
            Text(label).jacoText(13, .medium, isError ? JacoColor.dangerText : JacoColor.textSecondary)
            JacoInputBox(hovering: hovering, focused: focused, isError: isError, onActivate: { focused = true }) {
                JacoPlaceholderField(placeholder, text: $text, size: 16, focused: $focused, isError: isError)
            }
            .onHover { hovering = isEnabled && $0 }
            if let error {
                Text(error).jacoText(12, .regular, JacoColor.dangerText)
            } else if let hint {
                Text(hint).jacoText(12, .regular, JacoColor.textTertiary)
            }
        }
        .opacity(isEnabled ? 1 : jacoDisabledOpacity)
    }
}

// MARK: - A3 · State and information

public enum JacoBadgeKind { case neutral, brand, success, warning, danger, info }

/// Badge — 6 dot + 12/600 text, capsule.
public struct JacoBadge: View {
    private let label: String
    private let kind: JacoBadgeKind
    public init(_ label: String, kind: JacoBadgeKind = .neutral) { self.label = label; self.kind = kind }

    public var body: some View {
        HStack(spacing: JacoSpace.space2) {
            Circle().fill(text).frame(width: 6, height: 6)
            Text(label).jacoText(12, .semibold, text)
        }
        .padding(.horizontal, JacoSpace.space3)
        .padding(.vertical, JacoSpace.space1)
        .background(Capsule().fill(background))
    }

    private var background: Color {
        switch kind {
        case .neutral: JacoColor.bgHover
        case .brand: JacoColor.brandSoft
        case .success: JacoColor.successSoft
        case .warning: JacoColor.warningSoft
        case .danger: JacoColor.dangerSoft
        case .info: JacoColor.infoSoft
        }
    }

    private var text: Color {
        switch kind {
        case .neutral: JacoColor.textSecondary
        case .brand: JacoColor.textBrand
        case .success: JacoColor.successText
        case .warning: JacoColor.warningText
        case .danger: JacoColor.dangerText
        case .info: JacoColor.infoText
        }
    }
}

/// Usage Meter — label/value 13 and 6 bar.
public struct JacoUsageMeter: View {
    private let label: String, value: String, progress: Double
    public init(label: String, value: String, progress: Double) { self.label = label; self.value = value; self.progress = progress }

    public var body: some View {
        VStack(spacing: JacoSpace.space2) {
            HStack {
                Text(label).jacoText(13, .medium, JacoColor.textSecondary)
                Spacer()
                Text(value).jacoText(13, .semibold, JacoColor.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(JacoColor.bgActive)
                    Capsule().fill(JacoColor.textPrimary).frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - A4/A5 · Mascot and avatars

/// All shapes fill the whole square (width and height), like the ball.
public enum JacoAvatarShape: CaseIterable { case circle, squircle, hexagon, triangle, diamond, pentagon }

/// Bot colors (the first, `brand`, is the brand color: the main Bot).
public enum JacoBotColor: CaseIterable {
    case ember, teal, violet, rose, lime, blue, amber

    public var color: Color {
        switch self {
        case .ember: JacoPalette.ember500
        case .teal: JacoColor.botTeal
        case .violet: JacoColor.botViolet
        case .rose: JacoColor.botRose
        case .lime: JacoColor.botLime
        case .blue: JacoColor.botBlue
        case .amber: JacoColor.botAmber
        }
    }
}

/// Bot Avatar: the ball turned into a shape and a color. Capsule eyes (`bot-fg`).
/// Design sizes: 24, 40, 52 and 88.
public struct JacoAvatar: View {
    private let shape: JacoAvatarShape
    private let color: Color
    private let size: CGFloat

    public init(_ shape: JacoAvatarShape = .circle, color: Color = JacoPalette.ember500, size: CGFloat = 52) {
        self.shape = shape; self.color = color; self.size = size
    }

    public init(_ shape: JacoAvatarShape = .circle, bot: JacoBotColor, size: CGFloat = 52) {
        self.init(shape, color: bot.color, size: size)
    }

    public var body: some View {
        ZStack {
            body(for: shape)
            eyes(color: JacoColor.botFg, size: size, shape: shape)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func body(for shape: JacoAvatarShape) -> some View {
        switch shape {
        case .circle: Circle().fill(color)
        case .squircle: RoundedRectangle(cornerRadius: size * 0.34, style: .continuous).fill(color)
        case .hexagon: PolygonShape(points: [(25, 0), (75, 0), (100, 50), (75, 100), (25, 100), (0, 50)], corner: 0.08).fill(color)
        case .triangle: PolygonShape(points: [(50, 0), (100, 100), (0, 100)], corner: 0.12).fill(color)
        case .diamond: PolygonShape(points: [(50, 0), (100, 50), (50, 100), (0, 50)], corner: 0.14).fill(color)
        case .pentagon: PolygonShape(points: [(50, 0), (100, 25), (100, 75), (50, 100), (0, 75), (0, 25)], corner: 0.12).fill(color)
        }
    }

    /// Vertical center of the eyes (0 = top, 1 = bottom): on pointed shapes the eyes move down into the body.
    private func eyeCenter(for shape: JacoAvatarShape) -> CGFloat {
        switch shape {
        case .triangle: 0.64
        default: 0.5
        }
    }

    private func eyes(color: Color, size: CGFloat, shape: JacoAvatarShape) -> some View {
        let w = size * 0.1, h = size * 0.25, gap = size * 0.17
        return HStack(spacing: gap) {
            Capsule().fill(color).frame(width: w, height: h)
            Capsule().fill(color).frame(width: w, height: h)
        }
        .offset(y: (eyeCenter(for: shape) - 0.5) * size)
    }
}

/// Ball: the mascot. Body always in the brand color (`ember-500`), with a highlight and `ash-1000` eyes.
public enum JacoBallState { case attentive, thinking, surprised, sleeping }

public struct JacoBall: View {
    private let size: CGFloat
    private let state: JacoBallState
    public init(size: CGFloat = 120, state: JacoBallState = .attentive) { self.size = size; self.state = state }

    public var body: some View {
        let e = eyeSpec
        ZStack {
            Circle().fill(JacoPalette.ember500)
            Circle().fill(Color.white.opacity(0.25)).frame(width: size * 0.131, height: size * 0.131)
                .position(x: size * (0.185 + 0.0655), y: size * (0.149 + 0.0655))
            HStack(spacing: size * (0.565 - 0.345 - 0.089)) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule().fill(JacoPalette.ash1000).frame(width: size * e.w, height: size * e.h)
                }
            }
            .offset(x: size * e.dx, y: size * e.dy)
        }
        .frame(width: size, height: size)
    }

    private var eyeSpec: (w: CGFloat, h: CGFloat, dx: CGFloat, dy: CGFloat) {
        switch state {
        case .attentive: (0.089, 0.214, 0, -0.03)
        case .thinking: (0.089, 0.214, 0.05, -0.08)
        case .surprised: (0.089, 0.27, 0, -0.03)
        case .sleeping: (0.13, 0.02, 0, 0.06)
        }
    }
}

/// Rounded-corner polygon that always TOUCHES all four edges of the rectangle (full width and height,
/// like the ball). Rounding trims the contour's tips, so after rounding the contour is
/// stretched to fill the whole rectangle.
struct PolygonShape: Shape {
    let points: [(CGFloat, CGFloat)]
    /// Corner radius as a fraction of the side (0.12 = 12%), measured on a 100 frame.
    let corner: CGFloat

    func path(in rect: CGRect) -> Path {
        let base = rounded(points: points.map { CGPoint(x: $0.0, y: $0.1) }, radius: corner * 100)
        let b = base.boundingRect
        guard b.width > 0, b.height > 0 else { return base }
        let t = CGAffineTransform(translationX: rect.minX, y: rect.minY)
            .scaledBy(x: rect.width / b.width, y: rect.height / b.height)
            .translatedBy(x: -b.minX, y: -b.minY)
        return base.applying(t)
    }
}

func rounded(points: [CGPoint], radius: CGFloat) -> Path {
    var path = Path()
    let n = points.count
    for i in 0..<n {
        let prev = points[(i + n - 1) % n], cur = points[i], next = points[(i + 1) % n]
        func toward(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
            let dx = b.x - a.x, dy = b.y - a.y
            let len = max(sqrt(dx * dx + dy * dy), 0.0001)
            let d = min(radius, len / 2)
            return CGPoint(x: a.x + dx / len * d, y: a.y + dy / len * d)
        }
        let p1 = toward(cur, prev), p2 = toward(cur, next)
        if i == 0 { path.move(to: p1) } else { path.addLine(to: p1) }
        path.addQuadCurve(to: p2, control: cur)
    }
    path.closeSubpath()
    return path
}
