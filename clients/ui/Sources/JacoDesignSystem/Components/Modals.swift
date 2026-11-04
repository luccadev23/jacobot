import SwiftUI

// Rule for every modal (see B4 in the design): max height = window height − 48 on each side.
// When the content exceeds that, it scrolls and the thin bar (8 track, 4 bar) appears
// flush with the modal's right edge.

extension View {
    /// Floating surface (modal, menu): `bg-surface` background, subtle border and soft shadow ONLY on the container.
    /// The shadow sits on the background shape, so buttons and fields inside stay flat.
    public func jacoFloatingSurface(cornerRadius: CGFloat, shadowRadius: CGFloat, shadowY: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(JacoColor.bgSurface)
                    .shadow(color: JacoColor.shadow, radius: shadowRadius, y: shadowY)
            }
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).strokeBorder(JacoColor.borderSubtle, lineWidth: 1))
    }
}

/// Gap between the modal and the window edge (top and bottom).
public let jacoModalWindowMargin: CGFloat = JacoSpace.space12

// MARK: - Modal / Novo Bot

/// Modal / Novo Bot — avatar preview, name, shape and color. Width 520, radius 24, padding 24.
public struct JacoNewBotModal: View {
    private let onCancel: () -> Void
    private let onCreate: (String, JacoAvatarShape, Color) -> Void
    private let showsHandle: Bool
    private let maxHeight: CGFloat?
    @State private var name = ""
    @State private var nameError: String?
    @State private var shape: JacoAvatarShape = .circle
    /// Starts on the full-palette picker, already set to the brand color; the brand ball stays among the options.
    @State private var choice: ColorChoice = .custom
    @State private var custom = JacoHSB.brand
    @State private var pickerOpen = false

    static let nameMissing = "Give the Bot a name to create it."

    private enum ColorChoice: Equatable { case custom, preset(JacoBotColor) }

    private var currentColor: Color {
        switch choice {
        case .custom: custom.color
        case let .preset(p): p.color
        }
    }

    public init(showsHandle: Bool = false, maxHeight: CGFloat? = nil, startWithPickerOpen: Bool = false, startWithNameError: Bool = false, onCancel: @escaping () -> Void = {},
                onCreate: @escaping (String, JacoAvatarShape, Color) -> Void = { _, _, _ in }) {
        self.showsHandle = showsHandle; self.maxHeight = maxHeight; self.onCancel = onCancel; self.onCreate = onCreate
        _pickerOpen = State(initialValue: startWithPickerOpen)
        _nameError = State(initialValue: startWithNameError ? JacoNewBotModal.nameMissing : nil)
    }

    public var body: some View {
        // If it fits, show everything; if it exceeds the max height, the same content scrolls.
        ViewThatFits(in: .vertical) {
            card { form(trailing: JacoSpace.space6) }
            card { JacoScrollArea { form(trailing: 28) } }
        }
        .frame(maxHeight: maxHeight)
    }

    private func card<Inner: View>(@ViewBuilder _ inner: () -> Inner) -> some View {
        inner()
            .frame(width: 520)
            .jacoFloatingSurface(cornerRadius: 24, shadowRadius: 20, shadowY: 12)
    }

