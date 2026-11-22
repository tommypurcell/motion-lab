import SwiftUI

@main
struct ThinkingDotOrbApp: App {
  var body: some Scene { WindowGroup { ChatScreen() } }
}

// A homage remake of an "assistant is thinking" animation, drawn entirely with Canvas.
// The whole 16 s loop is a pure function of one clock t, so it repeats exactly.
// Recorded at half speed (SLOW = 2), then sped up 2x by ffmpeg.

let SLOW = 2.0
let LOOP = 22.1
let STEP = 1.35
let KINDS = [0, 1, 2, 3, 0]   // Scanning, Braiding, Drafting, Breathing, then Scanning as the avatar
let ORANGE = Color(red: 0.165, green: 0.149, blue: 0.133)   // accents are ink now
let INK = Color(red: 0.165, green: 0.149, blue: 0.133)
let MUTED = Color(red: 0.541, green: 0.514, blue: 0.475)
let PAPER = Color(red: 0.965, green: 0.949, blue: 0.922)

// MARK: - math helpers
func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
func clamp(_ x: Double, _ a: Double = 0, _ b: Double = 1) -> Double { min(max(x, a), b) }
func smooth(_ x: Double) -> Double { let t = clamp(x); return t * t * t * (t * (t * 6 - 15) + 10) }
/// progress 0...1 of t between a and b, eased
func seg(_ t: Double, _ a: Double, _ b: Double) -> Double { smooth((t - a) / (b - a)) }
/// underdamped spring step response, 0 before the event, settles at 1
func spring(_ tau: Double, freq: Double = 2.0, zeta: Double = 0.62) -> Double {
  if tau <= 0 { return 0 }
  let w = 2 * Double.pi * freq, wd = w * (1 - zeta * zeta).squareRoot()
  return 1 - exp(-zeta * w * tau) * (cos(wd * tau) + zeta * w / wd * sin(wd * tau))
}

// MARK: - dot orb engine
struct P { var x = 0.0, y = 0.0, z = 0.0, s = 1.0, a = 1.0 }
struct OrbFrame { var pts: [P]; var yaw = 0.0; var pitch = 0.0; var links = 0.0 }

func hash(_ i: Int, _ salt: Int = 0) -> Double {
  let v = sin(Double(i) * 12.9898 + Double(salt) * 78.233) * 43758.5453
  return v - floor(v)
}
func clamp01(_ v: Double) -> Double { min(max(v, 0), 1) }

// Points spread evenly over a sphere (the Fibonacci sphere).
func fib(_ n: Int, _ i: Int) -> (x: Double, y: Double, z: Double) {
  let y = 1 - 2 * (Double(i) + 0.5) / Double(n)
  let r = sqrt(max(0, 1 - y * y))
  let th = Double(i) * 2.399963229728653
  return (r * cos(th), y, r * sin(th))
}

let TAU = 2 * Double.pi

