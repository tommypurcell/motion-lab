import SwiftUI

// NAVBAR, LIVE-CODED IN SWIFTUI
// Top: a live preview. Bottom: an Xcode-style editor (XcodeLook.swift).
// The code is typed one step at a time. After each step, the preview turns that
// step's modifiers on, so the preview is always exactly what the typed code draws.
// Launch with -demo to auto-play: typing, then zoom, then tapping through the tabs.
// (Same engine as LoginLiveProof and ProductLiveProof.)

@main
struct GlassNavbarApp: App {
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

let screenBG = Color(hex: 0x161618)                          // dark gray, like Xcode's window
let navy = Color(red: 0.04, green: 0.07, blue: 0.15)         // the same constant the code types

let tabs = ["Home", "About", "Services", "Projects", "Contact"]

// MARK: - The steps

// Every step types a few lines. `stage` groups the steps into 4 stages.
// The preview checks `shown >= .someStep` to turn modifiers on.
enum Step: Int, CaseIterable, Comparable {
  case start
  // 1. Plain tabs
  case skeleton, text
  // 2. Glass bar
  case navy, textStyle, glass, border, shadow
  // 3. Pill
  case state, pillVar, pillUse
  // 4. Taps
  case taps

  static func < (a: Step, b: Step) -> Bool { a.rawValue < b.rawValue }

  var stage: Int {
    switch self {
    case .start: 0
    case .skeleton, .text: 1
    case .navy, .textStyle, .glass, .border, .shadow: 2
    case .state, .pillVar, .pillUse: 3
    case .taps: 4
    }
  }
}

let stageNames = ["", "Plain tabs", "Glass bar", "Pill", "Taps"]

// MARK: - The code (the whole finished file, 4-space indents like Tommy's project)

// One line: its text, the step that types it, and (optional) the step that deletes it.
struct CodeLine {
  let text: String
  let step: Step
  var until: Step? = nil
}

let file: [CodeLine] = [
  CodeLine(text: "import SwiftUI", step: .skeleton),
  CodeLine(text: "", step: .skeleton),
  CodeLine(text: "let navy = Color(red: 0.04, green: 0.07, blue: 0.15)", step: .navy),
  CodeLine(text: "", step: .navy),
  CodeLine(text: "struct Navbar: View {", step: .skeleton),
  CodeLine(text: "    let tabs = [\"Home\", \"About\", \"Services\",", step: .skeleton),
  CodeLine(text: "                \"Projects\", \"Contact\"]", step: .skeleton),
  CodeLine(text: "    @State var selected = \"Home\"", step: .state),
  CodeLine(text: "    @Namespace var ns", step: .state),
  CodeLine(text: "", step: .skeleton),
  CodeLine(text: "    var body: some View {", step: .skeleton),
  CodeLine(text: "        ZStack {", step: .skeleton),
  CodeLine(text: "            navy.ignoresSafeArea()", step: .navy),
  CodeLine(text: "            bar", step: .skeleton),
  CodeLine(text: "        }", step: .skeleton),
  CodeLine(text: "    }", step: .skeleton),
  CodeLine(text: "", step: .skeleton),
  CodeLine(text: "    var bar: some View {", step: .skeleton),
  CodeLine(text: "        HStack(spacing: 2) {", step: .skeleton),
  CodeLine(text: "            ForEach(tabs, id: \\.self) { tab in", step: .skeleton),
  CodeLine(text: "                tabButton(tab)", step: .skeleton),
  CodeLine(text: "            }", step: .skeleton),
  CodeLine(text: "        }", step: .skeleton),
  CodeLine(text: "        .padding(6)", step: .glass),
  CodeLine(text: "        .background(.ultraThinMaterial, in: .capsule)", step: .glass),
  CodeLine(text: "        .overlay(Capsule().stroke(.gray, lineWidth: 0.5))", step: .border),
  CodeLine(text: "        .shadow(color: .black, radius: 15, y: 10)", step: .shadow),
  CodeLine(text: "    }", step: .skeleton),
  CodeLine(text: "", step: .skeleton),
  CodeLine(text: "    func tabButton(_ tab: String) -> some View {", step: .skeleton),
  CodeLine(text: "        Text(tab)", step: .text),
  CodeLine(text: "            .font(.caption.weight(.medium))", step: .textStyle),
  CodeLine(text: "            .foregroundStyle(.white)", step: .textStyle),
  CodeLine(text: "            .padding(.horizontal, 10)", step: .textStyle),
  CodeLine(text: "            .padding(.vertical, 8)", step: .textStyle),
  CodeLine(text: "            .background {", step: .pillUse),
  CodeLine(text: "                if selected == tab { pill }", step: .pillUse),
  CodeLine(text: "            }", step: .pillUse),
  CodeLine(text: "            .onTapGesture {", step: .taps),
  CodeLine(text: "                withAnimation(.bouncy) {", step: .taps),
  CodeLine(text: "                    selected = tab", step: .taps),
  CodeLine(text: "                }", step: .taps),
  CodeLine(text: "            }", step: .taps),
  CodeLine(text: "    }", step: .skeleton),
  CodeLine(text: "", step: .pillVar),
  CodeLine(text: "    var pill: some View {", step: .pillVar),
  CodeLine(text: "        Capsule()", step: .pillVar),
  CodeLine(text: "            .fill(.cyan.gradient)", step: .pillVar),
  CodeLine(text: "            .shadow(color: .cyan, radius: 8)", step: .pillVar),
  CodeLine(text: "            .matchedGeometryEffect(id: \"pill\", in: ns)", step: .pillVar),
  CodeLine(text: "    }", step: .pillVar),
  CodeLine(text: "}", step: .skeleton),
]

// MARK: - Names for the Xcode-style coloring (see XcodeLook.swift)

let projectTypes: Set<String> = ["Navbar"]
let projectNames: Set<String> = ["navy", "tabs", "selected", "ns", "bar", "tabButton", "pill"]

// MARK: - Small helpers

extension View {
  // Our helper: apply some modifiers only when `on` is true.
  @ViewBuilder
  func when<V: View>(_ on: Bool, _ change: (Self) -> V) -> some View {
    if on { change(self) } else { self }
  }

