import SwiftUI

// KOI FISH, LIVE-CODED IN SWIFTUI
// Top: the koi (drawn by FishStage in Fish.swift). Drag a finger and it swims after it.
// Bottom: an Xcode-style editor (XcodeLook.swift) that types `follow` from Fish.swift.
// Launch with -demo to auto-play: type the code once, then a scripted finger leads the fish.
// (Same editor as HeartProof, NavbarLiveProof, LoginLiveProof and ProductLiveProof.)

@main
struct KoiApp: App {
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
// Copied from Fish.swift, character for character (every line here must also be in that file).

let file: [String] = [
  "import SwiftUI",
  "",
  "func follow(_ spine: inout [CGPoint],",
  "            heading: inout Double,",
  "            to target: CGPoint, dt: Double) {",
  "    // 1. The head turns toward the finger, gently.",
  "    let dx = target.x - spine[0].x",
  "    let dy = target.y - spine[0].y",
  "    let turn = wrap(atan2(dy, dx) - heading)",
  "    heading += clamp(turn, turnRate * dt)",
  "    let step = min(hypot(dx, dy) * 3, speed) * dt",
  "    spine[0].x += cos(heading) * step",
  "    spine[0].y += sin(heading) * step",
  "    // 2. Each segment follows the one in front,",
  "    //    but a joint can only bend so far.",
  "    var ahead = heading",
  "    for i in 1..<spine.count {",
  "        let a = spine[i - 1], b = spine[i]",
  "        let angle = atan2(a.y - b.y, a.x - b.x)",
  "        ahead += clamp(wrap(angle - ahead), maxBend)",
  "        spine[i].x = a.x - gap * cos(ahead)",
  "        spine[i].y = a.y - gap * sin(ahead)",
  "    }",
  "}",
]

// MARK: - Names for the Xcode-style coloring (see XcodeLook.swift)

let projectTypes: Set<String> = []
let projectNames: Set<String> = ["speed", "gap", "turnRate", "maxBend"]

// MARK: - The demo finger
// A pretend finger for the recording: it taps, then drags in big sweeps and two tight loops.
// Each stop is (seconds, x, y), with x and y as a fraction of the stage (0…1).

let fingerPath: [(Double, Double, Double)] = [
  (0.0, 0.80, 0.28),   // tap, top right
  (0.8, 0.78, 0.31),   // hold while the fish swims over
  (1.9, 0.22, 0.30),   // sweep left
  (2.7, 0.16, 0.68),   // and down
  (3.6, 0.52, 0.84),   // along the bottom
  (4.1, 0.76, 0.62),   // tight loop #1 (counterclockwise)
  (4.45, 0.62, 0.47),
  (4.8, 0.48, 0.61),
  (5.15, 0.62, 0.75),
  (5.5, 0.76, 0.61),
  (6.0, 0.70, 0.38),   // out the top
  (6.9, 0.32, 0.15),   // sweep across the top
  (7.7, 0.15, 0.42),
  (8.2, 0.36, 0.44),   // tight loop #2 (clockwise)
  (8.55, 0.50, 0.58),
  (8.9, 0.36, 0.72),
  (9.25, 0.22, 0.58),
  (9.6, 0.36, 0.44),
  (10.3, 0.72, 0.30),  // big sweep right
  (11.0, 0.82, 0.62),
  (11.6, 0.58, 0.74),  // lift the finger here
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
      FishStage(finger: { time, size in
        guard let fingerStart else { return nil }
        return demoFinger(time - fingerStart.timeIntervalSinceReferenceDate, size)
      })
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
    return XcodeEditor(project: "FishProof", fileStem: "Fish",
                       status: "\(segmentCount) segments",
                       rows: rows, current: current, lastKey: lastKey, dark: true)
  }

  // MARK: Demo (-demo launch argument)

  // Every pause in the demo is stretched by `pace`. Fast (0.65, like HeartProof),
  // because the fish is the point, not the typing.
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
    for i in file.indices { await type(i) }    // type the code once (the fish wanders meanwhile)
    current = -1
    await wait(0.4)
    fingerStart = .now                         // then a finger leads it around
  }
}

#Preview { ContentView() }
