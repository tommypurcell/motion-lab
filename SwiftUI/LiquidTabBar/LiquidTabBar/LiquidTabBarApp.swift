import SwiftUI

// LIQUID TAB BAR
// A colored ball (the "bead") sits on the bar's top edge, and the edge dips under it
// like water around a floating ball (a "meniscus"). Tap a tab, or drag the bead.
// Launch with -demo to auto-play the recorded sequence.

@main
struct LiquidTabBarApp: App {
  var body: some Scene {
    WindowGroup { ContentView() }
  }
}

// MARK: - Data

// One tab: its name, icon, subtitle and color (as red, green, blue numbers, so we can mix them).
struct Tab {
  let name: String
  let icon: String
  let subtitle: String
  let rgb: (Double, Double, Double)
}

let tabs: [Tab] = [
  Tab(name: "Home",     icon: "house",             subtitle: "All your stuff, one tap away.", rgb: (0.78, 0.96, 0.20)),
  Tab(name: "Profile",  icon: "person",            subtitle: "This is you, at a glance.",     rgb: (0.98, 0.86, 0.26)),
  Tab(name: "Messages", icon: "bubble.left",       subtitle: "Two new notes. Both nice.",     rgb: (0.99, 0.73, 0.23)),
  Tab(name: "Camera",   icon: "camera",            subtitle: "Point, shoot, keep it.",        rgb: (1.00, 0.48, 0.33)),
  Tab(name: "Settings", icon: "slider.horizontal.3", subtitle: "Set it once. Forget it.",     rgb: (0.95, 0.33, 0.48)),
]

// Color interpolation: for a position like 1.5 (halfway between tab 1 and tab 2),
// mix the two tab colors 50/50. So the bead changes color smoothly as it travels.
func color(at position: CGFloat) -> Color {
  let i = min(max(Int(position), 0), tabs.count - 2)   // the tab on the left
  let t = Double(min(max(position - CGFloat(i), 0), 1)) // 0...1 of the way to the next tab
  let a = tabs[i].rgb, b = tabs[i + 1].rgb
  return Color(red:   a.0 + (b.0 - a.0) * t,
               green: a.1 + (b.1 - a.1) * t,
               blue:  a.2 + (b.2 - a.2) * t)
}

// Sizes (points)
let barWidth: CGFloat = 360
let barHeight: CGFloat = 66
let slotGap: CGFloat = 57        // distance between tab centers
let beadSize: CGFloat = 46
let topSpace: CGFloat = 32       // room above the bar for the top half of the bead

// The x of tab number `position` inside the bar (position can be a fraction).
func slotX(_ position: CGFloat) -> CGFloat {
  barWidth / 2 + (position - 2) * slotGap
}

// MARK: - The bar shape with the notch

// A rounded rectangle whose top edge dips down at `notchX`.
// `animatableData` tells SwiftUI which numbers to animate, so the dip slides
// smoothly instead of jumping.
struct NotchedBar: Shape {
  var notchX: CGFloat
  var stretch: CGFloat   // 0 = at rest, bigger = wider, shallower notch while moving fast

  var animatableData: AnimatablePair<CGFloat, CGFloat> {
    get { AnimatablePair(notchX, stretch) }
    set { notchX = newValue.first; stretch = newValue.second }
  }

