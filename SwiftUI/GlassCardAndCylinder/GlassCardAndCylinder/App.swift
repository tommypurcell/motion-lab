import SwiftUI

let ARGS = ProcessInfo.processInfo.arguments
let DEMO = ARGS.contains("-demo")

@main
struct CSSRemixApp: App {
    var body: some Scene {
        WindowGroup {
            if ARGS.contains("-cyl") { CylinderScreen() } else { GlassCardScreen() }
        }
    }
}

// MARK: - 1. Glass card (remix of a CSS liquid-glass card you drag around)

let CARD = CGSize(width: 292, height: 480)
let CARD_RADIUS: CGFloat = 58
let LOOP = 16.0
let SIGN_AT = 12.4, SIGN_LEN = 1.8

let INTRO = 4.2

struct GlassCardScreen: View {
    @State private var liquid: Double = 0.6
    @State private var center: CGPoint?
    @State private var dragFrom: CGPoint?
    @State private var lift = false
    @State private var strokes: [[CGPoint]] = []
    @State private var handle = ""
    @State private var building = false
    @State private var builtAt: Date?
    @State private var start = Date()

    var body: some View {
        GeometryReader { geo in
            let screen = geo.size
            let home = CGPoint(x: screen.width / 2, y: screen.height * 0.49)
            TimelineView(.animation) { tl in
                let e = tl.date.timeIntervalSince(start)
                let intro = DEMO && e < INTRO
                let t = DEMO ? (intro ? 0 : (e - INTRO).truncatingRemainder(dividingBy: LOOP)) : -1
                let demo = DEMO && !intro ? DemoPose(t: t, home: home, screen: screen) : nil
                let iv = DEMO && intro ? IntroPose(e: e, home: home, screen: screen) : nil
                // time since the card was built: drives the pop-in
                let u = DEMO ? (intro ? e - 3.1 : 99) : builtAt.map { tl.date.timeIntervalSince($0) } ?? -1
                let pop = popScale(u)
                let shown = smooth((u - 0.15) / 0.4)
                let c = demo?.center ?? center ?? home
                let scale = (demo?.scale ?? (lift ? 1.04 : 1)) * pop
                let lq = demo?.liquid ?? liquid
                let size = CGSize(width: CARD.width * scale, height: CARD.height * scale)
                let rect = u < 0 ? CGRect(x: -2000, y: 0, width: 10, height: 10)
                    : CGRect(x: c.x - size.width / 2, y: c.y - size.height / 2, width: size.width, height: size.height)
                ZStack(alignment: .topLeading) {
                    Image("bg-reef").resizable().scaledToFill()
                        .frame(width: screen.width, height: screen.height).clipped()
                        .layerEffect(ShaderLibrary.glassCard(.float4(Float(rect.minX), Float(rect.minY), Float(rect.width), Float(rect.height)),
                                                             .float(Float(CARD_RADIUS * scale)), .float(Float(lq))),
                                     maxSampleOffset: CGSize(width: 220, height: 220))
                    if u < 0.4 {
                        let gone = smooth(u / 0.3)
                        BuilderPanel(handle: DEMO ? .constant(iv?.typed ?? "swingcoach") : $handle,
                                     building: DEMO ? (iv?.building ?? false) : building) {
                            building = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { building = false; builtAt = Date() }
                        }
                        .frame(width: screen.width - 48)
                        .scaleEffect(1 - 0.12 * gone)
                        .opacity(1 - gone)
                        .position(home)
                    }
                    CardContent(strokes: $strokes, demoT: t)
                        .frame(width: CARD.width, height: CARD.height)
                        .scaleEffect(scale)
                        .opacity(shown)
                        .position(c)
                        .gesture(DragGesture(minimumDistance: 4)
                            .onChanged { v in
                                if dragFrom == nil { dragFrom = center ?? home; withAnimation(.spring(duration: 0.3)) { lift = true } }
                                center = CGPoint(x: dragFrom!.x + v.translation.width, y: dragFrom!.y + v.translation.height)
                            }
                            .onEnded { _ in dragFrom = nil; withAnimation(.spring(duration: 0.4, bounce: 0.4)) { lift = false } })
                        .allowsHitTesting(u > 0)
                    LiquidSlider(value: DEMO ? .constant(lq) : $liquid)
                        .frame(width: screen.width - 48)
                        .opacity(shown)
                        .position(x: screen.width / 2, y: screen.height - 70)
                    if let f = demo?.finger ?? iv?.finger {
                        Circle().fill(.white.opacity(0.35))
                            .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2))
                            .frame(width: 40, height: 40)
                            .scaleEffect((demo?.press ?? iv?.press ?? false) ? 0.85 : 1)
                            .position(f)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// springy grow from small to full size; hidden before u = 0
func popScale(_ u: Double) -> CGFloat {
    if u < 0 { return 0 }
    return CGFloat(1 - 0.8 * exp(-6 * u) * cos(9 * u))
}

let PANEL_H: CGFloat = 200

// Load screen: type a handle, tap Build, the card pops in. Same idea as the CSS demo's builder.
struct BuilderPanel: View {
    @Binding var handle: String
    let building: Bool
    let build: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Glass Card").font(.system(size: 22, weight: .bold))
            Text("Turn your profile into a liquid-glass card you can sign and save.")
                .font(.system(size: 13, weight: .medium)).opacity(0.85)
            Spacer(minLength: 0)
            Text("Your handle").font(.system(size: 12, weight: .semibold)).opacity(0.85)
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "at").font(.system(size: 14, weight: .semibold)).opacity(0.8)
                    TextField("", text: $handle, prompt: Text("your handle").foregroundStyle(.white.opacity(0.5)))
                        .font(.system(size: 15, weight: .medium))
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                }
                .padding(.horizontal, 14).frame(height: 46)
                .background(.white.opacity(0.1), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.4)))
                Button(action: build) {
                    ZStack {
                        Text("Build").opacity(building ? 0 : 1)
                        if building { ProgressView().tint(.black) }
                    }
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(.black)
                    .frame(width: 80, height: 46)
                    .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.white)
        .padding(22)
        .frame(height: PANEL_H)
        .glassEffect(.regular.tint(.black.opacity(0.35)), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

// Intro script: tap the field, type, tap Build, spinner. The card pops at e = 3.1.
struct IntroPose {
    var typed = "", building = false, finger: CGPoint?, press = false

    init(e: Double, home: CGPoint, screen: CGSize) {
        let word = "swingcoach"
        typed = String(word.prefix(Int(Double(word.count) * min(max((e - 0.7) / 1.2, 0), 1))))
        building = e > 2.5
        let rowY = home.y + PANEL_H / 2 - 22 - 23
        let field = CGPoint(x: home.x - 50, y: rowY)
        let button = CGPoint(x: home.x + (screen.width - 48) / 2 - 22 - 40, y: rowY)
        if e > 0.2 && e < 2.8 {
            let m = smooth((e - 1.95) / 0.35)
            finger = CGPoint(x: field.x + (button.x - field.x) * m, y: rowY)
            press = (e > 0.4 && e < 0.6) || (e > 2.35 && e < 2.55)
        }
    }
}

// The scripted demo: drag the card at medium liquidness, slide it to full, drag again,
// slide it almost to zero, drag again, sign, then set it back. Everything is a function of t.
struct DemoPose {
    var center: CGPoint, scale: CGFloat = 1, liquid: Double = 0.55
    var finger: CGPoint?, press = false

    // (start, end) of each drag, and a different loop shape for each
    static let drags: [(Double, Double, CGFloat, CGFloat, Double)] = [
        (0.8, 4.0, 34, 70, 1), (5.8, 8.6, -40, 60, 2), (10.1, 12.1, 30, -50, 1)]
    // (start, end, from, to) of each slider move
    static let slides: [(Double, Double, Double, Double)] = [
        (4.3, 5.5, 0.55, 1.0), (8.9, 9.9, 1.0, 0.12), (14.7, 15.6, 0.12, 0.55)]

    init(t: Double, home: CGPoint, screen: CGSize) {
        center = home
        // liquidness: where the slider is right now
        liquid = 0.55
        for (a, b, from, to) in DemoPose.slides where t >= a {
            liquid = from + (to - from) * smooth((t - a - 0.15) / (b - a - 0.3))
        }
        for (a, b, ax, ay, f) in DemoPose.drags where t >= a && t < b {
            let u = smooth((t - a - 0.3) / (b - a - 0.6))
            let w = u * 2 * .pi
            let p = CGPoint(x: home.x + ax * sin(w * f) - 10 * sin(2 * w),
                            y: home.y - ay * sin(w / 2) + 30 * sin(2 * w))   // starts and ends at home
            let rise = smooth((t - a) / 0.3) - smooth((t - b + 0.3) / 0.3)
            center = p
            scale = 1 + 0.05 * rise
            finger = CGPoint(x: p.x, y: p.y - 170)                          // holding the avatar
            press = rise > 0.5
        }
        for (a, b, _, _) in DemoPose.slides where t >= a && t < b {
            let x0 = 138.0, travel = Double(screen.width) - 44 - x0
            finger = CGPoint(x: x0 + travel * liquid, y: screen.height - 70)
            press = t > a + 0.1 && t < b - 0.1
        }
        // signing: finger follows the signature pen
        if t >= SIGN_AT - 0.2 && t < SIGN_AT + SIGN_LEN + 0.3 {
            let pen = SignaturePad.demoPoint(progress: smooth((t - SIGN_AT) / SIGN_LEN), size: CGSize(width: CARD.width - 64, height: 54))
            finger = CGPoint(x: home.x - CARD.width / 2 + 32 + pen.x, y: home.y + 112 + pen.y)
            press = t > SIGN_AT && t < SIGN_AT + SIGN_LEN
        }
    }
}

func smooth(_ x: Double) -> Double { let c = min(max(x, 0), 1); return c * c * (3 - 2 * c) }

struct CardContent: View {
    @Binding var strokes: [[CGPoint]]
    let demoT: Double

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.85, green: 0.93, blue: 0.35), Color(red: 0.55, green: 0.76, blue: 0.20)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(Image(systemName: "figure.tennis").font(.system(size: 28, weight: .semibold)).foregroundStyle(.white))
                .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2))
                .frame(width: 60, height: 60)
                .padding(.top, 16)
            VStack(spacing: 2) {
                Text("SwingCoach").font(.system(size: 22, weight: .bold))
                Text("@swingcoach").font(.system(size: 12, weight: .medium)).opacity(0.8)
                Text("Film your swing. Get a fix in seconds.").font(.system(size: 11, weight: .medium)).opacity(0.85).padding(.top, 3)
            }
            HStack(spacing: 8) {
                Stat(value: "1,240", label: "Swings")
                Stat(value: "86", label: "Lessons")
                Stat(value: "23", label: "Day streak")
            }
            Panel {
                HStack {
                    Text("Practice").font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Text("1,240 swings this year").font(.system(size: 11, weight: .medium)).opacity(0.8)
                }
                DotGrid(reveal: demoT < 0 ? 1 : smooth(demoT / 1.2) - smooth((demoT - 15.3) / 0.6))
                    .frame(height: 50)
            }
            Panel {
                HStack {
                    Text("SIGNATURE").font(.system(size: 11, weight: .bold)).kerning(2.2)
                    Spacer()
                    Button("Clear") { strokes = [] }
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 11).padding(.vertical, 4)
                        .overlay(Capsule().strokeBorder(.white.opacity(0.6)))
                        .buttonStyle(.plain)
                }
                SignaturePad(strokes: $strokes, demoT: demoT).frame(height: 54)
            }
            HStack(spacing: 8) {
                Chip(icon: "tennisball.fill", text: "Tennis")
                Chip(icon: "calendar", text: "Joined 2026")
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.3), radius: 5, y: 1)
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(RoundedRectangle(cornerRadius: CARD_RADIUS, style: .continuous))
    }
}

