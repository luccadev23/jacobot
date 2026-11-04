# AGENTS.md · Tests

Design system tests (`Tests/JacoDesignSystemTests`), written with Swift Testing.

## Status

- They run with `swift test`, which requires Xcode. This environment only has the Command Line Tools, so the tests **do not run here**; never claim they passed.
- Current coverage: spacing scale, icon parsing, hex ↔ HSB round trip, bundled fonts.

## Rules

- Test pure logic: icon parsing, color conversion, tokens, derived values. Appearance is verified by snapshot, not by tests.
- One test per behavior, with a descriptive name in English.
- No dependency on screen, window or network.
- New code with logic (parser, conversion, calculation) gets a test in the same commit, even if it cannot be executed right now.
- If you move the package structure, update `Package.swift` (ask first).
