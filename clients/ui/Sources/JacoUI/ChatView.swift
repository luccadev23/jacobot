import SwiftUI
import JacoDesignSystem

/// Chat: the Bot name at the top and nothing else: bubbles, steps, attachment, approval and the composer.
struct ChatView: View {
    let bot: BotItem
    let panelOpen: Bool
    let onTogglePanel: () -> Void
    @State private var draft = ""
    @State private var extra: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: JacoSpace.space3) {
                JacoAvatar(bot.shape, bot: bot.color, size: 24)
                Text(bot.name).jacoText(17, .semibold, JacoColor.textPrimary)
                Spacer()
                JacoIconButton("monitor", pressed: panelOpen, action: onTogglePanel)
            }
            .padding(.horizontal, JacoInset.pane)
            .frame(height: 56)
            .jacoWindowDragHandle()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("9:41").jacoText(14, .regular, JacoColor.textTertiary).frame(maxWidth: .infinity)
                    JacoUserBubble("Gather this week's sales and send the summary to the team.")
                    JacoStepLine(icon: "globe", "Opening the sales dashboard in the browser")
                    JacoStepLine(icon: "download", "Exporting the week 42 spreadsheet")
                    JacoBotBubble("All done. The summary is below and the full spreadsheet is attached.")
                    JacoAttachment(title: "Sales week 42.pdf", meta: "12 pages · 1.2 MB")
                    JacoUserBubble("Perfect. You can send it to the sales team.", textWidth: 300)
                    JacoApprovalCard(
                        expires: "expira em 28 min",
                        message: "Send the weekly summary by email to 3 people on the sales team.",
                        detail: "To: ana@company.com, rui@company.com, lia@company.com"
                    )
                    ForEach(Array(extra.enumerated()), id: \.offset) { _, text in JacoUserBubble(text) }
                }
                .padding(EdgeInsets(top: JacoSpace.space1, leading: JacoInset.pane, bottom: JacoSpace.space4, trailing: JacoInset.pane))
            }

            JacoComposer(text: $draft, placeholder: "Message \(bot.name)") {
                let text = draft.trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty else { return }
                extra.append(text); draft = ""
            }
            .padding(EdgeInsets(top: 0, leading: JacoInset.pane, bottom: JacoSpace.space6, trailing: JacoInset.pane))
        }
        .background(JacoColor.bgSurface)
    }
}
