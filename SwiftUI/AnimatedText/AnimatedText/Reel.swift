import SwiftUI

// The animated reel: the same layout as the Figma post (1080 × 1920 points, scaled to the screen),
// with the six effects running live. Each effect view below runs exactly the code shown in its window (REEL_CODE).
// Launch with -reel and record the Simulator screen.

struct FX1: View {
  var body: some View {
    Text("Fade Up")
      .phaseAnimator([false, true]) { text, up in
        text.opacity(up ? 1 : 0)
          .offset(y: up ? 0 : 20)
      }
  }
}

struct FX2: View {
  var body: some View {
    TimelineView(.periodic(from: .now, by: 0.15)) { t in
      let n = Int(t.date.timeIntervalSince1970 * 6) % 17
      Text(String("Typing Animation".prefix(n)) + "|")
    }
  }
}

struct FX3: View {
  var body: some View {
    Text("Gradient Text")
      .foregroundStyle(.linearGradient(
        colors: [.cyan, .purple, .pink],
        startPoint: .leading, endPoint: .trailing))
      .phaseAnimator([0.0, 120.0]) { text, hue in
        text.hueRotation(.degrees(hue))
      }
  }
}

struct FX4: View {
  var body: some View {
    Text("Reveal Text")
      .phaseAnimator([false, true]) { text, on in
        text.mask(alignment: .leading) {
          Rectangle().frame(width: on ? 220 : 0)
        }
      }
  }
}

struct FX5: View {
  var body: some View {
    Text("Neon Light")
      .foregroundStyle(.cyan)
      .phaseAnimator([2.0, 14.0]) { text, glow in
        text.shadow(color: .cyan, radius: glow)
      }
  }
}

struct FX6: View {
  var body: some View {
    TimelineView(.animation) { t in
      let s = t.date.timeIntervalSince1970 * 6
      HStack(spacing: 2) {
        ForEach(Array("Wave!".enumerated()), id: \.offset) { i, c in
          Text(String(c)).offset(y: sin(s + Double(i)) * 8)
        }
      }
    }
  }
}

let REEL_CODE: [String] = [
#"""
Text("Fade Up")
  .phaseAnimator([false, true]) { text, up in
    text.opacity(up ? 1 : 0)
      .offset(y: up ? 0 : 20)
  }
"""#,
#"""
TimelineView(.periodic(from: .now, by: 0.15)) { t in
  let n = Int(t.date.timeIntervalSince1970 * 6) % 17
  Text(String("Typing Animation".prefix(n)) + "|")
}
"""#,
#"""
Text("Gradient Text")
  .foregroundStyle(.linearGradient(
    colors: [.cyan, .purple, .pink],
    startPoint: .leading, endPoint: .trailing))
  .phaseAnimator([0.0, 120.0]) { text, hue in
    text.hueRotation(.degrees(hue))
  }
"""#,
#"""
Text("Reveal Text")
  .phaseAnimator([false, true]) { text, on in
    text.mask(alignment: .leading) {
      Rectangle().frame(width: on ? 220 : 0)
    }
  }
"""#,
#"""
Text("Neon Light")
  .foregroundStyle(.cyan)
  .phaseAnimator([2.0, 14.0]) { text, glow in
    text.shadow(color: .cyan, radius: glow)
  }
"""#,
#"""
TimelineView(.animation) { t in
  let s = t.date.timeIntervalSince1970 * 6
  HStack(spacing: 2) {
    ForEach(Array("Wave!".enumerated()), id: \.offset) { i, c in
      Text(String(c)).offset(y: sin(s + Double(i)) * 8)
    }
  }
}
"""#,
]

private func hex(_ v: UInt32) -> Color { Color(red: Double(v >> 16 & 255) / 255, green: Double(v >> 8 & 255) / 255, blue: Double(v & 255) / 255) }

// Code text with the same colors as the Figma post: members, types, keywords, numbers, strings (later rules win).
struct CodeText: View {
  let code: String
  var body: some View {
    let chars = Array(code)
    var colors = Array(repeating: hex(0xE2E8F0), count: chars.count)
    let ns = code as NSString
    let rules: [(String, UInt32)] = [
      (#"\.[a-zA-Z]+(?=[\(\s,)]|$)"#, 0x93C5FD),
      (#"\b(Text|TimelineView|HStack|ForEach|Rectangle|Array|String|Int|Double)\b"#, 0x67E8F9),
      (#"\b(let|in)\b"#, 0xF472B6),
      (#"\b\d+(\.\d+)?\b"#, 0xC4B5FD),
      (#""[^"\n]*""#, 0xFCD34D),
    ]
    for (pattern, c) in rules {
      let re = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
      for m in re.matches(in: code, range: NSRange(location: 0, length: ns.length)) {
        for k in m.range.location ..< m.range.location + m.range.length { colors[k] = hex(c) }
      }
    }
    // join runs of the same color into one Text each
    var out = Text("")
    var start = 0
    for k in 1 ... chars.count {
      if k == chars.count || colors[k] != colors[start] {
        out = out + Text(String(chars[start ..< k])).foregroundColor(colors[start])
        start = k
      }
    }
    return out
      .font(.system(size: 14, design: .monospaced))
      .lineSpacing(4)
      .fixedSize()
  }
}

struct ReelCanvas: View {
  let effects: [AnyView] = [AnyView(FX1()), AnyView(FX2()), AnyView(FX3()), AnyView(FX4()), AnyView(FX5()), AnyView(FX6())]
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 4) {
        Text("SwiftUI").font(.system(size: 34)).foregroundStyle(hex(0xCBD5E1))
        Text("Animated Text").font(.system(size: 80, weight: .bold)).kerning(-1.6).foregroundStyle(.white)
      }
      Spacer().frame(height: 72)
      VStack(alignment: .leading, spacing: 72) {
        ForEach(0 ..< 6, id: \.self) { i in
          HStack(alignment: .center, spacing: 24) {
            effects[i]
              .font(.system(size: 27, weight: .bold))
              .foregroundStyle(.white)
              .frame(width: 340, height: 104)
              .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.07, green: 0.11, blue: 0.22)))
              .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
              .shadow(color: .black.opacity(0.3), radius: 12, y: 8)
            VStack(alignment: .leading, spacing: 14) {
              HStack(spacing: 8) { ForEach([0xFF5F57, 0xFEBC2E, 0x28C840] as [UInt32], id: \.self) { Circle().fill(hex($0)).frame(width: 12, height: 12) } }
              CodeText(code: REEL_CODE[i])
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            .frame(width: 588, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(hex(0x0B1020)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
            .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
          }
        }
      }
      Spacer(minLength: 0)
      Text("Real SwiftUI · iOS 17 · phaseAnimator and TimelineView").font(.system(size: 22)).foregroundStyle(hex(0x64748B))
        .frame(maxWidth: .infinity)
    }
    .padding(.horizontal, 64).padding(.top, 132).padding(.bottom, 72)
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
