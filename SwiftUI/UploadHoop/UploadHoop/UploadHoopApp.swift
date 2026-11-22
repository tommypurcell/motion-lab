import SwiftUI

@main
struct UploadHoopApp: App {
  var body: some Scene { WindowGroup { ReelView { ReelCanvas() } } }
}

// The Upload Hoop reel: an "Upload files" card where each file is flicked into a basketball hoop.
// Toss and UploadCount run exactly the code shown in the code windows (REEL_CODE).

// The throw: a parabola. t goes 0 → 1 (driven by a TimelineView below).
struct Toss: View {
  var t: Double
  var a: CGPoint, b: CGPoint
  var icon: String
  var body: some View {
    let x = a.x + (b.x - a.x) * min(t / 0.8, 1)
    let y = a.y + (b.y - a.y) * t - 1700 * t * (1 - t)
    Image(systemName: icon)
      .rotationEffect(.degrees(360 * t))
      .scaleEffect(1 - 0.4 * t)
      .position(x: x, y: y)
  }
}

struct UploadCount: View {
  var count: Int
  var body: some View {
    Text("Uploaded \(count)")
      .contentTransition(.numericText())
      .animation(.snappy, value: count)
  }
}

let REEL_TYPES = ["Image", "Text", "CGPoint", "Double", "String", "Int", "View"]
let REEL_TITLES = ["The throw", "The count"]
let REEL_CODE: [String] = [
#"""
let x = a.x + (b.x - a.x) * min(t / 0.8, 1)
let y = a.y + (b.y - a.y) * t - 1700 * t * (1 - t)
Image(systemName: icon)
  .rotationEffect(.degrees(360 * t))
  .scaleEffect(1 - 0.4 * t)
  .position(x: x, y: y)
"""#,
#"""
Text("Uploaded \(count)")
  .contentTransition(.numericText())
  .animation(.snappy, value: count)
"""#,
]

// MARK: - The scene (support code, not shown)

struct UploadFile { let name: String; let icon: String; let color: UInt32 }
let FILES = [
  UploadFile(name: "deck.pdf", icon: "doc.richtext.fill", color: 0xF43F5E),
  UploadFile(name: "photo.png", icon: "photo.fill", color: 0x38BDF8),
  UploadFile(name: "notes.txt", icon: "doc.text.fill", color: 0x34D399),
]

let CARD = CGSize(width: 952, height: 980)
let RIM = CGPoint(x: 660, y: 410)        // rim center
let RIM_W: CGFloat = 170
let NET_H: CGFloat = 130
let GOAL = CGPoint(x: 660, y: 600)       // where the throw ends: below the net
func chipCenter(_ i: Int) -> CGPoint { CGPoint(x: 48 + 136 + CGFloat(i) * (272 + 24), y: 856) }
func iconSpot(_ i: Int) -> CGPoint { CGPoint(x: chipCenter(i).x - 80, y: chipCenter(i).y) }

struct Backboard: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06))
      RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.55), lineWidth: 5)
      RoundedRectangle(cornerRadius: 6).stroke(hex(0xF97316).opacity(0.9), lineWidth: 5)
        .frame(width: 120, height: 86).offset(y: 30)
    }
    .frame(width: 340, height: 230)
  }
}

// The net: a few strings from the rim, narrowing to the bottom.
struct Net: Shape {
  func path(in r: CGRect) -> Path {
    var p = Path()
    let n = 6
    for i in 0 ... n {
      let f = CGFloat(i) / CGFloat(n)
      let top = CGPoint(x: r.minX + r.width * f, y: r.minY)
      let bot = CGPoint(x: r.minX + r.width * (0.2 + 0.6 * f), y: r.maxY)
      p.move(to: top); p.addLine(to: bot)
    }
    for row in 1 ... 3 {
      let k = CGFloat(row) / 3
      let inset = r.width * 0.2 * k
      p.move(to: CGPoint(x: r.minX + inset, y: r.minY + r.height * k))
      p.addLine(to: CGPoint(x: r.maxX - inset, y: r.minY + r.height * k))
    }
    return p
  }
}

struct Hoop: View {
  var count: Int
  var front: Bool
  var body: some View {
    if front {
      ZStack(alignment: .top) {
        Net().stroke(Color.white.opacity(0.75), style: StrokeStyle(lineWidth: 3, lineCap: .round))
          .frame(width: RIM_W - 6, height: NET_H)
          .offset(y: 6)
          .keyframeAnimator(initialValue: 1.0, trigger: count) { net, s in
            net.scaleEffect(x: 2 - s, y: s, anchor: .top)
          } keyframes: { _ in
            SpringKeyframe(1.3, duration: 0.12)
            SpringKeyframe(0.85, duration: 0.2)
            SpringKeyframe(1.0, spring: .bouncy)
          }
        // front half of the rim
        Ellipse().trim(from: 0, to: 0.5)
          .stroke(hex(0xF97316), style: StrokeStyle(lineWidth: 9, lineCap: .round))
          .frame(width: RIM_W, height: 34).offset(y: -17)
      }
      .frame(width: RIM_W, height: NET_H + 20, alignment: .top)
      .position(x: RIM.x, y: RIM.y + (NET_H + 20) / 2)
    } else {
      ZStack {
        Backboard().position(x: RIM.x, y: RIM.y - 110)
        // back half of the rim
        Ellipse().trim(from: 0.5, to: 1)
          .stroke(hex(0xC2410C), style: StrokeStyle(lineWidth: 9, lineCap: .round))
          .frame(width: RIM_W, height: 34).position(RIM)
      }
    }
  }
}

struct FileIcon: View {
  let file: UploadFile
  var body: some View {
    Image(systemName: file.icon).font(.system(size: 64, weight: .semibold)).foregroundStyle(hex(file.color))
      .shadow(color: hex(file.color).opacity(0.45), radius: 14)
  }
}

struct Chip: View {
  let i: Int
  let gone: Bool
  let done: Bool
  var body: some View {
    HStack(spacing: 14) {
      ZStack {
        RoundedRectangle(cornerRadius: 16).fill(hex(FILES[i].color).opacity(gone ? 0.06 : 0.14))
        RoundedRectangle(cornerRadius: 16).strokeBorder(hex(FILES[i].color).opacity(gone ? 0.35 : 0), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
        if done {
          Image(systemName: "checkmark").font(.system(size: 34, weight: .bold)).foregroundStyle(hex(0x34D399))
            .transition(.scale.combined(with: .opacity))
        }
      }
      .frame(width: 84, height: 84)
      VStack(alignment: .leading, spacing: 4) {
        Text(FILES[i].name).font(.system(size: 24, weight: .semibold)).foregroundStyle(.white)
        Text(done ? "Done" : "2.4 MB").font(.system(size: 22)).foregroundStyle(done ? hex(0x34D399) : hex(0x94A3B8))
          .contentTransition(.opacity)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 14)
    .frame(width: 272, height: 128)
    .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.05)))
    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.08)))
    .position(chipCenter(i))
  }
}

@Observable final class Show {
  var count = 0
  var thrown = 0           // files that left their chip
  var held: Int? = nil     // file the finger is dragging
  var drag = CGSize.zero
  var finger = CGPoint(x: 300, y: 1100)
  var fingerOn = false
  var tossStart: Date? = nil
  var tossFrom = CGPoint.zero
  var tossIndex = 0
  let tossTime = 1.0

  func run() async {
    while !Task.isCancelled {
      count = 0; thrown = 0; held = nil; drag = .zero; fingerOn = false; tossStart = nil
      finger = CGPoint(x: 180, y: 1080)
      await wait(0.7)
      for i in 0 ..< 3 {
        withAnimation(.smooth(duration: 0.5)) { finger = iconSpot(i); fingerOn = true }
        await wait(0.6)
        held = i
        withAnimation(.easeInOut(duration: 0.4)) {
          drag = CGSize(width: -36, height: 44)
          finger = CGPoint(x: iconSpot(i).x - 36, y: iconSpot(i).y + 44)
        }
        await wait(0.45)
        tossFrom = CGPoint(x: iconSpot(i).x - 36, y: iconSpot(i).y + 44)
        tossIndex = i; tossStart = .now; thrown = i + 1; held = nil; drag = .zero
        withAnimation(.easeOut(duration: 0.35)) { finger = CGPoint(x: tossFrom.x + 70, y: tossFrom.y - 120); fingerOn = false }
        await wait(0.88)
        count += 1
        await wait(tossTime - 0.88)
        tossStart = nil
        await wait(0.85)
      }
      await wait(0.9)
    }
  }
  func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
}

struct TossLayer: View {
  let show: Show
  let late: Bool
  var body: some View {
    TimelineView(.animation) { tl in
      if let start = show.tossStart {
        let t = min(1, tl.date.timeIntervalSince(start) / show.tossTime)
        if (t >= 0.8) == late {
          Toss(t: t, a: show.tossFrom, b: GOAL, icon: FILES[show.tossIndex].icon)
            .font(.system(size: 64, weight: .semibold))
            .foregroundStyle(hex(FILES[show.tossIndex].color))
            .opacity(t < 0.9 ? 1 : (1 - t) / 0.1)
        }
      }
    }
    .frame(width: CARD.width, height: CARD.height)
  }
}

struct UploadCard: View {
  @State private var show = Show()
  var body: some View {
    ZStack(alignment: .topLeading) {
      // header
      HStack(spacing: 20) {
        ZStack {
          RoundedRectangle(cornerRadius: 20).fill(LinearGradient(colors: [hex(0x6366F1), hex(0x3B82F6)], startPoint: .topLeading, endPoint: .bottomTrailing))
          Image(systemName: "arrow.up.doc.fill").font(.system(size: 36, weight: .semibold)).foregroundStyle(.white)
        }
        .frame(width: 80, height: 80)
        VStack(alignment: .leading, spacing: 4) {
          Text("Upload files").font(.system(size: 38, weight: .bold)).foregroundStyle(.white)
          Text("Flick a file into the hoop").font(.system(size: 24)).foregroundStyle(hex(0x94A3B8))
        }
      }
      .padding(48)

      // court floor glow
      Ellipse().fill(RadialGradient(colors: [hex(0xF97316).opacity(0.10), .clear], center: .center, startRadius: 0, endRadius: 320))
        .frame(width: 720, height: 220).position(x: RIM.x, y: 660)

      Hoop(count: show.count, front: false)

      // files waiting in their chips
      ForEach(0 ..< 3, id: \.self) { i in
        Chip(i: i, gone: i < show.thrown, done: i < show.count)
          .animation(.snappy, value: show.count)
        if i >= show.thrown {
          FileIcon(file: FILES[i])
            .scaleEffect(show.held == i ? 1.15 : 1)
            .position(iconSpot(i))
            .offset(show.held == i ? show.drag : .zero)
            .zIndex(show.held == i ? 20 : 2)
        }
      }

      // the file in the air: in front of the net on the way up, behind it on the way down
      TossLayer(show: show, late: false).zIndex(10)
      TossLayer(show: show, late: true).zIndex(6)

      Hoop(count: show.count, front: true).zIndex(8)

      // the counter, top right
      HStack(spacing: 10) {
        Image(systemName: show.count > 0 ? "checkmark.circle.fill" : "tray.and.arrow.up.fill")
          .contentTransition(.symbolEffect(.replace))
          .foregroundStyle(show.count > 0 ? hex(0x34D399) : hex(0x94A3B8))
        UploadCount(count: show.count)
          .foregroundStyle(.white)
      }
      .font(.system(size: 30, weight: .semibold))
      .padding(.horizontal, 24).frame(height: 68)
      .background(Capsule().fill(Color.white.opacity(0.08)))
      .overlay(Capsule().stroke(Color.white.opacity(0.1)))
      .position(x: CARD.width - 48 - 130, y: 88)
      .zIndex(9)

      FingerDot()
        .opacity(show.fingerOn ? 1 : 0)
        .scaleEffect(show.fingerOn ? 1 : 0.6)
        .position(show.finger)
        .zIndex(30)
    }
    .frame(width: CARD.width, height: CARD.height, alignment: .topLeading)
    .background(
      RoundedRectangle(cornerRadius: 40).fill(LinearGradient(colors: [hex(0x162447), hex(0x0E1730)], startPoint: .top, endPoint: .bottom))
    )
    .clipShape(RoundedRectangle(cornerRadius: 40))
    .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.white.opacity(0.1)))
    .shadow(color: .black.opacity(0.12), radius: 4, y: 4)
    .shadow(color: .black.opacity(0.4), radius: 32, y: 24)
    .task { await show.run() }
  }
}

struct ReelCanvas: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      TitleBlock(title: "Upload Hoop", subtitle: "A file upload you can throw")
      Spacer().frame(height: 48)
      UploadCard()
      Spacer().frame(height: 32)
      VStack(spacing: 24) {
        ForEach(0 ..< 2, id: \.self) { i in CodeWindow(title: REEL_TITLES[i], code: REEL_CODE[i], types: REEL_TYPES) }
      }
      Spacer(minLength: 0)
      Text("Real SwiftUI · iOS 26 · TimelineView, keyframeAnimator, numericText").font(.system(size: 22)).foregroundStyle(hex(0x64748B))
        .frame(maxWidth: .infinity)
    }
    .padding(.horizontal, 64).padding(.top, 96).padding(.bottom, 56)
    .frame(width: 1080, height: 1920, alignment: .topLeading)
    .background(LinearGradient(colors: [hex(0x0D1A3A), hex(0x060B1A)], startPoint: .top, endPoint: .bottom))
  }
}
