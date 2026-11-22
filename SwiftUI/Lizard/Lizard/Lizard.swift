import SwiftUI

// LIZARD.SWIFT
// Everything that makes the lizard skeleton. The editor in the app shows
// `follow` from this file, line for line (4-space indents so it matches).
//
// The idea in one sentence: the head walks toward your finger, and every
// bone after it is pulled along behind the bone in front of it.

// MARK: - Sizes

let boneCount = 44      // points along the spine, head first
let gap = 5.6           // distance between two spine points, in points
let speed = 420.0       // how fast the head walks, in points per second

// MARK: - The spine

// Move the head toward the finger, then pull every
// bone along behind the one in front of it.
func follow(_ spine: inout [CGPoint],
            to target: CGPoint, dt: Double) {
    // 1. The head walks toward the finger.
    let dx = target.x - spine[0].x
    let dy = target.y - spine[0].y
    let d = hypot(dx, dy)
    if d > 1 {
        let step = min(d, speed * dt)
        spine[0].x += dx / d * step
        spine[0].y += dy / d * step
    }
    // 2. Each bone follows the one in front of it.
    for i in 1..<spine.count {
        let a = spine[i - 1]   // the bone in front
        let b = spine[i]       // this bone
        let angle = atan2(a.y - b.y, a.x - b.x)
        spine[i].x = a.x - gap * cos(angle)
        spine[i].y = a.y - gap * sin(angle)
    }
}

// A straight lizard with its head at the center, facing down-right (the way it first wanders).
func startSpine(center: CGPoint) -> [CGPoint] {
    (0..<boneCount).map { i in
        CGPoint(x: center.x - Double(i) * gap * 0.8, y: center.y - Double(i) * gap * 0.6)
    }
}

// Which way the body points at spine point `i` (a length-1 arrow toward the head).
func forward(_ spine: [CGPoint], _ i: Int) -> CGPoint {
    let a = spine[max(i - 1, 0)]
    let b = spine[min(i + 1, spine.count - 1)]
    let len = max(hypot(a.x - b.x, a.y - b.y), 0.001)
    return CGPoint(x: (a.x - b.x) / len, y: (a.y - b.y) / len)
}

// MARK: - Legs

// One leg: a hip on the spine, an upper bone, a lower bone and a foot.
// The foot stays planted on the ground until the body has walked too far
// past it, then it snaps forward in one quick step.
struct Leg {
    var bone: Int              // the spine point the hip sits on
    var side: Double           // -1 = left side, +1 = right side
    var ahead: Double          // where the foot rests: this far in front of the hip…
    var out: Double            // …and this far out to the side
    var upper: Double          // length of the upper bone (hip to knee)
    var lower: Double          // length of the lower bone (knee to foot)
    var foot = CGPoint.zero    // where the foot is now
    var from = CGPoint.zero    // where the current step started
    var stepping = false       // true while the foot is in the air
    var progress = 0.0         // 0 → 1 during a step
}

// Legs at about 30% and 55% of the body. Order: front left, front right, back left, back right.
func makeLegs() -> [Leg] {
    let front = Int(Double(boneCount) * 0.30)
    let back = Int(Double(boneCount) * 0.55)
    return [
        Leg(bone: front, side: -1, ahead: 14, out: 42, upper: 28, lower: 28),
        Leg(bone: front, side: 1, ahead: 14, out: 42, upper: 28, lower: 28),
        Leg(bone: back, side: -1, ahead: 0, out: 44, upper: 30, lower: 30),
        Leg(bone: back, side: 1, ahead: 0, out: 44, upper: 30, lower: 30),
    ]
}

let stepTime = 0.09        // seconds a foot is in the air
let stepLength = 26.0      // how far the foot may fall behind before it steps

// Where a foot would like to stand right now (beside the hip, a little ahead).
func restSpot(_ leg: Leg, _ spine: [CGPoint]) -> CGPoint {
    let hip = spine[leg.bone]
    let f = forward(spine, leg.bone)
    let right = CGPoint(x: -f.y, y: f.x)     // turn the forward arrow 90°
    return CGPoint(x: hip.x + f.x * leg.ahead + right.x * leg.side * leg.out,
                   y: hip.y + f.y * leg.ahead + right.y * leg.side * leg.out)
}