// ph is the loop phase 0...1; a(k) is an angle that turns k whole times per loop.
func orbFrame(_ kind: Int, _ ph: Double, _ n: Int) -> OrbFrame {
  func a(_ k: Double) -> Double { TAU * k * ph }
  var f = OrbFrame(pts: [])
  f.pts.reserveCapacity(n + 40)
  switch kind {
  case 0: // Scanning
    let scan = a(3)
    for i in 0..<n {
      let p = fib(n, i)
      var d = atan2(p.z, p.x) - scan
      d = atan2(sin(d), cos(d))
      let w = exp(-d * d / (2 * 0.13 * 0.13))
      f.pts.append(P(x: p.x, y: p.y, z: p.z, s: 1 + 0.7 * w, a: 0.6 + 0.4 * w))
    }
    for j in 0..<26 {
      let lat = (Double(j) / 25 - 0.5) * Double.pi * 0.96
      f.pts.append(P(x: cos(lat) * cos(scan), y: sin(lat), z: cos(lat) * sin(scan), s: 1.35, a: 1))
    }
    f.yaw = a(1) + 0.4; f.pitch = 0.38
  case 1: // Braiding
    let m = max(18, n / 7)
    for i in 0..<n / 4 {
      let p = fib(n / 4, i)
      f.pts.append(P(x: p.x, y: p.y, z: p.z, s: 0.65, a: 0.28))
    }
    for k in 0..<3 {
      for j in 0..<m {
        let s = Double(j) / Double(m - 1) * 2 - 1
        let ang = s * Double.pi * 2.5 + a(2) + Double(k) * TAU / 3
        let r = sqrt(max(0, 1 - s * s)) * (1.0 + 0.05 * sin(a(3) + s * 6))
        f.pts.append(P(x: r * cos(ang), y: s, z: r * sin(ang), s: 1.45, a: 0.45 + 0.55 * sqrt(max(0, 1 - s * s))))
      }
    }
    f.yaw = a(1); f.pitch = 0.42
  case 2: // Drafting
    let cols = max(14, n / 5)
    for i in 0..<cols {
      let th = TAU * Double(i) / Double(cols)
      let center = 0.3 * sin(2 * th + a(2))
      let len = 0.55 + 0.45 * sin(3 * th - a(3))
      for b in 0..<5 {
        let y = center + Double(b - 2) * 0.13 * len
        let r = sqrt(max(0, 1 - y * y))
        f.pts.append(P(x: r * cos(th), y: y, z: r * sin(th), s: 0.9 + 0.5 * len, a: 0.5 + 0.5 * (1 - abs(Double(b - 2)) / 3)))
      }
    }
    f.yaw = a(1) + 0.5; f.pitch = 0.5
  case 3: // Breathing
    for ringIndex in 0..<2 {
      let cnt = ringIndex == 0 ? n * 2 / 3 : n / 3
      let scale = ringIndex == 0 ? 1.0 : 0.66
      for i in 0..<cnt {
        let th = TAU * Double(i) / Double(cnt)
        let wob = 1 + 0.11 * sin(3 * th + a(2) + Double(ringIndex)) + 0.05 * sin(5 * th - a(3))
        let r = 0.9 * scale * wob * (1 + 0.08 * sin(a(3)))
        f.pts.append(P(x: r * cos(th), y: r * sin(th), z: 0.12 * sin(2 * th + a(1)) * scale, s: ringIndex == 0 ? 1.15 : 0.85, a: ringIndex == 0 ? 1 : 0.7))
      }
    }
    f.yaw = 0.5 * sin(a(1)); f.pitch = 0.75 + 0.15 * sin(a(1) + 1)
  case 4: // Shaping
    let c = ph * 3
    let seg = Int(floor(c)), fr = c - floor(c)
    let e = smooth((fr - 0.18) / 0.64)
    func shapeR(_ idx: Int, _ th: Double) -> Double {
      if idx == 0 { return 1 }
      let sides = idx == 1 ? 3.0 : 4.0
      let step = TAU / sides
      var m = th.truncatingRemainder(dividingBy: step); if m < 0 { m += step }
      return cos(Double.pi / sides) / cos(m - step / 2)
    }
    let from = seg % 3, to = (seg + 1) % 3
    let layers = 3
    let cnt = n / layers
    for l in 0..<layers {
      let z = Double(l - 1) * 0.34
      for i in 0..<cnt {
        let th = TAU * Double(i) / Double(cnt) + Double(l) * 0.1
        let r = lerp(shapeR(from, th), shapeR(to, th), e) * 0.95
        f.pts.append(P(x: r * cos(th), y: r * sin(th), z: z, s: l == 1 ? 1.2 : 0.95, a: l == 1 ? 1 : 0.8))
      }
    }
    f.yaw = 0.8 * sin(a(1)) + 0.15; f.pitch = 0.45 + 0.15 * sin(a(2))
  case 5: // Gathering
    let fr = (ph * 3).truncatingRemainder(dividingBy: 1)
    let g = smooth(fr / 0.5) * (1 - smooth((fr - 0.72) / 0.28))
    for i in 0..<n {
      let p = fib(n, i)
      let u = 2 * hash(i, 1) - 1, ph2 = TAU * hash(i, 2)
      let rr = 1.0 + 0.35 * hash(i, 3)
      let sx = sqrt(1 - u * u) * cos(ph2) * rr, sy = u * rr, sz = sqrt(1 - u * u) * sin(ph2) * rr
      let gi = smooth(g * 1.7 - 0.7 * hash(i, 4))
      f.pts.append(P(x: lerp(sx, p.x, gi), y: lerp(sy, p.y, gi), z: lerp(sz, p.z, gi), s: lerp(0.8, 1, gi), a: lerp(0.4, 1, gi)))
    }
    f.yaw = a(2) + 0.3; f.pitch = 0.3
  case 6: // Listening
    let shells = 5
    var total = 0
    for sIdx in 0..<shells { total += (sIdx + 1) * (sIdx + 1) }
    for sIdx in 0..<shells {
      let rb = Double(sIdx + 1) / Double(shells)
      let cnt = max(6, n * (sIdx + 1) * (sIdx + 1) / total)
      for i in 0..<cnt {
        let p = fib(cnt, i)
        let wave = sin(TAU * 1.1 * rb - a(3))
        let r = rb + 0.09 * wave
        let b = pow(0.5 + 0.5 * wave, 1.6)
        let co = cos(Double(sIdx)), si = sin(Double(sIdx))
        f.pts.append(P(x: (p.x * co + p.z * si) * r, y: p.y * r, z: (-p.x * si + p.z * co) * r, s: 0.7 + 0.9 * b, a: 0.4 + 0.6 * b))
      }
    }
    f.yaw = a(1) + 0.2; f.pitch = 0.3
  case 7: // Linking
    let m = max(36, n / 3)
    for i in 0..<m {
      let p = fib(m, i)
      let r = 0.55 + 0.45 * hash(i, 5)
      let w = 0.05 * sin(a(2) + hash(i, 6) * TAU)
      f.pts.append(P(x: p.x * r + w, y: p.y * r + w * 0.7, z: p.z * r - w, s: 1.5, a: 1))
    }
    f.links = sqrt(14.0 / Double(m)) * 1.35
    f.yaw = a(1); f.pitch = 0.35
  default: // Solving
    let rings = 11
    var total = 0.0
    for j in 0..<rings { total += cos((Double(j) / Double(rings - 1) - 0.5) * Double.pi * 0.92) }
    for j in 0..<rings {
      let lat = (Double(j) / Double(rings - 1) - 0.5) * Double.pi * 0.92
      let rr = cos(lat)
      let cnt = max(6, Int(Double(n) * rr / total))
      let spin = a(Double(1 + j % 3)) * (j % 2 == 0 ? 1 : -1)
      for i in 0..<cnt {
        let th = TAU * Double(i) / Double(cnt) + spin
        f.pts.append(P(x: rr * cos(th), y: sin(lat), z: rr * sin(th), s: 1.1, a: 1))
      }
    }
    f.yaw = 0.3 * sin(a(1)); f.pitch = 0.5
  }
  return f
}

