import SwiftUI
import AppKit

// KOI ON A DUAL-MONITOR MAC SETUP
// The same koi as FishProof (Fish.swift is copied unchanged: same spine math, same drawing).
// Here it wanders by itself across two Mac displays. The pond is one continuous space behind
// both screens, so the fish slips behind the bezels between them and comes out the other side.
// Renders every frame offline (no real-time clock) and pipes them to ffmpeg.
// Usage: ./koi <out.mp4>

let W = 1920.0, H = 1080.0
let fps = 60.0
let period = 16.0            // one wander loop, in seconds
let fade = 1.0               // extra second, crossfaded onto the start so the video loops
let k = 1.6                  // the fish is drawn 1.6x its phone size

// The two screens (16:9), in video pixels.
let screenL = CGRect(x: 74, y: 220, width: 868, height: 488)
let screenR = CGRect(x: 978, y: 220, width: 868, height: 488)
let bezel = 10.0

// Where the fish is heading, `t` seconds in: a point gliding at one steady speed around a closed,
// rounded loop over both screens. Steady speed matters: the fish chases this point, so if the point
// slowed down at a turn the fish would catch up and stall. The loop keeps well clear of the screen edges.
let waypoints: [CGPoint] = [
    CGPoint(x: 330, y: 350), CGPoint(x: 600, y: 310), CGPoint(x: 900, y: 400), CGPoint(x: 1220, y: 530),
    CGPoint(x: 1500, y: 570), CGPoint(x: 1670, y: 470), CGPoint(x: 1600, y: 340), CGPoint(x: 1380, y: 320),
    CGPoint(x: 1100, y: 420), CGPoint(x: 800, y: 550), CGPoint(x: 480, y: 580), CGPoint(x: 260, y: 480),
]

// The loop as many small steps (a closed Catmull-Rom curve through the waypoints),
// plus how far along the loop each step is, so we can walk it at a constant speed.
let loopPoints: [CGPoint] = {
    var pts: [CGPoint] = []
    let n = waypoints.count
    for i in 0..<n {
        let p0 = waypoints[(i - 1 + n) % n], p1 = waypoints[i], p2 = waypoints[(i + 1) % n], p3 = waypoints[(i + 2) % n]
        for step in 0..<200 {
            let u = Double(step) / 200
            func spline(_ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
                0.5 * (2 * b + (c - a) * u + (2 * a - 5 * b + 4 * c - d) * u * u + (3 * b - a - 3 * c + d) * u * u * u)
            }
            pts.append(CGPoint(x: spline(p0.x, p1.x, p2.x, p3.x), y: spline(p0.y, p1.y, p2.y, p3.y)))
        }
    }
    return pts
}()
let loopDistance: [Double] = {
    var d = [0.0]
    for i in 1...loopPoints.count {
        let a = loopPoints[i - 1], b = loopPoints[i % loopPoints.count]
        d.append(d[i - 1] + hypot(b.x - a.x, b.y - a.y))
    }
    return d
}()

func pondTarget(_ t: Double) -> CGPoint {
    let length = loopDistance.last!
    let want = (t / period).truncatingRemainder(dividingBy: 1) * length
    var lo = 0, hi = loopPoints.count
    while hi - lo > 1 {                       // find the step that contains distance `want`
        let mid = (lo + hi) / 2
        if loopDistance[mid] <= want { lo = mid } else { hi = mid }
    }
    let a = loopPoints[lo], b = loopPoints[hi % loopPoints.count]
    let u = (want - loopDistance[lo]) / max(loopDistance[hi] - loopDistance[lo], 0.0001)
    return CGPoint(x: a.x + (b.x - a.x) * u, y: a.y + (b.y - a.y) * u)
}

func label(_ s: String, _ size: Double, _ weight: Font.Weight = .regular, _ opacity: Double = 0.92) -> Text {
    Text(s).font(.system(size: size, weight: weight)).foregroundColor(.white.opacity(opacity))
}
func symbol(_ name: String, _ size: Double, _ opacity: Double = 0.92) -> Text {
    Text(Image(systemName: name)).font(.system(size: size, weight: .medium)).foregroundColor(.white.opacity(opacity))
}

