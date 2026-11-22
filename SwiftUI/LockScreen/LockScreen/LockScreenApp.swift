import SwiftUI

@main
struct LockScreenApp: App {
  var body: some Scene { WindowGroup { LockRoot() } }
}

// Our own lock screen: a big clock tucked behind the mountain (depth effect), live widgets,
// notifications that stack in, a swipe to clear one, then press-and-hold to customize.
// Every moving value is a pure function of one clock `t`, so the 16 s loop is seamless.

// MARK: - helpers

func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }
func prog(_ t: Double, _ a: Double, _ b: Double) -> Double { clamp01((t - a) / (b - a)) }
func eio(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
func eout(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
func eback(_ x: Double) -> Double { let c1 = 1.1, c3 = 2.1; return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2) }
func lerp(_ a: Double, _ b: Double, _ x: Double) -> Double { a + (b - a) * x }

let W: CGFloat = 402, H: CGFloat = 874
let LOOP = 16.0

// MARK: - finger + ticker (same as the template)

struct FingerDot: View {
  var body: some View {
    Circle().fill(.white.opacity(0.55)).frame(width: 40, height: 40)
      .overlay(Circle().stroke(.black.opacity(0.25), lineWidth: 1.5))
      .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
  }
}

final class FrameTicker: NSObject {
  private var waiter: CheckedContinuation<Void, Never>?
  private var link: CADisplayLink?
  @MainActor func next() async {
    if link == nil {
      let l = CADisplayLink(target: self, selector: #selector(tick))
      l.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
      l.add(to: .main, forMode: .common)
      link = l
    }
    await withCheckedContinuation { waiter = $0 }
  }
  @objc private func tick() { waiter?.resume(); waiter = nil }
}

let SLOW = 2.0

// MARK: - the timeline

struct Finger { var pos = CGPoint.zero; var on = 0.0; var down = 0.0; var ring = 0.0 }

struct Timeline {
  let t: Double
  var wake: Double { eout(prog(t, 0, 0.9)) }
  var sleep: Double { eio(prog(t, 14.9, 15.6)) }
  var black: Double { t < 8 ? 1 - wake : sleep }

  func widgets(_ i: Int) -> Double { eout(prog(t, 0.8 + 0.25 * Double(i), 1.6 + 0.25 * Double(i))) }
  var rings: Double { eout(prog(t, 1.2, 3.4)) }
  var spark: Double { eio(prog(t, 1.4, 3.2)) }

  // notifications: 0 = oldest (Messages), 1 = Calendar, 2 = newest (Lumen)
  let arrive = [2.0, 3.0, 4.0]
  func arr(_ i: Int) -> Double { prog(t, arrive[i], arrive[i] + 0.8) }
  var clearP: Double { eio(prog(t, 6.7, 7.5)) }       // card 1 collapses
  var swipeU: Double { prog(t, 5.8, 7.1) }
  var cardX: Double { -460 * pow(swipeU, 1.8) }         // card 1 offset
  var cardFade: Double { 1 - prog(t, 6.8, 7.1) }
  func slot(_ i: Int) -> Double {  // how many newer notifications sit above this one
    var s = 0.0
    if i < 2 { for j in (i + 1)..<3 { s += eback(arr(j)) * (j == 1 ? 1 - clearP : 1) } }
    return s
  }

  // customize
  var holdEff: Double { t < 12 ? eout(prog(t, 8.1, 9.3)) : 0 }
  var p: Double { t < 12 ? eio(prog(t, 9.3, 10.1)) : 1 - eio(prog(t, 13.0, 13.8)) }
  var scale: Double { let b = 1 - 0.03 * holdEff; return b + (0.80 - b) * p }
  var carousel: Double {
    let d = 260.0 / 346
    let u = prog(t, 10.6, 11.5)
    let drag = d * u * u * (2 - u)
    return drag + (1 - d) * (1 - pow(1 - prog(t, 11.5, 12.3), 2))
  }

  var finger: Finger {
    var f = Finger()
    if t >= 5.2 && t < 7.2 {          // swipe a notification away
      f.on = prog(t, 5.3, 5.5) * (1 - prog(t, 6.6, 6.9))
      f.down = prog(t, 5.5, 5.7) * (1 - prog(t, 6.55, 6.7))
      let rel = -460 * pow(prog(6.6, 5.8, 7.1), 1.8)
      f.pos = CGPoint(x: 320 + (t < 6.6 ? cardX : rel - (t - 6.6) * 140), y: 643)
    } else if t >= 7.6 && t < 9.7 {   // press and hold on the wallpaper
      f.on = prog(t, 7.8, 8.0) * (1 - prog(t, 9.3, 9.55))
      f.down = prog(t, 8.0, 8.15) * (1 - prog(t, 9.3, 9.45))
      f.ring = prog(t, 8.15, 9.3)
      f.pos = CGPoint(x: 110, y: 300)
    } else if t >= 10.2 && t < 12.5 { // swipe to the next wallpaper
      let u = prog(t, 10.6, 11.5)
      f.on = prog(t, 10.3, 10.5) * (1 - prog(t, 11.55, 11.85))
      f.down = prog(t, 10.5, 10.65) * (1 - prog(t, 11.5, 11.65))
      f.pos = CGPoint(x: 330 - 260 * u * u * (2 - u) - (t > 11.5 ? (t - 11.5) * 60 : 0), y: 430)
    } else if t >= 12.4 && t < 13.5 { // tap to finish
      f.on = prog(t, 12.5, 12.7) * (1 - prog(t, 13.1, 13.3))
      f.down = prog(t, 12.75, 12.85) * (1 - prog(t, 13.0, 13.1))
      f.pos = CGPoint(x: 200, y: 430)
    }
    return f
  }
}

// MARK: - show

@Observable final class Show {
  var t = 0.0
  var minute = 40
  let ticker = FrameTicker()

  func run() async {
    let a = ProcessInfo.processInfo.arguments
    if let i = a.firstIndex(of: "-T"), let v = Double(a[i + 1]) { t = v; minute = v > 1 ? 41 : 40; return }
    while !Task.isCancelled {
      let t0 = Date.now
      var tr = Transaction(); tr.disablesAnimations = true
      withTransaction(tr) { minute = 40; t = 0 }
      while true {
        let x = Date.now.timeIntervalSince(t0) / SLOW
        if x >= LOOP { break }
        t = x
        let want = x > 1.0 ? 41 : 40
        if want != minute { withAnimation(.smooth(duration: 0.7 * SLOW)) { minute = want } }
        await ticker.next()
      }
    }
  }
}

// MARK: - theme + wallpaper art

struct Theme {
  let sky: [Color]
  let glow: Color
  let sun: Color
  let sunPos: CGPoint
  let ridgeBack: Color, ridgeMid: Color
  let peak: [Color]
  let rim: Color
  let fog: Color
  let clock: [Color]
  let stars: Double
}

let DUSK = Theme(
  sky: [Color(red: 0.07, green: 0.05, blue: 0.27), Color(red: 0.33, green: 0.15, blue: 0.52), Color(red: 0.85, green: 0.28, blue: 0.50), Color(red: 1.0, green: 0.62, blue: 0.36)],
  glow: Color(red: 1.0, green: 0.55, blue: 0.35), sun: Color(red: 1.0, green: 0.82, blue: 0.55), sunPos: CGPoint(x: 310, y: 470),
  ridgeBack: Color(red: 0.36, green: 0.17, blue: 0.47), ridgeMid: Color(red: 0.21, green: 0.10, blue: 0.36),
  peak: [Color(red: 0.14, green: 0.07, blue: 0.27), Color(red: 0.05, green: 0.02, blue: 0.12)],
  rim: Color(red: 1.0, green: 0.62, blue: 0.45), fog: Color(red: 1.0, green: 0.55, blue: 0.5),
  clock: [.white, Color(red: 1.0, green: 0.86, blue: 0.80)], stars: 0.8)

let DAWN = Theme(
  sky: [Color(red: 0.03, green: 0.16, blue: 0.30), Color(red: 0.13, green: 0.45, blue: 0.58), Color(red: 0.52, green: 0.82, blue: 0.80), Color(red: 1.0, green: 0.88, blue: 0.66)],
  glow: Color(red: 1.0, green: 0.9, blue: 0.7), sun: Color(red: 1.0, green: 0.97, blue: 0.85), sunPos: CGPoint(x: 90, y: 470),
  ridgeBack: Color(red: 0.16, green: 0.45, blue: 0.52), ridgeMid: Color(red: 0.08, green: 0.29, blue: 0.40),
  peak: [Color(red: 0.06, green: 0.22, blue: 0.31), Color(red: 0.02, green: 0.09, blue: 0.15)],
  rim: Color(red: 1.0, green: 0.93, blue: 0.75), fog: Color(red: 0.8, green: 0.95, blue: 0.9),
  clock: [.white, Color(red: 0.88, green: 0.97, blue: 0.95)], stars: 0.35)

func smoothRidge(_ pts: [CGPoint]) -> Path {
  var p = Path()
  p.move(to: CGPoint(x: pts[0].x, y: H))
  p.addLine(to: pts[0])
  for i in 1..<pts.count {
    let mid = CGPoint(x: (pts[i - 1].x + pts[i].x) / 2, y: (pts[i - 1].y + pts[i].y) / 2)
    p.addQuadCurve(to: mid, control: pts[i - 1])
  }
  p.addLine(to: pts.last!)
  p.addLine(to: CGPoint(x: pts.last!.x, y: H))
  p.closeSubpath()
  return p
}

let PEAK_TOP: [CGPoint] = [
  CGPoint(x: -10, y: 640), CGPoint(x: 40, y: 602), CGPoint(x: 80, y: 566), CGPoint(x: 112, y: 520),
  CGPoint(x: 134, y: 452), CGPoint(x: 160, y: 384), CGPoint(x: 184, y: 318), CGPoint(x: 205, y: 258),
  CGPoint(x: 226, y: 316), CGPoint(x: 248, y: 378), CGPoint(x: 276, y: 446), CGPoint(x: 310, y: 502),
  CGPoint(x: 354, y: 552), CGPoint(x: 412, y: 590)]

struct PeakShape: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: -10, y: H + 10))
    for pt in PEAK_TOP { p.addLine(to: pt) }
    p.addLine(to: CGPoint(x: 412, y: H + 10))
    p.closeSubpath()
    return p
  }
}
struct PeakEdge: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path(); p.move(to: PEAK_TOP[0])
    for pt in PEAK_TOP.dropFirst() { p.addLine(to: pt) }
    return p
  }
}