// Draws one orb: rotate (yaw, pitch), perspective, size + opacity by depth.
func drawOrb(_ ctx: inout GraphicsContext, _ size: CGSize, _ kind: Int, _ ph: Double, _ n: Int, _ ink: Color, _ fade: Double = 1) {
  let fr = orbFrame(kind, ph, n)
  let R = Double(min(size.width, size.height)) * 0.38
  let cx = Double(size.width) / 2, cy = Double(size.height) / 2
  let base = R * 0.040 * sqrt(320.0 / Double(n))
  let cyw = cos(fr.yaw), syw = sin(fr.yaw), cp = cos(fr.pitch), sp = sin(fr.pitch)
  struct Q { var x: Double; var y: Double; var d: Double; var sc: Double; var s: Double; var a: Double }
  var qs: [Q] = []
  qs.reserveCapacity(fr.pts.count)
  for p in fr.pts {
    let x1 = p.x * cyw + p.z * syw
    let z1 = -p.x * syw + p.z * cyw
    let y2 = p.y * cp - z1 * sp
    let z2 = p.y * sp + z1 * cp
    let persp = 1 / (1 - 0.22 * z2)
    let d = clamp01((z2 + 1.2) / 2.4)
    qs.append(Q(x: cx + R * x1 * persp, y: cy - R * y2 * persp, d: d, sc: persp, s: p.s, a: p.a))
  }
  if fr.links > 0 {
    let thr = fr.links * R
    var path = Path()
    for i in 0..<qs.count {
      for j in (i + 1)..<qs.count {
        let dx = qs[i].x - qs[j].x, dy = qs[i].y - qs[j].y
        if dx * dx + dy * dy < thr * thr {
          path.move(to: CGPoint(x: qs[i].x, y: qs[i].y)); path.addLine(to: CGPoint(x: qs[j].x, y: qs[j].y))
        }
      }
    }
    ctx.stroke(path, with: .color(ink.opacity(0.28 * fade)), lineWidth: max(0.6, R * 0.009))
  }
  for q in qs {
    let r = base * (0.45 + 0.85 * q.d) * q.s * q.sc
    let al = (0.1 + 0.9 * pow(q.d, 1.3)) * q.a * fade
    ctx.fill(Path(ellipseIn: CGRect(x: q.x - r, y: q.y - r, width: r * 2, height: r * 2)), with: .color(ink.opacity(al)))
  }
}