  func path(in rect: CGRect) -> Path {
    let r: CGFloat = 18                        // corner radius of the bar
    let x = notchX, top = rect.minY
    let half = 38 + stretch * 24               // where the dip starts, left and right of the bead
    let bowl = 28 + stretch * 6                // radius of the round bottom (bead radius 23 + a small gap)
    let center = CGPoint(x: x, y: top + 1 - stretch * 8)   // bowl center (rises a bit = shallower when stretched)

    // The point where the shoulder curve meets the round bottom: 55° out from straight down.
    let angle = 55.0 * .pi / 180
    let side = CGPoint(x: x - bowl * sin(angle), y: center.y + bowl * cos(angle))
    let dir = CGPoint(x: cos(angle), y: sin(angle))   // which way the bowl is heading at that point

    var p = Path()
    p.move(to: CGPoint(x: rect.minX + r, y: top))
    p.addLine(to: CGPoint(x: x - half, y: top))

    // Left shoulder: a bezier that leaves the top edge flat and arrives exactly in the
    // bowl's direction. No sharp corners anywhere, so the edge reads as one liquid curve,
    // not a circle cut out of a rectangle.
    p.addCurve(to: side,
               control1: CGPoint(x: x - half + 9, y: top),
               control2: CGPoint(x: side.x - dir.x * 8, y: side.y - dir.y * 8))
    // The round bottom, hugging the bead.
    p.addArc(center: center, radius: bowl,
             startAngle: .degrees(90 + 55), endAngle: .degrees(90 - 55), clockwise: true)
    // Right shoulder: the mirror image.
    p.addCurve(to: CGPoint(x: x + half, y: top),
               control1: CGPoint(x: 2 * x - side.x + dir.x * 8, y: side.y - dir.y * 8),
               control2: CGPoint(x: x + half - 9, y: top))

    // The rest is a normal rounded rectangle.
    p.addLine(to: CGPoint(x: rect.maxX - r, y: top))
    p.addArc(tangent1End: CGPoint(x: rect.maxX, y: top), tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: r)
    p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: r)
    p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: top), radius: r)
    p.addArc(tangent1End: CGPoint(x: rect.minX, y: top), tangent2End: CGPoint(x: rect.minX + r, y: top), radius: r)
    p.closeSubpath()
    return p
  }
}

// MARK: - The whole tab bar

// This view is Animatable too: during a spring, SwiftUI calls `body` every frame
// with the in-between `position`. That's how the color and icons can follow the bead.
struct LiquidTabBar: View, Animatable {
  var position: CGFloat   // 0...4, a fraction while moving
  var dragStretch: CGFloat   // extra stretch from a fast finger
  var tripFrom: CGFloat = 0  // where a tap's trip started (not animated)
  var tripTo: CGFloat = 0    // where it ends

  var animatableData: AnimatablePair<CGFloat, CGFloat> {
    get { AnimatablePair(position, dragStretch) }
    set { position = newValue.first; dragStretch = newValue.second }
  }

  // The bead stretches most halfway through a trip, and not at all at the ends.
  // (Worked out from `position`, so it moves with the same spring.)
  var stretch: CGFloat {
    let trip = tripTo - tripFrom
    guard trip != 0 else { return dragStretch }
    let progress = min(max((position - tripFrom) / trip, 0), 1)   // 0 at the start, 1 at the end
    return dragStretch + sin(.pi * progress) * min(abs(trip) * 0.1, 0.3)
  }

  var body: some View {
    let x = slotX(position)
    let tint = color(at: position)
    let nearest = Int(position.rounded())
    let offSlot = abs(position - CGFloat(nearest))   // 0 when parked on a tab

    ZStack(alignment: .topLeading) {
      // 1. The bar, filled dark, with a thin light outline.
      NotchedBar(notchX: x, stretch: stretch)
        .fill(LinearGradient(colors: [Color(red: 0.09, green: 0.08, blue: 0.12), Color(red: 0.04, green: 0.03, blue: 0.07)],
                             startPoint: .top, endPoint: .bottom))
        .overlay(NotchedBar(notchX: x, stretch: stretch).stroke(.white.opacity(0.2), lineWidth: 1))
        .frame(width: barWidth, height: barHeight)
        .offset(y: topSpace)

      // 2. The tab icons. The one under the bead fades out (the bead shows it instead).
      ForEach(0..<tabs.count, id: \.self) { i in
        Image(systemName: tabs[i].icon)
          .font(.system(size: 17, weight: .regular))
          .foregroundStyle(.white.opacity(0.8))
          .opacity(min(1, abs(position - CGFloat(i)) * 1.6))
          .position(x: slotX(CGFloat(i)), y: topSpace + 33)
      }

      // 3. The active tab's name, small, in its color.
      Text(tabs[nearest].name)
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(tint)
        .opacity(max(0, 1 - offSlot * 3))
        .position(x: slotX(CGFloat(nearest)), y: topSpace + 51)

      // 4. The bead. It squashes wider when `stretch` grows.
      Circle()
        .fill(tint)
        .overlay(
          Image(systemName: tabs[nearest].icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.black.opacity(0.8))
        )
        .frame(width: beadSize, height: beadSize)
        .scaleEffect(x: 1 + stretch, y: 1 - stretch * 0.4)
        .shadow(color: tint.opacity(0.45), radius: 12)
        .position(x: x, y: topSpace)
    }
    .frame(width: barWidth, height: topSpace + barHeight)
  }
}

