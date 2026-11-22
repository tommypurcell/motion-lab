import SwiftUI

@main
struct SolarSystemApp: App {
  var body: some Scene { WindowGroup { ReelView { ReelCanvas() } } }
}

// The Solar System reel: planets orbit a glowing sun on tilted rings; a fake finger taps Earth,
// it flies out of its orbit into a detail card (matchedGeometryEffect), then flies back.
// Orbit and Planet run exactly the code shown in the code windows (REEL_CODE).

struct Orbit: View {
  let p: World
  init(_ p: World) { self.p = p }
  var body: some View {
    TimelineView(.animation) { t in
      let a = t.date.timeIntervalSince1970 * p.speed
      Planet(p).offset(x: cos(a) * p.orbit,
                       y: sin(a) * p.orbit * 0.36)
    }
  }
}

struct Planet: View {
  let p: World
  init(_ p: World) { self.p = p }
  @Environment(\.solarSpace) private var space
  @Environment(\.pickedWorld) private var pick
  private var ns: Namespace.ID { space! }
  private var picked: World? {
    get { pick.wrappedValue }
    nonmutating set { pick.wrappedValue = newValue }
  }
  var body: some View {
    Sphere(p).matchedGeometryEffect(id: p.name, in: ns)
      .onTapGesture { withAnimation(.spring) { picked = p } }
  }
}