// Two designs drawn in one Canvas and cross-faded (with a little scale) so the orb morphs.
struct DotOrb: View {
  var a: Int, b: Int, m: Double, ph: Double
  var n: Int = 190
  var body: some View {
    Canvas { g, size in
      var c = g
      let mid = CGPoint(x: size.width / 2, y: size.height / 2)
      if m < 0.999 {
        var ca = c
        ca.translateBy(x: mid.x, y: mid.y); ca.scaleBy(x: lerp(1, 1.12, m), y: lerp(1, 1.12, m)); ca.translateBy(x: -mid.x, y: -mid.y)
        drawOrb(&ca, size, a, ph, n, INK, 1 - m)
      }
      var cb = c
      cb.translateBy(x: mid.x, y: mid.y); cb.scaleBy(x: lerp(0.88, 1, m), y: lerp(0.88, 1, m)); cb.translateBy(x: -mid.x, y: -mid.y)
      drawOrb(&cb, size, b, ph, n, INK, m < 0.999 ? m : 1)
      _ = c
    }
  }
}

// MARK: - the starburst (unused now, kept from the base)
// 12 rays. A "pattern" is 12 weights (how long each ray is). The glyph cross-fades smoothly
// between patterns (dot, 6 rays, 4 rays, long/short, full) so the shape morphs, never swaps.
enum Pat {
  static let dot   = [Double](repeating: 0.0, count: 12)
  static let full  = [Double](repeating: 1.0, count: 12)
  static let six   = (0..<12).map { $0 % 2 == 0 ? 1.0 : 0.14 }
  static let four  = (0..<12).map { $0 % 3 == 0 ? 1.0 : 0.10 }
  static let alt   = (0..<12).map { $0 % 2 == 0 ? 1.0 : 0.58 }
  static let fourB = (0..<12).map { $0 % 3 == 1 ? 1.0 : 0.10 }
  static let petal = (0..<12).map { 0.62 + 0.38 * cos(Double($0) * .pi / 3) }
  static let seq = [six, four, alt, full, fourB, petal]
}

struct Starburst: View {
  var phase: Double        // seconds of "thinking time"
  var calm: Double = 0     // 0 = thinking, 1 = settled avatar (smaller breathing)
  var body: some View {
    Canvas { g, size in
      let R = min(size.width, size.height) / 2
      let c = CGPoint(x: size.width / 2, y: size.height / 2)
      // which two patterns we are between
      let p = phase / 1.35
      let i = Int(floor(max(p, 0)))
      let f = smooth((p - floor(max(p, 0)) - 0.3) / 0.7)
      let a = i == 0 ? Pat.dot : Pat.seq[(i - 1) % Pat.seq.count]
      let b = Pat.seq[i % Pat.seq.count]
      let rot = phase * 0.55 + 0.35 * sin(phase * 0.8)
      let amp = lerp(0.26, 0.10, calm)
      for k in 0..<12 {
        var w = lerp(a[k], b[k], f)
        // each ray breathes with its own phase (two slow sines, irrational ratio)
        let kk = Double(k)
        let breathe = 0.65 * sin(phase * 2.3 + kk * 2.1) + 0.35 * sin(phase * 3.7 + kk * 0.9 + 1.3)
        w = clamp(w * (1 + amp * breathe) + 0.0, 0, 1.2)
        let ang = rot + kk * .pi / 6
        let r0 = 0.05 * R
        let r1 = r0 + (R * 0.93 - r0) * w
        let d = CGPoint(x: cos(ang), y: sin(ang))
        var path = Path()
        path.move(to: CGPoint(x: c.x + d.x * r0, y: c.y + d.y * r0))
        path.addLine(to: CGPoint(x: c.x + d.x * max(r1, r0 + 0.001), y: c.y + d.y * max(r1, r0 + 0.001)))
        g.stroke(path, with: .color(ORANGE), style: StrokeStyle(lineWidth: R * 0.29, lineCap: .round))
      }
    }
  }
}

// MARK: - shimmering verb label
let VERBS = ["Searching…", "Reading…", "Planning…", "Writing…"]

struct SwapText: View {
  let text: String; let prev: String; let p: Double   // p 0...1 incoming progress
  var font: Font; var color: Color
  var body: some View {
    ZStack(alignment: .leading) {
      Text(prev).opacity(1 - p).blur(radius: p * 6).offset(y: -p * 8)
      Text(text).opacity(p).blur(radius: (1 - p) * 6).offset(y: (1 - p) * 8)
    }
    .font(font).foregroundStyle(color)
  }
}

