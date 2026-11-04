import SwiftUI
import JacoDesignSystem

/// Main window measurements on macOS (1512 × 982 in the design).
enum MacMetrics {
    static let sidebarWidth: CGFloat = 380
    static let panelWidth: CGFloat = 440
    /// Distance from the sidebar footer to the account menu (account row 48 + 12 margin + 8 breathing room).
    static let accountMenuBottom: CGFloat = JacoInset.sidebar + 48 + 8
    /// Aligns the menu's right edge (260) with the account row's right edge (top-end).
    static let accountMenuLeading: CGFloat = sidebarWidth - JacoInset.sidebar - 260
}

public enum JacoOverlay: String { case newBot, apps }

public struct JacoMainView: View {
    @State private var selected: UUID? = MockData.bots.first?.id
    @State private var panelOpen = true
    @State private var overlay: JacoOverlay?
    @State private var accountMenuOpen: Bool
    private let pickerOpen: Bool
    private let nameError: Bool

    /// `overlay` and `accountMenuOpen` open a state directly (used by snapshots and previews).
    public init(overlay: JacoOverlay? = nil, accountMenuOpen: Bool = false, pickerOpen: Bool = false, nameError: Bool = false) {
        _overlay = State(initialValue: overlay)
        _accountMenuOpen = State(initialValue: accountMenuOpen)
        self.pickerOpen = pickerOpen
        self.nameError = nameError
    }

    private var bot: BotItem { MockData.bots.first { $0.id == selected } ?? MockData.bots[0] }

    public var body: some View {
        ZStack {
            HStack(spacing: 0) {
                SidebarView(
                    bots: MockData.bots, selected: $selected,
                    newBotPressed: overlay == .newBot, appsPressed: overlay == .apps, accountPressed: accountMenuOpen,
                    onNewBot: { overlay = .newBot },
                    onApps: { overlay = .apps },
                    onAccount: { accountMenuOpen.toggle() }
                )
                .frame(width: MacMetrics.sidebarWidth)
                .overlay(alignment: .trailing) { Rectangle().fill(JacoColor.borderSubtle).frame(width: 1) }

                ChatView(bot: bot, panelOpen: panelOpen) { withAnimation(.easeOut(duration: 0.18)) { panelOpen.toggle() } }
                    .id(bot.id)

                if panelOpen {
                    PanelView(bot: bot) { withAnimation(.easeOut(duration: 0.18)) { panelOpen = false } }
                        .frame(width: MacMetrics.panelWidth)
                        .overlay(alignment: .leading) { Rectangle().fill(JacoColor.borderSubtle).frame(width: 1) }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .background(JacoColor.bgSurface)

            if accountMenuOpen {
                Color.clear.contentShape(Rectangle()).onTapGesture { accountMenuOpen = false }
                VStack {
                    Spacer()
                    HStack {
                        JacoAccountMenu(onSettings: { accountMenuOpen = false },
                                        onLogout: { accountMenuOpen = false })
                            .padding(.leading, MacMetrics.accountMenuLeading)
                        Spacer()
                    }
                    .padding(.bottom, MacMetrics.accountMenuBottom)
                }
                .transition(.opacity)
            }

            if let overlay {
                JacoColor.bgOverlay.ignoresSafeArea().onTapGesture { self.overlay = nil }
                GeometryReader { geo in
                    let maxHeight = geo.size.height - 2 * jacoModalWindowMargin  // max height of every modal
                    Group {
                        switch overlay {
                        case .newBot:
                            JacoNewBotModal(maxHeight: maxHeight, startWithPickerOpen: pickerOpen, startWithNameError: nameError, onCancel: { self.overlay = nil }, onCreate: { _, _, _ in self.overlay = nil })
                        case .apps:
                            JacoAppsModal(sections: MockData.appSections, height: 700, maxHeight: maxHeight, onClose: { self.overlay = nil })
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .transition(.scale(scale: 0.98).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.15), value: overlay)
        .animation(.easeOut(duration: 0.12), value: accountMenuOpen)
        // The sidebar header starts at the top of the window, on the same line as the macOS buttons.
        .ignoresSafeArea(.container, edges: .top)
        .jacoDismissFocusOnOutsideClick()
    }
}