// MARK: - Title transition (blur + fade)

struct BlurFade: ViewModifier {
  let amount: CGFloat
  func body(content: Content) -> some View {
    content.blur(radius: amount * 10).opacity(1 - amount)
  }
}

// MARK: - The screen

struct ContentView: View {
  @State private var position: CGFloat = 0   // where the bead is (tab number, can be a fraction)
  @State private var stretch: CGFloat = 0     // drag stretch
  @State private var tripFrom: CGFloat = 0
  @State private var tripTo: CGFloat = 0
  @State private var selected = 0            // which tab's title is showing
  @State private var dragging: Bool? = nil   // nil = gesture not decided yet
  @State private var touch = CGPoint.zero    // demo only: where the fake finger is
  @State private var touchOn = false         // demo only: is the finger down?

  var body: some View {
    let tint = color(at: CGFloat(selected))

    ZStack {
      // Background: dark plum with a soft light at the top.
      LinearGradient(colors: [Color(red: 0.16, green: 0.12, blue: 0.24), Color(red: 0.05, green: 0.04, blue: 0.09)],
                     startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        Spacer()

        // "● LIQUID TAB BAR": the dot takes the active color.
        HStack(spacing: 8) {
          Circle().fill(tint).frame(width: 8, height: 8)
            .shadow(color: tint, radius: 4)
          Text("LIQUID TAB BAR")
            .font(.system(size: 13, weight: .semibold))
            .tracking(2)
            .foregroundStyle(.white.opacity(0.7))
        }

        // The title. `.id(selected)` makes a new Text for each tab,
        // so the old one blurs out while the new one blurs in.
        ZStack {
          Text(tabs[selected].name)
            .font(.system(size: 60, weight: .heavy))
            .tracking(-1.5)
            .foregroundStyle(.white.opacity(0.93))
            .id(selected)
            .transition(.modifier(active: BlurFade(amount: 1), identity: BlurFade(amount: 0)))
        }
        .padding(.top, 14)

        ZStack {
          Text(tabs[selected].subtitle)
            .font(.system(size: 16))
            .foregroundStyle(.white.opacity(0.55))
            .id(selected)
            .transition(.opacity)
        }
        .padding(.top, 6)

        LiquidTabBar(position: position, dragStretch: stretch, tripFrom: tripFrom, tripTo: tripTo)
          .background(   // soft glow under the bar, in the active color
            Ellipse().fill(tint).frame(width: 280, height: 110)
              .blur(radius: 60).opacity(0.35).offset(y: 80)
          )
          .overlay(alignment: .topLeading) { fingerDot }
          .contentShape(Rectangle())
          .gesture(dragOrTap)
          .padding(.top, 40)

        (Text("Tap a tab — or ") + Text("drag the bead").foregroundColor(.white.opacity(0.85)) + Text(" along the bar."))
          .font(.system(size: 14))
          .foregroundStyle(.white.opacity(0.45))
          .padding(.top, 44)

        Spacer()
        Spacer()
      }
    }
    .preferredColorScheme(.dark)
    .task {
      if CommandLine.arguments.contains("-demo") { await runDemo() }
    }
  }

