import Testing
import Foundation
import SwiftUI
@testable import JacoDesignSystem

@Suite("Design system")
struct TokensTests {
    @Test func spacingScale() {
        #expect(JacoSpace.space1 == 4)
        #expect(JacoSpace.space6 == 24)
        #expect(JacoRadius.md == 10)
        #expect(JacoControl.md == 40)
    }

    @Test func everyDesignIconParses() throws {
        let dir = try #require(Bundle.module.url(forResource: "Icons", withExtension: nil))
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path).filter { $0.hasSuffix(".svg") }
        #expect(files.count > 40)
        for f in files {
            let svg = try String(contentsOf: dir.appendingPathComponent(f), encoding: .utf8)
            #expect(!SVGShapes.path(fromSVG: svg).isEmpty, "Empty icon: \(f)")
        }
    }

    @Test func hexRoundTrip() {
        for hex in ["E8472E", "000000", "FFFFFF", "1FA89A", "8B6CE0"] {
            #expect(JacoHSB(hex: hex)?.hex == hex)
        }
        #expect(JacoHSB(hex: "#e8472e")?.hex == "E8472E")
        #expect(JacoHSB(hex: "zzzzzz") == nil)
    }

    @Test func fontsAreBundled() {
        let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
        #expect(urls.count == 5)
    }
}