struct WallBack: View {
  let th: Theme
  var body: some View {
    ZStack(alignment: .topLeading) {
      LinearGradient(stops: [.init(color: th.sky[0], location: 0), .init(color: th.sky[1], location: 0.34), .init(color: th.sky[2], location: 0.52), .init(color: th.sky[3], location: 0.62)], startPoint: .top, endPoint: .bottom)
        .frame(width: W, height: H)
      Canvas { ctx, _ in
        var seed: UInt64 = 7
        func rnd() -> Double { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Double(seed >> 33) / Double(1 << 31) }
        for _ in 0..<46 {
          let x = rnd() * W, y = rnd() * 300, r = 0.6 + rnd() * 1.1, a = 0.25 + rnd() * 0.6
          ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(.white.opacity(a * th.stars)))
        }
      }.frame(width: W, height: H)
      // sun + glow
      Circle().fill(RadialGradient(colors: [th.glow.opacity(0.75), th.glow.opacity(0)], center: .center, startRadius: 10, endRadius: 190))
        .frame(width: 380, height: 380).position(th.sunPos)
      // far ridges
      smoothRidge([CGPoint(x: -20, y: 530), CGPoint(x: 40, y: 496), CGPoint(x: 110, y: 514), CGPoint(x: 180, y: 478), CGPoint(x: 250, y: 500), CGPoint(x: 320, y: 462), CGPoint(x: 380, y: 486), CGPoint(x: 430, y: 474)])
        .fill(LinearGradient(colors: [th.ridgeBack, th.ridgeBack.opacity(0.8)], startPoint: .top, endPoint: .bottom))
      LinearGradient(colors: [th.fog.opacity(0), th.fog.opacity(0.28), th.fog.opacity(0)], startPoint: .top, endPoint: .bottom)
        .frame(width: W, height: 90).offset(y: 500)
      smoothRidge([CGPoint(x: -20, y: 576), CGPoint(x: 60, y: 540), CGPoint(x: 130, y: 566), CGPoint(x: 220, y: 526), CGPoint(x: 296, y: 552), CGPoint(x: 360, y: 524), CGPoint(x: 430, y: 548)])
        .fill(th.ridgeMid)
    }
    .frame(width: W, height: H)
  }
}