let REEL_TYPES = ["TimelineView", "Planet", "Sphere"]
let REEL_TITLES = ["Orbit", "Tap to zoom"]
let REEL_CODE: [String] = [
#"""
TimelineView(.animation) { t in
  let a = t.date.timeIntervalSince1970 * p.speed
  Planet(p).offset(x: cos(a) * p.orbit,
                   y: sin(a) * p.orbit * 0.36)
}
"""#,
#"""
Sphere(p).matchedGeometryEffect(id: p.name, in: ns)
  .onTapGesture { withAnimation(.spring) { picked = p } }
"""#,
]

// MARK: - Support code (not shown)

let LOOP = 14.0                       // every orbit period divides 14 s, so the video loops cleanly
let SCENE = CGSize(width: 952, height: 1102)
let SUN = CGPoint(x: 476, y: 320)
let TILT = 0.36
let CARD = CGRect(x: 48, y: 588, width: 856, height: 466)
let EARTH_IN_CARD = CGPoint(x: CARD.minX + 180, y: CARD.minY + 233)
let CHEVRON = CGPoint(x: CARD.minX + 788, y: CARD.minY + 68)

struct World: Identifiable, Equatable {
  let name: String
  let orbit: CGFloat
  let turns: Double                   // orbits per 14 s loop
  let size: CGFloat
  let colors: [UInt32]
  var bands = false
  var id: String { name }
  var speed: Double { turns * 2 * .pi / LOOP }
  func spot(_ time: Double) -> CGPoint {
    let a = time * speed
    return CGPoint(x: SUN.x + cos(a) * orbit, y: SUN.y + sin(a) * orbit * TILT)
  }
}

let WORLDS: [World] = [
  World(name: "Mercury", orbit: 140, turns: 5, size: 26, colors: [0xD6D3D1, 0x78716C]),
  World(name: "Venus", orbit: 205, turns: 4, size: 38, colors: [0xFDE68A, 0xD97706]),
  World(name: "Earth", orbit: 275, turns: 3, size: 46, colors: [0x60A5FA, 0x1D4ED8, 0x172554]),
  World(name: "Mars", orbit: 350, turns: 2, size: 34, colors: [0xFCA5A5, 0xB91C1C]),
  World(name: "Jupiter", orbit: 432, turns: 1, size: 72, colors: [0xFED7AA, 0xC2410C], bands: true),
]
let EARTH = WORLDS[2]

extension EnvironmentValues {
  @Entry var solarSpace: Namespace.ID? = nil
  @Entry var pickedWorld: Binding<World?> = .constant(nil)
}

func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

// Earth's continents, drawn on a 280 grid and scaled to any size.
struct Continent: Shape {
  let i: Int
  func path(in r: CGRect) -> Path {
    var p = Path()
    switch i {
    case 0:
      p.move(to: pt(40, 70))
      p.addCurve(to: pt(110, 80), control1: pt(70, 50), control2: pt(100, 60))
      p.addCurve(to: pt(120, 135), control1: pt(120, 100), control2: pt(100, 120))
      p.addCurve(to: pt(175, 160), control1: pt(140, 150), control2: pt(170, 135))
      p.addCurve(to: pt(120, 195), control1: pt(180, 185), control2: pt(145, 200))
      p.addCurve(to: pt(50, 170), control1: pt(95, 190), control2: pt(75, 165))
      p.addCurve(to: pt(15, 125), control1: pt(25, 175), control2: pt(10, 150))
      p.addCurve(to: pt(40, 70), control1: pt(20, 100), control2: pt(25, 85))
    case 1:
      p.move(to: pt(170, 40))
      p.addCurve(to: pt(230, 80), control1: pt(195, 40), control2: pt(225, 55))
      p.addCurve(to: pt(195, 105), control1: pt(235, 105), control2: pt(215, 110))
      p.addCurve(to: pt(155, 70), control1: pt(175, 100), control2: pt(160, 90))
      p.addCurve(to: pt(170, 40), control1: pt(150, 50), control2: pt(155, 40))
    default:
      p.move(to: pt(150, 200))
      p.addCurve(to: pt(210, 215), control1: pt(170, 190), control2: pt(200, 195))
      p.addCurve(to: pt(180, 250), control1: pt(220, 235), control2: pt(200, 250))
      p.addCurve(to: pt(135, 225), control1: pt(160, 250), control2: pt(140, 240))
      p.addCurve(to: pt(150, 200), control1: pt(130, 210), control2: pt(135, 205))
    }
    p.closeSubpath()
    return p.applying(CGAffineTransform(scaleX: r.width / 280, y: r.height / 280))
  }
}

// A shaded ball: drawn on a 280 grid, then scaled to whatever size it is given (ideal = its own size).
struct Sphere: View {
  let p: World
  init(_ p: World) { self.p = p }
  var body: some View {
    GeometryReader { g in
      ball.frame(width: 280, height: 280).scaleEffect(g.size.width / 280).frame(width: g.size.width, height: g.size.height)
    }
    .frame(idealWidth: p.size, idealHeight: p.size)
  }
  var ball: some View {
    ZStack {
      Circle().fill(LinearGradient(colors: p.colors.map(hex), startPoint: UnitPoint(x: 0.2, y: 0.1), endPoint: UnitPoint(x: 0.85, y: 0.95)))
      if p.bands {
        Rectangle().fill(.white.opacity(0.25)).frame(height: 28).offset(y: 280 * 0.37 - 140)
        Rectangle().fill(hex(0x7C2D12).opacity(0.35)).frame(height: 39).offset(y: 280 * 0.62 - 140)
      }
      if p.name == "Earth" {
        Continent(i: 0).fill(hex(0x22C55E))
        Continent(i: 1).fill(hex(0x16A34A))
        Continent(i: 2).fill(hex(0x4ADE80))
        Ellipse().fill(RadialGradient(colors: [.white.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: 100))
          .frame(width: 200, height: 120).position(x: 70, y: 50)
      }
      LinearGradient(stops: [.init(color: .black.opacity(0), location: 0.35), .init(color: .black.opacity(0.6), location: 1)],
                     startPoint: UnitPoint(x: 0.2, y: 0.2), endPoint: UnitPoint(x: 0.95, y: 0.95))
    }
    .frame(width: 280, height: 280)
    .clipShape(Circle())
    .shadow(color: hex(p.colors[0]).opacity(0.35), radius: 70)
  }
}

@MainActor @Observable final class Show {
  var picked: World? = nil
  var cardOn = false
  var finger = CGPoint(x: 600, y: 900)
  var fingerOn = false
  var press = false

  func until(_ t: Double) async {
    let s = t - Date().timeIntervalSince1970
    if s > 0 { try? await Task.sleep(for: .seconds(s)) }
  }
  func run() async {
    while !Task.isCancelled {
      let base = (floor(Date().timeIntervalSince1970 / LOOP) + 1) * LOOP   // next loop start
      // 0–6 s: orbit. Finger comes in and meets Earth where it will be at the tap.
      let tap = base + 6.22
      let e = EARTH.spot(tap)
      await until(base + 5.2)
      finger = CGPoint(x: e.x + 150, y: e.y + 260)
      withAnimation(.easeOut(duration: 0.3)) { fingerOn = true }
      withAnimation(.easeInOut(duration: 0.85)) { finger = e }
      await until(tap - 0.12)
      withAnimation(.easeOut(duration: 0.12)) { press = true }
      await until(tap)
      withAnimation(.spring) { picked = EARTH }
      withAnimation(.easeOut(duration: 0.45).delay(0.08)) { cardOn = true }
      withAnimation(.easeOut(duration: 0.2)) { press = false }
      await until(tap + 0.2)
      withAnimation(.easeInOut(duration: 0.6)) { finger = CGPoint(x: e.x + 52, y: e.y + 58); fingerOn = false }
      // 10.4 s: finger taps the chevron, the card drops away and Earth flies home.
      await until(base + 10.3)
      finger = CGPoint(x: CHEVRON.x + 60, y: CHEVRON.y + 260)
      withAnimation(.easeOut(duration: 0.3)) { fingerOn = true }
      withAnimation(.easeInOut(duration: 0.8)) { finger = CHEVRON }
      await until(base + 11.08)
      withAnimation(.easeOut(duration: 0.12)) { press = true }
      await until(base + 11.2)
      withAnimation(.spring) { picked = nil }
      withAnimation(.easeIn(duration: 0.3)) { cardOn = false }
      withAnimation(.easeOut(duration: 0.2)) { press = false }
      await until(base + 11.4)
      withAnimation(.easeInOut(duration: 0.6)) { finger = CGPoint(x: CHEVRON.x + 40, y: CHEVRON.y + 120); fingerOn = false }
    }
  }
}

struct Stars: View {
  var body: some View {
    Canvas { ctx, size in
      var seed = 7.0
      func rnd() -> Double { seed = (seed * 9301 + 49297).truncatingRemainder(dividingBy: 233280); return seed / 233280 }
      for _ in 0 ..< 90 {
        let s = 2 + rnd() * 3, x = rnd() * size.width, y = rnd() * size.height, o = 0.25 + rnd() * 0.6
        ctx.fill(Path(ellipseIn: CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)), with: .color(.white.opacity(o)))
      }
    }
  }
}

// A soft radial cloud, w × h, centered at (x, y).
func cloud(_ c: UInt32, _ a: Double, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> some View {
  Circle().fill(RadialGradient(colors: [hex(c).opacity(a), hex(c).opacity(0)], center: .center, startRadius: 0, endRadius: w / 2))
    .frame(width: w, height: w).scaleEffect(x: 1, y: h / w).position(x: x, y: y)
}

struct Sun: View {
  var time: Double
  var body: some View {
    let breathe = 0.95 + 0.05 * sin(time * 2 * .pi / 3.5)
    ZStack {
      Circle().fill(RadialGradient(stops: [.init(color: hex(0xFBBF24).opacity(0.5), location: 0), .init(color: hex(0xF97316).opacity(0.18), location: 0.45), .init(color: hex(0xF97316).opacity(0), location: 1)], center: .center, startRadius: 0, endRadius: 280))
        .frame(width: 560, height: 560)
        .scaleEffect(0.9 + (breathe - 0.95) * 3)
      Circle().fill(RadialGradient(stops: [.init(color: hex(0xFFFBEB), location: 0), .init(color: hex(0xFDE047), location: 0.45), .init(color: hex(0xF59E0B), location: 1)], center: .center, startRadius: 0, endRadius: 78))
        .frame(width: 156, height: 156)
        .shadow(color: hex(0xF59E0B).opacity(0.9), radius: 30)
        .shadow(color: hex(0xFDE047).opacity(0.8), radius: 12)
        .scaleEffect(breathe)
    }
    .allowsHitTesting(false)
  }
}

struct DetailCard: View {
  let p: World
  var body: some View {
    ZStack(alignment: .topLeading) {
      cloud(0x3B82F6, 0.45, 180, 233, 400, 400)
      VStack(alignment: .leading, spacing: 0) {
        Text("Third from the Sun").font(.system(size: 24)).foregroundStyle(hex(0x94A3B8))
        Text(p.name).font(.system(size: 64, weight: .bold)).kerning(-1).foregroundStyle(.white).padding(.top, 2)
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 38) {
          GridRow { stat("1 AU", "from the Sun"); stat("365 d", "one orbit") }
          GridRow { stat("1", "moon"); stat("15 °C", "average") }
        }
        .padding(.top, 36)
      }
      .offset(x: 368, y: 44)
      Image(systemName: "chevron.down").font(.system(size: 24, weight: .bold)).foregroundStyle(hex(0xCBD5E1))
        .frame(width: 56, height: 56).background(Circle().fill(.white.opacity(0.1)))
        .offset(x: 760, y: 40)
    }
    .frame(width: CARD.width, height: CARD.height, alignment: .topLeading)
    .background(RoundedRectangle(cornerRadius: 40).fill(hex(0x0F172A).opacity(0.78)))
    .overlay(RoundedRectangle(cornerRadius: 40).stroke(.white.opacity(0.12), lineWidth: 1.5))
    .clipShape(RoundedRectangle(cornerRadius: 40))
    .shadow(color: .black.opacity(0.2), radius: 4, y: 4)
    .shadow(color: .black.opacity(0.5), radius: 32, y: 24)
  }
  func stat(_ v: String, _ l: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(v).font(.system(size: 40, weight: .semibold)).foregroundStyle(.white)
      Text(l).font(.system(size: 22)).foregroundStyle(hex(0x94A3B8))
    }
    .frame(width: 220, alignment: .leading)
  }
}

struct SolarScene: View {
  @State private var show = Show()
  @Namespace private var ns
  var body: some View {
    @Bindable var show = show
    ZStack(alignment: .topLeading) {
      LinearGradient(colors: [hex(0x0B0A22), hex(0x03040C)], startPoint: .top, endPoint: .bottom)
      cloud(0x7C3AED, 0.28, 760, 160, 760, 520)
      cloud(0x2563EB, 0.22, 140, 520, 700, 520)
      cloud(0xDB2777, 0.12, 520, 980, 900, 400)
      Stars()
      ForEach(WORLDS) { w in
        Ellipse().stroke(.white.opacity(0.14), lineWidth: 2)
          .frame(width: w.orbit * 2, height: w.orbit * 2 * TILT).position(SUN)
      }
      TimelineView(.animation) { t in
        let now = t.date.timeIntervalSince1970
        ZStack {
          Sun(time: now).zIndex(0)
          ForEach(WORLDS.filter { $0 != EARTH }) { w in
            Orbit(w).fixedSize().zIndex(sin(now * w.speed))
          }
        }
        .frame(width: 0, height: 0)
        .position(SUN)
      }
      // Earth's orbit clears the sun, so it sits outside the depth sort and can leave its orbit.
      ZStack {
        if show.picked != EARTH { Orbit(EARTH).fixedSize() }
      }
      .frame(width: 0, height: 0)
      .position(SUN)
      if show.cardOn {
        DetailCard(p: EARTH)
          .offset(x: CARD.minX, y: CARD.minY)
          .transition(.opacity.combined(with: .offset(y: 80)))
      }
      if let p = show.picked {
        Sphere(p).matchedGeometryEffect(id: p.name, in: ns)
          .frame(width: 280, height: 280)
          .position(EARTH_IN_CARD)
      }
      FingerDot()
        .scaleEffect(show.press ? 0.8 : 1)
        .opacity(show.fingerOn ? 1 : 0)
        .scaleEffect(show.fingerOn ? 1 : 0.6)
        .position(show.finger)
    }
    .environment(\.solarSpace, ns)
    .environment(\.pickedWorld, $show.picked)
    .frame(width: SCENE.width, height: SCENE.height, alignment: .topLeading)
    .clipShape(RoundedRectangle(cornerRadius: 40))
    .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.white.opacity(0.08)))
    .shadow(color: .black.opacity(0.12), radius: 4, y: 4)
    .shadow(color: .black.opacity(0.4), radius: 32, y: 24)
    .task { await show.run() }
  }
}

struct ReelCanvas: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      TitleBlock(title: "Solar System", subtitle: "Tap a planet, it zooms into a card")
      Spacer().frame(height: 40)
      SolarScene()
      Spacer().frame(height: 28)
      VStack(spacing: 20) {
        ForEach(0 ..< 2, id: \.self) { i in CodeWindow(title: REEL_TITLES[i], code: REEL_CODE[i], types: REEL_TYPES) }
      }
      Spacer(minLength: 0)
      Text("Real SwiftUI · iOS 26 · TimelineView, offset, matchedGeometryEffect").font(.system(size: 22)).foregroundStyle(hex(0x64748B))
        .frame(maxWidth: .infinity)
    }
    .padding(.horizontal, 64).padding(.top, 72).padding(.bottom, 48)
    .frame(width: 1080, height: 1920, alignment: .topLeading)
    .background(LinearGradient(colors: [hex(0x0D1A3A), hex(0x060B1A)], startPoint: .top, endPoint: .bottom))
  }
}
