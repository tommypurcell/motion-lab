import SwiftUI

// HEART.SWIFT
// Everything that makes the particle heart. The editor in the app shows
// `heart` and `makeDots` from this file, line for line (4-space indents so it matches).

// One pink dot. Every dot starts at the center (0, 0) and flies to `target`.
struct Dot {
    var target = CGPoint.zero   // where it lands on the heart
    var delay = 0.0             // seconds it waits before it flies
    var duration = 0.0          // seconds the flight takes
    var size: CGFloat = 2       // width of the dot, in points
    var opacity = 1.0
    var color = Color.white
}

let pink = Color(hex: 0xF472B6)
let rose = Color(hex: 0xFB7185)

// Our helper: a small random nudge. Adding two randoms keeps most dots near the line,
// so the outline is thick in the middle and soft at the edges.
func jitter() -> Double {
    .random(in: -5...5) + .random(in: -5...5)
}

// Our helper: the `t` for each dot, so the dots are spread evenly by distance.
// (Even steps in t would bunch up at the top dip and the tip, where the curve moves slowly.)
func evenSteps(count: Int) -> [Double] {
    // 1. Walk the curve in tiny steps and add up the distance so far.
    let n = 20_000
    var lengths = [0.0]
    for k in 1...n {
        let a = heart(Double(k - 1) / Double(n) * 2 * .pi)
        let b = heart(Double(k) / Double(n) * 2 * .pi)
        lengths.append(lengths[k - 1] + hypot(b.x - a.x, b.y - a.y))
    }
    // 2. For each dot, find the t where its share of the distance is reached.
    var steps: [Double] = []
    var k = 0
    for i in 0..<count {
        let goal = Double(i) / Double(count) * lengths[n]
        while lengths[k] < goal { k += 1 }
        steps.append(Double(k) / Double(n) * 2 * .pi)
    }
    return steps
}

// The classic heart curve. t goes from 0 to 2π, starting at the top dip.
func heart(_ t: Double) -> CGPoint {
    let x = 16 * pow(sin(t), 3)
    let y = 13 * cos(t) - 5 * cos(2 * t)
          - 2 * cos(3 * t) - cos(4 * t)
    return CGPoint(x: x, y: -y)  // flip: y goes down
}

// Build the heart: `count` dots along the curve.
// Each dot waits a little longer than the one before, so the heart draws itself.
func makeDots(count: Int, scale: Double) -> [Dot] {
    let steps = evenSteps(count: count)
    var dots: [Dot] = []
    for i in 0..<count {
        let p = heart(steps[i])
        var dot = Dot()
        let x = p.x * scale + jitter()
        let y = p.y * scale + jitter()
        dot.target = CGPoint(x: x, y: y)
        dot.delay = Double(i) * 0.0007
        dot.duration = .random(in: 2...5)
        dot.size = .random(in: 1.5...2.5)
        dot.opacity = .random(in: 0.5...1)
        dot.color = [pink, rose].randomElement()!
        if i % 25 == 0 { dot.color = .white }
        dots.append(dot)
    }
    return dots
}

// easeInOut (the same curve as GSAP's power2.inOut): slow start, fast middle, slow end.
func ease(_ p: Double) -> Double {
    p < 0.5 ? 2 * p * p : 1 - pow(-2 * p + 2, 2) / 2
}

// Where one dot is, `time` seconds into the fly-in.
// It travels out from the center while turning, so the dots swirl into place.
func dotPosition(of dot: Dot, at time: Double) -> (point: CGPoint, progress: Double) {
    let p = min(max((time - dot.delay) / dot.duration, 0), 1)   // 0 = at the center, 1 = landed
    let e = ease(p)
    let turn = (1 - e) * 2.2                                     // radians still to turn
    let x = dot.target.x * e
    let y = dot.target.y * e
    let point = CGPoint(x: x * cos(turn) - y * sin(turn),
                        y: x * sin(turn) + y * cos(turn))
    return (point, p)
}

// MARK: - The loop: fly in, hold, fly out (the fly-in played backwards), repeat

let heartScale = 10.0
let dots = makeDots(count: 3000, scale: heartScale)    // made once, at launch

let flyIn = dots.map { $0.delay + $0.duration }.max()!  // when the last dot lands
let hold = 3.0

// Turn "seconds since the heart started" into "seconds into the fly-in".
func flyInTime(_ elapsed: Double) -> Double {
    let t = elapsed.truncatingRemainder(dividingBy: flyIn + hold + flyIn)
    if t < flyIn { return t }                  // flying in
    if t < flyIn + hold { return flyIn }       // holding the heart
    return flyIn - (t - flyIn - hold)          // flying out: the same flight, backwards
}

// MARK: - The view

struct ParticleHeart: View {
    let start: Date?     // when the heart began (nil: not yet)

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard let start else { return }
                let time = flyInTime(timeline.date.timeIntervalSince(start))

                // Put (0, 0) in the middle. The curve runs from y -17 to +12, so move up a bit.
                context.translateBy(x: size.width / 2, y: size.height / 2 - 2.5 * heartScale)
                context.blendMode = .plusLighter      // overlapping dots add up and glow

                for dot in dots {
                    let (point, progress) = dotPosition(of: dot, at: time)
                    if progress == 0 { continue }     // still waiting at the center: hidden
                    context.opacity = dot.opacity * min(progress * 8, 1)   // fade in as it leaves
                    let r = dot.size / 2
                    let circle = CGRect(x: point.x - r, y: point.y - r, width: dot.size, height: dot.size)
                    context.fill(Path(ellipseIn: circle), with: .color(dot.color))
                }
            }
        }
        .shadow(color: pink.opacity(0.8), radius: 4)   // a soft pink glow around every dot
    }
}
