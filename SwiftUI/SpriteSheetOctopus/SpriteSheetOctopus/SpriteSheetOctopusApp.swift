import SwiftUI

@main
struct SpriteSheetOctopusApp: App {
  var body: some Scene {
    WindowGroup {
      if CommandLine.arguments.contains("-live") { LiveView() } else { ReelView { ReelCanvas() } }
    }
  }
}

// Live mode: drag anywhere and the octopus looks at your finger. The screen point maps into the
// reel's coordinates (360 pt of screen = the reel's 700 pt range), then the same Show does the rest.
struct LiveView: View {
  @State private var show = Show()
  @State private var open = makeSheet(blink: false)
  @State private var shut = makeSheet(blink: true)
  var body: some View {
    GeometryReader { geo in
      let mid = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
      ZStack {
        hex(0x0D1117)
        BlendedSprite(sheet: show.blink ? shut : open, colF: show.colF, rowF: show.rowF)
          .scaleEffect(0.6)
          .frame(width: CELL * 0.6, height: CELL * 0.6)
      }
      .contentShape(Rectangle())
      .gesture(DragGesture(minimumDistance: 0).onChanged { v in
        show.finger = CGPoint(x: SPRITE_C.x + (v.location.x - mid.x) * 700 / 360,
                              y: SPRITE_C.y + (v.location.y - mid.y) * 700 / 360)
      })
      .task {
        show.finger = SPRITE_C
        show.look = SPRITE_C
        Task { await show.smooth() }
        while !Task.isCancelled {
          try? await Task.sleep(for: .seconds(Double.random(in: 2...5)))
          show.blink = true
          try? await Task.sleep(for: .milliseconds(120))
          show.blink = false
        }
      }
    }
    .ignoresSafeArea()
  }
}

// The Sprite Sheet reel: one image holds 19 × 19 poses of our octopus; a second sheet holds the same with eyes shut.
// The app shows one 500 × 500 cell of it: the finger picks the column and row, and the sheet slides
// behind a clipped frame (CSS: translate on a background-image). Then a debug view shows the whole
// sheet sliding, with the active cell boxed in green. Sprite runs exactly the code in the post.

let CELL: CGFloat = 500
let N = 19 // poses per side

struct Sprite: View {
  let sheet: UIImage
  let col: Int
  let row: Int
  var body: some View {
    Image(uiImage: sheet)
      .offset(x: -CGFloat(col) * CELL, y: -CGFloat(row) * CELL)
      .frame(width: CELL, height: CELL, alignment: .topLeading)
      .clipped()
  }
}

// Fades only in the middle 30% between two cells, so each pose stays crisp most of the time.
func quick(_ t: Double) -> Double { min(1, max(0, (t - 0.35) / 0.3)) }

// Between two cells, show both: the nearer one stronger. Four neighbors, blended across then down.
struct BlendedSprite: View {
  let sheet: UIImage
  let colF: Double
  let rowF: Double
  var body: some View {
    let c = min(Int(colF), N - 2), r = min(Int(rowF), N - 2)
    let x = quick(colF - Double(c)), y = quick(rowF - Double(r))
    let r0 = r
    ZStack {
      ZStack {
        Sprite(sheet: sheet, col: c, row: r0)
        Sprite(sheet: sheet, col: c + 1, row: r0).opacity(x)
      }
      ZStack {
        Sprite(sheet: sheet, col: c, row: r0 + 1)
        Sprite(sheet: sheet, col: c + 1, row: r0 + 1).opacity(x)
      }
      .compositingGroup()
      .opacity(y)
    }
  }
}

// MARK: - The mascot + the sheet (support code)

