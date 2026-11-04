import SwiftUI

/// Icon from the Lucide library (same as the design). The SVGs live in Resources/Icons.
/// 2 stroke on a 24 frame, with rounded caps and joins.
public struct JacoIcon: View {
    private let name: String
    private let size: CGFloat
    private let color: Color

    public init(_ name: String, size: CGFloat = 20, color: Color = JacoColor.textSecondary) {
        self.name = name
        self.size = size
        self.color = color
    }

    public var body: some View {
        LucideShape(path24: LucideStore.shared.path(named: name))
            .stroke(color, style: StrokeStyle(lineWidth: 2 * size / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

struct LucideShape: Shape {
    let path24: Path
    func path(in rect: CGRect) -> Path {
        path24.applying(CGAffineTransform(scaleX: rect.width / 24, y: rect.height / 24))
    }
}

final class LucideStore {
    static let shared = LucideStore()
    private var cache: [String: Path] = [:]
    private let lock = NSLock()

    func path(named name: String) -> Path {
        lock.lock(); defer { lock.unlock() }
        if let cached = cache[name] { return cached }
        let p = load(name)
        cache[name] = p
        return p
    }

    private func load(_ name: String) -> Path {
        guard let url = Bundle.module.url(forResource: name, withExtension: "svg", subdirectory: "Icons"),
              let svg = try? String(contentsOf: url, encoding: .utf8) else {
            assertionFailure("Missing Lucide icon: \(name)")
            return Path()
        }
        return SVGShapes.path(fromSVG: svg)
    }
}

// MARK: - SVG (subset used by Lucide: path, circle, rect, line, polyline)

enum SVGShapes {
    static func path(fromSVG svg: String) -> Path {
        var result = Path()
        let element = try! NSRegularExpression(pattern: "<(path|circle|rect|line|polyline)\\s+([^>]*?)/?>", options: [.dotMatchesLineSeparators])
        let attribute = try! NSRegularExpression(pattern: "([a-zA-Z0-9-]+)=\"([^\"]*)\"")
        let ns = svg as NSString
        for m in element.matches(in: svg, range: NSRange(location: 0, length: ns.length)) {
            let tag = ns.substring(with: m.range(at: 1))
            let attrString = ns.substring(with: m.range(at: 2)) as NSString
            var attrs: [String: String] = [:]
            for a in attribute.matches(in: attrString as String, range: NSRange(location: 0, length: attrString.length)) {
                attrs[attrString.substring(with: a.range(at: 1))] = attrString.substring(with: a.range(at: 2))
            }
            func num(_ k: String) -> CGFloat { CGFloat(Double(attrs[k] ?? "0") ?? 0) }
            switch tag {
            case "path":
                result.addPath(SVGPathParser.parse(attrs["d"] ?? ""))
            case "circle":
                let cx = num("cx"), cy = num("cy"), r = num("r")
                result.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
            case "rect":
                let rect = CGRect(x: num("x"), y: num("y"), width: num("width"), height: num("height"))
                let rx = attrs["rx"] != nil ? num("rx") : 0
                result.addRoundedRect(in: rect, cornerSize: CGSize(width: rx, height: rx))
            case "line":
                result.move(to: CGPoint(x: num("x1"), y: num("y1")))
                result.addLine(to: CGPoint(x: num("x2"), y: num("y2")))
            case "polyline":
                let nums = (attrs["points"] ?? "").split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
                var i = 0
                while i + 1 < nums.count {
                    let p = CGPoint(x: nums[i], y: nums[i + 1])
                    if i == 0 { result.move(to: p) } else { result.addLine(to: p) }
                    i += 2
                }
            default: break
            }
        }
        return result
    }
}

enum SVGPathParser {
    static func parse(_ d: String) -> Path {
        var tokens = Tokenizer(d)
        var path = Path()
        var cur = CGPoint.zero, start = CGPoint.zero
        var lastCtrl: CGPoint? = nil, lastQuad: CGPoint? = nil
        var cmd: Character = "M"

        while let next = tokens.nextCommandOrNumber() {
            if case .command(let c) = next { cmd = c; if c == "Z" || c == "z" { path.closeSubpath(); cur = start; lastCtrl = nil; lastQuad = nil; continue } }
            else { tokens.pushBack(next) }
            let rel = cmd.isLowercase
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y) }
            switch cmd {
            case "M", "m":
                guard let x = tokens.number(), let y = tokens.number() else { return path }
                cur = pt(x, y); start = cur; path.move(to: cur); lastCtrl = nil; lastQuad = nil
                cmd = rel ? "l" : "L"
            case "L", "l":
                guard let x = tokens.number(), let y = tokens.number() else { return path }
                cur = pt(x, y); path.addLine(to: cur); lastCtrl = nil; lastQuad = nil
            case "H", "h":
                guard let x = tokens.number() else { return path }
                cur = CGPoint(x: rel ? cur.x + x : x, y: cur.y); path.addLine(to: cur); lastCtrl = nil; lastQuad = nil
            case "V", "v":
                guard let y = tokens.number() else { return path }
                cur = CGPoint(x: cur.x, y: rel ? cur.y + y : y); path.addLine(to: cur); lastCtrl = nil; lastQuad = nil
            case "C", "c":
                guard let x1 = tokens.number(), let y1 = tokens.number(), let x2 = tokens.number(), let y2 = tokens.number(), let x = tokens.number(), let y = tokens.number() else { return path }
                let c1 = pt(x1, y1), c2 = pt(x2, y2), e = pt(x, y)
                path.addCurve(to: e, control1: c1, control2: c2); cur = e; lastCtrl = c2; lastQuad = nil
            case "S", "s":
                guard let x2 = tokens.number(), let y2 = tokens.number(), let x = tokens.number(), let y = tokens.number() else { return path }
                let c1 = lastCtrl.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let c2 = pt(x2, y2), e = pt(x, y)
                path.addCurve(to: e, control1: c1, control2: c2); cur = e; lastCtrl = c2; lastQuad = nil
            case "Q", "q":
                guard let x1 = tokens.number(), let y1 = tokens.number(), let x = tokens.number(), let y = tokens.number() else { return path }
                let c = pt(x1, y1), e = pt(x, y)
                path.addQuadCurve(to: e, control: c); cur = e; lastQuad = c; lastCtrl = nil
            case "T", "t":
                guard let x = tokens.number(), let y = tokens.number() else { return path }
                let c = lastQuad.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let e = pt(x, y)
                path.addQuadCurve(to: e, control: c); cur = e; lastQuad = c; lastCtrl = nil
            case "A", "a":
                guard let rx = tokens.number(), let ry = tokens.number(), let rot = tokens.number(),
                      let fa = tokens.flag(), let fs = tokens.flag(), let x = tokens.number(), let y = tokens.number() else { return path }
                let e = pt(x, y)
                addArc(&path, from: cur, to: e, rx: abs(rx), ry: abs(ry), rotation: rot, large: fa, sweep: fs)
                cur = e; lastCtrl = nil; lastQuad = nil
            default:
                return path
            }
        }
        return path
    }

    /// SVG arc (endpoint parameterization) converted to Bézier curves (SVG 1.1, F.6.5).
    private static func addArc(_ path: inout Path, from p0: CGPoint, to p1: CGPoint, rx rx0: CGFloat, ry ry0: CGFloat, rotation: CGFloat, large: Bool, sweep: Bool) {
        if p0 == p1 { return }
        var rx = rx0, ry = ry0
        if rx == 0 || ry == 0 { path.addLine(to: p1); return }
        let phi = rotation * .pi / 180
        let cosPhi = cos(phi), sinPhi = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1p = cosPhi * dx + sinPhi * dy
        let y1p = -sinPhi * dx + cosPhi * dy
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 { let s = sqrt(lambda); rx *= s; ry *= s }
        let num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
        let den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
        var coef = den == 0 ? 0 : sqrt(max(0, num / den))
        if large == sweep { coef = -coef }
        let cxp = coef * (rx * y1p / ry)
        let cyp = coef * -(ry * x1p / rx)
        let cx = cosPhi * cxp - sinPhi * cyp + (p0.x + p1.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + (p0.y + p1.y) / 2
        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let dot = ux * vx + uy * vy
            let len = sqrt(ux * ux + uy * uy) * sqrt(vx * vx + vy * vy)
            var a = acos(max(-1, min(1, dot / len)))
            if ux * vy - uy * vx < 0 { a = -a }
            return a
        }
        let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var dtheta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
        if !sweep && dtheta > 0 { dtheta -= 2 * .pi }
        if sweep && dtheta < 0 { dtheta += 2 * .pi }
        let segments = Int(ceil(abs(dtheta) / (.pi / 2)))
        let delta = dtheta / CGFloat(segments)
        let t = 4.0 / 3.0 * tan(delta / 4)
        var a = theta1
        for _ in 0..<segments {
            let cos1 = cos(a), sin1 = sin(a)
            let cos2 = cos(a + delta), sin2 = sin(a + delta)
            func map(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: cosPhi * rx * x - sinPhi * ry * y + cx, y: sinPhi * rx * x + cosPhi * ry * y + cy)
            }
            let c1 = map(cos1 - t * sin1, sin1 + t * cos1)
            let c2 = map(cos2 + t * sin2, sin2 - t * cos2)
            let e = map(cos2, sin2)
            path.addCurve(to: e, control1: c1, control2: c2)
            a += delta
        }
    }

    // MARK: tokenizer

    enum Token { case command(Character), number(CGFloat) }

    struct Tokenizer {
        private let chars: [Character]
        private var i = 0
        private var pending: Token? = nil
        init(_ s: String) { chars = Array(s) }

        mutating func pushBack(_ t: Token) { pending = t }

        mutating func nextCommandOrNumber() -> Token? {
            if let p = pending { pending = nil; return p }
            skipSeparators()
            guard i < chars.count else { return nil }
            let c = chars[i]
            if c.isLetter && c != "e" && c != "E" { i += 1; return .command(c) }
            if let n = readNumber() { return .number(n) }
            return nil
        }

        mutating func number() -> CGFloat? {
            if let p = pending { pending = nil; if case .number(let n) = p { return n }; return nil }
            skipSeparators()
            return readNumber()
        }

        /// Arc flags may be glued together ("0 01"): reads a single 0 or 1 digit.
        mutating func flag() -> Bool? {
            if let p = pending { pending = nil; if case .number(let n) = p { return n != 0 }; return nil }
            skipSeparators()
            guard i < chars.count, chars[i] == "0" || chars[i] == "1" else { return nil }
            defer { i += 1 }
            return chars[i] == "1"
        }

        private mutating func skipSeparators() {
            while i < chars.count, chars[i] == " " || chars[i] == "," || chars[i] == "\n" || chars[i] == "\t" || chars[i] == "\r" { i += 1 }
        }

        private mutating func readNumber() -> CGFloat? {
            let start = i
            if i < chars.count, chars[i] == "-" || chars[i] == "+" { i += 1 }
            var seenDot = false
            while i < chars.count {
                let c = chars[i]
                if c.isNumber { i += 1 }
                else if c == "." && !seenDot { seenDot = true; i += 1 }
                else if (c == "e" || c == "E"), i + 1 < chars.count, chars[i + 1].isNumber || chars[i + 1] == "-" || chars[i + 1] == "+" { i += 2 }
                else { break }
            }
            guard i > start, let v = Double(String(chars[start..<i])) else { return nil }
            return CGFloat(v)
        }
    }
}
