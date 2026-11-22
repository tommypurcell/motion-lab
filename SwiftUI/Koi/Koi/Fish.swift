import SwiftUI

// FISH.SWIFT
// Everything that makes the koi. The editor in the app shows `follow`
// from this file, line for line (4-space indents so it matches).
//
// The idea in one sentence: the head turns toward your finger, and every
// segment after it is pulled along behind the one in front of it, bending
// only a little at each joint so the body stays one smooth curve.

// MARK: - Sizes

let segmentCount = 14   // points along the spine, head first
let gap = 12.5          // distance between two spine points, in points
let speed = 380.0       // top swimming speed, in points per second
let turnRate = 6.5      // how fast the head can turn, in radians per second
let maxBend = 0.36      // how far one joint may bend, in radians (about 20°)

// MARK: - Small math helpers

// An angle folded into -π…π, so "turn left 350°" becomes "turn right 10°".
func wrap(_ angle: Double) -> Double {
    atan2(sin(angle), cos(angle))
}

// Keep `value` between -limit and +limit.
func clamp(_ value: Double, _ limit: Double) -> Double {
    max(-limit, min(limit, value))
}

// MARK: - The spine

// Turn the head toward the finger, swim forward, then pull every
// segment along behind the one in front of it.
func follow(_ spine: inout [CGPoint],
            heading: inout Double,
            to target: CGPoint, dt: Double) {
    // 1. The head turns toward the finger, gently.
    let dx = target.x - spine[0].x
    let dy = target.y - spine[0].y
    let turn = wrap(atan2(dy, dx) - heading)
    heading += clamp(turn, turnRate * dt)
    let step = min(hypot(dx, dy) * 3, speed) * dt
    spine[0].x += cos(heading) * step
    spine[0].y += sin(heading) * step
    // 2. Each segment follows the one in front,
    //    but a joint can only bend so far.
    var ahead = heading
    for i in 1..<spine.count {
        let a = spine[i - 1], b = spine[i]
        let angle = atan2(a.y - b.y, a.x - b.x)
        ahead += clamp(wrap(angle - ahead), maxBend)
        spine[i].x = a.x - gap * cos(ahead)
        spine[i].y = a.y - gap * sin(ahead)
    }
}

// Which way the body points at spine point `i` (a length-1 arrow toward the head).
func forward(_ spine: [CGPoint], _ i: Int) -> CGPoint {
    let a = spine[max(i - 1, 0)]
    let b = spine[min(i + 1, spine.count - 1)]
    let len = max(hypot(a.x - b.x, a.y - b.y), 0.001)
    return CGPoint(x: (a.x - b.x) / len, y: (a.y - b.y) / len)
}

// MARK: - The fish (spine + tail beat, moved once per frame)

final class Fish {
    var spine: [CGPoint] = []
    var heading = 0.0          // which way the head points, in radians
    var swimSpeed = 0.0        // smoothed speed, in points per second
    var beat = 0.0             // tail-beat phase, in radians (goes round and round)
    var lastTime: Double? = nil

    func update(target: CGPoint, time: Double, stage: CGSize) {
        if spine.isEmpty {
            // Start straight, head at the center, facing down-right (the way it first wanders).
            heading = atan2(0.6, 0.8)
            spine = (0..<segmentCount).map { i in
                CGPoint(x: stage.width / 2 - Double(i) * gap * 0.8,
                        y: stage.height / 2 - Double(i) * gap * 0.6)
            }
        }
        let dt = min(max(time - (lastTime ?? time), 0), 1.0 / 30)   // seconds since last frame
        lastTime = time
        guard dt > 0 else { return }

        // The tail beats faster when the fish swims faster.
        let rate = 3.0 + swimSpeed * 0.042
        beat += rate * dt
        // Swimming is a side-to-side wiggle: nudge the heading back and forth with the beat.
        // The body copies the wiggle down its length, so it travels to the tail as a wave.
        heading += cos(beat) * 0.16 * rate * min(swimSpeed / 120, 1) * dt

        let before = spine[0]
        follow(&spine, heading: &heading, to: target, dt: dt)
        let moved = hypot(spine[0].x - before.x, spine[0].y - before.y) / dt
        swimSpeed += (moved - swimSpeed) * min(dt * 6, 1)   // ease, so the beat never jumps
    }
}

// MARK: - Body shape