// The Mac menu bar across the top of one screen.
func drawMenuBar(_ r: CGRect, in context: GraphicsContext) {
    let bar = CGRect(x: r.minX, y: r.minY, width: r.width, height: 22)
    context.fill(Path(bar), with: .color(.black.opacity(0.30)))
    var x = r.minX + 16
    context.draw(symbol("apple.logo", 12.5), at: CGPoint(x: x, y: bar.midY - 0.5), anchor: .leading)
    x += 26
    for (i, name) in ["Xcode", "File", "Edit", "View", "Find", "Navigate", "Editor", "Product", "Window", "Help"].enumerated() {
        let text = context.resolve(label(name, 11.5, i == 0 ? .bold : .regular))
        context.draw(text, at: CGPoint(x: x, y: bar.midY), anchor: .leading)
        x += text.measure(in: CGSize(width: 400, height: 40)).width + 15
    }
    var rx = r.maxX - 14
    let clock = context.resolve(label("Sun Nov 22  9:41 AM", 11.5))
    context.draw(clock, at: CGPoint(x: rx, y: bar.midY), anchor: .trailing)
    rx -= clock.measure(in: CGSize(width: 400, height: 40)).width + 14
    for name in ["switch.2", "magnifyingglass", "wifi", "battery.100percent"] {
        context.draw(symbol(name, 11.5), at: CGPoint(x: rx, y: bar.midY), anchor: .trailing)
        rx -= name == "wifi" ? 30 : 26
    }
}

// The Dock: a glass tray of app tiles (generic tiles, no real app icons).
func drawDock(_ r: CGRect, in context: GraphicsContext) {
    let tiles: [(String, Color, Color)] = [
        ("face.smiling", Color(red: 0.35, green: 0.75, blue: 1.0), Color(red: 0.10, green: 0.45, blue: 0.95)),
        ("safari.fill", Color(red: 0.95, green: 0.97, blue: 1.0), Color(red: 0.70, green: 0.78, blue: 0.90)),
        ("envelope.fill", Color(red: 0.35, green: 0.70, blue: 1.0), Color(red: 0.10, green: 0.40, blue: 0.95)),
        ("music.note", Color(red: 1.0, green: 0.40, blue: 0.45), Color(red: 0.95, green: 0.15, blue: 0.30)),
        ("photo.fill", Color(red: 1.0, green: 0.80, blue: 0.35), Color(red: 0.95, green: 0.50, blue: 0.20)),
        ("hammer.fill", Color(red: 0.30, green: 0.65, blue: 1.0), Color(red: 0.08, green: 0.30, blue: 0.85)),
        ("swift", Color(red: 1.0, green: 0.55, blue: 0.25), Color(red: 0.95, green: 0.30, blue: 0.15)),
        ("gearshape.fill", Color(red: 0.62, green: 0.64, blue: 0.68), Color(red: 0.36, green: 0.38, blue: 0.42)),
    ]
    let tile = 36.0, space = 8.0, pad = 7.0
    let width = Double(tiles.count) * tile + Double(tiles.count - 1) * space + pad * 2
    let tray = CGRect(x: r.midX - width / 2, y: r.maxY - tile - pad * 2 - 6, width: width, height: tile + pad * 2)
    let trayPath = Path(roundedRect: tray, cornerRadius: 14, style: .continuous)
    context.fill(trayPath, with: .color(.white.opacity(0.13)))
    context.stroke(trayPath, with: .color(.white.opacity(0.22)), lineWidth: 0.8)
    for (i, (name, top, bottom)) in tiles.enumerated() {
        let box = CGRect(x: tray.minX + pad + Double(i) * (tile + space), y: tray.minY + pad, width: tile, height: tile)
        context.fill(Path(roundedRect: box, cornerRadius: 9, style: .continuous),
                     with: .linearGradient(Gradient(colors: [top, bottom]),
                                           startPoint: CGPoint(x: box.midX, y: box.minY), endPoint: CGPoint(x: box.midX, y: box.maxY)))
        let dark = name == "safari.fill"
        context.draw(Text(Image(systemName: name)).font(.system(size: 18, weight: .semibold))
                        .foregroundColor(dark ? Color(red: 0.1, green: 0.4, blue: 0.9) : .white),
                     at: CGPoint(x: box.midX, y: box.midY))
    }
    // The little "running" dot under Xcode's tile.
    let dotX = tray.minX + pad + 5 * (tile + space) + tile / 2
    context.fill(Path(ellipseIn: CGRect(x: dotX - 1.5, y: tray.maxY - 4.5, width: 3, height: 3)), with: .color(.white.opacity(0.8)))
}