struct ThinkingLabel: View {
  var tau: Double
  var body: some View {
    let per = STEP
    let idx = min(Int(floor(tau / per)), 3)
    let u = (tau - Double(idx) * per) / 0.4
    let p = idx == 0 ? 1 : smooth(u)
    let cur = VERBS[idx % VERBS.count], prv = VERBS[(idx + VERBS.count - 1) % VERBS.count]
    let sec = Int(tau), su = (tau - Double(sec)) / 0.25
    let sp = sec == 0 ? 1 : smooth(su)
    VStack(alignment: .leading, spacing: 3) {
      SwapText(text: cur, prev: idx == 0 ? cur : prv, p: p, font: .system(size: 19, weight: .semibold), color: MUTED)
        .overlay {
          // the shimmer: a bright band sweeps across the same text
          GeometryReader { geo in
            let sweep = (tau * 0.9).truncatingRemainder(dividingBy: 1.0)
            SwapText(text: cur, prev: idx == 0 ? cur : prv, p: p, font: .system(size: 19, weight: .semibold), color: INK)
              .mask(
                LinearGradient(colors: [.clear, .white, .clear], startPoint: .leading, endPoint: .trailing)
                  .frame(width: 70)
                  .offset(x: -70 + sweep * (geo.size.width + 140) - (sweep > 0 ? 0 : 0))
                  .frame(width: geo.size.width, alignment: .leading)
              )
          }
        }
      SwapText(text: "\(sec)s", prev: "\(max(sec - 1, 0))s", p: sp, font: .system(size: 14, weight: .medium).monospacedDigit(), color: MUTED.opacity(0.85))
    }
    .frame(height: 50, alignment: .center)
  }
}

// MARK: - answer layout
struct Flow: Layout {
  var spacing: CGFloat = 5, lineSpacing: CGFloat = 5
  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    layout(subviews, width: proposal.width ?? 300).size
  }
  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let r = layout(subviews, width: bounds.width)
    for (i, o) in r.offsets.enumerated() {
      subviews[i].place(at: CGPoint(x: bounds.minX + o.x, y: bounds.minY + o.y), proposal: .unspecified)
    }
  }
  private func layout(_ subviews: Subviews, width: CGFloat) -> (size: CGSize, offsets: [CGPoint]) {
    var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, out: [CGPoint] = [], maxX: CGFloat = 0
    for s in subviews {
      let sz = s.sizeThatFits(.unspecified)
      if x + sz.width > width && x > 0 { x = 0; y += lineH + lineSpacing; lineH = 0 }
      out.append(CGPoint(x: x, y: y)); x += sz.width + spacing; lineH = max(lineH, sz.height); maxX = max(maxX, x)
    }
    return (CGSize(width: maxX, height: y + lineH), out)
  }
}

struct Word { let s: String; let bold: Bool }
let ANSWER: [[Word]] = [
  "Here's a chill week: Bangkok for 2 days of street food and temples, then Chiang Mai for 3 days of night markets and a cooking class. End with 2 lazy beach days in Krabi 🏝️".split(separator: " ").map { Word(s: String($0), bold: false) },
]

struct AnswerView: View {
  var t: Double; var start: Double
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      ForEach(ANSWER.indices, id: \.self) { pi in
        let before = ANSWER[..<pi].reduce(0) { $0 + $1.count }
        Flow(spacing: 5, lineSpacing: 6) {
          ForEach(ANSWER[pi].indices, id: \.self) { wi in
            let w = ANSWER[pi][wi]
            let p = smooth((t - (start + 0.075 * Double(before + wi))) / 0.4)
            Text(w.s)
              .font(.system(size: 19, weight: w.bold ? .bold : .regular))
              .foregroundStyle(INK)
              .opacity(p).blur(radius: (1 - p) * 3).offset(y: (1 - p) * 9)
          }
        }
      }
    }
  }
}

// MARK: - parallax place carousel (same math as ParallaxCarouselProof, as a pure function of t)
enum CAR {
  static let top = 430.0
  static let cardW = 220.0, cardH = 280.0, gap = 14.0
  static var step: Double { cardW + gap }
  static let cardsIn = 13.4
  static let swipe1 = 14.4, swipe2 = 16.1, drag = 17.8, dragEnd = 20.4
}
struct PlaceInfo { let photo: String; let name: String; let days: String }
let PLACES = [
  PlaceInfo(photo: "city", name: "Bangkok", days: "2 days"),
  PlaceInfo(photo: "mountains", name: "Chiang Mai", days: "3 days"),
  PlaceInfo(photo: "beach", name: "Krabi", days: "2 days"),
]