  // Demo only: remember where this view is on screen, so the finger dot can tap it.
  func spot(_ key: String, in spots: Binding<[String: CGPoint]>) -> some View {
    onGeometryChange(for: CGPoint.self) { proxy in
      let f = proxy.frame(in: .global)
      return CGPoint(x: f.midX, y: f.midY)
    } action: { center in
      spots.wrappedValue[key] = center
    }
  }
}

// MARK: - The screen

struct ContentView: View {
  // The same state Navbar has in the code.
  @State private var selected = "Home"
  @Namespace private var ns

  // Editor state
  @State private var shown = Step.taps            // the last step the preview has applied
  @State private var typed: [Int: Int] = [:]      // line number in `file` -> letters typed so far
  @State private var current = -1                 // the line being typed (-1: none)
  @State private var dying: Set<Int> = []         // lines flashing before they are deleted
  @State private var lastKey = Date()             // when the last letter was typed
  @State private var zoomed = false               // end of the demo: preview zooms in

  // Demo only
  @State private var spots: [String: CGPoint] = [:]
  @State private var touch = CGPoint.zero
  @State private var touchOn = false

  var body: some View {
    VStack(spacing: 0) {
      previewPane
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .frame(height: 300)
        // The zoom is only a picture transform (scale + move): nothing re-lays out.
        .scaleEffect(zoomed ? 1.15 : 1)
        .offset(y: zoomed ? 210 : 0)
        .zIndex(1)
      editor
        .padding(.top, 10)
        .offset(y: zoomed ? 600 : 0)
        .opacity(zoomed ? 0 : 1)
    }
    // When zoomed, the screen behind matches the navy page, so the pane's edge disappears.
    .background(zoomed ? navy : screenBG)
    .overlay { fingerDot }
    .task {
      if CommandLine.arguments.contains("-demo") {
        await runDemo()
      } else {
        for i in file.indices where file[i].until == nil { typed[i] = file[i].text.count }
      }
    }
  }

  // MARK: Preview (this is Navbar's body, one step at a time)

  var previewPane: some View {
    ZStack {
      Color.black      // an empty page in dark mode (the glass bar is meant for a dark page)
        .opacity(zoomed ? 0 : 1)
      if shown >= .skeleton {
        ZStack {
          if shown >= .navy { navy.ignoresSafeArea() }
          bar
        }
      }
    }
    .environment(\.colorScheme, .dark)
    .clipShape(.rect(cornerRadius: 20))
  }

