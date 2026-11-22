import SwiftUI

@main
struct ParallaxCarouselApp: App {
  var body: some Scene { WindowGroup { ExploreScreen() } }
}

// The Parallax Carousel demo: a travel app where each card's photo slides slower than the card.
// Recorded in the Simulator, then placed in an iPhone frame on a background (see tools/phone_mockup.py).

struct Place: Identifiable {
  let photo: String
  let name: String
  let country: String
  var id: String { photo }
}

// The parallax: the photo is wider than the card and moves against it.
// The further the card is from the center, the more the photo slides back (65% of the distance).
struct PlaceCard: View {
  let place: Place
  var body: some View {
    Image(place.photo)
      .resizable().scaledToFill()
      .frame(width: 690, height: 440)
      .visualEffect { content, proxy in
        let center = (proxy.bounds(of: .scrollView)?.width ?? 0) / 2
        let distance = proxy.frame(in: .scrollView).midX - center
        return content.offset(x: min(max(-distance * 0.65, -200), 200))
      }
      .frame(width: 290, height: 440)
      .clipShape(.rect(cornerRadius: 28))
  }
}

let PLACES = [
  Place(photo: "beach", name: "Krabi", country: "Thailand"),
  Place(photo: "mountains", name: "Doi Inthanon", country: "Chiang Mai"),
  Place(photo: "court", name: "Sunset Court", country: "Koh Samui"),
  Place(photo: "city", name: "Bangkok", country: "Thailand"),
]

// The card label: a dark fade at the bottom with the place name.
struct CardLabel: View {
  let place: Place
  var body: some View {
    ZStack(alignment: .bottomLeading) {
      LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
      VStack(alignment: .leading, spacing: 3) {
        Text(place.name).font(.system(size: 24, weight: .bold))
        Label(place.country, systemImage: "mappin.circle.fill")
          .font(.system(size: 14, weight: .medium)).opacity(0.85)
      }
      .foregroundStyle(.white)
      .padding(20)
    }
    .clipShape(.rect(cornerRadius: 28))
    .allowsHitTesting(false)
  }
}

// The fake finger: the recording can't show touches, so a soft dot plays the user.
struct FingerDot: View {
  var body: some View {
    Circle().fill(.white.opacity(0.55)).frame(width: 40, height: 40)
      .overlay(Circle().stroke(.black.opacity(0.25), lineWidth: 1.5))
      .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
  }
}

// Wakes once per screen refresh, so each scroll step lands on its own frame.
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

// Recording runs everything at half speed; ffmpeg speeds it back up 2x so no frames go missing.
let SLOW = 2.0

@Observable final class Show {
  var scroll = ScrollPosition(x: 0)
  var index = 0
  var finger = CGPoint(x: 300, y: 250)
  var fingerOn = false
  var pressed: Int? = nil        // card being held
  let step: CGFloat = 290 + 16   // card width + spacing
  let ticker = FrameTicker()

  // The loop: swipes, a press-and-hold with slow drags, then a fling back to the start.
  func run() async {
    await wait(0.5)
    while !Task.isCancelled {
      await swipe(to: 1)
      await holdAndWiggle()
      await swipe(to: 2)
      await holdAndWiggle()
      await swipe(to: 3)
      await swipe(to: 0, duration: 1.8)
    }
  }

  // Runs one gesture frame by frame: f(t) gives the scroll offset and the finger x for t in 0...1.
  func drive(_ duration: Double, _ f: (Double) -> (CGFloat, CGFloat)) async {
    let t0 = Date.now
    while true {
      let t = min(1, Date.now.timeIntervalSince(t0) / (duration * SLOW))
      let (x, fx) = f(t)
      scroll.scrollTo(x: x)
      finger.x = fx
      if t >= 1 { break }
      await ticker.next()
    }
  }

  func touch(at x: CGFloat) async {
    finger = CGPoint(x: x, y: 250)
    withAnimation(.easeOut(duration: 0.15 * SLOW)) { fingerOn = true }
    await wait(0.15)
  }
  func lift() { withAnimation(.easeIn(duration: 0.25 * SLOW)) { fingerOn = false } }

  func swipe(to i: Int, duration: Double = 1.3) async {
    let x0 = CGFloat(index) * step, x1 = CGFloat(i) * step
    let start: CGFloat = x1 > x0 ? 300 : 100
    await touch(at: start)
    var lifted = false
    await drive(duration) { t in
      let e = t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2   // ease in-out
      let x = x0 + (x1 - x0) * e
      if t > 0.6 && !lifted { lifted = true; self.lift() }
      // the finger follows the content until it lets go, then drifts on
      return (x, lifted ? self.finger.x : start - (x - x0) * (abs(x1 - x0) > self.step ? 0.35 : 1))
    }
    index = i
    await wait(0.6)
  }