struct PlaceCarousel: View {
  var t: Double
  // scroll offset in points: two eased swipes, then a slow drag back and forth on the last card
  var scroll: Double {
    func ease3(_ x: Double) -> Double { let c = clamp(x); return c < 0.5 ? 4 * c * c * c : 1 - pow(-2 * c + 2, 3) / 2 }
    var s = CAR.step * ease3((t - CAR.swipe1) / 1.3) + CAR.step * ease3((t - CAR.swipe2) / 1.3)
    if t >= CAR.drag + 0.4 {
      let u = clamp((t - (CAR.drag + 0.4)) / (CAR.dragEnd - CAR.drag - 0.4))
      s -= 85 * sin(2 * .pi * 2 * u) * sin(.pi * u)
    }
    return s
  }
  var body: some View {
    let s = scroll
    let center = 402.0 / 2
    let press = seg(t, CAR.drag, CAR.drag + 0.3) * (1 - seg(t, CAR.dragEnd, CAR.dragEnd + 0.3))
    ZStack(alignment: .topLeading) {
      ForEach(0..<3, id: \.self) { i in
        let x = (402 - CAR.cardW) / 2 + Double(i) * CAR.step - s
        let dist = x + CAR.cardW / 2 - center
        let off = min(max(-dist * 0.65, -170), 170)
        let u = seg(t, CAR.cardsIn + 0.2 * Double(i), CAR.cardsIn + 0.2 * Double(i) + 0.5)
        let place = PLACES[i]
        Image(place.photo).resizable().scaledToFill()
          .frame(width: 560, height: CAR.cardH).offset(x: off)
          .frame(width: CAR.cardW, height: CAR.cardH)
          .clipShape(.rect(cornerRadius: 26))
          .overlay { CardLabel(place: place) }
          .shadow(color: .black.opacity(0.10), radius: 2, y: 2)
          .shadow(color: .black.opacity(0.18), radius: 12, y: 9)
          .scaleEffect(i == 2 ? 1 - 0.04 * press : 1)
          .opacity(u).offset(y: (1 - u) * 40)
          .offset(x: x)
      }
    }
  }
}

struct CardLabel: View {
  let place: PlaceInfo
  var body: some View {
    ZStack(alignment: .bottomLeading) {
      LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
      VStack(alignment: .leading, spacing: 3) {
        Text(place.name).font(.system(size: 22, weight: .bold))
        Label(place.days, systemImage: "mappin.circle.fill")
          .font(.system(size: 14, weight: .medium)).opacity(0.85)
      }
      .foregroundStyle(.white)
      .padding(18)
    }
    .clipShape(.rect(cornerRadius: 26))
    .allowsHitTesting(false)
  }
}

// MARK: - the fake finger
struct FingerDot: View {
  var body: some View {
    Circle().fill(.white.opacity(0.55)).frame(width: 40, height: 40)
      .overlay(Circle().stroke(.black.opacity(0.25), lineWidth: 1.5))
      .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
  }
}

// MARK: - timeline (seconds, pure function of t)
enum T {
  static let fingerIn = 0.6, tapField = 1.5, typeA = 1.9, typeB = 3.4
  static let toSend = 3.4, tapSend = 4.0, send = 4.1, fingerOut = 4.6
  static let think = 4.5, answer = 9.9, words = 10.15
  static let chatOut = 21.0
}

let MESSAGE = "plan my week in thailand"

struct ChatScreen: View {
  let t0 = Date.now
  var body: some View {
    TimelineView(.animation) { ctx in
      let t = (ctx.date.timeIntervalSince(t0) / SLOW).truncatingRemainder(dividingBy: LOOP)
      GeometryReader { geo in ChatStage(t: t, w: geo.size.width, h: geo.size.height) }
        .background(PAPER)
    }
    .ignoresSafeArea()
    .statusBarHidden(false)
  }
}