struct WallFront: View {
  let th: Theme
  var body: some View {
    ZStack {
      PeakShape().fill(LinearGradient(colors: th.peak, startPoint: .top, endPoint: .bottom))
      PeakShape().fill(LinearGradient(colors: [th.fog.opacity(0.0), th.fog.opacity(0.12), th.fog.opacity(0)], startPoint: UnitPoint(x: 0.5, y: 0.45), endPoint: UnitPoint(x: 0.5, y: 0.75)))
      PeakEdge().stroke(LinearGradient(colors: [th.rim.opacity(0.9), th.rim.opacity(0.0)], startPoint: UnitPoint(x: 0.55, y: 0.3), endPoint: UnitPoint(x: 0.55, y: 0.62)), style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))
    }
    .frame(width: W, height: H).allowsHitTesting(false)
  }
}

// MARK: - widgets + notifications

struct Glass: ViewModifier {
  var radius: CGFloat
  func body(content: Content) -> some View {
    content
      .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Color(white: 0.08).opacity(0.28)))
      .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(.white.opacity(0.13)))
      .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(.white.opacity(0.16), lineWidth: 0.8))
  }
}
extension View { func glass(_ r: CGFloat) -> some View { modifier(Glass(radius: r)) } }

struct RingsWidget: View {
  let fill: Double
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 5) {
        Image(systemName: "flame.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(Color(red: 1, green: 0.3, blue: 0.4))
        Text("Activity").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white.opacity(0.75))
        Spacer()
      }
      ZStack {
        ring(86, 0.86 * fill, [Color(red: 1, green: 0.2, blue: 0.4), Color(red: 1, green: 0.45, blue: 0.55)])
        ring(62, 0.64 * fill, [Color(red: 0.4, green: 0.95, blue: 0.3), Color(red: 0.7, green: 1, blue: 0.4)])
        ring(38, 0.92 * fill, [Color(red: 0.2, green: 0.8, blue: 1), Color(red: 0.4, green: 0.95, blue: 0.95)])
      }
      .frame(maxWidth: .infinity)
    }
    .padding(14).frame(width: 175, height: 146).glass(26)
  }
  func ring(_ d: CGFloat, _ v: Double, _ c: [Color]) -> some View {
    ZStack {
      Circle().stroke(c[0].opacity(0.22), lineWidth: 10)
      Circle().trim(from: 0, to: max(0.001, v))
        .stroke(LinearGradient(colors: c, startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 10, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }.frame(width: d, height: d)
  }
}

struct SparkLine: Shape {
  func path(in r: CGRect) -> Path {
    let ys: [CGFloat] = [0.7, 0.55, 0.3, 0.12, 0.2, 0.5, 0.8]
    var p = Path()
    let pts = ys.enumerated().map { CGPoint(x: r.minX + r.width * CGFloat($0.offset) / CGFloat(ys.count - 1), y: r.minY + r.height * $0.element) }
    p.move(to: pts[0])
    for i in 1..<pts.count {
      let a = pts[i - 1], b = pts[i]
      p.addCurve(to: b, control1: CGPoint(x: (a.x + b.x) / 2, y: a.y), control2: CGPoint(x: (a.x + b.x) / 2, y: b.y))
    }
    return p
  }
}

struct WeatherWidget: View {
  let spark: Double
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 4) {
        Image(systemName: "location.fill").font(.system(size: 10, weight: .bold))
        Text("Bangkok").font(.system(size: 13, weight: .semibold))
        Spacer()
        Image(systemName: "sun.max.fill").symbolRenderingMode(.multicolor).font(.system(size: 17))
      }.foregroundStyle(.white.opacity(0.75))
      Text("31°").font(.system(size: 46, weight: .semibold)).foregroundStyle(.white).padding(.top, 2)
      Text("Sunny  H:34°  L:26°").font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.7))
      Spacer(minLength: 6)
      SparkLine().trim(from: 0, to: max(0.001, spark))
        .stroke(LinearGradient(colors: [Color(red: 1, green: 0.85, blue: 0.45), .white], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        .frame(height: 22)
    }
    .padding(14).frame(width: 175, height: 146).glass(26)
  }
}