struct Chip: View {
    let icon: String, text: String
    var body: some View {
        Label(text, systemImage: icon).font(.system(size: 11, weight: .semibold))
            .frame(maxWidth: .infinity).padding(.vertical, 9)
            .background(.white.opacity(0.08), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.35)))
    }
}

struct Stat: View {
    let value: String, label: String
    var body: some View {
        VStack(spacing: 1) {
            Text(value).font(.system(size: 16, weight: .bold))
            Text(label).font(.system(size: 10, weight: .medium)).opacity(0.8)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 7)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.35)))
    }
}

struct Panel<C: View>: View {
    @ViewBuilder let content: C
    var body: some View {
        VStack(alignment: .leading, spacing: 8) { content }
            .padding(12)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.35)))
    }
}

struct DotGrid: View {
    let reveal: Double
    var body: some View {
        Canvas { ctx, size in
            let cols = 26, rows = 7
            let dx = size.width / CGFloat(cols), dy = size.height / CGFloat(rows)
            for c in 0..<cols {
                for r in 0..<rows {
                    let seed: Int = (c * 7 + r * 13 + c * r) % 5
                    let level = Double(seed) / 4      // fixed "random"
                    let on = Double(c) / Double(cols) < reveal * 1.2 - 0.1
                    let px: CGFloat = CGFloat(c) * dx + dx / 2 - 1.9
                    let py: CGFloat = CGFloat(r) * dy + dy / 2 - 1.9
                    let rr = CGRect(x: px, y: py, width: 3.8, height: 3.8)
                    let lit: Color = Color(red: 0.35, green: 0.85, blue: 1.0).opacity(0.35 + 0.65 * level)
                    let color: Color = (on && level > 0.2) ? lit : Color.white.opacity(0.25)
                    ctx.fill(Path(ellipseIn: rr), with: .color(color))
                }
            }
        }
    }
}

