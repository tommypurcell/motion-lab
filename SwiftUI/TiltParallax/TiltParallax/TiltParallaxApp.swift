import SwiftUI

@main
struct TiltParallaxApp: App {
  var body: some Scene { WindowGroup { PassportScreen() } }
}

// Tilt Parallax: a collectible card that tilts in 3D like the phone is tilting.
// The Simulator has no motion sensor, so tilt comes from a smooth looping path (and from the finger while it drags).

let SLOW = 2.0        // recording runs at half speed; ffmpeg speeds it back up
let LOOP = 16.0       // seconds, seamless

func smooth(_ x: Double) -> Double { let c = min(max(x, 0), 1); return c * c * (3 - 2 * c) }
// 0 -> 1 between a and b
func ramp(_ t: Double, _ a: Double, _ b: Double) -> Double { smooth((t - a) / (b - a)) }

struct FingerDot: View {
  var body: some View {
    Circle().fill(.white.opacity(0.55)).frame(width: 40, height: 40)
      .overlay(Circle().stroke(.black.opacity(0.25), lineWidth: 1.5))
      .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
  }
}

// MARK: art (all drawn in code, card space 322 x 456)

struct Karst: Shape {
  func path(in r: CGRect) -> Path {
    var p = Path()
    let w = r.width, h = r.height
    p.move(to: CGPoint(x: 0, y: h))
    p.addCurve(to: CGPoint(x: w * 0.14, y: h * 0.3), control1: CGPoint(x: w * 0.02, y: h * 0.7), control2: CGPoint(x: w * 0.0, y: h * 0.45))
    p.addCurve(to: CGPoint(x: w * 0.5, y: 0), control1: CGPoint(x: w * 0.22, y: h * 0.08), control2: CGPoint(x: w * 0.36, y: 0))
    p.addCurve(to: CGPoint(x: w * 0.86, y: h * 0.28), control1: CGPoint(x: w * 0.68, y: 0), control2: CGPoint(x: w * 0.8, y: h * 0.12))
    p.addCurve(to: CGPoint(x: w, y: h), control1: CGPoint(x: w * 1.0, y: h * 0.5), control2: CGPoint(x: w * 0.98, y: h * 0.75))
    p.closeSubpath()
    return p
  }
}

struct Boat: Shape {
  func path(in r: CGRect) -> Path {
    var p = Path()
    let w = r.width, h = r.height
    p.move(to: CGPoint(x: 0, y: h * 0.2))
    p.addQuadCurve(to: CGPoint(x: w * 0.3, y: h), control: CGPoint(x: w * 0.04, y: h * 0.8))
    p.addLine(to: CGPoint(x: w * 0.78, y: h))
    p.addQuadCurve(to: CGPoint(x: w, y: h * 0.45), control: CGPoint(x: w * 0.95, y: h * 0.9))
    p.addLine(to: CGPoint(x: w * 0.96, y: h * 0.4))
    p.addQuadCurve(to: CGPoint(x: w * 0.12, y: h * 0.28), control: CGPoint(x: w * 0.6, y: h * 0.5))
    p.closeSubpath()
    return p
  }
}

struct Palm: View {
  var body: some View {
    ZStack {
      Capsule().frame(width: 6, height: 120).rotationEffect(.degrees(10))
      ForEach(0..<7, id: \.self) { i in
        Capsule().frame(width: 62, height: 7)
          .offset(x: 31)
          .rotationEffect(.degrees(Double(i) * 38 - 120), anchor: .leading)
          .offset(x: 10, y: -64)
      }
    }
  }
}

// each layer is drawn a little bigger than the card so it can slide without showing an edge
struct SkyLayer: View {
  var body: some View {
    ZStack {
      LinearGradient(stops: [
        .init(color: Color(red: 0.13, green: 0.10, blue: 0.36), location: 0),
        .init(color: Color(red: 0.55, green: 0.20, blue: 0.52), location: 0.34),
        .init(color: Color(red: 0.98, green: 0.45, blue: 0.40), location: 0.5),
        .init(color: Color(red: 1.0, green: 0.78, blue: 0.50), location: 0.64),
      ], startPoint: .top, endPoint: .bottom)
      Circle().fill(RadialGradient(colors: [Color(red: 1, green: 0.85, blue: 0.6).opacity(0.7), .clear], center: .center, startRadius: 20, endRadius: 190))
        .frame(width: 380, height: 380).offset(y: -22)
      Circle().fill(LinearGradient(colors: [Color(red: 1, green: 0.97, blue: 0.82), Color(red: 1, green: 0.74, blue: 0.45)], startPoint: .top, endPoint: .bottom))
        .frame(width: 104, height: 104).offset(y: -22)
      Group {
        Capsule().frame(width: 120, height: 9).offset(x: -80, y: -40)
        Capsule().frame(width: 70, height: 7).offset(x: -50, y: -28)
        Capsule().frame(width: 100, height: 8).offset(x: 90, y: -78)
        Capsule().frame(width: 54, height: 6).offset(x: 110, y: -66)
        Capsule().frame(width: 80, height: 7).offset(x: -90, y: -120)
      }
      .foregroundStyle(.white.opacity(0.22))
      ForEach(0..<14, id: \.self) { i in
        Circle().fill(.white.opacity(0.55)).frame(width: i % 3 == 0 ? 2.5 : 1.6)
          .offset(x: CGFloat((i * 53) % 360) - 180, y: -CGFloat((i * 37) % 100) - 120)
      }
    }
    .frame(width: 400, height: 540)
  }
}