// Our octopus: white dome, dark visor face, white eyes, four stubby arms.
// `look` runs −1…1 on each axis; the face and eyes slide that way to fake a head turn.
struct Octo: View {
  let look: CGPoint
  let blink: Bool
  var body: some View {
    let dx = look.x, dy = look.y
    ZStack {
      // arms (they lag behind the head a little)
      ForEach(0 ..< 4, id: \.self) { i in
        let x = [-78.0, -28, 28, 78][i]
        Capsule().fill(hex(0xE6EDF3))
          .frame(width: 46, height: 140)
          .rotationEffect(.degrees([16.0, 5, -5, -16][i] - dx * 10), anchor: .top)
          .offset(x: x - dx * 6, y: 72 - dy * 2) // tops start inside the head, so they stay attached
      }
      // head
      Ellipse().fill(LinearGradient(colors: [.white, hex(0xD0D7DE)], startPoint: .top, endPoint: .bottom))
        .frame(width: 236 - abs(dx) * 14, height: 214 - abs(dy) * 8)
        .offset(x: dx * 10, y: -14 + dy * 8)
      // visor face
      ZStack {
        Capsule().fill(hex(0x1F2328)).frame(width: 168, height: 104)
        HStack(spacing: 40) {
          ForEach(0 ..< 2, id: \.self) { _ in
            Capsule().fill(.white)
              .frame(width: 26, height: blink ? 5 : 40)
              .overlay(alignment: .top) { if !blink { Circle().fill(hex(0x1F2328)).frame(width: 9).offset(x: 4 + dx * 3, y: 6 + dy * 3) } }
          }
        }
        .offset(x: dx * 16, y: dy * 10)
      }
      .scaleEffect(x: 1 - abs(dx) * 0.22, y: 1 - abs(dy) * 0.16)
      .offset(x: dx * 52, y: -8 + dy * 40)
    }
    .frame(width: 360, height: 360)
    .scaleEffect(CELL / 360)
    .frame(width: CELL, height: CELL)
  }
}

// 19 columns (look left → right) × 19 rows (look up → down). One sheet with eyes open, one shut.
struct SheetGrid: View {
  let blink: Bool
  var body: some View {
    VStack(spacing: 0) {
      ForEach(0 ..< N, id: \.self) { r in
        HStack(spacing: 0) {
          ForEach(0 ..< N, id: \.self) { c in
            Octo(look: CGPoint(x: Double(c) / Double(N / 2) - 1, y: Double(r) / Double(N / 2) - 1), blink: blink)
          }
        }
      }
    }
  }
}

@MainActor func makeSheet(blink: Bool) -> UIImage {
  let r = ImageRenderer(content: SheetGrid(blink: blink))
  r.scale = 0.6 // 300 px cells: each 5700 × 5700 sheet stays under the 8192 px image limit
  return r.uiImage!
}

// MARK: - The show (fake finger + camera + timing, 14 s loop)

let SCREEN = CGSize(width: 1000, height: 2228)
let K: CGFloat = 0.774
let SPRITE_C = CGPoint(x: 500, y: 1040) // sprite center on the screen

@Observable final class Show {
  var finger = CGPoint(x: 500, y: 1500)
  var look = CGPoint(x: 500, y: 1500) // where the octopus looks: eases toward the finger (smoothing)
  var fingerOn = false
  var blink = false
  var debug = false
  var zoom: CGFloat = 0.8
  var tilt: Double = 24
  // the finger picks the cell: 13 steps across 700 pt wide and tall, centered on the sprite
  // where the finger sits between cells, as a fraction (0…N−1): the whole part picks the cell, the rest blends
  var colF: Double { min(Double(N - 1), max(0, ((look.x - SPRITE_C.x) / 700 + 0.5) * Double(N) - 0.5)) }
  var rowF: Double { min(Double(N - 1), max(0, ((look.y - SPRITE_C.y) / 700 + 0.5) * Double(N) - 0.5)) }
  var col: Int { Int(colF.rounded()) }
  var row: Int { Int(rowF.rounded()) }

  func camera(zoom z: CGFloat, tilt t: Double, _ dur: Double) {
    withAnimation(.smooth(duration: dur)) { zoom = z; tilt = t }
  }

  // moves the finger frame by frame (so col/row update all the way)
  func glide(_ t0: ContinuousClock.Instant, from s: Double, to e: Double, _ p: CGPoint) async {
    let clock = ContinuousClock()
    let a = finger
    while true {
      let t = (clock.now - t0) / .seconds(1)
      let q = min(1, max(0, (t - s) / (e - s)))
      let k = q < 0.5 ? 2 * q * q : 1 - pow(-2 * q + 2, 2) / 2
      finger = CGPoint(x: a.x + (p.x - a.x) * k, y: a.y + (p.y - a.y) * k)
      if q >= 1 { break }
      try? await clock.sleep(for: .milliseconds(16))
    }
  }

