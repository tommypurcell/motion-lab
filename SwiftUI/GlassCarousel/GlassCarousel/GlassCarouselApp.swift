import SwiftUI

@main
struct GlassCarouselApp: App {
  var body: some Scene { WindowGroup { ReelView { ReelCanvas() }.preferredColorScheme(.dark) } }
}

// The Glass Carousel reel: three Liquid Glass weather cards in a horizontal snap carousel over
// drifting color blobs. ScrollPosition snaps one card every 2 s (Kyoto → Oslo → Kyoto → Lisbon),
// a fake finger plays the swipe. Carousel and GlassCard run exactly the code in REEL_CODE.

struct Carousel: View {
  @Binding var pos: ScrollPosition
  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 24) { ForEach(cards) { GlassCard($0) } }
        .scrollTargetLayout()
    }
    .scrollTargetBehavior(.viewAligned)
    .scrollPosition($pos, anchor: .center)
    .contentMargins(.horizontal, (HERO.width - CARD.width) / 2, for: .scrollContent)
    .scrollIndicators(.hidden)
  }
}

struct GlassCard: View {
  let c: City
  init(_ c: City) { self.c = c }
  var body: some View {
    CityCard(c).glassEffect(.regular, in: .rect(cornerRadius: 40))
      .scrollTransition { view, phase in
        view.scaleEffect(1 - abs(phase.value) * 0.15)
      }
  }
}