// One display: aluminium stand, black bezel. (The picture on the screen is drawn separately.)
func drawDisplayBody(_ screen: CGRect, in context: GraphicsContext) {
    let outer = screen.insetBy(dx: -bezel, dy: -bezel)
    let metalTop = Color(red: 0.74, green: 0.76, blue: 0.80), metalLow = Color(red: 0.42, green: 0.44, blue: 0.48)
    // Stand: a neck and a flat foot.
    let neck = CGRect(x: outer.midX - 70, y: outer.maxY - 6, width: 140, height: 92)
    context.fill(Path(neck), with: .linearGradient(Gradient(colors: [metalLow, metalTop, metalLow]),
                                                   startPoint: CGPoint(x: neck.minX, y: 0), endPoint: CGPoint(x: neck.maxX, y: 0)))
    context.fill(Path(neck), with: .linearGradient(Gradient(colors: [.black.opacity(0.55), .clear]),
                                                   startPoint: CGPoint(x: 0, y: neck.minY), endPoint: CGPoint(x: 0, y: neck.minY + 40)))
    let foot = CGRect(x: outer.midX - 120, y: neck.maxY - 2, width: 240, height: 11)
    context.fill(Path(roundedRect: foot, cornerRadius: 3), with: .linearGradient(Gradient(colors: [metalTop, metalLow]),
                                                   startPoint: CGPoint(x: 0, y: foot.minY), endPoint: CGPoint(x: 0, y: foot.maxY)))
    // Bezel, with a thin metal edge.
    let frame = Path(roundedRect: outer, cornerRadius: 15, style: .continuous)
    context.fill(Path(roundedRect: outer.insetBy(dx: -1.5, dy: -1.5), cornerRadius: 16.5, style: .continuous), with: .color(metalLow))
    context.fill(frame, with: .color(Color(red: 0.02, green: 0.02, blue: 0.03)))
}


// Keyboard and trackpad on the desk, seen from the front (so they look flattened).
func drawDeskGear(in context: GraphicsContext) {
    let metalTop = Color(red: 0.70, green: 0.72, blue: 0.76), metalLow = Color(red: 0.40, green: 0.42, blue: 0.46)
    func slab(_ r: CGRect) {
        context.drawLayer { shadow in
            shadow.addFilter(.blur(radius: 10))
            shadow.fill(Path(roundedRect: r.offsetBy(dx: 0, dy: 10), cornerRadius: 8), with: .color(.black.opacity(0.5)))
        }
        context.fill(Path(roundedRect: r.offsetBy(dx: 0, dy: 4), cornerRadius: 8, style: .continuous), with: .color(metalLow))
        context.fill(Path(roundedRect: r, cornerRadius: 8, style: .continuous), with: .linearGradient(
            Gradient(colors: [metalTop, metalLow]), startPoint: CGPoint(x: 0, y: r.minY), endPoint: CGPoint(x: 0, y: r.maxY + 30)))
    }
    let keyboard = CGRect(x: 640, y: 905, width: 470, height: 86)
    slab(keyboard)
    let rows = 5, cols = 15, pad = 8.0, space = 3.5
    let keyW = (keyboard.width - pad * 2 - Double(cols - 1) * space) / Double(cols)
    let keyH = (keyboard.height - pad * 2 - Double(rows - 1) * space) / Double(rows)
    for row in 0..<rows {
        var x = keyboard.minX + pad
        var col = 0
        while col < cols {
            let span = (row == rows - 1 && col == 4) ? 6 : 1          // the space bar
            let w = Double(span) * keyW + Double(span - 1) * space
            let key = CGRect(x: x, y: keyboard.minY + pad + Double(row) * (keyH + space), width: w, height: keyH)
            context.fill(Path(roundedRect: key, cornerRadius: 2.5), with: .color(Color(red: 0.93, green: 0.94, blue: 0.96).opacity(0.92)))
            x += w + space
            col += span
        }
    }
    let trackpad = CGRect(x: 1136, y: 905, width: 150, height: 86)
    slab(trackpad)
    context.fill(Path(roundedRect: trackpad.insetBy(dx: 1.5, dy: 1.5), cornerRadius: 7, style: .continuous),
                 with: .color(Color(red: 0.86, green: 0.87, blue: 0.90).opacity(0.9)))
}

