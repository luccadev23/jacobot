import SwiftUI

/// Color as hue, saturation and brightness (0 to 1). It is the picker's value and converts to and from hexadecimal.
public struct JacoHSB: Equatable {
    public var h: Double
    public var s: Double
    public var b: Double

    public init(h: Double, s: Double, b: Double) {
        self.h = min(max(h, 0), 1); self.s = min(max(s, 0), 1); self.b = min(max(b, 0), 1)
    }

    /// The brand color (`ember-500`), the picker's starting point.
    public static let brand = JacoHSB(hex: "E8472E")!

    /// Accepts "E8472E" or "#E8472E".
    public init?(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased()
        guard clean.count == 6, let v = UInt32(clean, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255, g = Double((v >> 8) & 0xFF) / 255, b = Double(v & 0xFF) / 255
        let mx = max(r, g, b), mn = min(r, g, b), d = mx - mn
        var h: Double = 0
        if d > 0 {
            if mx == r { h = ((g - b) / d).truncatingRemainder(dividingBy: 6) }
            else if mx == g { h = (b - r) / d + 2 }
            else { h = (r - g) / d + 4 }
            h /= 6
            if h < 0 { h += 1 }
        }
        self.init(h: h, s: mx == 0 ? 0 : d / mx, b: mx)
    }

    public var color: Color { Color(hue: h, saturation: s, brightness: b) }

    /// Hexadecimal without "#", uppercase.
    public var hex: String {
        let c = h * 6, i = Int(c.rounded(.down)) % 6, f = c - c.rounded(.down)
        let p = b * (1 - s), q = b * (1 - f * s), t = b * (1 - (1 - f) * s)
        let rgb: (Double, Double, Double)
        switch i {
        case 0: rgb = (b, t, p)
        case 1: rgb = (q, b, p)
        case 2: rgb = (p, b, t)
        case 3: rgb = (p, q, b)
        case 4: rgb = (t, p, b)
        default: rgb = (b, p, q)
        }
        func byte(_ x: Double) -> Int { Int((x * 255).rounded()) }
        return String(format: "%02X%02X%02X", byte(rgb.0), byte(rgb.1), byte(rgb.2))
    }
}

/// Color Picker — saturation and brightness area, hue bar, preview and hexadecimal field.
/// Opens inside the modal, below the color row. The field uses the same standard as the other inputs.
public struct JacoColorPicker: View {
    @Binding private var hsb: JacoHSB
    @State private var hexText = ""
    @FocusState private var hexFocused: Bool
    @State private var hexHovering = false

    public init(hsb: Binding<JacoHSB>) { _hsb = hsb }

    private let handle: CGFloat = 20

    public var body: some View {
        VStack(spacing: JacoSpace.space3) {
            saturationArea
            hueSlider
            HStack(spacing: JacoSpace.space3) {
                Circle().fill(hsb.color).frame(width: 44, height: 44)
                hexField
            }
        }
        .padding(JacoSpace.space4)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(JacoColor.borderSubtle, lineWidth: 1))
        .onAppear { hexText = hsb.hex }
        .onChange(of: hsb) { _, new in if !hexFocused { hexText = new.hex } }
    }

    private var saturationArea: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color(hue: hsb.h, saturation: 1, brightness: 1))
                LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .leading, endPoint: .trailing)
                LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                Circle().strokeBorder(Color.white, lineWidth: 3)
                    .frame(width: handle, height: handle)
                    .offset(x: hsb.s * geo.size.width - handle / 2, y: (1 - hsb.b) * geo.size.height - handle / 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                hsb.s = min(max(g.location.x / geo.size.width, 0), 1)
                hsb.b = 1 - min(max(g.location.y / geo.size.height, 0), 1)
            })
        }
        .frame(height: 160)
        .jacoPointer()
    }

    private var hueSlider: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(LinearGradient(
                    colors: (0...6).map { Color(hue: Double($0) / 6, saturation: 1, brightness: 1) },
                    startPoint: .leading, endPoint: .trailing))
                Circle().fill(Color(hue: hsb.h, saturation: 1, brightness: 1))
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 3))
                    .frame(width: handle, height: handle)
                    .offset(x: hsb.h * (geo.size.width - handle))
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                hsb.h = min(max((g.location.x - handle / 2) / (geo.size.width - handle), 0), 1)
            })
        }
        .frame(height: handle)
        .padding(.vertical, -4)
        .jacoPointer()
    }

    private var hexField: some View {
        HStack(spacing: 0) {
            Text("#").font(JacoFont.ui(16)).foregroundStyle(JacoColor.textTertiary)
            TextField("", text: $hexText)
                .textFieldStyle(.plain)
                .focusEffectDisabled()
                .focused($hexFocused)
                .font(JacoFont.ui(16))
                .foregroundStyle(JacoColor.textPrimary)
                .onChange(of: hexText) { _, value in
                    let filtered = String(value.uppercased().filter { "0123456789ABCDEF".contains($0) }.prefix(6))
                    if filtered != value { hexText = filtered; return }
                    if filtered.count == 6, let parsed = JacoHSB(hex: filtered) { hsb = parsed }
                }
        }
        .padding(.horizontal, JacoSpace.space4)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(hexHovering && !hexFocused ? JacoColor.bgActive : JacoColor.bgHover, in: RoundedRectangle(cornerRadius: JacoRadius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: JacoRadius.lg, style: .continuous).strokeBorder(hexFocused ? JacoColor.focusRing : .clear, lineWidth: 2))
        .contentShape(RoundedRectangle(cornerRadius: JacoRadius.lg, style: .continuous))
        .onTapGesture { hexFocused = true }
        .jacoTextCursor()
        .onHover { hexHovering = $0 }
        .animation(jacoStateAnimation, value: hexFocused)
    }
}