struct SignaturePad: View {
    @Binding var strokes: [[CGPoint]]
    let demoT: Double
    var body: some View {
        GeometryReader { geo in
            let demoProgress = smooth((demoT - SIGN_AT) / SIGN_LEN)
            let empty = demoT >= 0 ? demoProgress == 0 : strokes.isEmpty
            ZStack {
                if empty {
                    Label("sign here", systemImage: "pencil").font(.system(size: 13, weight: .medium).italic()).opacity(0.7)
                }
                Canvas { ctx, _ in
                    var all = strokes
                    if demoT >= 0 { all = [SignaturePad.demoLine(geo.size, progress: demoProgress)] }
                    for s in all where s.count > 1 {
                        var p = Path(); p.addLines(s)
                        ctx.stroke(p, with: .color(.white), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    }
                }
                .opacity(demoT < 0 ? 1 : 1 - smooth((demoT - 15.2) / 0.6))
            }
            .contentShape(Rectangle())
            .highPriorityGesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    if v.translation == .zero { strokes.append([]) }
                    strokes[strokes.count - 1].append(v.location)
                })
        }
    }

    // loopy cursive line, drawn left to right as progress goes 0 -> 1
    static func demoPoint(progress u: Double, size: CGSize) -> CGPoint {
        let x = 0.1 + u * 0.75
        return CGPoint(x: size.width * x + 12 * sin(u * .pi * 10),
                       y: size.height * (0.55 - 0.1 * sin(u * .pi * 2)) - 14 * cos(u * .pi * 10) * (0.6 + 0.4 * sin(u * 9)))
    }
    static func demoLine(_ size: CGSize, progress: Double) -> [CGPoint] {
        let n = Int(200 * progress)
        return (0..<max(n, 0)).map { demoPoint(progress: Double($0) / 200, size: size) }
    }
}

