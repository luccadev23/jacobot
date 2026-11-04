# AGENTS.md · Components

SwiftUI components mirroring the `05 Components Library` board in `design/jaco.pen`. General rules: root and design system `AGENTS.md`.

## Organization

| File | Contents |
| --- | --- |
| `Atoms.swift` | `JacoButton` (primary, secondary, outline, ghost, ghostDanger, danger), `JacoIconButton`, `JacoToggle`, `JacoInputBox`, `JacoSearchField`, `JacoPlaceholderField`, `JacoField`, `JacoBadge`, `JacoUsageMeter`, `JacoAvatar` (shapes), `JacoBotColor`, `JacoBall` |
| `Molecules.swift` | bubbles, `StepLine`, attachments, composer, approval/draft cards, takeover banner, `BotRow`, list items, menus and account menu, computer screen, voice panel |
| `Modals.swift` | floating surface, `JacoNewBotModal`, `JacoAppsModal`, `JacoScrollArea` (custom scrollbar) |
| `ColorPicker.swift` | `JacoHSB` (hex ↔ HSB) and `JacoColorPicker` |

Large files: if one passes ~700 lines, split it by theme (e.g. `Menus.swift`, `Composer.swift`) instead of letting it grow.

## Rules

- One code component ↔ one Pencil component, with the same name. States (hover, focus, error, disabled) exist in the design before the code.
- Appearance parameters are semantic enums/flags (`kind`, `onCard`, `fullWidth`), not colors or measurements.
- Hover: ghost uses `bg-hover`; destructive actions use the translucent red (`danger-soft`), never a solid color at rest.
- On cards over `bg-hover`, the secondary button uses `bg-active` (`onCard`), otherwise it disappears.
- Fields: height 44, radius 14, `bg-hover` background; an error paints the label, border and hint red. Hint/error align with the field edge, with no extra inset.
- Avatars: `PolygonShape` scales the contour to touch all four edges; shapes keep the same visual size as the ball. Valid shapes: `circle, squircle, hexagon, triangle, diamond, pentagon`.
- Modals: window margin `jacoModalWindowMargin` (48); tall content becomes scrollable via `ViewThatFits`; the scrollbar sits at the modal edge and starts aligned with the first item.
- The account menu has only **Settings** and **Sign out**.
- Previews are not used; verify with snapshots.