  var bar: some View {
    HStack(spacing: 2) {
      ForEach(tabs, id: \.self) { tab in
        tabButton(tab)
      }
    }
    .when(shown >= .glass) {
      $0.padding(6)
        .background(.ultraThinMaterial, in: .capsule)
    }
    .when(shown >= .border) { $0.overlay(Capsule().stroke(.gray, lineWidth: 0.5)) }
    .when(shown >= .shadow) { $0.shadow(color: .black, radius: 15, y: 10) }
  }

  @ViewBuilder
  func tabButton(_ tab: String) -> some View {
    if shown >= .text {
      Text(tab)
        .when(shown >= .textStyle) {
          $0.font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .when(shown >= .pillUse) {
          $0.background {
            if selected == tab { pill }
          }
        }
        .when(shown >= .taps) {
          $0.onTapGesture {
            withAnimation(.bouncy) {
              selected = tab
            }
          }
        }
        .spot(tab, in: $spots)
    }
  }

  var pill: some View {
    Capsule()
      .fill(.cyan.gradient)
      .shadow(color: .cyan, radius: 8)
      .matchedGeometryEffect(id: "pill", in: ns)
  }

  // MARK: Editor (drawn by XcodeEditor in XcodeLook.swift)

  var editor: some View {
    let rows = file.indices.filter { typed[$0] != nil }.map { i in
      EditorRow(id: i, text: String(file[i].text.prefix(typed[i]!)), dying: dying.contains(i))
    }
    let stage = file.indices.contains(current) ? file[current].step.stage : shown.stage
    return XcodeEditor(project: "NavbarLive", fileStem: "Navbar",
                       status: stage > 0 ? "\(stage)/4 · \(stageNames[stage])" : nil,
                       rows: rows, current: current, lastKey: lastKey, dark: true)
  }

  // MARK: Demo (-demo launch argument)

  var fingerDot: some View {
    Circle()
      .fill(.white.opacity(0.28))
      .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1.5))
      .frame(width: 34, height: 34)
      .scaleEffect(touchOn ? 1 : 1.5)
      .opacity(touchOn ? 1 : 0)
      .position(touch)
      .ignoresSafeArea()
      .allowsHitTesting(false)
  }

  // Every pause in the demo is stretched by `pace` (1.3 = 30% slower, so the typing is readable).
  let pace = 1.3

  func wait(_ seconds: Double) async {
    try? await Task.sleep(for: .seconds(seconds * pace))
  }

  // Type one line, a few letters at a time.
  func type(_ i: Int) async {
    let text = file[i].text
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

  // Show the finger dot on a spot, then run the tap.
  func demoTap(_ key: String, _ press: () -> Void) async {
    guard let spot = spots[key] else { return }
    touch = spot
    withAnimation(.easeOut(duration: 0.15)) { touchOn = true }
    await wait(0.2)
    press()
    await wait(0.3)
    withAnimation(.easeOut(duration: 0.25)) { touchOn = false }
  }

  func runDemo() async {
    shown = .start
    await wait(1.0)

    // 1. Type every step, then let the preview catch up.
    for step in Step.allCases where step != .start {
      let old = file.indices.filter { file[$0].until == step }
      if !old.isEmpty {                        // lines this step replaces: select, delete
        current = -1
        dying = Set(old)
        await wait(0.35)
        for i in old { typed[i] = nil }
        dying = []
        await wait(0.1)
      }
      for i in file.indices where file[i].step == step {
        await type(i)
      }
      shown = step                              // the preview snaps, like a live preview
      await wait(step == .skeleton ? 0.15 : 0.45)
    }
    current = -1
    await wait(1.0)

    // 2. Zoom to the finished navbar.
    withAnimation(.spring(duration: 1.0, bounce: 0.1)) { zoomed = true }
    await wait(1.2)

    // 3. Tap through the tabs, like the original. Each tap runs the code's own action.
    for tab in ["About", "Services", "Projects", "Contact", "Home"] {
      await demoTap(tab) {
        withAnimation(.bouncy) { selected = tab }
      }
      await wait(0.55)
    }
  }
}

#Preview { ContentView() }
