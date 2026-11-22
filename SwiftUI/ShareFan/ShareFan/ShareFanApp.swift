import SwiftUI

@main
struct ShareFanApp: App {
  var body: some Scene { WindowGroup { ReelView { ReelCanvas() } } }
}

// The Share Button reel: a fake finger taps the share button, 5 icons fan out in an arc with staggered springs,
// each glows as the finger hovers it, then the finger taps again and they fold back. 6 s loop.
// Each code window shows lines copied exactly from the views below (checked by ../TabBarsProof/check_code.py).

let icons = ["message.fill", "envelope.fill", "link", "camera.fill", "paperplane.fill"]
let colors = [hex(0x22C55E), hex(0x3B82F6), hex(0xF59E0B), hex(0xEC4899), hex(0x06B6D4)]

struct ShareIcon: View {
  let i: Int
  let lit: Bool
  var body: some View {
    Image(systemName: icons[i])
      .foregroundStyle(lit ? .white : colors[i])
      .frame(width: 116, height: 116)
      .background(Circle().fill(lit ? colors[i] : hex(0x1E293B)))
      .shadow(color: colors[i].opacity(lit ? 0.9 : 0), radius: 28)
      .scaleEffect(lit ? 1.18 : 1)
      .animation(.snappy(duration: 0.25), value: lit)
  }
}

struct Fan: View {
  let open: Bool
  let hover: Int
  var body: some View {
    ZStack {
      ForEach(0 ..< 5, id: \.self) { i in
        let a = Double(i) * .pi / 4
        ShareIcon(i: i, lit: hover == i)
          .offset(x: open ? -cos(a) * 290 : 0,
                  y: open ? -sin(a) * 290 : 0)
          .scaleEffect(open ? 1 : 0.3)
          .opacity(open ? 1 : 0)
          .animation(.spring(duration: 0.5, bounce: 0.45)
            .delay(Double(i) * 0.05), value: open)
      }
    }
    .font(.system(size: 44, weight: .semibold))
  }
}

let REEL_CODE: [String] = [
#"""
ForEach(0 ..< 5, id: \.self) { i in
  let a = Double(i) * .pi / 4
  ShareIcon(i: i, lit: hover == i)
    .offset(x: open ? -cos(a) * 290 : 0,
            y: open ? -sin(a) * 290 : 0)
    .scaleEffect(open ? 1 : 0.3)
    .opacity(open ? 1 : 0)
    .animation(.spring(duration: 0.5, bounce: 0.45)
      .delay(Double(i) * 0.05), value: open)
}
"""#,
#"""
Image(systemName: icons[i])
  .foregroundStyle(lit ? .white : colors[i])
  .frame(width: 116, height: 116)
  .background(Circle().fill(lit ? colors[i] : hex(0x1E293B)))
  .shadow(color: colors[i].opacity(lit ? 0.9 : 0), radius: 28)
  .scaleEffect(lit ? 1.18 : 1)
  .animation(.snappy(duration: 0.25), value: lit)
"""#,
]

// ---- The fake finger (the Simulator recording can't show touches) ----

let PERIOD = 6.0
func iconPoint(_ k: Int) -> CGPoint {
  let a = Double(k) * .pi / 4
  return CGPoint(x: -cos(a) * 290, y: -sin(a) * 290)
}
// (time, point relative to the share button's center)
let FINGER: [(Double, CGPoint)] = {
  var keys: [(Double, CGPoint)] = [(0, CGPoint(x: 250, y: 250)), (0.6, CGPoint(x: 26, y: 34)), (0.9, CGPoint(x: 26, y: 34))]
  for k in 0 ..< 5 {
    let p = CGPoint(x: iconPoint(k).x + 26, y: iconPoint(k).y + 34)
    keys.append((1.45 + 0.6 * Double(k), p))
    keys.append((1.85 + 0.6 * Double(k), p))
  }
  keys += [(4.6, CGPoint(x: 26, y: 34)), (5.0, CGPoint(x: 26, y: 34)), (5.8, CGPoint(x: 250, y: 250)), (6.0, CGPoint(x: 250, y: 250))]
  return keys
}()

func fingerAt(_ t: Double) -> CGPoint {
  for j in 1 ..< FINGER.count where t <= FINGER[j].0 {
    let (t0, a) = FINGER[j - 1], (t1, b) = FINGER[j]
    var u = (t - t0) / max(t1 - t0, 0.0001)
    u = u * u * (3 - 2 * u)
    return CGPoint(x: a.x + (b.x - a.x) * u, y: a.y + (b.y - a.y) * u)
  }
  return FINGER.last!.1
}
func pressed(_ t: Double) -> Bool { (0.62 ... 0.85).contains(t) || (4.62 ... 4.85).contains(t) }
func hoverAt(_ t: Double) -> Int {
  for k in 0 ..< 5 where (1.45 + 0.6 * Double(k) ... 1.85 + 0.6 * Double(k)).contains(t) { return k }
  return -1
}

struct ShareDemo: View {
  var body: some View {
    TimelineView(.animation) { ctx in
      let t = ctx.date.timeIntervalSince1970.truncatingRemainder(dividingBy: PERIOD)
      let open = t >= 0.8 && t < 4.8
      let f = fingerAt(t)
      let down = pressed(t)
      ZStack {
        Fan(open: open, hover: hoverAt(t))
        Image(systemName: open ? "xmark" : "square.and.arrow.up")
          .contentTransition(.symbolEffect(.replace))
          .font(.system(size: 64, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 184, height: 184)
          .background(Circle().fill(LinearGradient(colors: [hex(0x818CF8), hex(0x7C3AED)], startPoint: .topLeading, endPoint: .bottomTrailing)))
          .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 2))
          .shadow(color: hex(0x7C3AED).opacity(0.5), radius: 30, y: 12)
          .scaleEffect(down && length(f) < 60 ? 0.9 : 1)
          .animation(.spring(duration: 0.3, bounce: 0.5), value: down)
          .animation(.smooth(duration: 0.3), value: open)
        Circle().fill(.white.opacity(0.6))
          .frame(width: 44, height: 44)
          .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
          .scaleEffect(down ? 0.8 : 1)
          .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
          .offset(x: f.x, y: f.y)
          .animation(.easeOut(duration: 0.12), value: down)
      }
      .offset(y: 140)
    }
  }
  func length(_ p: CGPoint) -> Double { (p.x * p.x + p.y * p.y).squareRoot() }
}

struct ReelCanvas: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ReelTitle(title: "Share Button", subtitle: "Tap, fan out in an arc, glow on hover")
      Spacer(minLength: 32)
      ShareDemo()
        .frame(width: 952, height: 760)
        .background(RadialGradient(colors: [hex(0x1E2A4F), hex(0x0F1A33)], center: UnitPoint(x: 0.5, y: 0.7), startRadius: 40, endRadius: 600))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.08)))
      Spacer(minLength: 24)
      VStack(alignment: .leading, spacing: 24) {
        CodeWindow(code: REEL_CODE[0])
        CodeWindow(code: REEL_CODE[1])
      }
      Spacer(minLength: 32)
      Text("Real SwiftUI · iOS 26 · spring, delay, offset, shadow, symbolEffect")
        .font(.system(size: 22)).foregroundStyle(hex(0x64748B))
        .frame(maxWidth: .infinity)
    }
    .padding(.horizontal, 64).padding(.top, 72).padding(.bottom, 48)
    .frame(width: 1080, height: 1920, alignment: .topLeading)
    .background(REEL_BG)
  }
}