struct FarLayer: View {
  var body: some View {
    ZStack {
      Karst().fill(Color(red: 0.62, green: 0.32, blue: 0.55)).frame(width: 90, height: 118).offset(x: -112, y: 14)
      Karst().fill(Color(red: 0.66, green: 0.34, blue: 0.54)).frame(width: 70, height: 92).offset(x: -52, y: 27)
      Karst().fill(Color(red: 0.62, green: 0.32, blue: 0.55)).frame(width: 100, height: 130).offset(x: 108, y: 8)
      Karst().fill(Color(red: 0.68, green: 0.36, blue: 0.55)).frame(width: 60, height: 70).offset(x: 168, y: 38)
    }
    .frame(width: 400, height: 540)
    .overlay(alignment: .center) { Color.clear }
  }
}

struct SeaLayer: View {
  var body: some View {
    ZStack {
      // mid islands
      Karst().fill(Color(red: 0.36, green: 0.16, blue: 0.42)).frame(width: 130, height: 104).offset(x: 126, y: 52)
      Karst().fill(Color(red: 0.34, green: 0.15, blue: 0.40)).frame(width: 84, height: 62).offset(x: -150, y: 66)
      // sea
      Rectangle().fill(LinearGradient(stops: [
        .init(color: Color(red: 1.0, green: 0.62, blue: 0.45), location: 0),
        .init(color: Color(red: 0.76, green: 0.34, blue: 0.50), location: 0.35),
        .init(color: Color(red: 0.22, green: 0.14, blue: 0.40), location: 1),
      ], startPoint: .top, endPoint: .bottom))
        .frame(width: 400, height: 280).offset(y: 190)
      // sun path on the water
      ForEach(0..<9, id: \.self) { i in
        Capsule().fill(Color(red: 1, green: 0.93, blue: 0.7).opacity(0.75 - Double(i) * 0.07))
          .frame(width: 110 - CGFloat(i) * 8 + (i % 2 == 0 ? 0 : -20), height: 4)
          .offset(x: i % 2 == 0 ? -4 : 6, y: 92 + CGFloat(i) * 15)
      }
    }
    .frame(width: 400, height: 540)
  }
}

struct SubjectLayer: View {
  var body: some View {
    ZStack {
      // longtail boat
      ZStack {
        Boat().fill(Color(red: 0.12, green: 0.07, blue: 0.22)).frame(width: 92, height: 22)
        Capsule().fill(Color(red: 0.95, green: 0.36, blue: 0.35)).frame(width: 52, height: 3).offset(x: -4, y: -4)
        Capsule().fill(Color(red: 0.12, green: 0.07, blue: 0.22)).frame(width: 80, height: 3).rotationEffect(.degrees(-12)).offset(x: 62, y: 6)
        Capsule().fill(Color(red: 0.12, green: 0.07, blue: 0.22)).frame(width: 2, height: 22).offset(x: -6, y: -20)
        Path { p in p.move(to: CGPoint(x: -26, y: -30)); p.addLine(to: CGPoint(x: 18, y: -30)); p.addLine(to: CGPoint(x: 12, y: -22)); p.addLine(to: CGPoint(x: -20, y: -22)); p.closeSubpath() }
          .fill(Color(red: 0.12, green: 0.07, blue: 0.22))
      }
      .offset(x: -6, y: 116)
      // water ripple under the boat
      Capsule().fill(.white.opacity(0.35)).frame(width: 70, height: 2.5).offset(x: -4, y: 134)
      Capsule().fill(.white.opacity(0.2)).frame(width: 110, height: 2.5).offset(x: -4, y: 142)
    }
    .frame(width: 400, height: 540)
  }
}

struct CliffLayer: View {
  var body: some View {
    ZStack {
      Karst().fill(Color(red: 0.08, green: 0.05, blue: 0.17)).frame(width: 150, height: 150).offset(x: -125, y: 160)
      Karst().fill(Color(red: 0.08, green: 0.05, blue: 0.17)).frame(width: 120, height: 90).offset(x: 160, y: 190)
    }
    .frame(width: 400, height: 540)
  }
}

