import SwiftUI

@main
struct CardRevealApp: App {
  var body: some Scene { WindowGroup { ReelView { ReelCanvas() } } }
}

// The Card Reveal reel: a finger taps a travel card, it lifts (phaseAnimator), the photo slides up
// and the details fade in one by one; a second tap lifts it again and it settles back to the photo.
// LiftingCard and Card run exactly the code shown in the code windows (REEL_CODE).

let REEL_TYPES = ["Card"]
let REEL_TITLES = ["Lift and reveal", "Two-part shadow"]
let REEL_CODE: [String] = [
#"""
Card().phaseAnimator([0, 1, 2], trigger: tap) { card, phase in
  card.scaleEffect(phase == 1 ? 1.06 : 1)
    .offset(y: phase == 1 ? -24 : 0)
}
"""#,
#"""
.shadow(color: .black.opacity(0.12), radius: 4, y: 4)
.shadow(color: .black.opacity(0.4), radius: 32, y: 24)
"""#,
]

struct LiftingCard: View {
  var tap: Int
  var body: some View {
    Card().phaseAnimator([0, 1, 2], trigger: tap) { card, phase in
      card.scaleEffect(phase == 1 ? 1.06 : 1)
        .offset(y: phase == 1 ? -24 : 0)
    }
  }
}

// MARK: - The card (support code; only the shadow lines are shown)

let CW: CGFloat = 660, CH: CGFloat = 932, IH: CGFloat = 520
let HERO = CGSize(width: 952, height: 1115)
let CARD_C = CGPoint(x: 476, y: 80 + 466)

extension EnvironmentValues {
  @Entry var revealed = false
}

struct Ridge: Shape {
  var pts: [CGPoint] // in a 620 × 260 box
  func path(in r: CGRect) -> Path {
    var p = Path()
    let sx = r.width / 620, sy = r.height / 260
    p.move(to: CGPoint(x: 0, y: r.maxY))
    for q in pts { p.addLine(to: CGPoint(x: r.minX + q.x * sx, y: r.minY + q.y * sy)) }
    p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
    p.closeSubpath()
    return p
  }
}

struct Stars: View {
  var body: some View {
    Canvas { ctx, _ in
      var seed = 3.0
      func rnd() -> Double { seed = (seed * 9301 + 49297).truncatingRemainder(dividingBy: 233280); return seed / 233280 }
      for _ in 0 ..< 26 {
        let s = 2 + rnd() * 2.5
        let x = rnd() * CW, y = rnd() * 170
        let a = 0.35 + rnd() * 0.5
        ctx.fill(Path(ellipseIn: CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)), with: .color(.white.opacity(a)))
      }
    }
    .frame(width: CW, height: 180)
  }
}

struct Photo: View {
  var height: CGFloat
  var body: some View {
    ZStack(alignment: .topLeading) {
      LinearGradient(stops: [.init(color: hex(0x1E1B4B), location: 0), .init(color: hex(0x6D28D9), location: 0.38), .init(color: hex(0xEC4899), location: 0.7), .init(color: hex(0xFDBA74), location: 1)], startPoint: .top, endPoint: .bottom)
      Stars()
      // sun + mountains stay pinned to the bottom edge of the photo
      ZStack(alignment: .topLeading) {
        Circle().fill(RadialGradient(colors: [hex(0xFEF3C7).opacity(0.7), hex(0xFEF3C7).opacity(0)], center: .center, startRadius: 0, endRadius: 180))
          .frame(width: 360, height: 360).position(x: 430, y: 80)
        Circle().fill(LinearGradient(colors: [hex(0xFFFBEB), hex(0xFDE68A)], startPoint: .top, endPoint: .bottom))
          .frame(width: 130, height: 130).position(x: 430, y: 80)
        Ridge(pts: [.init(x: 0, y: 120), .init(x: 80, y: 40), .init(x: 150, y: 95), .init(x: 250, y: 10), .init(x: 350, y: 110), .init(x: 430, y: 60), .init(x: 520, y: 120), .init(x: 620, y: 70)])
          .fill(hex(0x4C1D95)).frame(width: CW, height: 260).offset(y: 0)
        Ridge(pts: [.init(x: 0, y: 170), .init(x: 110, y: 110), .init(x: 200, y: 150), .init(x: 300, y: 90), .init(x: 400, y: 160), .init(x: 500, y: 120), .init(x: 620, y: 150)])
          .fill(hex(0x2E1065)).frame(width: CW, height: 260)
        Ridge(pts: [.init(x: 0, y: 215), .init(x: 150, y: 190), .init(x: 320, y: 210), .init(x: 480, y: 185), .init(x: 620, y: 205)])
          .fill(hex(0x1E1B4B)).frame(width: CW, height: 260)
      }
      .frame(width: CW, height: 260, alignment: .topLeading)
      .offset(y: height - 260)
      HStack(spacing: 10) {
        Image(systemName: "star.fill").font(.system(size: 22)).foregroundStyle(hex(0xFDE68A))
        Text("4.9").font(.system(size: 24, weight: .semibold)).foregroundStyle(.white)
      }
      .frame(width: 132, height: 52)
      .background(Capsule().fill(.white.opacity(0.22)))
      .overlay(Capsule().stroke(.white.opacity(0.35)))
      .offset(x: 28, y: 28)
      Circle().fill(.white.opacity(0.22)).overlay(Circle().stroke(.white.opacity(0.35)))
        .overlay(Image(systemName: "heart.fill").font(.system(size: 28)).foregroundStyle(.white))
        .frame(width: 64, height: 64)
        .offset(x: CW - 28 - 64, y: 22)
    }
    .frame(width: CW, height: height, alignment: .topLeading)
    .clipped()
  }
}

struct Chip: View {
  var symbol: String
  var label: String
  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: symbol).font(.system(size: 22, weight: .semibold)).foregroundStyle(hex(0x6366F1))
      Text(label).font(.system(size: 24, weight: .semibold)).foregroundStyle(hex(0x334155))
    }
    .padding(.leading, 20).padding(.trailing, 22).frame(height: 56)
    .background(Capsule().fill(hex(0xEEF2FF)))
  }
}

// Fades and lifts one detail row in, i × 0.06 s after the photo starts moving.
struct Reveal: ViewModifier {
  var i: Int
  @Environment(\.revealed) private var open
  func body(content: Content) -> some View {
    content
      .opacity(open ? 1 : 0)
      .offset(y: open ? 0 : 28)
      .animation(open ? .smooth(duration: 0.45).delay(0.12 + Double(i) * 0.06) : .easeOut(duration: 0.2), value: open)
  }
}

struct Card: View {
  @Environment(\.revealed) private var open
  var body: some View {
    ZStack(alignment: .topLeading) {
      VStack(alignment: .leading, spacing: 0) {
        Text("Lofoten, Norway").font(.system(size: 46, weight: .bold)).kerning(-0.7).foregroundStyle(hex(0x0F172A))
          .modifier(Reveal(i: 0))
        Text("Fjords, northern lights, quiet cabins").font(.system(size: 26)).foregroundStyle(hex(0x475569))
          .padding(.top, 10).modifier(Reveal(i: 1))
        HStack(spacing: 12) {
          Chip(symbol: "clock", label: "7 days")
          Chip(symbol: "person.fill", label: "2 guests")
          Chip(symbol: "mappin", label: "Arctic")
        }
        .padding(.top, 26).modifier(Reveal(i: 2))
        Spacer(minLength: 0)
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 2) {
            Text("$1,290").font(.system(size: 44, weight: .bold)).kerning(-0.4).foregroundStyle(hex(0x0F172A))
            Text("per person").font(.system(size: 22)).foregroundStyle(hex(0x64748B))
          }
          Spacer()
          Text("Book trip").font(.system(size: 30, weight: .semibold)).foregroundStyle(.white)
            .frame(width: 250, height: 88)
            .background(Capsule().fill(LinearGradient(colors: [hex(0x6366F1), hex(0x8B5CF6)], startPoint: .leading, endPoint: .trailing)))
            .shadow(color: hex(0x4338CA).opacity(0.15), radius: 2, y: 2)
            .shadow(color: hex(0x6366F1).opacity(0.3), radius: 12, y: 10)
        }
        .modifier(Reveal(i: 3))
      }
      .padding(.top, IH + 36).padding(.horizontal, 40).padding(.bottom, 48)
      .frame(width: CW, height: CH, alignment: .topLeading)
      Photo(height: open ? IH : CH)
    }
    .frame(width: CW, height: CH, alignment: .topLeading)
    .background(hex(0xF8FAFC))
    .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
    .shadow(color: .black.opacity(0.12), radius: 4, y: 4)
    .shadow(color: .black.opacity(0.4), radius: 32, y: 24)
  }
}

// MARK: - The show (fake finger + timing, 9 s loop)

@Observable final class Show {
  var tap = 0
  var open = false
  var lifted = false
  var finger = CGPoint(x: 316, y: 480)
  var fingerOn = false
  var press = false

  func tapCard(_ t0: ContinuousClock.Instant, _ s: Double, open newOpen: Bool) async {
    let clock = ContinuousClock()
    func at(_ x: Double) async { try? await clock.sleep(until: t0 + .seconds(s + x)) }
    withAnimation(.smooth(duration: 0.35)) { fingerOn = true }
    await at(0.6)
    withAnimation(.easeOut(duration: 0.12)) { press = true }
    await at(0.72)
    tap += 1
    withAnimation(.smooth(duration: 0.35)) { lifted = true }
    withAnimation(.easeOut(duration: 0.2)) { press = false }
    withAnimation(.easeOut(duration: 0.35).delay(0.15)) { fingerOn = false }
    await at(1.05)
    withAnimation(.spring(duration: 0.55, bounce: 0.15)) { open = newOpen }
    withAnimation(.smooth(duration: 0.4)) { lifted = false }
  }

  func run() async {
    let clock = ContinuousClock()
    while !Task.isCancelled {
      let t0 = clock.now
      func at(_ s: Double) async { try? await clock.sleep(until: t0 + .seconds(s)) }
      await at(0.4)
      finger = CGPoint(x: 316, y: 480)
      await tapCard(t0, 0.4, open: true)    // tap at 1.1 s, photo slides at 1.45 s
      await at(5.4)
      finger = CGPoint(x: 316, y: 300)
      await tapCard(t0, 5.4, open: false)   // tap at 6.1 s, settles back at 6.45 s
      await at(9.0)
    }
  }
}

struct CardScene: View {
  @State private var show = Show()
  var body: some View {
    ZStack(alignment: .topLeading) {
      LinearGradient(colors: [hex(0x14122B), hex(0x07060F)], startPoint: .top, endPoint: .bottom)
      Ellipse().fill(RadialGradient(colors: [hex(0x7C3AED).opacity(0.35), hex(0x7C3AED).opacity(0)], center: .center, startRadius: 0, endRadius: 450))
        .frame(width: 900, height: 700).blur(radius: 40)
        .position(x: 476, y: 340)
      Ellipse().fill(RadialGradient(colors: [.black.opacity(0.7), .black.opacity(0)], center: .center, startRadius: 0, endRadius: 280))
        .frame(width: 560, height: 70).blur(radius: 16)
        .scaleEffect(show.lifted ? 0.85 : 1).opacity(show.lifted ? 0.6 : 1)
        .position(x: 476, y: 80 + CH + 40)
      LiftingCard(tap: show.tap)
        .environment(\.revealed, show.open)
        .position(CARD_C)
      FingerDot()
        .scaleEffect(show.press ? 0.8 : 1)
        .opacity(show.fingerOn ? 1 : 0)
        .scaleEffect(show.fingerOn ? 1 : 0.6)
        .position(show.finger)
    }
    .frame(width: HERO.width, height: HERO.height, alignment: .topLeading)
    .clipShape(RoundedRectangle(cornerRadius: 40))
    .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.white.opacity(0.08)))
    .shadow(color: .black.opacity(0.12), radius: 4, y: 4)
    .shadow(color: .black.opacity(0.4), radius: 32, y: 24)
    .task { await show.run() }
  }
}

struct ReelCanvas: View {
  var body: some View {
    ZStack(alignment: .topLeading) {
      LinearGradient(colors: [hex(0x0D1A3A), hex(0x060B1A)], startPoint: .top, endPoint: .bottom)
      TitleBlock(title: "Card Reveal", subtitle: "Lift, slide the photo up, fade the details in")
        .offset(x: 64, y: 72)
      CardScene().offset(x: 64, y: 295)
      VStack(spacing: 20) {
        ForEach(0 ..< 2, id: \.self) { i in CodeWindow(title: REEL_TITLES[i], code: REEL_CODE[i], types: REEL_TYPES) }
      }
      .frame(width: 952)
      .offset(x: 64, y: 295 + HERO.height + 28)
      Text("Real SwiftUI · iOS 26 · PhaseAnimator, scaleEffect, offset, shadow").font(.system(size: 22)).foregroundStyle(hex(0x64748B))
        .frame(width: 1080).offset(y: 1846)
    }
    .frame(width: 1080, height: 1920, alignment: .topLeading)
  }
}