struct ChatStage: View {
  let t: Double, w: Double, h: Double
  var body: some View {
    let chatOp = 1 - seg(t, T.chatOut, T.chatOut + 0.7)
    let emptyOp = (1 - seg(t, 3.9, 4.35)) * (t < 8 ? 1 : 0) + seg(t, 21.4, 22.0) * (t > 8 ? 1 : 0)
    let sent = t >= T.send
    let userK = spring(t - T.send, freq: 2.3, zeta: 0.7)
    // thinking
    let tau = max(0, t - T.think)
    let tauPhase = t < T.answer ? tau : (T.answer - T.think) + (t - T.answer) * 0.35
    let appear = spring(t - T.think, freq: 1.6, zeta: 0.6)
    let shrink = spring(t - T.answer, freq: 1.7, zeta: 0.58)
    let yA = 218.0
    let gSize = lerp(72 * appear, 42, shrink)
    let gx = lerp(54, 38, shrink), gy = lerp(yA + 17, yA - 3 + 12, shrink)
    let labelOp = seg(t, T.think + 0.15, T.think + 0.55) * (1 - seg(t, T.answer, T.answer + 0.25))
    let starts = [T.think, T.think + STEP, T.think + 2 * STEP, T.think + 3 * STEP, T.answer]
    let gi = starts.lastIndex(where: { t >= $0 }) ?? 0
    let gm = gi == 0 ? 1.0 : smooth((t - starts[gi]) / 0.45)
    let gb = KINDS[gi], ga = KINDS[max(gi - 1, 0)]
    let showGlyph = t >= T.think - 0.01 && t < T.chatOut + 0.75

    ZStack(alignment: .topLeading) {
      // header
      HStack {
        Image(systemName: "line.3.horizontal").font(.system(size: 20, weight: .medium))
        Spacer()
        Text("New chat").font(.system(size: 17, weight: .semibold))
        Spacer()
        Image(systemName: "square.and.pencil").font(.system(size: 19, weight: .medium))
      }
      .foregroundStyle(INK).padding(.horizontal, 22).padding(.top, 66)
      .frame(width: w)

      // empty state
      VStack(spacing: 18) {
        DotOrb(a: 0, b: 0, m: 1, ph: t / LOOP, n: 190).frame(width: 76, height: 76)
        Text("What's on your mind?").font(.system(size: 27, weight: .semibold)).kerning(-0.4).foregroundStyle(INK)
        VStack(spacing: 10) {
          ForEach(["Plan a trip", "Draft an email", "Explain something"], id: \.self) { s in
            Text(s).font(.system(size: 16, weight: .medium)).foregroundStyle(INK.opacity(0.8))
              .padding(.horizontal, 18).frame(height: 42)
              .background(Capsule().fill(.white))
              .overlay(Capsule().stroke(INK.opacity(0.08)))
          }
        }.padding(.top, 8)
      }
      .frame(width: w).padding(.top, 220)
      .opacity(emptyOp)

      // conversation
      ZStack(alignment: .topLeading) {
        if sent {
          Text(MESSAGE).font(.system(size: 18)).foregroundStyle(INK)
            .padding(.horizontal, 18).frame(height: 46)
            .background(RoundedRectangle(cornerRadius: 23).fill(Color(red: 0.918, green: 0.890, blue: 0.847)))
            .scaleEffect(lerp(0.8, 1, userK), anchor: .bottomTrailing)
            .opacity(clamp(userK * 3))
            .offset(y: (1 - userK) * 70)
            .frame(width: w - 40, alignment: .trailing).padding(.leading, 20).padding(.top, 134)
        }
        if t >= T.words - 0.1 {
          AnswerView(t: t, start: T.words)
            .padding(.leading, 62).padding(.trailing, 24).padding(.top, yA - 1)
        }
        if t >= CAR.cardsIn - 0.1 {
          PlaceCarousel(t: t).frame(width: w, height: 280, alignment: .topLeading).padding(.top, CAR.top)
        }
        // thinking label
        ThinkingLabel(tau: tau)
          .opacity(labelOp).blur(radius: (1 - labelOp) * 0)
          .padding(.leading, 100).padding(.top, yA - 8 + 0)
          .opacity(t >= T.think && t < T.answer + 0.3 ? 1 : 0)
      }
      .frame(width: w, height: h, alignment: .topLeading)
      .opacity(chatOp)

      // the glyph, one view that travels from "thinking" to the avatar slot
      if showGlyph {
        DotOrb(a: ga, b: gb, m: gm, ph: tauPhase / 3.0, n: 170)
          .frame(width: max(gSize, 1), height: max(gSize, 1))
          .position(x: gx, y: gy)
          .opacity(chatOp)
      }

      composer
      finger
      carouselFinger
    }
    .frame(width: w, height: h, alignment: .topLeading)
  }

