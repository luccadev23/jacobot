# AGENTS.md · JacoDesignSystem

Tokens, typography, icons, interaction helpers and components. Shared between macOS and iOS. General rules are in the root `AGENTS.md`; only specifics are here.

## Files

| File | Role |
| --- | --- |
| `ColorSupport.swift` | `Color.jacoDynamic` (light/dark) and hex conversion |
| `Typography.swift` | font registration (`JacoFont.register`) and `.jacoText` |
| `LucideIcon.swift` | `JacoIcon` and the SVG → `Path` parser |
| `Pointer.swift` | `jacoPointer()` / `jacoTextCursor()` |
| `FocusDismiss.swift` | drop focus when clicking outside fields |
| `WindowDrag.swift` | window drag area (`performDrag`) |
| `Components/` | atoms, molecules, modals, color picker (see `Components/AGENTS.md`) |
| `Generated/` | `Tokens.swift`, generated |
| `Resources/Fonts` | Inter (Regular/Medium/SemiBold/Bold) and JetBrains Mono, with licenses |
| `Resources/Icons` | Lucide SVGs |

## Rules

- Resources are loaded through `Bundle.module` (`.copy`). Do not use an asset catalog.
- New font: file plus license in `Resources/Fonts`, then register it in `JacoFont.register`.
- New icon: SVG in `Resources/Icons`. The parser supports `path`, `circle`, `rect`, `line`, `polyline` (arcs become Béziers). Anything else requires extending the parser, with a test.
- AppKit code only behind `#if canImport(AppKit)`; this target also compiles for iOS.
- Cursor and focus: `jacoPointer()` uses `onContinuousHover` with a state counter. Do not go back to `pointerStyle` or `NSView` cursor rects (they failed in the real window).
- Nothing here imports `JacoUI` or `JacoMac`.
