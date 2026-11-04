# AGENTS.md · JacoUI

Screens and flows assembled from `JacoDesignSystem` components. No platform dependency beyond SwiftUI. General rules: root `AGENTS.md`.

## Files

| File | Role |
| --- | --- |
| `MainView.swift` | `JacoMainView`: root layout, overlays (modals, account menu), focus dismissal |
| `SidebarView.swift` | sidebar: draggable header, bot list, apps, account |
| `ChatView.swift` | conversation: bubbles, steps, composer, approvals |
| `PanelView.swift` | side panel: profile, settings, computer, voice |
| `MockData.swift` | sample data (9 bots, app sections) |

## Rules

- Composition only: no new reusable component here. If it is reusable, it goes to the design system (and to Pencil).
- Data comes from `MockData`. When a backend exists, a model/protocol layer will be added; do not wire network or AI here.
- `JacoMainView` takes state parameters (`overlay`, `accountMenu`, `pickerOpen`, `nameError`) used by snapshot mode. Keep them: they are how each state is verified.
- Modals live in a `GeometryReader` with `maxHeight` so they scroll when the window is short.
- The sidebar header is 56pt and is the only area that drags the window; the rest of the screen must not move it.
- Sidebar spacing: `JacoInset.sidebar` at the edges and `space1` between rows.
- Bots with avatar shapes: Support = pentagon, Inbox = diamond.
- Do not show texts like "report computer active" (Portuguese in the old design): they were removed from the design.
