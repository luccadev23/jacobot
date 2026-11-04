# AGENTS.md · Jaco UI

Interface layer of Jaco: the design (Pencil), shared design tokens and the native clients. The current client is macOS, in SwiftUI; other platforms will reuse the design and tokens. UI only: no AI or harness code in this repository.

Each important subfolder has its own `AGENTS.md` with local rules; the one closest to the edited file takes precedence. `CLAUDE.md` is a symlink to the `AGENTS.md` in the same folder: always edit `AGENTS.md`.

## Commands

```sh
swift build                                   # build everything
.build/debug/JacoMac                          # launch the app
.build/debug/JacoMac --snapshot /path/out.png [--dark] [--overlay newBot|apps] [--account] [--picker] [--error]
python3 scripts/generate_tokens.py            # tokens.json → Generated/Tokens.swift
```

- `swift test` does not run here (Command Line Tools only, no Swift Testing/XCTest). Verify with `swift build` plus light and dark snapshots.
- Write captures outside the repository (temporary directory/scratchpad), never into the versioned tree.

## Architecture

```text
JacoMac (executable) → JacoUI (screens) → JacoDesignSystem (tokens, components)
```

- Dependencies only follow the arrow. The design system knows nothing about screens; screens know nothing about the window.
- `design/jaco.pen` is the visual source; `design/tokens.json` is the source of values.

## Non-negotiable rules

1. **Design first.** Every visual change goes into `design/jaco.pen` first (including states and the dark library) and only then into code. If a request changes the UI, point out that the design needs updating.
2. **Tokens, not numbers.** Colors, spacing, radii and heights come from `JacoColor`, `JacoSpace`, `JacoRadius`, `JacoControl`, `JacoInset`. No hex literals, `padding(13)` or loose fonts.
3. **Do not edit `Generated/Tokens.swift`.** Change `tokens.json` and run the generator.
4. **Reuse design system components** before creating a new one. A new component must also exist in Pencil.
5. **Minimalist, Apple-like visuals**: minimal shadows, consistent spacing, no gratuitous decoration, nothing that looks "AI-made".
6. **Light and dark themes** always: use dynamic semantic colors, never a color fixed to one theme.
7. **Every clickable element** uses `jacoPointer()` (and `jacoTextCursor()` on text fields).
8. **Icons** come from `Resources/Icons` (Lucide) via `JacoIcon`. New icon: add the SVG and register it; do not use SF Symbols.
9. **Everything is in English**: UI text, code, comments and docs. (The `.pen` file may still contain Portuguese text until it is updated.)

## Code conventions

- Swift 6 toolchain with `swiftLanguageModes: [.v5]`. Platforms: macOS 14, iOS 17.
- `Jaco` prefix on public design system types. Screens in `JacoUI` end in `View`.
- macOS-specific code (AppKit, `NSWindow`, `NSEvent`, `NSCursor`) lives behind `#if canImport(AppKit)` or in `JacoMac`.
- Comments explain the why, in English, when the reason is not obvious.
- Small, focused changes; do not refactor beyond the request.

## Verification flow

1. `swift build` with no new errors or warnings.
2. Snapshots in both themes (`--dark`) and in the affected overlays.
3. Compare with the matching frame in the `.pen`.

## Boundaries

- **Ask first** before adding a dependency or changing `Package.swift`, platforms or the folder structure.
- **Never** commit, push or stage without an explicit request from the user.
- **Never** put harness code, API keys, AI code or secrets in this repository.
- Do not delete or overwrite `design/jaco.pen` without confirming; it is the main artifact. It is encrypted: access it only through the Pencil MCP, never with `Read`/`grep`.
- When editing the `.pen` through the MCP, use the path `/Users/luccabonim/projetos/jaco/jacobot/clients/ui/design/jaco.pen`.

## Where to look

| To… | See |
| --- | --- |
| Tokens, components, icons | `Sources/JacoDesignSystem/AGENTS.md` |
| Screens and sample data | `Sources/JacoUI/AGENTS.md` |
| Window and snapshot | `Sources/JacoMac/AGENTS.md` |
| Design and tokens.json | `design/AGENTS.md` |
| Token generation | `scripts/AGENTS.md` |
| Tests | `Tests/AGENTS.md` |