// Half the body's width at each spine point: round head, widest just behind it,
// tapering to a thin tail.
let halfWidths: [Double] = [13.5, 17.5, 19, 19, 18.5, 17.5, 15.5, 13.5, 11.5, 9.5, 7.5, 5.8, 4.4, 3.2]

func side(_ spine: [CGPoint], _ i: Int, _ s: Double, _ w: Double) -> CGPoint {
    let f = forward(spine, i)
    return CGPoint(x: spine[i].x - f.y * s * w, y: spine[i].y + f.x * s * w)
}

// A smooth closed curve through `pts` (Catmull-Rom, turned into Bézier curves).
func smoothClosed(_ pts: [CGPoint]) -> Path {
    var p = Path()
    let n = pts.count
    p.move(to: pts[0])
    for i in 0..<n {
        let p0 = pts[(i - 1 + n) % n], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n]
        p.addCurve(to: p2,
                   control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                   control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
    }
    p.closeSubpath()
    return p
}

// One outline down the left side, round the tail and back up the right side,
// with a rounded nose in front.
func bodyPath(_ s: [CGPoint]) -> Path {
    let f = forward(s, 0)
    let w = halfWidths[0]
    var pts: [CGPoint] = []
    pts.append(CGPoint(x: s[0].x + f.x * w * 1.15, y: s[0].y + f.y * w * 1.15))   // nose
    pts.append(CGPoint(x: s[0].x + f.x * w * 0.75 + f.y * w * 0.75,
                       y: s[0].y + f.y * w * 0.75 - f.x * w * 0.75))
    for i in 0..<s.count { pts.append(side(s, i, -1, halfWidths[i])) }
    for i in (0..<s.count).reversed() { pts.append(side(s, i, 1, halfWidths[i])) }
    pts.append(CGPoint(x: s[0].x + f.x * w * 0.75 - f.y * w * 0.75,
                       y: s[0].y + f.y * w * 0.75 + f.x * w * 0.75))
    return smoothClosed(pts)
}

// MARK: - Fins

// A fin as an ellipse, hung off the body at `root` and pointing along `angle`.
func finPath(root: CGPoint, angle: Double, length: Double, width: Double) -> Path {
    Path(ellipseIn: CGRect(x: -2, y: -width / 2, width: length, height: width))
        .applying(CGAffineTransform(rotationAngle: angle)
            .concatenating(CGAffineTransform(translationX: root.x, y: root.y)))
}

// The four side fins: two pectorals near the head, two smaller pelvics further back.
// They sweep back from the body and paddle a little with the tail beat.
func sideFins(_ fish: Fish) -> [Path] {
    let s = fish.spine
    var fins: [Path] = []
    for (i, length, width, sweep) in [(2, 32.0, 14.0, 0.95), (7, 19.0, 8.5, 0.8)] {
        let f = forward(s, i)
        let back = atan2(-f.y, -f.x)
        for sd in [-1.0, 1.0] {
            let paddle = sin(fish.beat * 0.5 + sd) * 0.18
            let root = side(s, i, sd, halfWidths[i] * 0.7)
            fins.append(finPath(root: root, angle: back - sd * (sweep + paddle), length: length, width: width))
        }
    }
    return fins
}

// The forked tail: two lobes and a notch, swishing with the beat on top of the body's bend.
func tailFin(_ fish: Fish) -> (shape: Path, rays: Path) {
    let s = fish.spine
    let n = s.count - 1
    let f = forward(s, n)
    let bend = wrap(atan2(f.y, f.x) - atan2(forward(s, n - 3).y, forward(s, n - 3).x))
    let dir = atan2(-f.y, -f.x) + sin(fish.beat - 0.8) * 0.32 - bend * 0.8
    let base = s[n]
    func at(_ a: Double, _ r: Double) -> CGPoint {
        CGPoint(x: base.x + cos(dir + a) * r, y: base.y + sin(dir + a) * r)
    }
    let lag = sin(fish.beat - 1.6) * 0.12      // the tips trail behind the swish
    var p = Path()
    p.move(to: at(1.5, 4))
    p.addQuadCurve(to: at(0.62 + lag, 42), control: at(0.9, 25))
    p.addQuadCurve(to: at(0, 20), control: at(0.22, 30))
    p.addQuadCurve(to: at(-0.62 + lag, 42), control: at(-0.22, 30))
    p.addQuadCurve(to: at(-1.5, 4), control: at(-0.9, 25))
    p.closeSubpath()
    var rays = Path()
    for a in [-0.42, -0.2, 0.2, 0.42] {
        rays.move(to: at(a * 0.4, 5))
        rays.addLine(to: at(a + lag * 0.7, 34))
    }
    return (p, rays)
}

