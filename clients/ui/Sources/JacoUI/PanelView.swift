import SwiftUI
import JacoDesignSystem

/// Right panel: the Bot's computer and plain lists of Routines, Skills and Memory, without cards.
struct PanelView: View {
    let bot: BotItem
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                JacoIconButton("x", action: onClose)
            }
            .padding(.horizontal, JacoSpace.space4)
            .frame(height: 56)
            .jacoWindowDragHandle()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: JacoSpace.space1) {
                    JacoComputerScreen(height: 240)
                    JacoTakeoverBanner(message: "Solve the CAPTCHA.")

                    JacoSectionLabel("Routines")
                    JacoListItem(icon: "timer", title: "Sales summary", subtitle: "Every business day at 8am")
                    JacoListItem(icon: "timer", title: "Email triage", subtitle: "Every 2 hours")
                    JacoListItem(icon: "circle-pause", title: "Monthly report", subtitle: "Paused")

                    JacoSectionLabel("Skills")
                    JacoListItem(icon: "book-open", title: "Export dashboard report", subtitle: "Learned by demonstration")
                    JacoListItem(icon: "book-open", title: "Summarize customer emails", subtitle: "Written instructions")

                    JacoSectionLabel("Memory")
                    JacoListItem(icon: "brain", title: "Prefers summaries up to 5 lines", subtitle: "October 12")
                    JacoListItem(icon: "brain", title: "Amounts always in reais", subtitle: "October 14")
                }
                .padding(EdgeInsets(top: 0, leading: JacoInset.pane, bottom: JacoSpace.space4, trailing: JacoInset.pane))
            }
        }
        .background(JacoColor.bgSurface)
    }
}
