import SwiftUI
import JacoDesignSystem

/// Sample data (same texts as the design). To be replaced by the real data layer.
struct BotItem: Identifiable {
    let id = UUID()
    let name: String
    let shape: JacoAvatarShape
    let color: JacoBotColor
    let time: String
    let preview: String
    let unread: Bool
}

enum MockData {
    static let bots: [BotItem] = [
        BotItem(name: "Reports", shape: .circle, color: .ember, time: "7:34", preview: "Weekly summary ready to review", unread: true),
        BotItem(name: "Research", shape: .squircle, color: .violet, time: "7:12", preview: "3 new sources about the industry", unread: false),
        BotItem(name: "Inbox", shape: .diamond, color: .lime, time: "6:58", preview: "Inbox zero. 2 replies ready", unread: false),
        BotItem(name: "Sales", shape: .hexagon, color: .teal, time: "Yesterday", preview: "Proposals awaiting approval", unread: true),
        BotItem(name: "Recruiting", shape: .circle, color: .amber, time: "Yesterday", preview: "List of 6 candidates ready", unread: false),
        BotItem(name: "Marketing", shape: .squircle, color: .rose, time: "Tue", preview: "Copy variations to review", unread: false),
        BotItem(name: "Support", shape: .pentagon, color: .blue, time: "Tue", preview: "12 tickets resolved, 2 escalated", unread: false),
        BotItem(name: "Expenses", shape: .triangle, color: .rose, time: "Mon", preview: "Receipts logged, 1 needs you", unread: false),
        BotItem(name: "Invoices", shape: .hexagon, color: .violet, time: "Mon", preview: "9 invoices downloaded from the portals", unread: false),
    ]

    static let appSections: [JacoAppSection] = [
        JacoAppSection(title: "Connected", items: [
            JacoAppEntry(icon: "mail", title: "Gmail", subtitle: "Read, search and prepare drafts", status: "Connected"),
            JacoAppEntry(icon: "calendar", title: "Calendar", subtitle: "View and create events", status: "Connected"),
            JacoAppEntry(icon: "hard-drive", title: "Drive", subtitle: "Files and spreadsheets", status: "Connected"),
        ]),
        JacoAppSection(title: "Available", items: [
            JacoAppEntry(icon: "hash", title: "Slack", subtitle: "Post and trigger routines", status: "Connect"),
            JacoAppEntry(icon: "git-branch", title: "GitHub", subtitle: "Issues, PRs and events", status: "Connect"),
            JacoAppEntry(icon: "file-text", title: "Notion", subtitle: "Pages and databases", status: "Connect"),
            JacoAppEntry(icon: "square-kanban", title: "Linear", subtitle: "Tasks and cycles", status: "Connect"),
            JacoAppEntry(icon: "inbox", title: "Outlook", subtitle: "Email and calendar", status: "Connect"),
            JacoAppEntry(icon: "message-circle", title: "WhatsApp Business", subtitle: "Messages and customer service", status: "Connect"),
            JacoAppEntry(icon: "users", title: "Microsoft Teams", subtitle: "Messages and meetings", status: "Connect"),
            JacoAppEntry(icon: "contact", title: "Zoho CRM", subtitle: "Contacts and deals", status: "Connect"),
            JacoAppEntry(icon: "calculator", title: "QuickBooks", subtitle: "Accounting and invoices", status: "Connect"),
            JacoAppEntry(icon: "credit-card", title: "Stripe Link", subtitle: "Payments and billing", status: "Connect"),
            JacoAppEntry(icon: "network", title: "Tailscale", subtitle: "Private network", status: "Connect"),
            JacoAppEntry(icon: "key-round", title: "1Password", subtitle: "Vault logins", status: "Connect"),
        ]),
        JacoAppSection(title: "Other", items: [
            JacoAppEntry(icon: "plus", title: "MCP Server", subtitle: "Add by URL or command", status: "Add"),
        ]),
    ]
}