// MARK: the card

struct TiltCard: View {
  let roll: Double      // degrees, left-right tilt
  let pitch: Double     // degrees, up-down tilt
  var u: Double { roll / 14 }     // -1...1
  var v: Double { pitch / 10 }

  // the parallax: every layer shifts by tilt x depth. Far layers move one way, near layers the other.
  func shift<V: View>(_ view: V, _ depth: CGFloat) -> some View {
    view.offset(x: CGFloat(u) * depth, y: CGFloat(-v) * depth * 0.7)
  }

  var body: some View {
    ZStack {
      shift(SkyLayer(), -16)
      shift(FarLayer().offset(y: -52), -9)
      shift(SeaLayer().offset(y: -52), -3)
      shift(SubjectLayer().offset(y: -78), 8)
      shift(CliffLayer(), 18)

      // bottom fade so the title reads
      LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: UnitPoint(x: 0.5, y: 0.5), endPoint: .bottom)

      // title, closest to the viewer
      shift(
        VStack(alignment: .leading, spacing: 6) {
          Text("KRABI  ·  THAILAND").font(.system(size: 11, weight: .semibold)).kerning(1.6).opacity(0.8)
          Text("Phi Phi\nIslands").font(.system(size: 44, weight: .bold)).kerning(-1).lineSpacing(-6)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
        .frame(width: 322, height: 456, alignment: .bottomLeading)
        .padding(.leading, 24).padding(.bottom, 24)
        .frame(width: 322, height: 456, alignment: .bottomLeading), 30)

      // rarity chip
      shift(
        HStack(spacing: 6) {
          Image(systemName: "sparkles").font(.system(size: 11, weight: .bold))
          Text("RARE  042/150").font(.system(size: 11, weight: .bold)).kerning(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12).frame(height: 28)
        .background(Capsule().fill(.white.opacity(0.18)))
        .overlay(Capsule().stroke(.white.opacity(0.35), lineWidth: 1))
        .frame(width: 322, height: 456, alignment: .topLeading).padding(20)
        .frame(width: 322, height: 456, alignment: .topLeading), 24)

      // holo foil band: slides against the tilt
      LinearGradient(colors: [.clear, Color(red: 0.4, green: 0.9, blue: 1).opacity(0.22), Color(red: 1, green: 0.5, blue: 0.9).opacity(0.22), Color(red: 1, green: 0.9, blue: 0.4).opacity(0.18), .clear],
                     startPoint: UnitPoint(x: 0.5 - u * 0.9 - 0.4, y: 0.0), endPoint: UnitPoint(x: 0.5 - u * 0.9 + 0.4, y: 1.0))
        .blendMode(.plusLighter)
      // glare: a soft light spot that moves opposite to the tilt
      RadialGradient(colors: [.white.opacity(0.5), .white.opacity(0.12), .clear], center: UnitPoint(x: 0.5 - u * 0.75, y: 0.32 + v * 0.55), startRadius: 0, endRadius: 190)
        .blendMode(.plusLighter)
    }
    .frame(width: 322, height: 456)
    .clipShape(.rect(cornerRadius: 32, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .strokeBorder(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.06), .white.opacity(0.25)], startPoint: UnitPoint(x: 0.5 - u * 0.5, y: 0), endPoint: UnitPoint(x: 0.5 + u * 0.5, y: 1)), lineWidth: 1.5)
    )
  }
}

// MARK: the show: everything is a function of time, so the loop is exact

struct Pose { var roll = 0.0, pitch = 0.0, finger = CGPoint.zero, fingerOn = 0.0, press = 0.0 }

