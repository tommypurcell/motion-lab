import SwiftUI

// LIZARD SKELETON, LIVE-CODED IN SWIFTUI
// Top: the lizard (drawn by LizardStage in Lizard.swift). Drag a finger and it chases it.
// Bottom: an Xcode-style editor (XcodeLook.swift) that types `follow` from Lizard.swift.
// Launch with -demo to auto-play: type the code once, then a scripted finger leads the lizard.
// (Same editor as HeartProof, NavbarLiveProof, LoginLiveProof and ProductLiveProof.)

@main
struct LizardApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .preferredColorScheme(.dark)   // white status bar on the dark screen
    }
  }
}

// MARK: - Colors

extension Color {
  init(hex: UInt32) {   // our own little helper: 0xRRGGBB -> Color
    self.init(red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
  }
}

let screenBG = Color(hex: 0x161618)   // dark gray, like Xcode's window

// MARK: - The code in the editor
// Copied from Lizard.swift, character for character (every line here must also be in that file).

let file: [String] = [
  "import SwiftUI",
  "",
  "func follow(_ spine: inout [CGPoint],",
  "            to target: CGPoint, dt: Double) {",
  "    // 1. The head walks toward the finger.",
  "    let dx = target.x - spine[0].x",
  "    let dy = target.y - spine[0].y",
  "    let d = hypot(dx, dy)",
  "    if d > 1 {",
  "        let step = min(d, speed * dt)",
  "        spine[0].x += dx / d * step",
  "        spine[0].y += dy / d * step",
  "    }",
  "    // 2. Each bone follows the one in front of it.",
  "    for i in 1..<spine.count {",
  "        let a = spine[i - 1]   // the bone in front",
  "        let b = spine[i]       // this bone",
  "        let angle = atan2(a.y - b.y, a.x - b.x)",
  "        spine[i].x = a.x - gap * cos(angle)",
  "        spine[i].y = a.y - gap * sin(angle)",
  "    }",
  "}",
]

// MARK: - Names for the Xcode-style coloring (see XcodeLook.swift)

let projectTypes: Set<String> = []
let projectNames: Set<String> = ["speed", "gap"]

// MARK: - The demo finger
// A pretend finger for the recording: it taps, then drags with a few sharp turns.
// Each stop is (seconds, x, y), with x and y as a fraction of the stage (0…1).

let fingerPath: [(Double, Double, Double)] = [
  (0.0, 0.82, 0.18),   // tap, top right
  (0.9, 0.80, 0.22),   // hold while the lizard runs over
  (1.9, 0.22, 0.26),   // drag left
  (2.5, 0.14, 0.56),   // sharp turn down
  (3.2, 0.52, 0.80),   // across the bottom
  (3.7, 0.84, 0.62),   // up the right side
  (4.2, 0.62, 0.38),   // sharp turn back left
  (5.0, 0.20, 0.78),
  (5.6, 0.36, 0.90),   // hook
  (6.3, 0.80, 0.82),
  (7.1, 0.84, 0.34),
  (7.8, 0.50, 0.14),   // across the top
  (8.6, 0.30, 0.46),   // curl back in
  (9.4, 0.52, 0.56),   // lift the finger here
]

// Where the pretend finger is, `t` seconds after it touched down (nil: not touching).
// Catmull-Rom spline through the stops, so the drag is smooth between them.
func demoFinger(_ t: Double, _ size: CGSize) -> CGPoint? {
  guard t >= 0, t <= fingerPath.last!.0 else { return nil }
  var k = 0
  while fingerPath[k + 1].0 < t { k += 1 }
  let p0 = fingerPath[max(k - 1, 0)], p1 = fingerPath[k]
  let p2 = fingerPath[k + 1], p3 = fingerPath[min(k + 2, fingerPath.count - 1)]
  let u = (t - p1.0) / (p2.0 - p1.0)
  func spline(_ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
    0.5 * (2 * b + (c - a) * u + (2 * a - 5 * b + 4 * c - d) * u * u + (3 * b - a - 3 * c + d) * u * u * u)
  }
  return CGPoint(x: spline(p0.1, p1.1, p2.1, p3.1) * size.width,
                 y: spline(p0.2, p1.2, p2.2, p3.2) * size.height)
}

// MARK: - The screen

struct ContentView: View {
  @State private var fingerStart: Date? = nil     // when the demo finger touched down
  @State private var typed: [Int: Int] = [:]      // line number in `file` -> letters typed so far
  @State private var current = -1                 // the line being typed (-1: none)
  @State private var lastKey = Date()             // when the last letter was typed

  var body: some View {
    VStack(spacing: 0) {
      LizardStage(finger: { time, size in
        guard let fingerStart else { return nil }
        return demoFinger(time - fingerStart.timeIntervalSinceReferenceDate, size)
      })
      .background(.black)
      .clipShape(.rect(cornerRadius: 20))
      .padding(.horizontal, 10)
      .padding(.top, 6)
      .frame(height: 400)
      editor
        .padding(.top, 10)
    }
    .background(screenBG)
    .task {
      if CommandLine.arguments.contains("-demo") {
        await runDemo()
      } else {
        for i in file.indices { typed[i] = file[i].count }
      }
    }
  }

  // MARK: Editor (drawn by XcodeEditor in XcodeLook.swift)

  var editor: some View {
    let rows = file.indices.filter { typed[$0] != nil }.map { i in
      EditorRow(id: i, text: String(file[i].prefix(typed[i]!)), dying: false)
    }
    return XcodeEditor(project: "LizardProof", fileStem: "Lizard",
                       status: "\(boneCount) bones",
                       rows: rows, current: current, lastKey: lastKey, dark: true)
  }

  // MARK: Demo (-demo launch argument)

  // Every pause in the demo is stretched by `pace`. Fast (0.65, like HeartProof),
  // because the lizard is the point, not the typing.
  let pace = 0.65

  func wait(_ seconds: Double) async {
    try? await Task.sleep(for: .seconds(seconds * pace))
  }

  // Type one line, a few letters at a time.
  func type(_ i: Int) async {
    let text = file[i]
    let indent = text.prefix { $0 == " " }.count
    current = i
    typed[i] = indent                          // spaces appear at once
    lastKey = .now
    while typed[i]! < text.count {
      typed[i] = min(typed[i]! + 3, text.count)
      lastKey = .now
      await wait(0.028)
    }
    await wait(0.03)
  }

  func runDemo() async {
    await wait(0.8)
    for i in file.indices { await type(i) }    // type the code once (the lizard wanders meanwhile)
    current = -1
    await wait(0.4)
    fingerStart = .now                         // then a finger leads it around
  }
}

#Preview { ContentView() }
