import SwiftUI
import JacoDesignSystem

/// Sidebar: just the Bot list, search, a `+` at the top and, at the bottom, Apps and the account.
struct SidebarView: View {
    let bots: [BotItem]
    @Binding var selected: UUID?
    let newBotPressed: Bool
    let appsPressed: Bool
    let accountPressed: Bool
    let onNewBot: () -> Void
    let onApps: () -> Void
    let onAccount: () -> Void
    @State private var query = ""

    private var visible: [BotItem] {
        query.isEmpty ? bots : bots.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.preview.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (56): the macOS window buttons sit on the left; the `+` on the right.
            HStack {
                Spacer()
                JacoIconButton("plus", pressed: newBotPressed, action: onNewBot)
            }
            .padding(EdgeInsets(top: 0, leading: JacoSpace.space5, bottom: 0, trailing: JacoInset.sidebar))
            .frame(height: 56)
            .jacoWindowDragHandle()

            JacoSearchField("Search", text: $query)
                .padding(EdgeInsets(top: 0, leading: JacoInset.sidebar, bottom: JacoInset.sidebar, trailing: JacoInset.sidebar))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: JacoSpace.space1) {  // 4 gap between conversations
                    ForEach(visible) { bot in
                        JacoBotRow(shape: bot.shape, color: bot.color, name: bot.name, time: bot.time, preview: bot.preview,
                                   unread: bot.unread, selected: bot.id == selected) { selected = bot.id }
                    }
                }
                .padding(.horizontal, JacoInset.sidebar)
            }

            VStack(spacing: 0) {
                FooterRow(icon: "plug", title: "Apps", pressed: appsPressed, action: onApps)
                FooterRow(icon: "circle-user-round", title: "Ana Souza", pressed: accountPressed, action: onAccount)
            }
            .padding(EdgeInsets(top: JacoSpace.space1, leading: JacoInset.sidebar, bottom: JacoInset.sidebar, trailing: JacoInset.sidebar))
        }
        .background(JacoColor.bgApp)
    }
}

private struct FooterRow: View {
    let icon: String, title: String, pressed: Bool, action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: JacoSpace.space4) {
                JacoIcon(icon, size: 20, color: JacoColor.textTertiary)
                Text(title).jacoText(16, .medium, JacoColor.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, JacoSpace.space4)
            .frame(height: 48)
            .background(pressed ? JacoColor.bgActive : (hovering ? JacoColor.bgHover : .clear),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .jacoPointer()
        .onHover { hovering = $0 }
    }
}