    private func form(trailing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: JacoSpace.space5) {
            if showsHandle { JacoSheetHandle() }
            VStack(alignment: .leading, spacing: JacoSpace.space1) {
                Text("New Bot").jacoText(.title2, JacoColor.textPrimary)
                Text("Pick a name, a shape and a color. You can change them later.")
                    .jacoText(15, .regular, JacoColor.textSecondary, lineHeight: 1.4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            JacoAvatar(shape, color: currentColor, size: 88).frame(maxWidth: .infinity)
            JacoField("Name", placeholder: "E.g. Reports", hint: "Shown in conversations and mentions.", error: nameError, text: $name)
                .onChange(of: name) { _, _ in nameError = nil }

            VStack(alignment: .leading, spacing: JacoSpace.space2) {
                Text("Shape").jacoText(14, .semibold, JacoColor.textTertiary)
                HStack(spacing: JacoSpace.space3) {
                    ForEach(JacoAvatarShape.allCases, id: \.self) { s in
                        HoverOption(selected: shape == s, radius: 20, action: { shape = s }) {
                            JacoAvatar(s, color: currentColor, size: 52).frame(width: 60, height: 60)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: JacoSpace.space2) {
                Text("Color").jacoText(14, .semibold, JacoColor.textTertiary)
                HStack(spacing: JacoSpace.space3) {
                    // First: every possible color. Clicking selects and opens/closes the picker.
                    HoverOption(selected: choice == .custom, radius: 20, action: {
                        if choice == .custom { withAnimation(.easeOut(duration: 0.18)) { pickerOpen.toggle() } }
                        else { choice = .custom; withAnimation(.easeOut(duration: 0.18)) { pickerOpen = true } }
                    }) {
                        PaletteSwatch(current: custom.color).frame(width: 40, height: 40)
                    }
                    ForEach(JacoBotColor.allCases, id: \.self) { c in
                        HoverOption(selected: choice == .preset(c), radius: 20, action: {
                            choice = .preset(c)
                            withAnimation(.easeOut(duration: 0.18)) { pickerOpen = false }
                        }) {
                            Circle().fill(c.color).frame(width: 28, height: 28).frame(width: 40, height: 40)
                        }
                    }
                }
                if pickerOpen {
                    JacoColorPicker(hsb: $custom)
                        .padding(.top, JacoSpace.space2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            HStack(spacing: JacoSpace.space2) {
                Spacer(minLength: 0)
                JacoButton("Cancel", kind: .ghost, action: onCancel)
                JacoButton("Create Bot", kind: .primary) {
                    if name.trimmingCharacters(in: .whitespaces).isEmpty { nameError = Self.nameMissing }
                    else { onCreate(name, shape, currentColor) }
                }
            }
        }
        .padding(EdgeInsets(top: JacoSpace.space6, leading: JacoSpace.space6, bottom: JacoSpace.space6, trailing: trailing))
    }
}

/// Full-palette swatch: a ring with every color and, in the center, the picker's current color.
struct PaletteSwatch: View {
    let current: Color
    var body: some View {
        ZStack {
            Circle().fill(AngularGradient(
                colors: (0...6).map { Color(hue: Double($0) / 6, saturation: 1, brightness: 1) }, center: .center))
                .frame(width: 28, height: 28)
            Circle().fill(current).frame(width: 14, height: 14)
                .overlay(Circle().strokeBorder(JacoColor.bgSurface, lineWidth: 2))
        }
    }
}

/// Selectable option (shape or color): hover in `bg-hover`, selected with a 2 ring in `brand`.
struct HoverOption<Content: View>: View {
    let selected: Bool
    let radius: CGFloat
    let action: () -> Void
    @ViewBuilder let content: Content
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            content
                .background(hovering && !selected ? JacoColor.bgHover : .clear, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(selected ? JacoColor.brand : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .jacoPointer()
        .onHover { hovering = $0 }
        .animation(jacoStateAnimation, value: hovering)
    }
}

/// Centered drag pill of bottom sheets (iPhone/Android).
public struct JacoSheetHandle: View {
    public init() {}
    public var body: some View {
        HStack { Spacer(); Capsule().fill(JacoColor.borderStrong).frame(width: 36, height: 5); Spacer() }
    }
}

// MARK: - Modal / Apps

public struct JacoAppEntry: Identifiable {
    public let id = UUID()
    public let icon: String, title: String, subtitle: String, status: String
    public init(icon: String, title: String, subtitle: String, status: String) {
        self.icon = icon; self.title = title; self.subtitle = subtitle; self.status = status
    }
}

public struct JacoAppSection: Identifiable {
    public let id = UUID()
    public let title: String
    public let items: [JacoAppEntry]
    public init(title: String, items: [JacoAppEntry]) { self.title = title; self.items = items }
}

/// Modal / Apps — search and a scrollable list of what can be connected. The scrollbar sits at the edge of the
/// modal and starts aligned with the top of the first app (not the section label).
public struct JacoAppsModal: View {
    private let sections: [JacoAppSection]
    private let height: CGFloat
    private let onClose: () -> Void
    @State private var query = ""

    /// `height` is the desired height; `maxHeight` (window − 48 on each side) caps it.
    public init(sections: [JacoAppSection], height: CGFloat = 680, maxHeight: CGFloat? = nil, onClose: @escaping () -> Void = {}) {
        self.sections = sections
        self.height = min(height, maxHeight ?? height)
        self.onClose = onClose
    }

    private var filtered: [JacoAppSection] {
        guard !query.isEmpty else { return sections }
        return sections.compactMap { s in
            let items = s.items.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.subtitle.localizedCaseInsensitiveContains(query) }
            return items.isEmpty ? nil : JacoAppSection(title: s.title, items: items)
        }
    }

    public var body: some View {
        VStack(spacing: JacoSpace.space4) {
            VStack(spacing: JacoSpace.space4) {
                HStack(alignment: .top, spacing: JacoSpace.space3) {
                    VStack(alignment: .leading, spacing: JacoSpace.space1) {
                        Text("Apps").jacoText(.title2, JacoColor.textPrimary)
                        Text("Connect the tools your Bots use.").jacoText(15, .regular, JacoColor.textSecondary, lineHeight: 1.4)
                    }
                    Spacer(minLength: 0)
                    JacoIconButton("x", action: onClose)
                }
                JacoSearchField("Search apps", text: $query)
            }
            .padding(EdgeInsets(top: JacoSpace.space6, leading: JacoSpace.space6, bottom: 0, trailing: JacoSpace.space6))

            JacoScrollArea(thumbTopInset: JacoSectionLabel.height) {
                VStack(spacing: 0) {
                    ForEach(filtered) { section in
                        JacoSectionLabel(section.title)
                        ForEach(section.items) { app in
                            JacoListItem(icon: app.icon, title: app.title, subtitle: app.subtitle,
                                         trailing: app.status, trailingBrand: app.status == "Connect", action: {})
                        }
                    }
                }
                .padding(EdgeInsets(top: 0, leading: JacoSpace.space6, bottom: 0, trailing: 28))
            }
            .padding(.bottom, JacoSpace.space6)
        }
        .frame(width: 560, height: height)
        .jacoFloatingSurface(cornerRadius: 24, shadowRadius: 20, shadowY: 12)
    }
}

// MARK: - Scroll with its own bar

private struct ScrollMetrics: Equatable {
    var offset: CGFloat = 0
    var content: CGFloat = 0
    var viewport: CGFloat = 0
}

/// Scrollable area with a thin bar (8 track, 4 bar) flush with the right edge.
/// The bar only appears when the content exceeds the available size.
/// `thumbTopInset` is where the bar starts, measured from the top of the content.
public struct JacoScrollArea<Content: View>: View {
    private let thumbTopInset: CGFloat
    private let content: Content
    @State private var metrics = ScrollMetrics()

    public init(thumbTopInset: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.thumbTopInset = thumbTopInset; self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            scroll
            if metrics.content > metrics.viewport + 1 { thumb }
        }
    }

    @ViewBuilder
    private var scroll: some View {
        if #available(macOS 15.0, iOS 18.0, *) {
            ScrollView(.vertical, showsIndicators: false) { content }
                .onScrollGeometryChange(for: ScrollMetrics.self, of: { geo in
                    ScrollMetrics(offset: geo.contentOffset.y + geo.contentInsets.top,
                                  content: geo.contentSize.height,
                                  viewport: geo.containerSize.height)
                }, action: { _, new in metrics = new })
        } else {
            // macOS 14 / iOS 17: without the scroll measurement, uses the system bar.
            ScrollView(.vertical, showsIndicators: true) { content }
        }
    }

    private var thumb: some View {
        let track = max(metrics.viewport - thumbTopInset - JacoSpace.space1, 1)
        let size = min(96, track)
        let range = max(metrics.content - metrics.viewport, 1)
        let progress = min(max(metrics.offset / range, 0), 1)
        return Capsule().fill(JacoColor.borderStrong)
            .frame(width: 4, height: size)
            .frame(width: 8)
            .offset(y: thumbTopInset + (track - size) * progress)
            .allowsHitTesting(false)
    }
}