struct Frame: View {
    let t: Double
    let fish: Fish

    var body: some View {
        Canvas { context, size in
            // The room: a dark wall, a glow from the screens, a desk.
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [Color(red: 0.02, green: 0.04, blue: 0.09), Color(red: 0.03, green: 0.07, blue: 0.13)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            context.drawLayer { glow in
                glow.addFilter(.blur(radius: 90))
                glow.fill(Path(CGRect(x: 120, y: 180, width: 1680, height: 560)),
                          with: .color(Color(red: 0.10, green: 0.45, blue: 0.60).opacity(0.38)))
            }
            let desk = CGRect(x: 0, y: 818, width: size.width, height: size.height - 818)
            context.fill(Path(desk), with: .linearGradient(
                Gradient(colors: [Color(red: 0.07, green: 0.09, blue: 0.13), Color(red: 0.03, green: 0.04, blue: 0.07)]),
                startPoint: CGPoint(x: 0, y: desk.minY), endPoint: CGPoint(x: 0, y: desk.maxY)))
            context.fill(Path(CGRect(x: 0, y: desk.minY, width: size.width, height: 1.5)), with: .color(.white.opacity(0.10)))
            context.drawLayer { glow in      // the screens' light falling on the desk
                glow.clip(to: Path(desk))
                glow.addFilter(.blur(radius: 60))
                glow.fill(Path(ellipseIn: CGRect(x: 200, y: 790, width: 1520, height: 170)),
                          with: .color(Color(red: 0.10, green: 0.50, blue: 0.62).opacity(0.30)))
            }

            drawDeskGear(in: context)

            context.draw(Text("Koi").font(.system(size: 54, weight: .semibold)).foregroundColor(.white)
                         + Text(" · ").font(.system(size: 54, weight: .semibold)).foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.2))
                         + Text("SwiftUI").font(.system(size: 54, weight: .semibold)).foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.2)),
                         at: CGPoint(x: size.width / 2, y: 108))

            for screen in [screenL, screenR] { drawDisplayBody(screen, in: context) }

            // The picture: water on each screen, then the one fish, visible only through the two screens.
            var both = Path()
            for screen in [screenL, screenR] { both.addRoundedRect(in: screen, cornerSize: CGSize(width: 5, height: 5)) }
            context.drawLayer { glass in
                glass.clip(to: both)
                for (i, screen) in [screenL, screenR].enumerated() {
                    glass.drawLayer { water in
                        water.clip(to: Path(screen))
                        water.translateBy(x: screen.minX, y: screen.minY)
                        water.scaleBy(x: k, y: k)
                        drawWater(t + Double(i) * 37, CGSize(width: screen.width / k, height: screen.height / k), in: water)
                    }
                }
                glass.drawLayer { pond in
                    pond.scaleBy(x: k, y: k)
                    drawFish(fish, in: pond)
                }
                for screen in [screenL, screenR] { drawMenuBar(screen, in: glass) }
                drawDock(screenL, in: glass)
                // A faint diagonal sheen on the glass.
                for screen in [screenL, screenR] {
                    glass.fill(Path(screen), with: .linearGradient(
                        Gradient(colors: [.white.opacity(0.05), .clear]),
                        startPoint: CGPoint(x: screen.minX, y: screen.minY), endPoint: CGPoint(x: screen.midX, y: screen.maxY)))
                }
            }
        }
        .frame(width: W, height: H)
    }
}

