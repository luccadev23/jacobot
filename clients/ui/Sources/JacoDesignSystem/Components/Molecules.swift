import SwiftUI

// MARK: - B1 · Conversation

/// Message / User — black bubble (`text-primary`), `text-inverse` text 17/1.4, radius 22, padding 12 × 20.
public struct JacoUserBubble: View {
    private let text: String
    private let textWidth: CGFloat
    public init(_ text: String, textWidth: CGFloat = 360) { self.text = text; self.textWidth = textWidth }

    public var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Text(text)
                .jacoText(17, .regular, JacoColor.textInverse, lineHeight: 1.4)
                .frame(maxWidth: textWidth, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, JacoSpace.space5)
                .padding(.vertical, JacoSpace.space3)
                .background(JacoColor.textPrimary, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}

/// Message / Bot — gray bubble (`bg-hover`), no avatar or name.
public struct JacoBotBubble: View {
    private let text: String
    private let textWidth: CGFloat
    public init(_ text: String, textWidth: CGFloat = 420) { self.text = text; self.textWidth = textWidth }

    public var body: some View {
        HStack(spacing: 0) {
            Text(text)
                .jacoText(17, .regular, JacoColor.textPrimary, lineHeight: 1.4)
                .frame(maxWidth: textWidth, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, JacoSpace.space5)
                .padding(.vertical, JacoSpace.space3)
                .background(JacoColor.bgHover, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            Spacer(minLength: 0)
        }
    }
}

/// Step Line — Bot step in small text (14, `text-tertiary`).
public struct JacoStepLine: View {
    private let icon: String, text: String
    public init(icon: String, _ text: String) { self.icon = icon; self.text = text }

    public var body: some View {
        HStack(spacing: JacoSpace.space2) {
            JacoIcon(icon, size: 14, color: JacoColor.textTertiary)
            Text(text).jacoText(14, .regular, JacoColor.textTertiary)
            Spacer(minLength: 0)
        }
        .frame(height: 24)
    }
}

/// Attachment — 340 wide, radius 16, 40 type icon.
public struct JacoAttachment: View {
    private let kind: String, title: String, meta: String
    @State private var hovering = false
    public init(kind: String = "PDF", title: String, meta: String) { self.kind = kind; self.title = title; self.meta = meta }

    public var body: some View {
        HStack(spacing: JacoSpace.space3) {
            Text(kind).jacoText(11, .bold, JacoColor.dangerText)
                .frame(width: 40, height: 40)
                .background(JacoColor.dangerSoft, in: RoundedRectangle(cornerRadius: JacoRadius.md, style: .continuous))
            VStack(alignment: .leading, spacing: 0) {
                Text(title).jacoText(15, .semibold, JacoColor.textPrimary)
                Text(meta).jacoText(13, .regular, JacoColor.textSecondary)
            }
            Spacer(minLength: 0)
            JacoIcon("download", size: 18, color: JacoColor.textSecondary)
        }
        .padding(.horizontal, JacoSpace.space4)
        .padding(.vertical, JacoSpace.space3)
        .frame(width: 340)
        .background(hovering ? JacoColor.bgHover : JacoColor.bgRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(JacoColor.borderSubtle, lineWidth: 1))
        .jacoPointer()
        .onHover { hovering = $0 }
        .animation(jacoStateAnimation, value: hovering)
    }
}

/// Composer — 56 pill, no shadow. `+` on the left and microphone (or send) on the right.
/// Focus: `border-strong` border. Button hover: `bg-active` on the `+` and 85% opacity on microphone/send.
public struct JacoComposer: View {
    @Binding private var text: String
    private let placeholder: String
    private let onSend: () -> Void
    @FocusState private var focused: Bool
    @State private var hoverPlus = false
    @State private var hoverSend = false

    public init(text: Binding<String>, placeholder: String, onSend: @escaping () -> Void = {}) {
        _text = text; self.placeholder = placeholder; self.onSend = onSend
    }

    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespaces).isEmpty }