// Plant the feet, and step the ones that fell too far behind.
func moveFeet(_ legs: inout [Leg], spine: [CGPoint], dt: Double) {
    for i in legs.indices {
        let rest = restSpot(legs[i], spine)
        let f = forward(spine, legs[i].bone)
        // Aim a little past the rest spot, so the foot can stay down longer.
        let landing = CGPoint(x: rest.x + f.x * stepLength * 0.5,
                              y: rest.y + f.y * stepLength * 0.5)

        if legs[i].stepping {
            // In the air: slide from where the step started to the landing spot.
            legs[i].progress = min(legs[i].progress + dt / stepTime, 1)
            let t = legs[i].progress
            let e = t * t * (3 - 2 * t)                       // smoothstep: soft start and stop
            legs[i].foot.x = legs[i].from.x + (landing.x - legs[i].from.x) * e
            legs[i].foot.y = legs[i].from.y + (landing.y - legs[i].from.y) * e
            if t >= 1 { legs[i].stepping = false }
            continue
        }

        // On the ground: the foot stays put. Step if it fell too far behind.
        let behind = hypot(legs[i].foot.x - rest.x, legs[i].foot.y - rest.y)
        // Walk like a lizard: never lift a foot while the one beside it
        // (other side) or the one behind/in front (same side) is in the air.
        let neighborUp = legs[i ^ 1].stepping || legs[i ^ 2].stepping
        if behind > stepLength && (!neighborUp || behind > stepLength * 2) {
            legs[i].stepping = true
            legs[i].progress = 0
            legs[i].from = legs[i].foot
        }
    }
}

// 2-bone IK: find the knee, given the hip, the foot and the two bone lengths.
// The knee bends out, away from the body (`outward` points to that side).
func knee(hip: CGPoint, foot: CGPoint, upper: Double, lower: Double, outward: CGPoint) -> CGPoint {
    let d = min(max(hypot(foot.x - hip.x, foot.y - hip.y), 0.001), upper + lower - 0.001)
    let toFoot = atan2(foot.y - hip.y, foot.x - hip.x)
    // Law of cosines: the angle between "hip → foot" and "hip → knee".
    let bend = acos(min(max((upper * upper + d * d - lower * lower) / (2 * upper * d), -1), 1))
    let a = CGPoint(x: hip.x + upper * cos(toFoot + bend), y: hip.y + upper * sin(toFoot + bend))
    let b = CGPoint(x: hip.x + upper * cos(toFoot - bend), y: hip.y + upper * sin(toFoot - bend))
    // Of the two possible knees, keep the one further out to the side.
    let outA = (a.x - hip.x) * outward.x + (a.y - hip.y) * outward.y
    let outB = (b.x - hip.x) * outward.x + (b.y - hip.y) * outward.y
    return outA > outB ? a : b
}

// MARK: - The lizard (spine + legs, moved once per frame)

final class Lizard {
    var spine: [CGPoint] = []
    var legs = makeLegs()
    var lastTime: Double? = nil

    func update(target: CGPoint, time: Double, stage: CGSize) {
        if spine.isEmpty {
            spine = startSpine(center: CGPoint(x: stage.width / 2, y: stage.height / 2))
            for i in legs.indices { legs[i].foot = restSpot(legs[i], spine) }
        }
        let dt = min(max(time - (lastTime ?? time), 0), 1.0 / 30)   // seconds since last frame
        lastTime = time
        follow(&spine, to: target, dt: dt)
        moveFeet(&legs, spine: spine, dt: dt)
    }
}

// MARK: - Drawing

// How long the ribs are along the body: short at the neck, widest at the belly,
// thin down the tail. `t` goes 0 (head) → 1 (tail tip).
func ribLength(_ t: Double) -> Double {
    if t < 0.06 { return 3 + t / 0.06 * 3 }                 // neck
    if t < 0.28 { return 6 + (t - 0.06) / 0.22 * 9 }       // shoulders → belly
    if t < 0.55 { return 15 }                               // belly
    return 13 * pow(1 - (t - 0.55) / 0.45, 1.2) + 2         // tail, thinning out
}