struct Notif: View {
  let icon: String, tint: [Color], app: String, title: String, msg: String
  var text: some View {
    VStack(alignment: .leading, spacing: 1) {
      HStack {
        Text(title).font(.system(size: 15, weight: .semibold))
        Spacer()
        Text("now").font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
      }
      Text(msg).font(.system(size: 14)).foregroundStyle(.white.opacity(0.8)).lineLimit(2)
    }
  }
  var body: some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .fill(LinearGradient(colors: tint, startPoint: .top, endPoint: .bottom))
        .frame(width: 40, height: 40)
        .overlay(Image(systemName: icon).font(.system(size: 19, weight: .semibold)).foregroundStyle(.white))
      text.foregroundStyle(.white)
    }
    .padding(.horizontal, 14).frame(width: 362, height: 70).glass(22)
  }
}

// MARK: - the face (wallpaper + clock + widgets + notifications)

struct LockFace: View {
  let th: Theme
  let tl: Timeline
  let minute: Int

  var body: some View {
    let t = tl.t
    ZStack(alignment: .topLeading) {
      WallBack(th: th)

      // date + clock, drawn BEHIND the mountain
      VStack(spacing: 0) {
        Text("Wednesday 18 November")
          .font(.system(size: 18, weight: .semibold)).foregroundStyle(.white.opacity(0.85))
        VStack(spacing: -54) {
          Text("9")
          Text("\(minute)").contentTransition(.numericText(value: Double(minute)))
        }
        .font(.system(size: 136, weight: .heavy, design: .rounded))
        .foregroundStyle(LinearGradient(colors: th.clock, startPoint: .top, endPoint: .bottom))
        .padding(.top, 2)
      }
      .frame(width: W).offset(y: 72)
      .shadow(color: .black.opacity(0.18), radius: 14, y: 4)

      WallFront(th: th)

      // widgets
      HStack(spacing: 12) {
        RingsWidget(fill: tl.rings).opacity(tl.widgets(0)).offset(y: (1 - tl.widgets(0)) * 26)
        WeatherWidget(spark: tl.spark).opacity(tl.widgets(1)).offset(y: (1 - tl.widgets(1)) * 26)
      }
      .offset(x: 20, y: 366)

      // notifications: newest on top
      let items: [Notif] = [
        Notif(icon: "bubble.left.fill", tint: [Color(red: 0.35, green: 0.9, blue: 0.45), Color(red: 0.1, green: 0.7, blue: 0.3)], app: "Messages", title: "Mia", msg: "Sunset at 6? I'll bring the speaker."),
        Notif(icon: "calendar", tint: [Color(red: 1, green: 0.45, blue: 0.4), Color(red: 0.9, green: 0.2, blue: 0.25)], app: "Calendar", title: "Design review", msg: "Starts in 15 min, Room 4B"),
        Notif(icon: "sparkles", tint: [Color(red: 0.55, green: 0.5, blue: 1), Color(red: 0.35, green: 0.25, blue: 0.9)], app: "Lumen", title: "12 day focus streak", msg: "One more session keeps it going."),
      ]
      ForEach(0..<3, id: \.self) { i in
        let a = tl.arr(i)
        let ae = eback(a)
        let isCleared = (i == 1)
        let slot = tl.slot(i)
        let y = 530 + 78 * slot + (1 - ae) * -34
        let x = isCleared ? tl.cardX : 0
        let op = a * min(1, 1.4 * a) * (isCleared ? tl.cardFade : 1)
        items[i]
          .scaleEffect(lerp(0.94, 1, ae))
          .opacity(op * (1 - min(1, tl.p * 1.8)))
          .offset(x: 20 + x, y: y)
          .zIndex(Double(i))
      }

      // lock screen buttons
      Group {
        Color.clear.frame(width: 50, height: 50).glass(25).overlay(Image(systemName: "flashlight.off.fill").font(.system(size: 20)).foregroundStyle(.white)).offset(x: 40, y: 786)
        Color.clear.frame(width: 50, height: 50).glass(25).overlay(Image(systemName: "camera.fill").font(.system(size: 20)).foregroundStyle(.white)).offset(x: 312, y: 786)
      }.opacity(tl.wake * (1 - min(1, tl.p * 2)))
    }
    .frame(width: W, height: H, alignment: .topLeading)
    .compositingGroup()
  }
}