    public var body: some View {
        HStack(spacing: JacoSpace.space3) {
            Button {} label: {
                JacoIcon("plus", size: 20, color: JacoColor.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(hoverPlus ? JacoColor.bgActive : JacoColor.bgHover))
            }
            .buttonStyle(JacoPressStyle())
            .jacoPointer()
            .onHover { hoverPlus = $0 }

            JacoPlaceholderField(placeholder, text: $text, size: 17, focused: $focused)
                .onSubmit(onSend)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { focused = true }
                .jacoTextCursor()

            Button(action: onSend) {
                JacoIcon(isEmpty ? "mic" : "arrow-up", size: 20, color: isEmpty ? JacoColor.textInverse : JacoColor.textOnBrand)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(isEmpty ? JacoColor.textPrimary : JacoColor.brand))
            }
            .buttonStyle(JacoPressStyle())
            .jacoPointer()
            .opacity(hoverSend ? 0.85 : 1)
            .onHover { hoverSend = $0 }
        }
        .padding(.horizontal, JacoSpace.space2)
        .frame(height: 56)
        .background(JacoColor.bgRaised, in: Capsule())
        .overlay(Capsule().strokeBorder(focused ? JacoColor.borderStrong : JacoColor.borderDefault, lineWidth: 1))
        .animation(jacoStateAnimation, value: hoverPlus)
        .animation(jacoStateAnimation, value: hoverSend)
        .animation(jacoStateAnimation, value: focused)
    }
}

// MARK: - B2 · Decisions and notices

/// Approval — the Bot asks for permission. `bg-hover` background, radius 22, padding 20.
public struct JacoApprovalCard: View {
    private let title: String, expires: String, message: String, detail: String
    private let onDeny: () -> Void, onAlways: () -> Void, onAllow: () -> Void