  // finger for the carousel swipes and the slow drag
  var carouselFinger: some View {
    let y = CAR.top + 150
    func ease3(_ x: Double) -> Double { let c = clamp(x); return c < 0.5 ? 4 * c * c * c : 1 - pow(-2 * c + 2, 3) / 2 }
    func win(_ a: Double, _ b: Double) -> Double { seg(t, a - 0.15, a) * (1 - seg(t, b, b + 0.25)) }
    let s1 = CAR.swipe1, s2 = CAR.swipe2, d0 = CAR.drag
    var x = 330.0
    var on = win(s1, s1 + 0.78)
    var press = 0.0
    if t >= d0 - 0.2 {
      on = win(d0, CAR.dragEnd)
      let u = clamp((t - (d0 + 0.4)) / (CAR.dragEnd - d0 - 0.4))
      let dd = 85 * sin(2 * .pi * 2 * u) * sin(.pi * u)
      x = 200 + dd
      press = seg(t, d0, d0 + 0.3) * (1 - seg(t, CAR.dragEnd, CAR.dragEnd + 0.3))
    } else if t >= s2 - 0.2 {
      on = win(s2, s2 + 0.78)
      x = 330 - CAR.step * ease3((t - s2) / 1.3)
    } else {
      x = 330 - CAR.step * ease3((t - s1) / 1.3)
    }
    return FingerDot()
      .scaleEffect((0.8 + 0.2 * on) * (1 - 0.15 * press))
      .opacity(on)
      .position(x: x, y: y)
      .allowsHitTesting(false)
  }

  // composer
  var composer: some View {
    let typedT = clamp((t - T.typeA) / (T.typeB - T.typeA))
    let n = t >= T.send ? 0 : Int(Double(MESSAGE.count) * (typedT * typedT * (3 - 2 * typedT) * 0.35 + typedT * 0.65) + 0.0001)
    let typed = String(MESSAGE.prefix(n))
    let focused = t >= T.tapField + 0.1 && t < T.send
    let ready = n > 0 && t < T.send
    let press = seg(t, T.tapSend, T.tapSend + 0.1) * (1 - seg(t, T.tapSend + 0.12, T.tapSend + 0.3))
    let caret = focused && Int(t * 2.4) % 2 == 0
    return ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 30).fill(.white)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(focused ? ORANGE.opacity(0.55) : INK.opacity(0.08), lineWidth: focused ? 1.5 : 1))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
      HStack(spacing: 1) {
        if typed.isEmpty { Text("Message").foregroundStyle(MUTED.opacity(0.8)) }
        else { Text(typed).foregroundStyle(INK) }
        Rectangle().fill(ORANGE).frame(width: 2, height: 22).opacity(caret ? 1 : 0)
        Spacer()
      }
      .font(.system(size: 18)).padding(.leading, 22)
      HStack { Spacer()
        Circle().fill(ready ? ORANGE : Color(red: 0.85, green: 0.82, blue: 0.77))
          .frame(width: 42, height: 42)
          .overlay(Image(systemName: "arrow.up").font(.system(size: 17, weight: .bold)).foregroundStyle(.white))
          .scaleEffect(1 - 0.12 * press)
          .padding(.trailing, 8)
      }
    }
    .frame(width: w - 32, height: 58)
    .position(x: w / 2, y: h - 70)
  }

  var finger: some View {
    let fx0 = w * 0.78, fy0 = h - 30
    let fieldP = CGPoint(x: w * 0.40, y: h - 70)
    let sendP = CGPoint(x: w - 16 - 8 - 21, y: h - 70)
    let a = seg(t, T.fingerIn, T.tapField), b = seg(t, T.toSend, T.tapSend)
    let x = lerp(lerp(fx0, fieldP.x, a), sendP.x, b)
    let y = lerp(lerp(fy0, fieldP.y, a), sendP.y, b)
    let op = seg(t, T.fingerIn, T.fingerIn + 0.3) * (1 - seg(t, T.tapSend + 0.25, T.fingerOut))
    let press1 = seg(t, T.tapField, T.tapField + 0.1) * (1 - seg(t, T.tapField + 0.12, T.tapField + 0.3))
    let press2 = seg(t, T.tapSend, T.tapSend + 0.1) * (1 - seg(t, T.tapSend + 0.12, T.tapSend + 0.3))
    return FingerDot()
      .scaleEffect(1 - 0.18 * max(press1, press2))
      .opacity(op)
      .position(x: x, y: y)
      .allowsHitTesting(false)
  }
}
