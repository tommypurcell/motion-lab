import SwiftUI

// Shared reel chrome (same look as the R1/R2 reels): colors, code windows, title block, and the screen fit.

func hex(_ v: UInt32) -> Color { Color(red: Double(v >> 16 & 255) / 255, green: Double(v >> 8 & 255) / 255, blue: Double(v & 255) / 255) }

// Code text with the reel colors: members, types, keywords, numbers, strings, comments (later rules win).
struct CodeText: View {
  let code: String
  let types: [String]
  var body: some View {
    let chars = Array(code.utf16)
    var colors = Array(repeating: hex(0xE2E8F0), count: chars.count)
    let ns = code as NSString
    let rules: [(String, UInt32)] = [
      (#"\.[a-zA-Z]+(?=[\(\s,)]|$)"#, 0x93C5FD),
      (#"\b("# + types.joined(separator: "|") + #")\b"#, 0x67E8F9),
      (#"\b(var|let|in|if|struct|some|func|withAnimation)\b"#, 0xF472B6),
      (#"\b\d+(\.\d+)?\b"#, 0xC4B5FD),
      (#""[^"\n]*""#, 0xFCD34D),
      (#"//.*$"#, 0x64748B),
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
        out = out + Text(ns.substring(with: NSRange(location: start, length: k - start))).foregroundColor(colors[start])
        start = k
      }
    }
    return out.font(.system(size: 22, weight: .medium, design: .monospaced)).lineSpacing(7).fixedSize()
  }
}

struct CodeWindow: View {
  let title: String
  let code: String
  let types: [String]
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 8) {
        ForEach([0xFF5F57, 0xFEBC2E, 0x28C840] as [UInt32], id: \.self) { Circle().fill(hex($0)).frame(width: 14, height: 14) }
        Text(title).font(.system(size: 22, weight: .semibold)).foregroundStyle(hex(0x94A3B8)).padding(.leading, 12)
      }
      CodeText(code: code, types: types)
    }
    .padding(.horizontal, 24).padding(.vertical, 20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 20).fill(hex(0x0B1020)))
    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08)))
    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
  }
}

struct TitleBlock: View {
  let title: String
  let subtitle: String
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("SwiftUI").font(.system(size: 34)).foregroundStyle(hex(0xCBD5E1))
      Text(title).font(.system(size: 80, weight: .bold)).kerning(-1.6).foregroundStyle(.white)
      Text(subtitle).font(.system(size: 28)).foregroundStyle(hex(0x94A3B8)).padding(.top, 6)
    }
  }
}

// Fits a 1080 × 1920 canvas to the screen width, centered, with nothing else on screen.
struct ReelView<Canvas: View>: View {
  let canvas: Canvas
  init(@ViewBuilder _ canvas: () -> Canvas) { self.canvas = canvas() }
  var body: some View {
    GeometryReader { geo in
      let s = geo.size.width / 1080
      canvas
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

// The fake finger: the recording can't show touches, so a white dot (44 pt on the phone = 110 on the canvas, 60%) plays the user.
struct FingerDot: View {
  var body: some View {
    Circle().fill(.white.opacity(0.6)).frame(width: 110, height: 110)
      .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 3))
      .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
  }
}
