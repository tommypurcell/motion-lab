import SwiftUI

// PARTICLE HEART, LIVE-CODED IN SWIFTUI
// Top: the heart (drawn by ParticleHeart in Heart.swift).
// Bottom: an Xcode-style editor (XcodeLook.swift) that types `makeDots` from Heart.swift.
// Launch with -demo to auto-play: type the code once, then let the heart play.
// (Same editor as NavbarLiveProof, LoginLiveProof and ProductLiveProof.)

@main
struct ParticleHeartApp: App {
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
// Copied from Heart.swift, character for character (every line here must also be in that file).

let file: [String] = [
  "import SwiftUI",
  "",
  "func heart(_ t: Double) -> CGPoint {",
  "    let x = 16 * pow(sin(t), 3)",
  "    let y = 13 * cos(t) - 5 * cos(2 * t)",
  "          - 2 * cos(3 * t) - cos(4 * t)",
  "    return CGPoint(x: x, y: -y)  // flip: y goes down",
  "}",
  "",
  "func makeDots(count: Int, scale: Double) -> [Dot] {",
  "    let steps = evenSteps(count: count)",
  "    var dots: [Dot] = []",
  "    for i in 0..<count {",
  "        let p = heart(steps[i])",
  "        var dot = Dot()",
  "        let x = p.x * scale + jitter()",
  "        let y = p.y * scale + jitter()",
  "        dot.target = CGPoint(x: x, y: y)",
  "        dot.delay = Double(i) * 0.0007",
  "        dot.duration = .random(in: 2...5)",
  "        dot.size = .random(in: 1.5...2.5)",
  "        dot.opacity = .random(in: 0.5...1)",
  "        dot.color = [pink, rose].randomElement()!",
  "        if i % 25 == 0 { dot.color = .white }",
  "        dots.append(dot)",
  "    }",
  "    return dots",
  "}",
]

// MARK: - Names for the Xcode-style coloring (see XcodeLook.swift)

let projectTypes: Set<String> = ["Dot"]
let projectNames: Set<String> = ["jitter", "pink", "rose", "heart", "evenSteps", "target", "delay",
                                  "duration", "size", "opacity", "color"]

// MARK: - The screen

struct ContentView: View {
  @State private var heartStart: Date? = nil       // when the heart began playing
  @State private var typed: [Int: Int] = [:]      // line number in `file` -> letters typed so far
  @State private var current = -1                 // the line being typed (-1: none)
  @State private var lastKey = Date()             // when the last letter was typed

  var body: some View {
    VStack(spacing: 0) {
      ParticleHeart(start: heartStart)
        .background(.black)
        .clipShape(.rect(cornerRadius: 20))
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .frame(height: 360)
      editor
        .padding(.top, 10)
    }
    .background(screenBG)
    .task {
      if CommandLine.arguments.contains("-demo") {
        await runDemo()
      } else {
        for i in file.indices { typed[i] = file[i].count }
        heartStart = .now
      }
    }
  }

  // MARK: Editor (drawn by XcodeEditor in XcodeLook.swift)

  var editor: some View {
    let rows = file.indices.filter { typed[$0] != nil }.map { i in
      EditorRow(id: i, text: String(file[i].prefix(typed[i]!)), dying: false)
    }
    return XcodeEditor(project: "HeartProof", fileStem: "Heart",
                       status: heartStart == nil ? nil : "3,000 dots",
                       rows: rows, current: current, lastKey: lastKey, dark: true)
  }

  // MARK: Demo (-demo launch argument)

  // Every pause in the demo is stretched by `pace`. NavbarLiveProof uses 1.3; here the typing
  // runs twice as fast (0.65), because the heart is the point. The heart's own timing is separate.
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
    for i in file.indices { await type(i) }    // type the code once
    current = -1
    await wait(0.4)
    heartStart = .now                          // then the heart plays
  }
}

#Preview { ContentView() }