func pose(at t: Double) -> Pose {
  // idle sway: the phone "tilting in a hand"
  let a = 2 * Double.pi * t / LOOP
  let idleRoll = 13 * sin(2 * a), idlePitch = 8 * sin(3 * a + 0.9) * 1.0 - 8 * sin(0.9)
  let idleP = 8 * sin(3 * a + 0.9)
  _ = idlePitch

  // finger on the card (stage coordinates, card centre is 0,0)
  var f = CGPoint(x: 0, y: 0)
  var w = 0.0, press = 0.0, on = 0.0
  // drag: slow figure eight, 3.2 ... 10
  let dragIn = ramp(t, 3.0, 3.6), dragOut = 1 - ramp(t, 10.0, 10.6)
  let d = dragIn * dragOut
  if d > 0 {
    let e = ramp(t, 3.4, 4.6) * (1 - ramp(t, 8.6, 10.0))
    let ph = 2 * Double.pi * (t - 3.4) / 6.0
    f = CGPoint(x: 105 * sin(ph) * e, y: 96 * sin(2 * ph) * e * 0.8 - 20 * (1 - e) * 0)
    w = ramp(t, 3.0, 4.2) * (1 - ramp(t, 10.2, 11.8))
    on = d
    press = d
  }
  // press and hold in the lower left corner: 12 ... 14.6
  let hIn = ramp(t, 11.9, 12.4), hOut = 1 - ramp(t, 14.3, 14.7)
  let h = hIn * hOut
  if h > 0 {
    let drift = 6 * sin((t - 12.4) * 1.1)
    f = CGPoint(x: -88 + drift, y: 120 + drift * 0.6)
    w = max(w, ramp(t, 12.0, 13.0) * (1 - ramp(t, 14.4, 15.8)))
    on = h
    press = h
  } else if t > 14.7 && t < 15.8 {
    w = max(w, 1 - ramp(t, 14.4, 15.8))
  }
  // the finger sets the tilt: dragging right tips the right edge away, pressing a corner pushes it in
  let fr = Double(f.x) / 105 * 13
  let fp = -Double(f.y) / 110 * 9 * (h > 0 ? 1 : 1)
  let roll = idleRoll * (1 - w) + fr * w
  let pitch = idleP * (1 - w) + fp * w
  return Pose(roll: roll, pitch: pitch, finger: f, fingerOn: on, press: press)
}

struct StageView: View {
  var body: some View {
    TimelineView(.animation) { ctx in
      let t = (ctx.date.timeIntervalSinceReferenceDate / SLOW).truncatingRemainder(dividingBy: LOOP)
      let p = pose(at: t)
      ZStack {
        // soft glow of the card colours on the table
        Ellipse().fill(Color(red: 0.95, green: 0.4, blue: 0.5).opacity(0.28)).frame(width: 300, height: 60).blur(radius: 30)
          .offset(x: CGFloat(-p.roll / 14) * 26, y: 250)
        TiltCard(roll: p.roll, pitch: p.pitch)
          .rotation3DEffect(.degrees(-p.roll), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
          .rotation3DEffect(.degrees(p.pitch), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
          .scaleEffect(1 - 0.035 * p.press)
          .shadow(color: .black.opacity(0.45), radius: 3, y: 2)
          .shadow(color: .black.opacity(0.5), radius: 26, x: CGFloat(-p.roll / 14) * 14, y: 22 + CGFloat(p.pitch / 10) * 8)
        FingerDot()
          .scaleEffect(0.6 + 0.4 * p.fingerOn - 0.12 * p.press)
          .opacity(p.fingerOn)
          .offset(x: p.finger.x, y: p.finger.y)
          .allowsHitTesting(false)
      }
    }
  }
}

let BG = Color(red: 0.04, green: 0.05, blue: 0.09)

struct PassportScreen: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Collection").font(.system(size: 32, weight: .bold)).kerning(-0.6)
          Text("12 of 150 cards").font(.system(size: 15, weight: .medium)).foregroundStyle(Color(white: 0.55))
        }
        Spacer()
        Image(systemName: "line.3.horizontal.decrease")
          .font(.system(size: 17, weight: .semibold))
          .frame(width: 44, height: 44)
          .background(Circle().fill(.white.opacity(0.08)))
      }
      .padding(.horizontal, 24).padding(.top, 10)

      Spacer(minLength: 0)
      StageView().frame(height: 500).frame(maxWidth: .infinity)
      Spacer(minLength: 0)

      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text("Phi Phi Islands").font(.system(size: 19, weight: .semibold))
          Text("Collected 12 Oct 2026").font(.system(size: 14)).foregroundStyle(Color(white: 0.55))
        }
        Spacer()
        HStack(spacing: 6) {
          Image(systemName: "square.and.arrow.up").font(.system(size: 14, weight: .semibold))
          Text("Share").font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(.black).padding(.horizontal, 18).frame(height: 40)
        .background(Capsule().fill(.white))
      }
      .padding(.horizontal, 24).padding(.bottom, 20)

      HStack {
        ForEach([("rectangle.stack.fill", "Cards"), ("map", "Map"), ("trophy", "Rewards"), ("person", "Profile")], id: \.1) { icon, name in
          VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 21))
            Text(name).font(.system(size: 11, weight: .medium))
          }
          .foregroundStyle(name == "Cards" ? Color.white : Color(white: 0.45))
          .frame(maxWidth: .infinity)
        }
      }
      .padding(.top, 12)
      .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.08)).frame(height: 1) }
    }
    .foregroundStyle(.white)
    .padding(.top, 12)
    .background(
      ZStack {
        BG
        RadialGradient(colors: [Color(red: 0.35, green: 0.18, blue: 0.45).opacity(0.35), .clear], center: .init(x: 0.5, y: 0.45), startRadius: 0, endRadius: 380)
      }.ignoresSafeArea()
    )
    .preferredColorScheme(.dark)
  }
}
