import SwiftUI

@main
struct ThemeRevealApp: App {
  var body: some Scene { WindowGroup { ReelView { ReelCanvas() } } }
}

// The Theme Reveal reel: tap the toggle and a dark copy of the screen is revealed by a circle
// that grows out of the toggle. Tap again and the circle shrinks back into it.
// RevealHero's mask and ThemeToggle's body run exactly the code shown in the code windows (REEL_CODE).

let toggleCenter = CGPoint(x: 836, y: 88)

struct RevealHero: View {
  @Environment(Show.self) private var show
  var body: some View {
    let dark = show.dark
    ZStack(alignment: .topLeading) {
      SettingsScreen(t: .light)
      DarkScreen()
        .mask {
          Circle().frame(width: 2400, height: 2400)
            .scaleEffect(dark ? 1 : 0.001)
            .position(toggleCenter)
        }
        .animation(.smooth(duration: 0.9), value: dark)
      // The thin indigo edge of the circle (support, not shown).
      Circle().stroke(hex(0x818CF8).opacity(0.6), lineWidth: 3)
        .frame(width: dark ? 2400 : 0, height: dark ? 2400 : 0)
        .position(toggleCenter)
        .animation(.smooth(duration: 0.9), value: dark)
        .allowsHitTesting(false)
      FingerDot()
        .scaleEffect(show.press ? 0.8 : 1)
        .opacity(show.fingerOn ? 1 : 0)
        .scaleEffect(show.fingerOn ? 1 : 0.6)
        .position(show.finger)
        .allowsHitTesting(false)
    }
  }
}

struct ThemeToggle: View {
  @Binding var dark: Bool
  var body: some View {
    Button { dark.toggle() } label: {
      Image(systemName: dark ? "moon.fill" : "sun.max.fill")
        .contentTransition(.symbolEffect(.replace))
    }
    .buttonStyle(KnobStyle())
  }
}

