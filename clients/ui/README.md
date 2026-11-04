# Jaco · UI

The interface layer of **Jaco**: the design system, the shared design tokens and the native clients. The first client is macOS, built in SwiftUI; other platforms reuse the same design and tokens.

This repository contains **the UI only**. The harness and the AI layer live in a separate repository (`../harness`) and do not belong here.

![Status](https://img.shields.io/badge/status-UI%20prototype-blue)
![macOS client](https://img.shields.io/badge/macOS%20client-SwiftUI-lightgrey)

## Table of contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Repository layout](#repository-layout)
- [Workflow: design first](#workflow-design-first)
- [Design tokens](#design-tokens)
- [Visual verification](#visual-verification)
- [Tests](#tests)
- [Platforms](#platforms)
- [For AI agents](#for-ai-agents)

## Overview

- **One design, many clients.** The visual source of truth is the [Pencil](https://pencil.dev) file at `design/jaco.pen`, with screens for macOS, Windows, iPad, iPhone and Android at real sizes. Code follows the design.
- **Shared tokens.** Colors, spacing, radii and type live in `design/tokens.json`; each client generates its own code from it.
- Minimalist look in the spirit of Apple apps: few shadows, consistent spacing, a single brand color (`ember`, `#E8472E`).
- Light and dark themes, with semantic colors.
- Components (buttons, fields, menus, modals, color picker, avatars, mascot) built on tokens, with [Lucide](https://lucide.dev) icons and the Inter and JetBrains Mono fonts.
- **Current client:** macOS, in SwiftUI. The same Swift packages are meant to serve iOS and iPadOS.

## Requirements

For the macOS client:

| Item | Version |
| --- | --- |
| macOS | 14 or later |
| Swift | 6.x (Command Line Tools are enough to build) |
| Python | 3, only to generate tokens |
| Xcode | optional; required to run the tests and to build for iOS |

There are no third-party dependencies.

## Quick start

Run the macOS client:

```sh
swift build
.build/debug/JacoMac
```

## Repository layout

```text
Package.swift                    targets and platforms
Sources/
  JacoDesignSystem/              tokens, typography, icons and components (shared)
    Components/                  atoms, molecules, modals, color picker
    Generated/                   Tokens.swift, generated, do not edit
    Resources/                   fonts and SVG icons
  JacoUI/                        screens and flows, with sample data (MockData)
  JacoMac/                       macOS app shell (window, snapshot)
Tests/JacoDesignSystemTests/     design system tests
design/
  jaco.pen                       full design in Pencil
  tokens.json                    tokens exported from the design
scripts/generate_tokens.py       tokens.json → Tokens.swift
```

Target dependencies: `JacoMac` → `JacoUI` → `JacoDesignSystem`. Never the other way around.

Each important folder has an `AGENTS.md` with its local rules.

## Workflow: design first

1. Change the design in `design/jaco.pen` (including states and the dark library).
2. If a token changed, export it to `design/tokens.json` and run the generator.
3. Reproduce the change in code, using existing tokens and components.
4. Check it with a snapshot (see below) in both themes.

Code never introduces visual values that do not exist in the design.

## Design tokens

```sh
python3 scripts/generate_tokens.py
```

Reads `design/tokens.json` and writes `Sources/JacoDesignSystem/Generated/Tokens.swift` (`JacoPalette`, `JacoColor`, `JacoSpace`, `JacoRadius`, `JacoControl`, `JacoInset`). Do not edit the generated file by hand.

## Visual verification

The app can render a capture without opening a window:

```sh
.build/debug/JacoMac --snapshot output.png [--dark] [--overlay newBot|apps] [--account] [--picker] [--error]
```

It does not depend on the screen recording permission.

## Tests

```sh
swift test
```

The tests use Swift Testing and require Xcode. With only the Command Line Tools the command fails because the framework is missing; in that case verify with `swift build` and snapshots.

## Platforms

| Platform | Status | How it is built |
| --- | --- | --- |
| macOS | In progress | SwiftUI (this repository) |
| iOS / iPadOS | Planned | Same Swift packages |
| Windows, Linux, Android | Planned | Native clients generated from `design/tokens.json` and the `.pen` design |

SwiftUI only exists on Apple platforms, so the other clients do not reuse these Swift packages.

## For AI agents

Instructions live in [`AGENTS.md`](AGENTS.md). In each folder, `CLAUDE.md` is a symlink to its `AGENTS.md`.