// MARK: - Render every frame and pipe it to ffmpeg

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "koi-raw.mp4"
let ffmpeg = Process()
ffmpeg.executableURL = URL(fileURLWithPath: "/usr/bin/env")
ffmpeg.arguments = ["ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", "\(Int(W))x\(Int(H))",
                    "-r", "\(Int(fps))", "-i", "-", "-c:v", "libx264", "-crf", "12", "-preset", "fast", "-pix_fmt", "yuv420p", out]
let pipe = Pipe()
ffmpeg.standardInput = pipe
try ffmpeg.run()

@MainActor func renderAll() {
    let bitmap = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: Int(W) * 4,
                           space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let stage = CGSize(width: W / k, height: H / k)
    let warmUp = 3                     // loops swum before recording, so the fish has settled into its path

    // Move the fish one frame. `beatScale` stretches the tail beat a hair (see below).
    func advance(_ fish: Fish, _ n: Int, beatScale: Double) {
        let t = Double(n) / fps
        let target = pondTarget(t)
        let before = fish.beat
        fish.update(target: CGPoint(x: target.x / k, y: target.y / k), time: 1000 + t, stage: stage)
        fish.beat = before + (fish.beat - before) * beatScale
    }

    // For a seamless loop the tail must finish a whole number of beats per loop.
    // Trial swim: count the beats in one settled loop, then stretch them to the nearest whole number.
    let trial = Fish()
    var beatAtLoopStart = 0.0
    for n in 0..<Int(Double(warmUp + 1) * period * fps) {
        if n == Int(Double(warmUp) * period * fps) { beatAtLoopStart = trial.beat }
        advance(trial, n, beatScale: 1)
    }
    let beats = (trial.beat - beatAtLoopStart) / (2 * .pi)
    let beatScale = beats.rounded() / beats

    let fish = Fish()
    let first = Int(Double(warmUp) * period * fps)
    let total = first + Int((period + fade) * fps)
    var last = CGPoint.zero, slowest = 1e9, fastest = 0.0
    var spineAtStart: [CGPoint] = [], seam = 0.0
    for n in 0..<total {
        advance(fish, n, beatScale: beatScale)
        guard n >= first else { last = fish.spine[0]; continue }
        let t = Double(n - first) / fps
        let head = fish.spine[0]
        let v = hypot(head.x - last.x, head.y - last.y) * fps * k
        slowest = min(slowest, v); fastest = max(fastest, v); last = head
        if n == first { spineAtStart = fish.spine }
        if n == first + Int(period * fps) {
            seam = zip(spineAtStart, fish.spine).map { hypot($0.x - $1.x, $0.y - $1.y) * k }.max()!
        }
        let renderer = ImageRenderer(content: Frame(t: t, fish: fish))
        renderer.scale = 1
        guard let image = renderer.cgImage else { fatalError("no image at frame \(n)") }
        bitmap.draw(image, in: CGRect(x: 0, y: 0, width: W, height: H))
        pipe.fileHandleForWriting.write(Data(bytes: bitmap.data!, count: Int(W) * Int(H) * 4))
        if n % 120 == 0 { print("frame \(n)/\(total)") }
    }
    print("head speed \(Int(slowest))-\(Int(fastest)) px/s, \(beats) beats per loop, fish differs by \(seam) px between loop start and end")
}
MainActor.assumeIsolated { renderAll() }
try pipe.fileHandleForWriting.close()
ffmpeg.waitUntilExit()
print("wrote \(out)")