  func blinkLoop(_ t0: ContinuousClock.Instant) async {
    let clock = ContinuousClock()
    for (s, d) in [(2.4, 0.12), (5.2, 0.1), (5.42, 0.1), (8.6, 0.12), (11.3, 0.12)] {
      try? await clock.sleep(until: t0 + .seconds(s)); blink = true
      try? await clock.sleep(until: t0 + .seconds(s + d)); blink = false
    }
  }

  // smoothing: every frame, close 12% of the gap between where it looks and the finger
  func smooth() async {
    let clock = ContinuousClock()
    while !Task.isCancelled {
      look.x += (finger.x - look.x) * 0.12
      look.y += (finger.y - look.y) * 0.12
      try? await clock.sleep(for: .milliseconds(16))
    }
  }

  func run() async {
    Task { await smooth() }
    let clock = ContinuousClock()
    let now = Date.timeIntervalSinceReferenceDate
    try? await clock.sleep(for: .seconds(14 - now.truncatingRemainder(dividingBy: 14)))
    while !Task.isCancelled {
      let t0 = clock.now
      func at(_ s: Double) async { try? await clock.sleep(until: t0 + .seconds(s)) }
      finger = CGPoint(x: 500, y: 1500); debug = false
      Task { await blinkLoop(t0) }
      camera(zoom: 1, tilt: 0, 1.3)
      Task { await at(1.6); self.camera(zoom: 1.3, tilt: 0, 1.0); await at(7.2); self.camera(zoom: 1, tilt: 0, 1.0) }
      await at(0.9)
      withAnimation(.smooth(duration: 0.3)) { fingerOn = true }
      let path: [(Double, CGPoint)] = [
        (1.8, CGPoint(x: 200, y: 1060)), (2.8, CGPoint(x: 240, y: 700)), (3.6, CGPoint(x: 520, y: 640)),
        (4.4, CGPoint(x: 800, y: 700)), (5.3, CGPoint(x: 820, y: 1120)), (6.2, CGPoint(x: 760, y: 1420)),
        (7.0, CGPoint(x: 300, y: 1440)),
        // debug view: the whole sheet slides behind the frame
        (8.4, CGPoint(x: 160, y: 1000)), (9.3, CGPoint(x: 500, y: 680)), (10.2, CGPoint(x: 840, y: 1040)),
        (11.2, CGPoint(x: 520, y: 1420)), (12.0, CGPoint(x: 500, y: 1500)),
      ]
      var s = 1.0
      for (e, p) in path {
        if e == 8.4 { withAnimation(.smooth(duration: 0.5)) { debug = true } }
        await glide(t0, from: s, to: e, p)
        s = e + 0.08
        await at(s)
      }
      withAnimation(.smooth(duration: 0.4)) { debug = false; fingerOn = false }
      camera(zoom: 0.8, tilt: 24, 1.3)
      await at(14.0)
    }
  }
}

// MARK: - Screen + phone

struct StatusBar: View {
  var body: some View {
    HStack {
      Text("9:41").font(.system(size: 42, weight: .semibold))
      Spacer()
      HStack(spacing: 14) {
        Image(systemName: "cellularbars"); Image(systemName: "wifi"); Image(systemName: "battery.100percent")
      }
      .font(.system(size: 34, weight: .semibold))
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 84)
    .frame(width: SCREEN.width, height: 140)
  }
}

struct GridPaper: View {
  var body: some View {
    Canvas { ctx, size in
      var p = Path()
      for x in stride(from: 0.0, through: size.width, by: 62.5) { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)) }
      for y in stride(from: 0.0, through: size.height, by: 62.5) { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)) }
      ctx.stroke(p, with: .color(.white.opacity(0.05)), lineWidth: 1.5)
    }
  }
}

