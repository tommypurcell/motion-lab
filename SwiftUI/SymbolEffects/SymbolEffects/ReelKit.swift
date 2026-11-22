import SwiftUI

// Shared reel pieces (same look as R1/R2): colors, syntax-colored code, the code window,
// the title block, and ReelView, which fits the 1080 × 1920 canvas to the screen.

func hex(_ v: UInt32) -> Color { Color(red: Double(v >> 16 & 255) / 255, green: Double(v >> 8 & 255) / 255, blue: Double(v & 255) / 255) }

// Code text: members, types, keywords, numbers, strings (later rules win).
struct CodeText: View {
  let code: String
  var size: CGFloat = 24
  var body: some View {
    let chars = Array(code)
    var colors = Array(repeating: hex(0xE2E8F0), count: chars.count)
    let ns = code as NSString
    let rules: [(String, UInt32)] = [
      (#"\.[a-zA-Z]+(?=[\(\s,)]|$)"#, 0x93C5FD),
      (#"\b(Image|Text|Circle|ZStack|DetailScreen|ListScreen|Animation)\b"#, 0x67E8F9),
      (#"\b(var|let|in|if|else)\b|@State|@Namespace"#, 0xF472B6),
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

// Two-part shadow (DESIGN_RULES §6), tuned for a dark canvas.
extension View {
  func softShadow() -> some View {
    self.shadow(color: .black.opacity(0.35), radius: 3, y: 1)
      .shadow(color: .black.opacity(0.30), radius: 24, y: 12)
  }
}

struct CodeWindow: View {
  let code: String
  var size: CGFloat = 24
  var dots = true
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      if dots {
        HStack(spacing: 8) { ForEach([0xFF5F57, 0xFEBC2E, 0x28C840] as [UInt32], id: \.self) { Circle().fill(hex($0)).frame(width: 14, height: 14) } }
      }
      CodeText(code: code, size: size)
    }
    .padding(.horizontal, 24).padding(.vertical, 20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 16).fill(hex(0x0B1020)))
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08)))
    .softShadow()
  }
}

struct TitleBlock: View {
  let title: String
  let subtitle: String
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("SwiftUI").font(.system(size: 34)).foregroundStyle(hex(0xCBD5E1))
      Text(title).font(.system(size: 88, weight: .bold)).kerning(-1.8).foregroundStyle(.white)
      Text(subtitle).font(.system(size: 30)).foregroundStyle(hex(0x94A3B8)).padding(.top, 4)
    }
  }
}

struct Footer: View {
  let apis: String
  var body: some View {
    Text("Real SwiftUI · iOS 26 · \(apis)").font(.system(size: 24)).foregroundStyle(hex(0x64748B))
      .frame(maxWidth: .infinity)
  }
}

extension View {
  func reelCanvas() -> some View {
    self.padding(.horizontal, 64).padding(.top, 110).padding(.bottom, 64)
      .frame(width: 1080, height: 1920, alignment: .topLeading)
      .background(LinearGradient(colors: [hex(0x0D1A3A), hex(0x060B1A)], startPoint: .top, endPoint: .bottom))
  }
}

// Fits the 1080 × 1920 canvas to the screen width, centered, with nothing else on screen.
struct ReelView: View {
  var body: some View {
    GeometryReader { geo in
      let s = geo.size.width / 1080
      ReelCanvas()
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