    public init(title: String = "Needs your approval", expires: String, message: String, detail: String,
                onDeny: @escaping () -> Void = {}, onAlways: @escaping () -> Void = {}, onAllow: @escaping () -> Void = {}) {
        self.title = title; self.expires = expires; self.message = message; self.detail = detail
        self.onDeny = onDeny; self.onAlways = onAlways; self.onAllow = onAllow
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: JacoSpace.space4) {
            HStack(spacing: JacoSpace.space2) {
                Text(title).jacoText(17, .semibold, JacoColor.textPrimary)
                Spacer(minLength: 0)
                Text(expires).jacoText(13, .regular, JacoColor.textTertiary)
            }
            Text(message).jacoText(15, .regular, JacoColor.textSecondary, lineHeight: 1.4)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(JacoFont.mono(13)).foregroundStyle(JacoColor.textSecondary).lineSpacing(13 * (1.5 - 1.32))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(JacoSpace.space3)
                .background(JacoColor.bgSunken, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            HStack(spacing: JacoSpace.space2) {
                Spacer(minLength: 0)
                JacoButton("Deny", kind: .ghost, onCard: true, action: onDeny)
                JacoButton("Always", kind: .secondary, onCard: true, action: onAlways)
                JacoButton("Allow", kind: .primary, action: onAllow)
            }
        }
        .padding(JacoSpace.space5)
        .frame(width: 520)
        .background(JacoColor.bgHover, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// Draft — draft waiting for you to send.
public struct JacoDraftCard: View {
    private let subject: String, content: String
    public init(subject: String, content: String) { self.subject = subject; self.content = content }

    public var body: some View {
        VStack(alignment: .leading, spacing: JacoSpace.space3) {
            HStack(spacing: JacoSpace.space2) {
                Text("Email draft").jacoText(17, .semibold, JacoColor.textPrimary)
                Spacer(minLength: 0)
                Text("waiting for you").jacoText(13, .medium, JacoColor.warningText)
            }
            Text(subject).jacoText(15, .semibold, JacoColor.textPrimary)
            Text(content).jacoText(15, .regular, JacoColor.textSecondary, lineHeight: 1.4).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: JacoSpace.space2) {
                Spacer(minLength: 0)
                JacoButton("Discard", kind: .ghost, onCard: true)
                JacoButton("Send", icon: "arrow-up", kind: .primary)
            }
        }
        .padding(JacoSpace.space5)
        .frame(width: 520)
        .background(JacoColor.bgHover, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// Takeover — asks you to take over a step (CAPTCHA, SSO…). The text wraps; the button never overlaps it.
public struct JacoTakeoverBanner: View {
    private let title: String, message: String
    private let onTake: () -> Void
    public init(title: String = "A step only you can do", message: String, onTake: @escaping () -> Void = {}) {
        self.title = title; self.message = message; self.onTake = onTake
    }

    public var body: some View {
        HStack(spacing: JacoSpace.space3) {
            JacoIcon("hand", size: 22, color: JacoColor.warningText)
            VStack(alignment: .leading, spacing: JacoSpace.space1) {
                Text(title).jacoText(16, .semibold, JacoColor.warningText).fixedSize(horizontal: false, vertical: true)
                Text(message).jacoText(14, .regular, JacoColor.warningText).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            JacoButton("Take over", kind: .primary, action: onTake)
        }
        .padding(JacoSpace.space4)
        .background(JacoColor.warningSoft, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - B3 · Lists

/// Bot Row — 76 high, avatar 52, name 17/600, time 14, preview 15.
public struct JacoBotRow: View {
    private let shape: JacoAvatarShape, color: JacoBotColor
    private let name: String, time: String, preview: String
    private let unread: Bool, selected: Bool
    private let action: () -> Void
    @State private var hovering = false

    public init(shape: JacoAvatarShape = .circle, color: JacoBotColor = .ember, name: String, time: String, preview: String,
                unread: Bool = false, selected: Bool = false, action: @escaping () -> Void = {}) {
        self.shape = shape; self.color = color; self.name = name; self.time = time; self.preview = preview
        self.unread = unread; self.selected = selected; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: JacoSpace.space4) {
                JacoAvatar(shape, bot: color, size: 52)
                VStack(alignment: .leading, spacing: JacoSpace.space1) {
                    HStack(spacing: JacoSpace.space2) {
                        Text(name).jacoText(17, .semibold, JacoColor.textPrimary).lineLimit(1)
                        Spacer(minLength: 0)
                        if unread { Circle().fill(JacoColor.brand).frame(width: 8, height: 8) }
                        Text(time).jacoText(14, .regular, JacoColor.textTertiary)
                    }
                    Text(preview).jacoText(15, .regular, JacoColor.textSecondary).lineLimit(1)
                }
            }
            .padding(.horizontal, JacoSpace.space4)
            .frame(height: 76)
            .background(selected ? (hovering ? JacoColor.bgActive : JacoColor.bgHover) : (hovering ? JacoColor.bgHover : .clear),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .jacoPointer()
        .onHover { hovering = $0 }
        .animation(jacoStateAnimation, value: hovering)
    }
}

/// List Item — icon 20, title 16/500, subtitle 15, trailing text 14.
public struct JacoListItem: View {
    private let icon: String?, title: String, subtitle: String?, trailing: String?
    private let trailingBrand: Bool
    private let action: (() -> Void)?
    @State private var hovering = false

    public init(icon: String? = nil, title: String, subtitle: String? = nil, trailing: String? = nil, trailingBrand: Bool = false, action: (() -> Void)? = nil) {
        self.icon = icon; self.title = title; self.subtitle = subtitle; self.trailing = trailing
        self.trailingBrand = trailingBrand; self.action = action
    }

    public var body: some View {
        HStack(spacing: JacoSpace.space4) {
            if let icon { JacoIcon(icon, size: 20, color: JacoColor.textTertiary) }
            VStack(alignment: .leading, spacing: JacoSpace.space1) {
                Text(title).jacoText(16, .medium, JacoColor.textPrimary)
                if let subtitle { Text(subtitle).jacoText(15, .regular, JacoColor.textSecondary) }
            }
            Spacer(minLength: 0)
            if let trailing {
                Text(trailing).jacoText(14, trailingBrand ? .semibold : .regular, trailingBrand ? JacoColor.textBrand : JacoColor.textTertiary)
            }
        }
        .padding(.vertical, JacoSpace.space3)
        .padding(.horizontal, action != nil ? JacoSpace.space3 : 0)
        .background(action != nil && hovering ? JacoColor.bgHover : .clear, in: RoundedRectangle(cornerRadius: JacoRadius.md, style: .continuous))
        .padding(.horizontal, action != nil ? -JacoSpace.space3 : 0)
        .contentShape(Rectangle())
        .onTapGesture { action?() }
        .jacoPointer(action != nil)
        .onHover { hovering = action != nil && $0 }
        .animation(jacoStateAnimation, value: hovering)
    }
}

/// List Item / Toggle
public struct JacoToggleItem: View {
    private let title: String, subtitle: String
    @Binding private var isOn: Bool
    public init(title: String, subtitle: String, isOn: Binding<Bool>) { self.title = title; self.subtitle = subtitle; _isOn = isOn }

    public var body: some View {
        HStack(spacing: JacoSpace.space4) {
            VStack(alignment: .leading, spacing: JacoSpace.space1) {
                Text(title).jacoText(16, .medium, JacoColor.textPrimary)
                Text(subtitle).jacoText(15, .regular, JacoColor.textSecondary)
            }
            Spacer(minLength: 0)
            JacoToggle(isOn: $isOn)
        }
        .padding(.vertical, JacoSpace.space3)
    }
}

/// Section Label — 14/600 `text-tertiary`, 16 above and 4 below (37 total).
public struct JacoSectionLabel: View {
    public static let height: CGFloat = 37
    private let text: String
    public init(_ text: String) { self.text = text }

    public var body: some View {
        Text(text).jacoText(14, .semibold, JacoColor.textTertiary)
            .padding(.top, JacoSpace.space4).padding(.bottom, JacoSpace.space1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - A6/B4 · Menu

/// A menu entry: a button (with a destructive variant) or a separator. The separator can go in any position.
public enum JacoMenuEntry {
    case item(_ title: String, icon: String, destructive: Bool = false, action: () -> Void = {})
    case separator
}

/// Menu Separator — 1 hairline in `border-default`, edge to edge of the menu, with 4 breathing room above and below.
public struct JacoMenuSeparator: View {
    public init() {}
    public var body: some View {
        Rectangle().fill(JacoColor.borderDefault).frame(height: 1).padding(.vertical, JacoSpace.space1)
    }
}

/// Menu item = Button / Ghost at full width, content on the left (transparent, hover `bg-hover`). `destructive` uses Ghost · Danger.
public struct JacoMenuItem: View {
    private let icon: String, label: String
    private let destructive: Bool
    private let action: () -> Void

    public init(icon: String, _ label: String, destructive: Bool = false, action: @escaping () -> Void = {}) {
        self.icon = icon; self.label = label; self.destructive = destructive; self.action = action
    }

    public var body: some View {
        JacoButton(label, icon: icon, kind: destructive ? .ghostDanger : .ghost, fullWidth: true, leading: true, action: action)
    }
}

/// Menu — floating container (radius 16, `bg-surface`) with buttons and separators. Separators only appear
/// where defined in `entries` and run edge to edge; buttons have 8 side margin.
public struct JacoMenu<Header: View>: View {
    private let width: CGFloat
    private let header: Header
    private let entries: [JacoMenuEntry]

    public init(width: CGFloat = 260, entries: [JacoMenuEntry], @ViewBuilder header: () -> Header) {
        self.width = width; self.entries = entries; self.header = header()
    }

    public var body: some View {
        VStack(spacing: JacoSpace.space1) {
            header
            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                switch entry {
                case let .item(title, icon, destructive, action):
                    JacoMenuItem(icon: icon, title, destructive: destructive, action: action)
                        .padding(.horizontal, JacoSpace.space2)
                case .separator:
                    JacoMenuSeparator()
                }
            }
        }
        .padding(.vertical, JacoSpace.space2)
        .frame(width: width)
        .jacoFloatingSurface(cornerRadius: 16, shadowRadius: 8, shadowY: 4)
    }
}

extension JacoMenu where Header == EmptyView {
    public init(width: CGFloat = 260, entries: [JacoMenuEntry]) {
        self.init(width: width, entries: entries) { EmptyView() }
    }
}

/// Account Menu — account dropdown: just the options (Settings and Sign out), no header and no separator.
/// For other content, pass `entries` (options and, if needed, `.separator`).
public struct JacoAccountMenu: View {
    private let entries: [JacoMenuEntry]

    public init(entries: [JacoMenuEntry]) { self.entries = entries }

    public init(onSettings: @escaping () -> Void = {}, onLogout: @escaping () -> Void = {}) {
        self.init(entries: [
            .item("Settings", icon: "settings", action: onSettings),
            .item("Sign out", icon: "log-out", destructive: true, action: onLogout),
        ])
    }

    public var body: some View { JacoMenu(entries: entries) }
}

// MARK: - C1 · Computer

/// Screen Thumb — the Bot's cloud computer: browser with URL and content, dock and cursor.
public struct JacoComputerScreen: View {
    private let height: CGFloat?
    public init(height: CGFloat? = 240) { self.height = height }

    public var body: some View {
        VStack(spacing: JacoSpace.space3) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: JacoSpace.space2) {
                    browser
                    HStack(spacing: JacoSpace.space3) {
                        ForEach(["globe", "terminal", "folder", "mail"], id: \.self) { JacoIcon($0, size: 16, color: JacoColor.textSecondary) }
                    }
                    .padding(.horizontal, JacoSpace.space3).padding(.vertical, JacoSpace.space1)
                    .background(JacoColor.bgRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(JacoColor.borderSubtle, lineWidth: 1))
                    .frame(height: 32)
                }
                .padding(EdgeInsets(top: JacoSpace.space3, leading: JacoSpace.space3, bottom: JacoSpace.space2, trailing: JacoSpace.space3))
                JacoIcon("mouse-pointer-2", size: 18, color: JacoColor.textPrimary).offset(x: 250, y: 112)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(JacoColor.bgSunken)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(JacoColor.borderSubtle, lineWidth: 1))
        }
        .padding(.bottom, JacoSpace.space3)
    }

    private var browser: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: JacoSpace.space1) {
                Text("Sales").jacoText(11, .medium, JacoColor.textPrimary)
                    .padding(.horizontal, JacoSpace.space3).padding(.vertical, JacoSpace.space1)
                    .background(JacoColor.bgRaised, in: UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8))
                Text("Spreadsheet").jacoText(11, .regular, JacoColor.textTertiary)
                    .padding(.horizontal, JacoSpace.space3).padding(.vertical, JacoSpace.space1)
                Spacer(minLength: 0)
            }
            .padding(EdgeInsets(top: JacoSpace.space1, leading: JacoSpace.space2, bottom: 0, trailing: JacoSpace.space2))
            .frame(height: 28).background(JacoColor.bgHover)
            HStack(spacing: JacoSpace.space2) {
                JacoIcon("lock", size: 12, color: JacoColor.textTertiary)
                Text("dashboard.company.com/sales").jacoText(11, .regular, JacoColor.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, JacoSpace.space3).frame(height: 28)
            .overlay(alignment: .bottom) { Rectangle().fill(JacoColor.borderSubtle).frame(height: 1) }
            VStack(alignment: .leading, spacing: JacoSpace.space3) {
                RoundedRectangle(cornerRadius: 4).fill(JacoColor.textTertiary).frame(width: 120, height: 8)
                HStack(alignment: .bottom, spacing: JacoSpace.space2) {
                    ForEach(Array([32, 52, 40, 68, 48, 60].enumerated()), id: \.offset) { i, h in
                        RoundedRectangle(cornerRadius: 4).fill(i == 3 ? JacoPalette.ember500 : JacoColor.bgActive).frame(width: 28, height: CGFloat(h))
                    }
                }
                .frame(height: 72, alignment: .bottom)
                RoundedRectangle(cornerRadius: 3).fill(JacoColor.bgActive).frame(width: 260, height: 6)
            }
            .padding(JacoSpace.space3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(JacoColor.bgRaised)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))
        .overlay(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10).strokeBorder(JacoColor.borderSubtle, lineWidth: 1))
    }
}

/// Voice — the ball, audio waveform and the end button.
public struct JacoVoicePanel: View {
    private let onEnd: () -> Void
    public init(onEnd: @escaping () -> Void = {}) { self.onEnd = onEnd }

    public var body: some View {
        VStack(spacing: 32) {
            JacoBall(size: 120)
            HStack(alignment: .center, spacing: JacoSpace.space1) {
                ForEach(Array([10, 24, 38, 18, 44, 28, 12, 34, 16].enumerated()), id: \.offset) { _, h in
                    RoundedRectangle(cornerRadius: 2.5).fill(JacoColor.textSecondary).frame(width: 5, height: CGFloat(h))
                }
            }
            .frame(height: 44)
            JacoButton("End", icon: "phone-off", kind: .danger, action: onEnd)
        }
        .frame(width: 360)
    }
}
