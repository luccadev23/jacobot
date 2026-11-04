# AGENTS.md · JacoMac

macOS app shell: entry point, window and snapshot mode. General rules: root `AGENTS.md`.

## Files

| File | Role |
| --- | --- |
| `JacoMacApp.swift` | `@main`, font registration, window (`hiddenTitleBar`, 1512×982), `--snapshot` mode |
| `WindowChrome.swift` | traffic lights centered in the 56pt header (20pt from the left, 20pt pitch), `fullSizeContentView` |

## Rules

- The only place for non-reusable window/AppKit code. No screen logic.
- Snapshot mode: `--snapshot <png> [--dark] [--overlay newBot|apps] [--account] [--picker] [--error]`. Renders offscreen via `NSHostingView` + `cacheDisplay`, without the screen recording permission. A new verifiable screen state means a new flag, documented here and in the README.
- Content ignores the top safe area (`ignoresSafeArea(.container, edges: .top)`) and the window uses `isMovableByWindowBackground = false`; without that the traffic lights misalign or the window drags from anywhere.
- When testing the real window, quit the previous process before relaunching.