// The dorsal fin: a thin blade along the middle of the back, leaning to the outside of each bend.
func dorsalFin(_ s: [CGPoint]) -> Path {
    let range = Array(3...9)
    var left: [CGPoint] = [], right: [CGPoint] = []
    for (k, i) in range.enumerated() {
        let t = Double(k) / Double(range.count - 1)
        let h = 4 * sin(t * .pi)                       // thickest in the middle
        let f0 = forward(s, max(i - 1, 0)), f1 = forward(s, min(i + 1, s.count - 1))
        let curl = f0.x * f1.y - f0.y * f1.x             // how much the body bends here
        let lean = clamp(-curl * 16, 3.5)
        left.append(side(s, i, -1, h - lean))
        right.append(side(s, i, 1, h + lean))
    }
    return smoothClosed(left + right.reversed())
}

// MARK: - Drawing

let koiWhite = Color(red: 1.0, green: 0.97, blue: 0.93)
let koiOrange = Color(red: 1.0, green: 0.45, blue: 0.10)

// Orange patches, each a chain of circles that rides on the spine (index, side offset, radius).
let patches: [[(Int, Double, Double)]] = [
    [(1, 0, 10)],                                               // head cap (tancho)
    [(3, 6, 12.5), (4, 5, 14), (5, 2.5, 13), (6, 1, 10)],           // big saddle
    [(5, -11, 6), (6, -10, 7.5)],                                   // small spot on the other side
    [(9, -2.5, 8.5), (10, -1, 7.5), (11, 0, 5.5)],                    // tail patch
]

func drawFish(_ fish: Fish, in context: GraphicsContext) {
    let s = fish.spine
    let body = bodyPath(s)
    let fins = sideFins(fish)
    let tail = tailFin(fish)
    let outline = GraphicsContext.Shading.color(.white.opacity(0.92))
    let finFill = GraphicsContext.Shading.color(koiWhite.opacity(0.72))
    let finLine = StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)

    // Soft shadow on the pond floor, a little below and to the side.
    context.drawLayer { shadow in
        shadow.addFilter(.blur(radius: 7))
        shadow.translateBy(x: 10, y: 16)
        let dark = GraphicsContext.Shading.color(.black.opacity(0.35))
        for fin in fins { shadow.fill(fin, with: dark) }
        shadow.fill(tail.shape, with: dark)
        shadow.fill(body, with: dark)
    }

    // Fins first, so the body covers their roots.
    for fin in fins {
        context.fill(fin, with: finFill)
        context.stroke(fin, with: outline, style: finLine)
    }
    context.fill(tail.shape, with: finFill)
    context.stroke(tail.rays, with: .color(.white.opacity(0.35)), lineWidth: 0.8)
    context.stroke(tail.shape, with: outline, style: finLine)

    // Body: warm white, orange patches (clipped to the body), white outline.
    context.fill(body, with: .color(koiWhite))
    context.drawLayer { skin in
        skin.clip(to: body)
        for patch in patches {
            var blob = Path()
            for (i, off, r) in patch {
                let c = side(s, i, 1, off)
                blob.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            }
            skin.fill(blob, with: .color(koiOrange))
        }
        // A soft shine down the back.
        var back = Path()
        back.addLines(Array(s[0...8]))
        skin.addFilter(.blur(radius: 3))
        skin.stroke(back, with: .color(.white.opacity(0.25)), lineWidth: 5)
    }
    context.stroke(body, with: outline, style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))

    // Dorsal fin along the back.
    let dorsal = dorsalFin(s)
    context.fill(dorsal, with: .color(koiWhite.opacity(0.55)))
    context.stroke(dorsal, with: .color(.white.opacity(0.8)), lineWidth: 0.8)

    // Eyes: one each side of the head, with a tiny glint.
    for sd in [-1.0, 1.0] {
        let f = forward(s, 0)
        let e = side(s, 0, sd, halfWidths[0] * 0.62)
        let c = CGPoint(x: e.x + f.x * 5, y: e.y + f.y * 5)
        context.fill(Path(ellipseIn: CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6)),
                     with: .color(Color(red: 0.05, green: 0.07, blue: 0.12)))
        context.fill(Path(ellipseIn: CGRect(x: c.x - 0.4 + f.x, y: c.y - 1.6 + f.y, width: 1.4, height: 1.4)),
                     with: .color(.white.opacity(0.9)))
    }
}