struct LiquidSlider: View {
    @Binding var value: Double
    var body: some View {
        HStack(spacing: 14) {
            Text("Liquidness").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
            Slider(value: $value, in: 0...1).tint(.white)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .glassEffect(.clear, in: Capsule())
    }
}

// MARK: - 2. Cylinder carousel (remix of a CSS trig cylinder)

let PHOTOS = (0..<12).map { String(format: "c%02d", $0) }
let PLACES = ["Longtail lagoon", "Palm sunset", "Jungle falls", "Night market", "Island bays", "Water bungalow",
              "Hill road", "Coconut hour", "Misty cliffs", "Pink sea", "Temple gold", "Reef swim",
              "Fruit stall", "Hammock", "Dawn boats"]

struct CylinderScreen: View {
    @State private var rot: Double = 0          // radians
    @State private var dragStart: Double?
    @State private var velocity: Double = 0
    @State private var last = Date()
    @State private var start = Date()

    let itemW: CGFloat = 132, itemH: CGFloat = 188

    var body: some View {
        TimelineView(.animation) { tl in
            let now = tl.date
            let r = DEMO ? demoRot(now.timeIntervalSince(start)) : rot
            let n = Double(PHOTOS.count), a = 2 * Double.pi / n
            GeometryReader { geo in
                ZStack {
                    // fixed background: dark with a soft warm glow behind the ring
                    Color(red: 0.06, green: 0.06, blue: 0.08)
                    RadialGradient(colors: [Color(red: 0.55, green: 0.42, blue: 0.30).opacity(0.45), .clear],
                                   center: .center, startRadius: 0, endRadius: geo.size.width * 0.9)
                    VStack(spacing: 0) {
                        Spacer()
                        ring(r)
                        Spacer()
                    }
                    .frame(width: geo.size.width)
                    .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.18),
                                                 .init(color: .black, location: 0.82), .init(color: .clear, location: 1)],
                                         startPoint: .leading, endPoint: .trailing))
                    // caption: a plain fade, locked to the ring
                    ZStack {
                        ForEach(0..<PHOTOS.count, id: \.self) { i in
                            let th = remainder(Double(i) * a + r, 2 * .pi)
                            Text(PLACES[i]).fixedSize().opacity(smooth(1 - abs(th) / (a * 0.5)))
                        }
                    }
                    .font(.system(size: 15, weight: .medium)).foregroundStyle(.white.opacity(0.7))
                    .offset(y: itemH * 0.95)
                }
            }
            .onChange(of: now) { _, t in coast(t) }
        }
        .background(.black)
        .ignoresSafeArea()
        .gesture(DragGesture()
            .onChanged { v in
                if dragStart == nil { dragStart = rot }
                rot = dragStart! + Double(v.translation.width) / 150
                velocity = 0
            }
            .onEnded { v in
                dragStart = nil
                velocity = Double(v.predictedEndTranslation.width - v.translation.width) / 150 * 2.5
            })
    }

    func ring(_ r: Double) -> some View {
        let n = PHOTOS.count, a = 2 * Double.pi / Double(n)
        let radius = Double(itemW) / 2 / tan(a / 2) * 1.2       // same trig as the CSS: w / sin(a), plus a gap
        return ZStack {
            ForEach(0..<n, id: \.self) { i in
                let th = Double(i) * a + r
                let z = cos(th)
                let depth = radius * (1 - z)                           // distance behind the front
                let s = 520 / (520 + depth)                            // real perspective
                Image(PHOTOS[i]).resizable().scaledToFill()
                    .frame(width: itemW, height: itemH).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .brightness(-0.45 * (1 - z) / 2)
                    .rotation3DEffect(.radians(th), axis: (0, 1, 0), perspective: 0.3)
                    .scaleEffect(s)
                    .offset(x: sin(th) * radius * s, y: -depth * 0.42 * s)
                    .opacity(z < -0.3 ? 0.7 : 1)
                    .zIndex(z)
            }
        }
        .frame(height: itemH * 1.05).offset(y: 40)
    }

    func coast(_ t: Date) {
        let dt = min(t.timeIntervalSince(last), 1 / 30); last = t
        guard dragStart == nil, abs(velocity) > 0.0005 else { return }
        rot += velocity * dt
        velocity *= pow(0.04, dt)
    }

    // spin, ease to a stop on a photo, spin again
    func demoRot(_ t: Double) -> Double {
        let a = 2 * Double.pi / Double(PHOTOS.count)
        let seg = 2.2, k = floor(t / seg), f = (t - k * seg) / seg
        let e = smooth(min(f / 0.7, 1))
        return -(k * 3 + e * 3) * a
    }
}