func line(_ a: CGPoint, _ b: CGPoint) -> Path {
    var p = Path()
    p.move(to: a)
    p.addLine(to: b)
    return p
}

// Little claws: 4 short lines fanned out at the foot, pointing the way the lower bone points.
func claws(at foot: CGPoint, from knee: CGPoint) -> Path {
    var p = Path()
    let dir = atan2(foot.y - knee.y, foot.x - knee.x)
    for spread in [-0.8, -0.4, 0, 0.4, 0.8] {
        p.move(to: foot)
        p.addLine(to: CGPoint(x: foot.x + 7 * cos(dir + spread), y: foot.y + 7 * sin(dir + spread)))
    }
    return p
}

func drawLizard(_ liz: Lizard, in context: GraphicsContext) {
    let s = liz.spine
    let bone = GraphicsContext.Shading.color(.white.opacity(0.88))
    let thin = StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round)

    // Spine: one line through every point.
    var spinePath = Path()
    spinePath.addLines(s)
    context.stroke(spinePath, with: bone, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))

    // Ribs: a curved line on each side of every spine point, sweeping back toward the tail.
    var ribs = Path()
    for i in 1..<s.count {
        let r = ribLength(Double(i) / Double(s.count - 1))
        let f = forward(s, i)
        let right = CGPoint(x: -f.y, y: f.x)
        for side in [-1.0, 1.0] {
            let tip = CGPoint(x: s[i].x + right.x * side * r - f.x * r * 0.5,
                              y: s[i].y + right.y * side * r - f.y * r * 0.5)
            let bend = CGPoint(x: s[i].x + right.x * side * r * 0.75,
                               y: s[i].y + right.y * side * r * 0.75)
            ribs.move(to: s[i])
            ribs.addQuadCurve(to: tip, control: bend)
        }
    }
    context.stroke(ribs, with: .color(.white.opacity(0.7)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))

    // Head: a small ring at the front.
    context.stroke(Path(ellipseIn: CGRect(x: s[0].x - 3.5, y: s[0].y - 3.5, width: 7, height: 7)),
                   with: bone, style: thin)

    // Legs: hip → knee → foot (2-bone IK), with claws.
    for leg in liz.legs {
        let hip = s[leg.bone]
        let f = forward(s, leg.bone)
        let outward = CGPoint(x: -f.y * leg.side, y: f.x * leg.side)
        let k = knee(hip: hip, foot: leg.foot, upper: leg.upper, lower: leg.lower, outward: outward)
        // If the foot is out of reach, draw the lower bone only as long as it really is.
        let toFoot = atan2(leg.foot.y - k.y, leg.foot.x - k.x)
        let foot = CGPoint(x: k.x + leg.lower * cos(toFoot), y: k.y + leg.lower * sin(toFoot))
        context.stroke(line(hip, k), with: bone, style: thin)
        context.stroke(line(k, foot), with: bone, style: thin)
        context.stroke(claws(at: foot, from: k), with: bone, style: thin)
    }
}

// MARK: - Where the lizard walks when nobody is touching: a slow, lazy figure-8.

func wander(_ time: Double, _ size: CGSize) -> CGPoint {
    CGPoint(x: size.width / 2 + size.width * 0.30 * sin(time * 0.45),
            y: size.height / 2 + size.height * 0.26 * sin(time * 0.9))
}

// MARK: - The view

struct LizardStage: View {
    let finger: (Double, CGSize) -> CGPoint?   // a scripted finger for the demo (nil: none)
    @State private var lizard = Lizard()
    @State private var touch: CGPoint? = nil  // a real finger on the screen
    @State private var start = Date()         // when the stage appeared (the wander starts here)

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let point = touch ?? finger(time, size)
                let idle = wander(time - start.timeIntervalSinceReferenceDate, size)
                lizard.update(target: point ?? idle, time: time, stage: size)
                drawLizard(lizard, in: context)

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