// MARK: - root

struct LockRoot: View {
  @State private var show = Show()
  var body: some View {
    let tl = Timeline(t: show.t)
    let p = tl.p
    let stride = 402 - 54 * p
    ZStack {
      Color.black
      ZStack {
        ForEach(0..<2, id: \.self) { i in
          if i == 0 || p > 0.001 || tl.carousel > 0 {
            LockFace(th: i == 0 ? DUSK : DAWN, tl: tl, minute: show.minute)
              .clipShape(RoundedRectangle(cornerRadius: 56 * p, style: .continuous))
              .scaleEffect(tl.scale)
              .offset(x: (Double(i) - tl.carousel) * stride, y: -22 * p)
          }
        }
      }
      .scaleEffect(1 + 0.045 * (1 - tl.wake) * (show.t < 8 ? 1 : 0))
      .frame(width: W, height: H).clipped()

      // customize chrome
      VStack(spacing: 14) {
        Spacer()
        HStack(spacing: 7) {
          ForEach(0..<2, id: \.self) { i in
            Circle().fill(.white.opacity(abs(tl.carousel - Double(i)) < 0.5 ? 0.95 : 0.3)).frame(width: 7, height: 7)
          }
        }
        Text("Customize").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
          .padding(.horizontal, 28).frame(height: 44).background(Capsule().fill(.white.opacity(0.18)))
          .padding(.bottom, 44)
      }
      .frame(width: W, height: H)
      .opacity(clamp01((p - 0.5) * 2)).offset(y: (1 - p) * 30)

      // fake finger
      let f = tl.finger
      ZStack {
        Circle().trim(from: 0, to: max(0.001, f.ring)).stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 3, lineCap: .round))
          .rotationEffect(.degrees(-90)).frame(width: 66, height: 66).opacity(f.ring > 0 && f.ring < 1 ? 1 : 0)
        FingerDot().scaleEffect(lerp(1, 0.82, f.down))
      }
      .opacity(f.on).scaleEffect(lerp(0.6, 1, f.on))
      .position(f.pos).allowsHitTesting(false)

      Color.black.opacity(tl.black).frame(width: W, height: H).allowsHitTesting(false)
    }
    .frame(width: W, height: H)
    .ignoresSafeArea()
    .background(Color.black)
    .preferredColorScheme(.dark)
    .task { await show.run() }
  }
}