  // MARK: Actions

  // Tap: spring the bead to tab i. Remember the trip so the bead can stretch on the way.
  func select(_ i: Int) {
    tripFrom = position
    tripTo = CGFloat(i)
    withAnimation(.spring(response: 0.6, dampingFraction: 0.68)) { position = CGFloat(i) }
    withAnimation(.easeInOut(duration: 0.4)) { selected = i }
  }

  // One gesture does both: a short touch is a tap, a touch that starts on the bead and moves is a drag.
  var dragOrTap: some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        if dragging == nil, abs(value.translation.width) > 6 {
          dragging = abs(value.startLocation.x - slotX(position)) < beadSize * 0.7
        }
        if dragging == true { dragBead(to: value.location.x, speed: value.velocity.width) }
      }
      .onEnded { value in
        if dragging == true {
          release()
        } else if dragging == nil {   // it was a tap: pick the closest tab
          let i = Int(((value.location.x - slotX(0)) / slotGap).rounded())
          select(min(max(i, 0), tabs.count - 1))
        }
        dragging = nil
      }
  }

  // While dragging, the bead follows the finger. Faster finger = more stretch.
  func dragBead(to x: CGFloat, speed: CGFloat) {
    let p = min(max((x - slotX(0)) / slotGap, 0), CGFloat(tabs.count - 1))
    tripFrom = 0; tripTo = 0   // no tap trip while dragging
    withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.8)) {
      position = p
      stretch = min(abs(speed) / 1800, 0.3)
    }
    let nearest = Int(p.rounded())
    if nearest != selected {
      withAnimation(.easeInOut(duration: 0.4)) { selected = nearest }
    }
  }

  // Let go: snap to the nearest tab with a bouncy spring.
  func release() {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
      position = position.rounded()
      stretch = 0
    }
  }

  // MARK: Demo (-demo launch argument)

  var fingerDot: some View {
    Circle()
      .fill(.white.opacity(0.35))
      .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1.5))
      .frame(width: 30, height: 30)
      .scaleEffect(touchOn ? 1 : 1.4)
      .opacity(touchOn ? 1 : 0)
      .position(touch)
  }

  func wait(_ seconds: Double) async {
    try? await Task.sleep(for: .seconds(seconds))
  }

  func demoTap(_ i: Int) async {
    let point = CGPoint(x: slotX(CGFloat(i)), y: topSpace + 36)
    touch = point
    withAnimation(.easeOut(duration: 0.15)) { touchOn = true }
    await wait(0.18)
    select(i)
    await wait(0.25)
    withAnimation(.easeOut(duration: 0.2)) { touchOn = false }
  }

  func runDemo() async {
    await wait(1.2)
    await demoTap(2)            // Home -> Messages
    await wait(1.3)
    await demoTap(4)            // Messages -> Settings
    await wait(1.4)

    // Drag the bead from Settings back to Home, like a finger would.
    touch = CGPoint(x: slotX(4), y: topSpace)
    withAnimation(.easeOut(duration: 0.15)) { touchOn = true }
    await wait(0.3)
    let start = Date(), duration = 1.0
    var lastX = slotX(4), lastTime = start
    while true {
      let t = min(Date().timeIntervalSince(start) / duration, 1)
      let eased = t * t * (3 - 2 * t)                    // smooth start and stop
      let x = slotX(4 - 4 * CGFloat(eased))
      let now = Date()
      let speed = (x - lastX) / max(now.timeIntervalSince(lastTime), 0.001)
      lastX = x; lastTime = now
      touch = CGPoint(x: x, y: topSpace)
      dragBead(to: x, speed: speed)
      if t >= 1 { break }
      await wait(1.0 / 120)
    }
    release()
    await wait(0.2)
    withAnimation(.easeOut(duration: 0.2)) { touchOn = false }
  }
}

#Preview { ContentView() }