// MARK: - The water: deep navy to teal, a slow caustic shimmer and a few bubbles

func drawWater(_ time: Double, _ size: CGSize, in context: GraphicsContext) {
    let rect = CGRect(origin: .zero, size: size)
    context.fill(Path(rect), with: .linearGradient(
        Gradient(colors: [Color(red: 0.03, green: 0.08, blue: 0.16), Color(red: 0.03, green: 0.17, blue: 0.22)]),
        startPoint: .zero, endPoint: CGPoint(x: size.width * 0.4, y: size.height)))

    // Caustics: a loose net of wavy light lines, drifting and blurred until they just shimmer.
    context.drawLayer { light in
        light.addFilter(.blur(radius: 4))
        var net = Path()
        for k in 0..<6 {
            let y0 = size.height * (Double(k) + 0.3 + 0.4 * sin(Double(k) * 2.1)) / 6
            net.move(to: CGPoint(x: -20, y: y0))
            for x in stride(from: -20.0, through: size.width + 20, by: 10) {
                let y = y0 + 16 * sin(x * 0.021 + time * 0.55 + Double(k) * 1.7)
                    + 7 * sin(x * 0.067 - time * 0.4 + Double(k) * 0.9)
                net.addLine(to: CGPoint(x: x, y: y))
            }
        }
        for k in 0..<6 {
            let x0 = size.width * (Double(k) + 0.3 + 0.4 * sin(Double(k) * 1.3)) / 6
            net.move(to: CGPoint(x: x0, y: -20))
            for y in stride(from: -20.0, through: size.height + 20, by: 10) {
                let x = x0 + 16 * sin(y * 0.019 - time * 0.5 + Double(k) * 2.3)
                    + 7 * sin(y * 0.061 + time * 0.35 + Double(k) * 1.1)
                net.addLine(to: CGPoint(x: x, y: y))
            }
        }
        light.stroke(net, with: .color(Color(red: 0.6, green: 0.9, blue: 1.0).opacity(0.06)), lineWidth: 4)
    }

    // Bubbles rising slowly, wobbling side to side.
    for k in 0..<7 {
        let seed = Double(k) * 1.618
        let r = 2.0 + Double(k % 3) * 1.3
        let rise = 16 + Double(k % 4) * 7
        let travel = size.height + 30
        let y = size.height + 15 - (time * rise + seed * 97).truncatingRemainder(dividingBy: travel)
        let x = size.width * (0.08 + (seed * 0.37).truncatingRemainder(dividingBy: 0.84)) + 5 * sin(time * 1.3 + seed)
        let b = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
        context.stroke(Path(ellipseIn: b), with: .color(.white.opacity(0.22)), lineWidth: 0.8)
        context.fill(Path(ellipseIn: CGRect(x: x - r * 0.45, y: y - r * 0.55, width: r * 0.5, height: r * 0.5)),
                     with: .color(.white.opacity(0.3)))
    }
}

// MARK: - Where the fish swims when nobody is touching: a slow, lazy loop.

func wander(_ time: Double, _ size: CGSize) -> CGPoint {
    CGPoint(x: size.width / 2 + size.width * 0.28 * sin(time * 0.4),
            y: size.height / 2 + size.height * 0.24 * sin(time * 0.8))
}

// MARK: - The view

struct FishStage: View {
    let finger: (Double, CGSize) -> CGPoint?   // a scripted finger for the demo (nil: none)
    @State private var fish = Fish()
    @State private var touch: CGPoint? = nil  // a real finger on the screen
    @State private var start = Date()         // when the stage appeared (the wander starts here)

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let since = time - start.timeIntervalSinceReferenceDate
                let point = touch ?? finger(time, size)
                fish.update(target: point ?? wander(since, size), time: time, stage: size)
                drawWater(since, size, in: context)
                drawFish(fish, in: context)

                // The finger: a soft gray dot, like the Simulator's touch marker.
                if let point {
                    let dot = CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30)
                    context.fill(Path(ellipseIn: dot), with: .color(.white.opacity(0.22)))
                    context.stroke(Path(ellipseIn: dot), with: .color(.white.opacity(0.5)), lineWidth: 1.5)
                }
            }
        }
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { touch = $0.location }
                .onEnded { _ in touch = nil }
        )
    }
}