let REEL_TYPES = ["ScrollView", "LazyHStack", "ForEach", "GlassCard", "CityCard"]
let REEL_TITLES = ["Snap carousel", "Glass + scale"]
let REEL_CODE: [String] = [
#"""
ScrollView(.horizontal) {
  LazyHStack(spacing: 24) { ForEach(cards) { GlassCard($0) } }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.viewAligned)
"""#,
#"""
CityCard(c).glassEffect(.regular, in: .rect(cornerRadius: 40))
  .scrollTransition { view, phase in
    view.scaleEffect(1 - abs(phase.value) * 0.15)
  }
"""#,
]

// MARK: - The scene (support code, not shown)

let HERO = CGSize(width: 952, height: 1016)
let CARD = CGSize(width: 500, height: 700)
let CY: CGFloat = 490

enum Sky { case sun, cloud, mix }
struct City: Identifiable {
  let id: String
  let country: String
  let temp: String
  let sky: Sky
  let stats: [(String, String)]
}
let cards = [
  City(id: "Lisbon", country: "Portugal", temp: "21°", sky: .sun, stats: [("H", "23°"), ("L", "15°"), ("Wind", "12")]),
  City(id: "Kyoto", country: "Japan", temp: "24°", sky: .mix, stats: [("H", "27°"), ("L", "18°"), ("Wind", "9")]),
  City(id: "Oslo", country: "Norway", temp: "8°", sky: .cloud, stats: [("H", "10°"), ("L", "4°"), ("Wind", "14")]),
]

struct CityCard: View {
  let c: City
  init(_ c: City) { self.c = c }
  var body: some View {
    ZStack(alignment: .topLeading) {
      // soft highlight in the top right corner
      Circle().fill(RadialGradient(colors: [.white.opacity(0.25), .white.opacity(0)], center: .center, startRadius: 0, endRadius: 250))
        .frame(width: 500, height: 500).position(x: 425, y: 0)
      VStack(alignment: .leading, spacing: 6) {
        Text(c.id).font(.system(size: 52, weight: .bold)).kerning(-0.5).foregroundStyle(.white)
        Text(c.country).font(.system(size: 28)).foregroundStyle(.white.opacity(0.75))
      }
      .padding(40)
      if c.sky != .cloud {
        Circle().fill(RadialGradient(colors: [hex(0xFDE68A).opacity(0.6), hex(0xFDE68A).opacity(0)], center: .center, startRadius: 0, endRadius: 115))
          .frame(width: 230, height: 230).position(x: 280, y: 280)
        Circle().fill(LinearGradient(colors: [hex(0xFEF3C7), hex(0xFBBF24)], startPoint: .top, endPoint: .bottom))
          .frame(width: 120, height: 120)
          .shadow(color: hex(0xF59E0B).opacity(0.7), radius: 15)
          .position(x: 280, y: 280)
      }
      if c.sky != .sun {
        Image(systemName: "cloud.fill").font(.system(size: 170)).foregroundStyle(.white)
          .shadow(color: hex(0x1E3A8A).opacity(0.15), radius: 10, y: 10)
          .position(x: c.sky == .mix ? 245 : 250, y: c.sky == .mix ? 335 : 300)
      }
      Text(c.temp).font(.system(size: 150, weight: .light)).kerning(-6).foregroundStyle(.white)
        .frame(width: CARD.width).position(x: CARD.width / 2, y: 485)
      HStack(spacing: 0) {
        ForEach(c.stats, id: \.0) { k, v in
          VStack(spacing: 6) {
            Text(k).font(.system(size: 26, weight: .medium)).foregroundStyle(.white.opacity(0.7))
            Text(v).font(.system(size: 30, weight: .semibold)).foregroundStyle(.white)
          }
          .frame(maxWidth: .infinity)
        }
      }
      .padding(.horizontal, 40)
      .frame(width: CARD.width).position(x: CARD.width / 2, y: 620)
    }
    .frame(width: CARD.width, height: CARD.height, alignment: .topLeading)
    .background(RoundedRectangle(cornerRadius: 40).fill(.white.opacity(0.06)))
    .overlay(RoundedRectangle(cornerRadius: 40).strokeBorder(LinearGradient(stops: [.init(color: .white.opacity(0.7), location: 0), .init(color: .white.opacity(0.12), location: 0.5), .init(color: .white.opacity(0.35), location: 1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2))
    .clipShape(RoundedRectangle(cornerRadius: 40))
  }
}

// Five big blurred color blobs that drift on an 8 s loop, so the glass has something to bend.
struct Blobs: View {
  let blobs: [(CGFloat, CGFloat, CGFloat, UInt32)] = [(150, 220, 560, 0xEC4899), (820, 260, 600, 0x3B82F6), (500, 640, 520, 0xF59E0B), (80, 860, 480, 0x10B981), (880, 880, 520, 0x8B5CF6)]
  var body: some View {
    TimelineView(.animation) { tl in
      let t = tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 8) / 8 * 2 * .pi
      ZStack(alignment: .topLeading) {
        hex(0x0B1020)
        ForEach(0 ..< blobs.count, id: \.self) { i in
          let b = blobs[i]
          Circle().fill(hex(b.3).opacity(0.9)).frame(width: b.2, height: b.2)
            .blur(radius: 90)
            .position(x: b.0 + 40 * cos(t + Double(i) * 1.3), y: b.1 + 40 * sin(t + Double(i) * 2.1))
        }
        hex(0x0B1020).opacity(0.18)
      }
    }
  }
}

@Observable final class Show {
  var pos = ScrollPosition(id: "Kyoto", anchor: .center)
  var page = 1
  var finger = CGPoint(x: 720, y: CY + 120)
  var fingerOn = false

  // One swipe: the finger lands, drags across, and the carousel snaps to the next card.
  func swipe(to i: Int, from x0: CGFloat, to x1: CGFloat, at t: Double, _ start: ContinuousClock.Instant) async {
    finger = CGPoint(x: x0, y: CY + 120)
    await until(start, t - 0.35)
    withAnimation(.easeOut(duration: 0.25)) { fingerOn = true }
    await until(start, t)
    withAnimation(.easeInOut(duration: 0.55)) { finger.x = x1 }
    withAnimation(.smooth(duration: 0.7)) { pos.scrollTo(id: cards[i].id, anchor: .center); page = i }
    await until(start, t + 0.5)
    withAnimation(.easeOut(duration: 0.3)) { fingerOn = false }
  }
  func run() async {
    try? await Task.sleep(for: .seconds(0.3))
    pos.scrollTo(id: "Kyoto", anchor: .center)
    var start = ContinuousClock.now
    while !Task.isCancelled {
      await swipe(to: 2, from: 720, to: 300, at: 1.6, start)   // Kyoto → Oslo
      await swipe(to: 1, from: 240, to: 660, at: 3.6, start)   // Oslo → Kyoto
      await swipe(to: 0, from: 240, to: 660, at: 5.6, start)   // Kyoto → Lisbon
      await swipe(to: 1, from: 720, to: 300, at: 7.6, start)   // Lisbon → Kyoto
      start = start.advanced(by: .seconds(8))
    }
  }
  func until(_ start: ContinuousClock.Instant, _ t: Double) async {
    try? await Task.sleep(until: start.advanced(by: .seconds(t)), clock: .continuous)
  }
}

struct CarouselScene: View {
  @State private var show = Show()
  var body: some View {
    @Bindable var show = show
    ZStack(alignment: .topLeading) {
      Blobs()
      Text("Your cities").font(.system(size: 32, weight: .semibold)).foregroundStyle(.white)
        .padding(.leading, 48).padding(.top, 38)
      Text("3 places").font(.system(size: 26)).foregroundStyle(.white.opacity(0.7))
        .frame(width: HERO.width - 48, alignment: .trailing).padding(.top, 44)
      Carousel(pos: $show.pos)
        .frame(width: HERO.width, height: CARD.height + 40)
        .position(x: HERO.width / 2, y: CY)
      HStack(spacing: 12) {
        ForEach(0 ..< 3, id: \.self) { i in
          Capsule().fill(.white.opacity(i == show.page ? 1 : 0.45)).frame(width: i == show.page ? 40 : 12, height: 12)
        }
      }
      .frame(width: HERO.width).position(x: HERO.width / 2, y: CY + 350 + 62)
      FingerDot()
        .opacity(show.fingerOn ? 1 : 0)
        .scaleEffect(show.fingerOn ? 1 : 0.7)
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
    VStack(alignment: .leading, spacing: 0) {
      TitleBlock(title: "Glass Carousel", subtitle: "Snap through glass cards over color")
      Spacer().frame(height: 38)
      CarouselScene()
      Spacer().frame(height: 28)
      VStack(spacing: 20) {
        ForEach(0 ..< 2, id: \.self) { i in CodeWindow(title: REEL_TITLES[i], code: REEL_CODE[i], types: REEL_TYPES) }
      }
      Spacer(minLength: 0)
      Text("Real SwiftUI · iOS 26 · scrollTargetBehavior, scrollTransition, glassEffect").font(.system(size: 22)).foregroundStyle(hex(0x64748B))
        .frame(maxWidth: .infinity)
    }
    .padding(.horizontal, 64).padding(.top, 72).padding(.bottom, 46)
    .frame(width: 1080, height: 1920, alignment: .topLeading)
    .background(LinearGradient(colors: [hex(0x0D1A3A), hex(0x060B1A)], startPoint: .top, endPoint: .bottom))
  }
}