let REEL_TYPES = ["DarkScreen", "Circle", "Button", "Image"]
let REEL_TITLES = ["Circle reveal", "Toggle"]
let REEL_CODE: [String] = [
#"""
DarkScreen()
  .mask {
    Circle().frame(width: 2400, height: 2400)
      .scaleEffect(dark ? 1 : 0.001)
      .position(toggleCenter)
  }
  .animation(.smooth(duration: 0.9), value: dark)
"""#,
#"""
Button { dark.toggle() } label: {
  Image(systemName: dark ? "moon.fill" : "sun.max.fill")
    .contentTransition(.symbolEffect(.replace))
}
"""#,
]

// MARK: - The settings screen (support code, not shown)

let HERO = CGSize(width: 952, height: 950)

struct Theme {
  var bg, card, ink, sub, slider, sliderFill: UInt32
  var shadowA, shadowB: Double
  var isDark: Bool
  static let light = Theme(bg: 0xF1F5F9, card: 0xFFFFFF, ink: 0x0F172A, sub: 0x64748B, slider: 0xCBD5E1, sliderFill: 0x6366F1, shadowA: 0.06, shadowB: 0.06, isDark: false)
  static let dark = Theme(bg: 0x0B1120, card: 0x1E293B, ink: 0xF8FAFC, sub: 0x94A3B8, slider: 0x334155, sliderFill: 0x818CF8, shadowA: 0.3, shadowB: 0.25, isDark: true)
}

struct DarkScreen: View {
  var body: some View { SettingsScreen(t: .dark) }
}

// The toggle's track and knob, drawn around the button's label.
struct KnobStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View { Knob(label: configuration.label) }
}

struct Knob<L: View>: View {
  let label: L
  @Environment(Show.self) private var show
  var body: some View {
    let on = show.dark
    return ZStack(alignment: on ? .trailing : .leading) {
      Capsule().fill(on ? hex(0x4F46E5) : hex(0xE2E8F0))
        .shadow(color: hex(0x4F46E5).opacity(on ? 0.4 : 0), radius: 8, y: 4)
      Circle().fill(on ? hex(0x0F172A) : .white)
        .frame(width: 60, height: 60)
        .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
        .overlay {
          label
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(on ? hex(0xFDE68A) : hex(0xF59E0B))
        }
        .padding(8)
    }
    .frame(width: 136, height: 76)
    .animation(.smooth(duration: 0.5), value: on)
  }
}

struct SettingsScreen: View {
  let t: Theme
  @Environment(Show.self) private var show
  var body: some View {
    @Bindable var show = show
    ZStack(alignment: .topLeading) {
      hex(t.bg)
      Text("Settings").font(.system(size: 52, weight: .bold)).kerning(-0.8).foregroundStyle(hex(t.ink))
        .offset(x: 48, y: 44)
      ThemeToggle(dark: $show.dark)
        .offset(x: 768, y: 50)
      profile.offset(x: 48, y: 168)
      rows.offset(x: 48, y: 352)
      brightness.offset(x: 48, y: 824)
    }
    .frame(width: HERO.width, height: HERO.height, alignment: .topLeading)
  }

  func card<C: View>(_ h: CGFloat, @ViewBuilder _ c: () -> C) -> some View {
    c().frame(width: 856, height: h, alignment: .topLeading)
      .background(RoundedRectangle(cornerRadius: 32).fill(hex(t.card)))
      .shadow(color: .black.opacity(t.shadowA), radius: 1.5, y: 1)
      .shadow(color: .black.opacity(t.shadowB), radius: 12, y: 8)
  }

  var profile: some View {
    card(152) {
      HStack(spacing: 0) {
        Circle().fill(LinearGradient(colors: [hex(0xF472B6), hex(0x8B5CF6)], startPoint: .topLeading, endPoint: .bottomTrailing))
          .frame(width: 96, height: 96)
          .overlay(Text("MC").font(.system(size: 34, weight: .semibold)).foregroundStyle(.white))
        VStack(alignment: .leading, spacing: 4) {
          Text("Maya Chen").font(.system(size: 34, weight: .semibold)).foregroundStyle(hex(t.ink))
          Text(verbatim: "maya@studio.app").font(.system(size: 26)).foregroundStyle(hex(t.sub))
        }
        .padding(.leading, 28)
        Spacer()
        chevron
      }
      .padding(.horizontal, 28).frame(maxHeight: .infinity)
    }
  }

  var chevron: some View {
    Image(systemName: "chevron.right").font(.system(size: 26, weight: .semibold)).foregroundStyle(hex(t.sub))
      .frame(width: 32, height: 32)
  }

  var rows: some View {
    let items: [(String, String, String?, UInt32)] = [
      ("bell.fill", "Notifications", nil, 0xF43F5E),
      ("textformat.size", "Text size", "Large", 0x3B82F6),
      ("moon.fill", "Appearance", t.isDark ? "Dark" : "Light", 0x6366F1),
      ("speaker.wave.2.fill", "Sounds", "On", 0x10B981),
    ]
    return card(432) {
      VStack(spacing: 0) {
        ForEach(0 ..< 4, id: \.self) { i in
          let (ic, label, value, c) = items[i]
          HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 16).fill(hex(c)).frame(width: 60, height: 60)
              .overlay(Image(systemName: ic).font(.system(size: 28, weight: .semibold)).foregroundStyle(.white))
            Text(label).font(.system(size: 30)).foregroundStyle(hex(t.ink)).padding(.leading, 28)
            Spacer()
            if let value {
              Text(value).font(.system(size: 28)).foregroundStyle(hex(t.sub)).padding(.trailing, 12)
              chevron
            } else {
              Capsule().fill(hex(0x34C759)).frame(width: 100, height: 56)
                .overlay(alignment: .trailing) {
                  Circle().fill(.white).frame(width: 48, height: 48).shadow(color: .black.opacity(0.2), radius: 2, y: 2).padding(.trailing, 4)
                }
            }
          }
          .padding(.horizontal, 28)
          .frame(height: 104)
        }
      }
      .padding(.vertical, 8)
    }
  }

  var brightness: some View {
    HStack(spacing: 20) {
      Image(systemName: "sun.max").font(.system(size: 30, weight: .medium)).foregroundStyle(hex(t.sub))
        .frame(width: 36, height: 36)
      ZStack(alignment: .leading) {
        Capsule().fill(hex(t.slider)).frame(width: 800, height: 10)
        Capsule().fill(hex(t.sliderFill)).frame(width: 496, height: 10)
        Circle().fill(.white).frame(width: 36, height: 36).shadow(color: .black.opacity(0.25), radius: 3, y: 2)
          .offset(x: 496 - 18)
      }
    }
  }
}

// MARK: - Autoplay (support code, not shown): the finger taps the toggle at 1.5 s and 5 s; loop 8 s.

@Observable final class Show {
  var dark = false
  var finger = CGPoint(x: 820, y: 240)
  var fingerOn = false
  var press = false

  func tap() async {
    withAnimation(.smooth(duration: 0.6)) { finger = CGPoint(x: 830, y: 100); fingerOn = true }
    await wait(0.85)
    withAnimation(.easeOut(duration: 0.12)) { press = true }
    await wait(0.15)
    dark.toggle()
    withAnimation(.easeOut(duration: 0.2)) { press = false }
    await wait(0.35)
    withAnimation(.smooth(duration: 0.6)) { finger = CGPoint(x: 816, y: 158) }
    await wait(0.9)
    withAnimation(.easeOut(duration: 0.4)) { fingerOn = false }
    await wait(0.45)
    finger = CGPoint(x: 820, y: 240)
  }
  func run() async {
    while !Task.isCancelled {
      await wait(0.5)
      await tap()          // 0.5 → 3.2 (toggle at 1.5)
      await wait(0.8)      // → 4.0
      await tap()          // 4.0 → 6.7 (toggle at 5.0)
      await wait(1.3)      // → 8.0
    }
  }
  func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
}

struct ReelCanvas: View {
  @State private var show = Show()
  var body: some View {
    ZStack(alignment: .topLeading) {
      LinearGradient(colors: [hex(0x0D1A3A), hex(0x060B1A)], startPoint: .top, endPoint: .bottom)
      TitleBlock(title: "Theme Reveal", subtitle: "Dark mode spreads out from the toggle")
        .offset(x: 64, y: 72)
      RevealHero()
        .frame(width: HERO.width, height: HERO.height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.white.opacity(0.08)))
        .shadow(color: .black.opacity(0.12), radius: 4, y: 4)
        .shadow(color: .black.opacity(0.4), radius: 32, y: 24)
        .offset(x: 64, y: 295)
      VStack(spacing: 20) {
        ForEach(0 ..< 2, id: \.self) { i in CodeWindow(title: REEL_TITLES[i], code: REEL_CODE[i], types: REEL_TYPES) }
      }
      .frame(width: 952)
      .offset(x: 64, y: 1273)
      Text("Real SwiftUI · iOS 26 · mask, scaleEffect, smooth, contentTransition").font(.system(size: 22)).foregroundStyle(hex(0x64748B))
        .frame(width: 952)
        .offset(x: 64, y: 1846)
    }
    .frame(width: 1080, height: 1920, alignment: .topLeading)
    .environment(show)
    .task { await show.run() }
  }
}
