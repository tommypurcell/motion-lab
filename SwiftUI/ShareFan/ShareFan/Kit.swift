import SwiftUI

// Shared reel kit (same look as GlassProof / TextFXProof): colors, code window, the wall-clock beat, the 1080 × 1920 canvas fit.

func hex(_ v: UInt32) -> Color { Color(red: Double(v >> 16 & 255) / 255, green: Double(v >> 8 & 255) / 255, blue: Double(v & 255) / 255) }

// Code text: members, types, keywords, numbers, strings (later rules win).
struct CodeText: View {
  let code: String
  var size: CGFloat = 22
  var body: some View {
    let chars = Array(code)
    var colors = Array(repeating: hex(0xE2E8F0), count: chars.count)
    let ns = code as NSString
    let rules: [(String, UInt32)] = [
      (#"\.[a-zA-Z]+(?=[\(\s,)\]]|$)"#, 0x93C5FD),
      (#"\b[A-Z][A-Za-z]+\b"#, 0x67E8F9),
      (#"\b(var|let|in|if|else)\b(?!:)|@Namespace"#, 0xF472B6),
      (#"\b\d+(\.\d+)?\b"#, 0xC4B5FD),
      (#""[^"\n]*""#, 0xFCD34D),
    ]
    for (pattern, c) in rules {
      let re = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
      for m in re.matches(in: code, range: NSRange(location: 0, length: ns.length)) {
        for k in m.range.location ..< m.range.location + m.range.length { colors[k] = hex(c) }
      }
    }
    var out = Text("")
    var start = 0
    for k in 1 ... chars.count {
      if k == chars.count || colors[k] != colors[start] {
        out = out + Text(String(chars[start ..< k])).foregroundColor(colors[start])
        start = k
      }
    }
    return out.font(.system(size: size, weight: .medium, design: .monospaced)).lineSpacing(6).fixedSize()
  }
}

// A small macOS-style code window.
struct CodeWindow: View {
  let code: String
  var size: CGFloat = 22
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) { ForEach([0xFF5F57, 0xFEBC2E, 0x28C840] as [UInt32], id: \.self) { Circle().fill(hex($0)).frame(width: 12, height: 12) } }
      CodeText(code: code, size: size)
    }
    .padding(.horizontal, 16).padding(.vertical, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 14).fill(hex(0x0B1020)))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    .shadow(color: .black.opacity(0.3), radius: 12, y: 8)
  }
}

// The demo number, for "reply with the number".
struct NumberBadge: View {
  let n: Int
  var body: some View {
    Text("\(n)")
      .font(.system(size: 28, weight: .bold, design: .rounded))
      .foregroundStyle(.white)
      .frame(width: 52, height: 52)
      .background(Circle().fill(Color.white.opacity(0.12)))
      .overlay(Circle().stroke(Color.white.opacity(0.18)))
  }
}

// Ticks on wall-clock multiples of `step`, so the loop never drifts. Gives the tick number to the content.
struct Beat<Content: View>: View {
  let step: Double
  @ViewBuilder let content: (Int) -> Content
  @State private var n = 0
  var body: some View {
    content(n).task {
      while !Task.isCancelled {
        let t = Date().timeIntervalSince1970
        let next = (floor(t / step) + 1) * step
        try? await Task.sleep(for: .seconds(next - t))
        n = Int((next / step).rounded())
      }
    }
  }
}

// A bold, colorful backdrop for glass to bend (same as GlassProof).
struct Backdrop: View {
  var body: some View {
    ZStack {
      MeshGradient(width: 3, height: 3, points: [
        [0, 0], [0.5, 0], [1, 0], [0, 0.5], [0.5, 0.5], [1, 0.5], [0, 1], [0.5, 1], [1, 1]
      ], colors: [
        hex(0x6366F1), hex(0xA855F7), hex(0xEC4899),
        hex(0x0EA5E9), hex(0x8B5CF6), hex(0xF97316),
        hex(0x14B8A6), hex(0x3B82F6), hex(0xF43F5E)
      ])
      Canvas { ctx, size in
        var x: CGFloat = -size.height
        while x < size.width {
          var path = Path()
          path.move(to: CGPoint(x: x, y: size.height)); path.addLine(to: CGPoint(x: x + size.height, y: 0))
          ctx.stroke(path, with: .color(.white.opacity(0.22)), lineWidth: 6)
          x += 26
        }
      }
    }
  }
}

// Title block used by every reel.
struct ReelTitle: View {
  let title: String
  let subtitle: String
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("SwiftUI").font(.system(size: 34)).foregroundStyle(hex(0xCBD5E1))
      Text(title).font(.system(size: 80, weight: .bold)).kerning(-1.6).foregroundStyle(.white)
      Text(subtitle).font(.system(size: 28)).foregroundStyle(hex(0x94A3B8)).padding(.top, 4)
    }
  }
}

let REEL_BG = LinearGradient(colors: [hex(0x0D1A3A), hex(0x060B1A)], startPoint: .top, endPoint: .bottom)

// Fits the 1080 × 1920 canvas to the screen width, centered, with nothing else on screen.
struct ReelView<Canvas: View>: View {
  @ViewBuilder let canvas: () -> Canvas
  var body: some View {
    GeometryReader { geo in
      let s = geo.size.width / 1080
      canvas()
        .frame(width: 1080, height: 1920, alignment: .topLeading)
        .scaleEffect(s, anchor: .topLeading)
        .frame(width: geo.size.width, height: 1920 * s, alignment: .topLeading)
        .position(x: geo.size.width / 2, y: geo.size.height / 2)
    }
    .background(hex(0x060B1A))
    .ignoresSafeArea()
    .statusBarHidden()
    .persistentSystemOverlays(.hidden)
  }
}