struct AppScreen: View {
  var show: Show
  let open: UIImage
  let shut: UIImage
  var body: some View {
    let sheet = show.blink ? shut : open
    ZStack(alignment: .topLeading) {
      hex(0x0D1117)
      GridPaper()
      StatusBar()
      // debug: the whole sheet, ghosted, slid so the active cell sits under the frame
      Image(uiImage: sheet)
        .opacity(show.debug ? 0.22 : 0)
        .offset(x: SPRITE_C.x - CELL / 2 - CGFloat(show.col) * CELL, y: SPRITE_C.y - CELL / 2 - CGFloat(show.row) * CELL)
      BlendedSprite(sheet: sheet, colF: show.colF, rowF: show.rowF)
        .offset(x: SPRITE_C.x - CELL / 2, y: SPRITE_C.y - CELL / 2)
      RoundedRectangle(cornerRadius: 8).stroke(hex(0x3FB950), lineWidth: 6)
        .frame(width: CELL, height: CELL)
        .shadow(color: hex(0x3FB950).opacity(0.7), radius: 16)
        .offset(x: SPRITE_C.x - CELL / 2, y: SPRITE_C.y - CELL / 2)
        .opacity(show.debug ? 1 : 0)
      Text("c\(show.col) · r\(show.row % N)")
        .font(.system(size: 30, weight: .semibold, design: .monospaced)).foregroundStyle(hex(0x0D1117))
        .padding(.horizontal, 16).padding(.vertical, 6)
        .background(Capsule().fill(hex(0x3FB950)))
        .frame(width: CELL)
        .offset(x: SPRITE_C.x - CELL / 2, y: SPRITE_C.y + CELL / 2 + 24)
        .opacity(show.debug ? 1 : 0)
      FingerDot()
        .scaleEffect(0.85)
        .opacity(show.fingerOn ? 1 : 0)
        .position(show.finger)
      Capsule().fill(.black).frame(width: 313, height: 92).offset(x: (SCREEN.width - 313) / 2, y: 28)
      Capsule().fill(.white.opacity(0.8)).frame(width: 340, height: 12).offset(x: (SCREEN.width - 340) / 2, y: SCREEN.height - 32)
    }
    .frame(width: SCREEN.width, height: SCREEN.height, alignment: .topLeading)
    .clipped()
  }
}

// An iPhone 17 Pro style frame: titanium edge, black bezel, side buttons.
struct Phone<Screen: View>: View {
  @ViewBuilder var screen: Screen
  var body: some View {
    let w = SCREEN.width * K, h = SCREEN.height * K
    screen
      .scaleEffect(K)
      .frame(width: w, height: h)
      .clipShape(RoundedRectangle(cornerRadius: 104, style: .continuous))
      .padding(18)
      .background(RoundedRectangle(cornerRadius: 122, style: .continuous).fill(.black))
      .overlay(RoundedRectangle(cornerRadius: 122, style: .continuous)
        .stroke(LinearGradient(colors: [hex(0x8E8E93), hex(0x3A3A3C), hex(0x8E8E93)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 6))
      .background(alignment: .topLeading) {
        ZStack(alignment: .topLeading) {
          ForEach([(300.0, 110.0), (440.0, 110.0)], id: \.0) { y, len in
            RoundedRectangle(cornerRadius: 4).fill(hex(0x48484A)).frame(width: 12, height: len).offset(x: -6, y: y)
          }
          RoundedRectangle(cornerRadius: 4).fill(hex(0x48484A)).frame(width: 12, height: 170).offset(x: w + 36 - 6, y: 380)
        }
      }
      .shadow(color: .black.opacity(0.5), radius: 40, y: 30)
  }
}

struct ReelCanvas: View {
  @State private var show = Show()
  @State private var open = makeSheet(blink: false)
  @State private var shut = makeSheet(blink: true)
  var body: some View {
    Phone { AppScreen(show: show, open: open, shut: shut) }
      .frame(width: 1080, height: 1920)
      .rotation3DEffect(.degrees(show.tilt), axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0.6)
      .scaleEffect(show.zoom)
      .frame(width: 1080, height: 1920)
      .background(LinearGradient(colors: [hex(0x18181B), hex(0x09090B)], startPoint: .top, endPoint: .bottom))
      .clipped()
      .task {
        // save the sheet so it can go in the post
        if let png = open.pngData() { try? png.write(to: URL.documentsDirectory.appending(path: "octo-sheet.png")) }
        if let png = shut.pngData() { try? png.write(to: URL.documentsDirectory.appending(path: "octo-sheet-blink.png")) }
        await show.run()
      }
  }
}
