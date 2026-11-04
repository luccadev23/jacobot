// swift-tools-version: 6.0
import PackageDescription

// Layout:
//   JacoDesignSystem  tokens, typography, icons and components (SwiftUI, shared across macOS/iOS/iPadOS)
//   JacoUI            screens and flows, no platform dependency beyond SwiftUI
//   JacoMac           macOS app shell (window, shortcuts)
// Windows, Linux and Android do not use SwiftUI: they reuse design/tokens.json, not these targets.
let package = Package(
    name: "Jaco",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "JacoDesignSystem", targets: ["JacoDesignSystem"]),
        .library(name: "JacoUI", targets: ["JacoUI"]),
        .executable(name: "JacoMac", targets: ["JacoMac"]),
    ],
    targets: [
        .target(
            name: "JacoDesignSystem",
            // Docs for AI agents live next to the code; they are not target sources.
            exclude: [
                "AGENTS.md", "CLAUDE.md",
                "Components/AGENTS.md", "Components/CLAUDE.md",
                "Generated/AGENTS.md", "Generated/CLAUDE.md",
            ],
            resources: [
                .copy("Resources/Fonts"),
                .copy("Resources/Icons"),
            ]
        ),
        .target(name: "JacoUI", dependencies: ["JacoDesignSystem"], exclude: ["AGENTS.md", "CLAUDE.md"]),
        .executableTarget(name: "JacoMac", dependencies: ["JacoUI", "JacoDesignSystem"], exclude: ["AGENTS.md", "CLAUDE.md"]),
        .testTarget(name: "JacoDesignSystemTests", dependencies: ["JacoDesignSystem"]),
    ],
    swiftLanguageModes: [.v5]
)