  // Press and hold the card, then drag it slowly left and right so the photo slides inside.
  func holdAndWiggle() async {
    let base = CGFloat(index) * step
    await touch(at: 200)
    withAnimation(.spring(duration: 0.35 * SLOW)) { pressed = index }
    await wait(0.35)
    await drive(2.6) { t in
      let d = 110 * sin(2 * .pi * 2 * t) * sin(.pi * t)   // two slow back-and-forths, eased in and out
      return (base - d, 200 + d)
    }
    withAnimation(.spring(duration: 0.4 * SLOW, bounce: 0.3)) { pressed = nil }
    lift()
    await wait(0.6)
  }

  func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s * SLOW)) }
}

struct Carousel: View {
  @State private var show = Show()
  var body: some View {
    VStack(spacing: 18) {
      ZStack {
        ScrollView(.horizontal) {
          HStack(spacing: 16) {
            ForEach(PLACES.indices, id: \.self) { i in
              let place = PLACES[i]
              PlaceCard(place: place)
                .overlay { CardLabel(place: place) }
                .shadow(color: .black.opacity(0.1), radius: 2, y: 2)
                .shadow(color: .black.opacity(0.2), radius: 14, y: 10)
                .scaleEffect(show.pressed == i ? 0.96 : 1)
            }
          }
        }
        .contentMargins(.horizontal, 56, for: .scrollContent)
        .scrollPosition($show.scroll)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()

        FingerDot()
          .opacity(show.fingerOn ? 1 : 0)
          .scaleEffect(show.fingerOn ? (show.pressed == nil ? 1 : 0.85) : 0.6)
          .animation(.spring(duration: 0.3 * SLOW), value: show.pressed)
          .position(show.finger)
          .allowsHitTesting(false)
      }
      .frame(height: 440)

      // page dots
      HStack(spacing: 6) {
        ForEach(PLACES.indices, id: \.self) { i in
          Capsule().fill(.black.opacity(i == show.index ? 0.8 : 0.15))
            .frame(width: i == show.index ? 22 : 7, height: 7)
        }
      }
      .animation(.smooth(duration: 0.5 * SLOW), value: show.index)
    }
    .task { await show.run() }
  }
}

struct ExploreScreen: View {
  let chips = ["All", "Beaches", "Mountains", "Cities"]
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // search row
      HStack(spacing: 12) {
        Image(systemName: "line.3.horizontal").font(.system(size: 20, weight: .medium))
        HStack(spacing: 8) {
          Image(systemName: "magnifyingglass")
          Text("Search places")
          Spacer()
        }
        .font(.system(size: 16)).foregroundStyle(.secondary)
        .padding(.horizontal, 14).frame(height: 44)
        .background(Capsule().fill(Color(white: 0.95)))
        Circle().fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
          .frame(width: 40, height: 40)
          .overlay(Text("T").font(.system(size: 17, weight: .bold)).foregroundStyle(.white))
      }
      .padding(.horizontal, 24)

      Text("Explore\nThailand")
        .font(.system(size: 38, weight: .bold)).kerning(-0.8)
        .padding(.horizontal, 24).padding(.top, 28)

      HStack(spacing: 8) {
        ForEach(chips, id: \.self) { c in
          Text(c).font(.system(size: 15, weight: .semibold))
            .foregroundStyle(c == "All" ? .white : .primary)
            .padding(.horizontal, 16).frame(height: 36)
            .background(Capsule().fill(c == "All" ? Color.black : Color(white: 0.95)))
        }
      }
      .padding(.horizontal, 24).padding(.top, 18).padding(.bottom, 26)

      Carousel()

      Spacer(minLength: 0)

      // tab bar
      HStack {
        ForEach([("house.fill", "Home"), ("safari", "Explore"), ("heart", "Saved"), ("person", "Profile")], id: \.1) { icon, name in
          VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 22))
            Text(name).font(.system(size: 11, weight: .medium))
          }
          .foregroundStyle(name == "Home" ? Color.black : Color(white: 0.6))
          .frame(maxWidth: .infinity)
        }
      }
      .padding(.top, 10)
      .overlay(alignment: .top) { Rectangle().fill(Color(white: 0.92)).frame(height: 1) }
    }
    .padding(.top, 12)
    .background(Color.white)
    .preferredColorScheme(.light)
  }
}
