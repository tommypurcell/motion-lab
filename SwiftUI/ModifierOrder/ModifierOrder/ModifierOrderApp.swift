import SwiftUI

// PADDING + MODIFIER ORDER IN SWIFTUI
// SwiftUI applies modifiers top to bottom. Each one wraps the view built so far.
//   .padding() then .background()  -> a colored box with space inside it
//   .background() then .padding()  -> only the text is colored, clear space outside
// Also: which sides get padding, the default amount, EdgeInsets,
// and how .border / .clipShape / a second layer stack up.
// The dashed lines show the real frame of each layer (measured, not drawn by hand).
// Launch with -demo to auto-play.

@main
struct ModifierOrderApp: App {
  var body: some Scene {
    WindowGroup { ContentView() }
  }
}

// MARK: - Colors (slate grays + code colors from docs/DESIGN_RULES.md)

extension Color {
  init(hex: UInt32) {   // our own little helper: 0xRRGGBB -> Color
    self.init(red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
  }
}

let ink = Color(hex: 0x0F172A)
let secondary = Color(hex: 0x475569)
let tertiary = Color(hex: 0x64748B)
let canvas = Color(hex: 0xF1F5F9)
let dash = Color(hex: 0x94A3B8)

let zoom: CGFloat = 2                                   // the demo is drawn 2× bigger so it's easy to see
let box = CGSize(width: 300, height: 200)               // the hidden area the real chain is measured in

// MARK: - The options

// Which sides get padding (and how much).
enum Sides: CaseIterable {
  case all, standard, leading, top, horizontal, custom

  var name: String {
    switch self {
    case .all: "all · 20"
    case .standard: "default"
    case .leading: ".leading"
    case .top: ".top"
    case .horizontal: ".horizontal"
    case .custom: "EdgeInsets"
    }
  }
}

enum Order: CaseIterable {
  case paddingFirst, backgroundFirst

  var name: String {
    switch self {
    case .paddingFirst: "padding first"
    case .backgroundFirst: "background first"
    }
  }
}

enum Extra: CaseIterable {
  case none, border, clip, nested

  var name: String {
    switch self {
    case .none: "none"
    case .border: ".border"
    case .clip: ".clipShape"
    case .nested: "nested"
    }
  }
}

// MARK: - The real modifier chain

// This view runs the EXACT chain shown in the code block. It is hidden:
// we only use it to ask SwiftUI "where is each layer, and how big?"
// Then the visible drawing animates to those frames (so they're real, not made up).
struct RealChain: View {
  let sides: Sides
  let order: Order
  let extra: Extra
  let report: (String, CGRect) -> Void

  // The padding part of the chain.
  @ViewBuilder func addPadding(_ view: some View) -> some View {
    switch sides {
    case .all:
      view.padding(20).measure("pad", report)
    case .standard:
      view.padding().measure("pad", report)
    case .leading:
      view.padding(.leading, 20).measure("pad", report)
    case .top:
      view.padding(.top, 20).measure("pad", report)
    case .horizontal:
      view.padding(.horizontal, 24).measure("padH", report)
        .padding(.vertical, 8).measure("pad", report)
    case .custom:
      view.padding(EdgeInsets(top: 4, leading: 32, bottom: 20, trailing: 8)).measure("pad", report)
    }
  }

  // The background part (plus a border or clip right after it).
  @ViewBuilder func addBackground(_ view: some View) -> some View {
    switch extra {
    case .border:
      view.background(.orange).measure("orange", report)
        .border(.black).measure("border", report)
    case .clip:
      view.background(.orange).measure("orange", report)
        .clipShape(.capsule).measure("clip", report)
    case .none, .nested:
      view.background(.orange).measure("orange", report)
    }
  }

  // Padding and background, in the chosen order.
  @ViewBuilder var base: some View {
    let text = Text("Hello").measure("text", report)
    if order == .paddingFirst {
      addBackground(addPadding(text))
    } else {
      addPadding(addBackground(text))
    }
  }

  var body: some View {
    if extra == .nested {
      base
        .padding(20).measure("outerPad", report)
        .background(.blue).measure("blue", report)
    } else {
      base
    }
  }
}

extension View {
  // Our helper: tells us this layer's frame. It doesn't change the layout.
  func measure(_ name: String, _ report: @escaping (String, CGRect) -> Void) -> some View {
    onGeometryChange(for: CGRect.self) { proxy in
      proxy.frame(in: .named("chain"))
    } action: { rect in
      report(name, rect)
    }
  }

  // Our helper: draw this at a measured frame, 2× bigger.
  func place(_ rect: CGRect) -> some View {
    frame(width: max(rect.width, 0) * zoom, height: max(rect.height, 0) * zoom)
      .offset(x: rect.minX * zoom, y: rect.minY * zoom)
  }
}

// The layer names, inside out. Same order as RealChain.
func layers(_ sides: Sides, _ order: Order, _ extra: Extra) -> [String] {
  let padding = sides == .horizontal ? ["padH", "pad"] : ["pad"]
  var background = ["orange"]
  if extra == .border { background.append("border") }
  if extra == .clip { background.append("clip") }
  var list = ["text"] + (order == .paddingFirst ? padding + background : background + padding)
  if extra == .nested { list += ["outerPad", "blue"] }
  return list
}

// MARK: - Captions (line 1: what you see. line 2: why.)

func caption(_ sides: Sides, _ order: Order, _ extra: Extra) -> (String, String) {
  let first = order == .paddingFirst
  switch extra {
  case .nested:
    return first
      ? ("An orange box inside a blue box.", "Each .background fills the padding above it.")
      : ("Orange hugs the text. Blue fills both paddings.", "The first padding is clear, so blue shows.")
  case .clip:
    return first
      ? ("The capsule cuts the padded orange box.", "clipShape only cuts what's above it.")
      : ("The capsule cuts just the orange text.", "clipShape only cuts what's above it.")
  case .border:
    return first
      ? ("The border goes around the orange box.", "It wraps the padding above it.")
      : ("The border hugs the text.", "Padding comes after, so it's outside the border.")
  case .none:
    if !first {
      return ("Background first: only the text is orange.", "Padding then adds clear space outside it.")
    }
    switch sides {
    case .all: return ("Padding first: orange fills the padding.", "20 points on every side.")
    case .standard: return ("No number = the system default, 16 points.", "Same on all four sides.")
    case .leading: return ("Pick a side: 20 points on .leading only.", "Leading = the left side in English.")
    case .top: return ("Pick a side: 20 points on .top only.", "The other three sides get nothing.")
    case .horizontal: return ("Horizontal = left and right, 24 each.", "Vertical = top and bottom, 8. Pill look.")
    case .custom: return ("Set all four sides yourself.", "EdgeInsets: top, leading, bottom, trailing.")
    }
  }
}

// MARK: - Code block

// One colored piece of a code line.
enum Kind { case type, call, label, value, string, plain }

struct Piece {
  let text: String
  let kind: Kind
}

// One line of code. The id lets a line keep its place, so it can slide when the order flips.
struct Row {
  let id: String
  let pieces: [Piece]
  var text: String { pieces.map(\.text).joined() }
}

func color(of kind: Kind) -> Color {
  switch kind {
  case .type: Color(hex: 0x7DD3FC)
  case .call: Color(hex: 0xE2E8F0)
  case .label: Color(hex: 0xC4B5FD)
  case .value: Color(hex: 0xFCD34D)
  case .string: Color(hex: 0x94A3B8)
  case .plain: Color(hex: 0x64748B)
  }
}

func call(_ name: String) -> Piece { Piece(text: name, kind: .call) }
func plain(_ text: String) -> Piece { Piece(text: text, kind: .plain) }
func value(_ text: String) -> Piece { Piece(text: text, kind: .value) }
func label(_ text: String) -> Piece { Piece(text: text, kind: .label) }

// The code lines for the current choice. Same text as RealChain above.
func codeRows(_ sides: Sides, _ order: Order, _ extra: Extra) -> [Row] {
  var padding: [Row]
  switch sides {
  case .all:
    padding = [Row(id: "pad", pieces: [call("  .padding"), plain("("), value("20"), plain(")")])]
  case .standard:
    padding = [Row(id: "pad", pieces: [call("  .padding"), plain("()")])]
  case .leading:
    padding = [Row(id: "pad", pieces: [call("  .padding"), plain("("), value(".leading"), plain(", "), value("20"), plain(")")])]
  case .top:
    padding = [Row(id: "pad", pieces: [call("  .padding"), plain("("), value(".top"), plain(", "), value("20"), plain(")")])]
  case .horizontal:
    padding = [Row(id: "pad", pieces: [call("  .padding"), plain("("), value(".horizontal"), plain(", "), value("24"), plain(")")]),
               Row(id: "pad2", pieces: [call("  .padding"), plain("("), value(".vertical"), plain(", "), value("8"), plain(")")])]
  case .custom:
    padding = [Row(id: "pad", pieces: [call("  .padding"), plain("("), Piece(text: "EdgeInsets", kind: .type), plain("(")]),
               Row(id: "pad2", pieces: [label("      top: "), value("4"), plain(", "), label("leading: "), value("32"), plain(",")]),
               Row(id: "pad3", pieces: [label("      bottom: "), value("20"), plain(", "), label("trailing: "), value("8"), plain("))")])]
  }

  var background = [Row(id: "orange", pieces: [call("  .background"), plain("("), value(".orange"), plain(")")])]
  if extra == .border {
    background.append(Row(id: "border", pieces: [call("  .border"), plain("("), value(".black"), plain(")")]))
  }
  if extra == .clip {
    background.append(Row(id: "clip", pieces: [call("  .clipShape"), plain("("), value(".capsule"), plain(")")]))
  }

  var rows = [Row(id: "text", pieces: [Piece(text: "Text", kind: .type), plain("("),
                                       Piece(text: "\"Hello\"", kind: .string), plain(")")])]
  rows += order == .paddingFirst ? padding + background : background + padding
  if extra == .nested {
    rows.append(Row(id: "outerPad", pieces: [call("  .padding"), plain("("), value("20"), plain(")")]))
    rows.append(Row(id: "blue", pieces: [call("  .background"), plain("("), value(".blue"), plain(")")]))
  }
  return rows
}

// Glue the pieces of one line into a single colored Text.
func codeText(_ pieces: [Piece]) -> Text {
  pieces.reduce(Text("")) { result, piece in
    result + Text(piece.text)
      .foregroundColor(color(of: piece.kind))
      .fontWeight(piece.kind == .value ? .semibold : .medium)
  }
}

// MARK: - The screen

struct ContentView: View {
  @State private var sides: Sides = .all
  @State private var order: Order = .paddingFirst
  @State private var extra: Extra = .none
  @State private var frames: [String: CGRect] = [:]   // real frame of each layer, by name
  @State private var changed: Set<String> = []        // code lines that just moved, changed or appeared
  @State private var lifted: Set<String> = []         // code lines stepping aside so others can pass

  // Demo only
  @State private var spots: [String: CGPoint] = [:]   // center of each option row on screen
  @State private var touch = CGPoint.zero
  @State private var touchOn = false

  var chain: [String] { layers(sides, order, extra) }
  var outer: String { chain.last ?? "text" }
  func has(_ name: String) -> Bool { chain.contains(name) }

  // A layer's frame. A layer not in the chain right now sits on the outer layer (and is faded out).
  func frame(_ name: String) -> CGRect {
    frames[has(name) ? name : outer] ?? .zero
  }

  var body: some View {
    ZStack {
      canvas.ignoresSafeArea()

      VStack(spacing: 0) {
        header
        stage.padding(.top, 12)
        sizeLine.padding(.top, 8)
        captionBlock.padding(.top, 6)
        options.padding(.top, 14)
        codeBlock.padding(.top, 14)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 16)
      .padding(.top, 4)
    }
    .overlay(alignment: .topLeading) { fingerDot }
    .coordinateSpace(.named("screen"))
    .task {
      if CommandLine.arguments.contains("-demo") { await runDemo() }
    }
  }

  // MARK: Header

  var header: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("SWIFTUI · MODIFIERS")
        .font(.system(size: 12, weight: .semibold))
        .tracking(1.2)
        .foregroundStyle(tertiary)
      Text("Modifier order")
        .font(.system(size: 28, weight: .bold))
        .tracking(-0.6)
        .foregroundStyle(ink)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: Stage (the demo)

  var stage: some View {
    DotGrid()
      .frame(height: 228)
      .frame(maxWidth: .infinity)
      .background {
        // Hidden: the real modifier chain, used only to measure.
        RealChain(sides: sides, order: order, extra: extra) { name, rect in
          withAnimation(.spring(duration: 0.6, bounce: 0.12)) { frames[name] = rect }
        }
        .frame(width: box.width, height: box.height)
        .coordinateSpace(.named("chain"))
        .hidden()
      }
      .overlay { drawing }
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .overlay(alignment: .topTrailing) {
        Text("2× zoom")
          .font(.system(size: 12, weight: .medium, design: .monospaced))
          .foregroundStyle(tertiary)
          .padding(10)
      }
      .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
      .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
  }

  // The drawing, back to front. Every frame comes from the real chain.
  var drawing: some View {
    ZStack(alignment: .topLeading) {
      // .background(.blue): behind everything above it
      Rectangle()
        .fill(.blue)
        .place(frame("blue"))
        .opacity(has("blue") ? 1 : 0)

      ZStack(alignment: .topLeading) {
        // .background(.orange)
        Rectangle()
          .fill(.orange)
          .place(frame("orange"))

        Text("Hello")
          .font(.system(size: 17 * zoom))
          .fixedSize()
          .place(frame("text"))

        // .border(.black): drawn on top, inside the edge
        Rectangle()
          .strokeBorder(.black, lineWidth: 1 * zoom)
          .place(frame("border"))
          .opacity(has("border") ? 1 : 0)
      }
      .mask(alignment: .topLeading) {
        // .clipShape(.capsule): a capsule is a rectangle with fully round ends.
        // With no clip, the mask covers the whole area.
        let clip = has("clip") ? frame("clip") : CGRect(origin: .zero, size: box)
        RoundedRectangle(cornerRadius: has("clip") ? min(clip.width, clip.height) / 2 * zoom : 0)
          .place(clip)
      }

      // Dashed outlines: the real frame of the text and of each padding.
      ForEach(["text", "padH", "pad", "outerPad"], id: \.self) { name in
        Rectangle()
          .strokeBorder(dash, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
          .place(frame(name))
          .opacity(has(name) ? 1 : 0)
      }
    }
    .frame(width: box.width * zoom, height: box.height * zoom, alignment: .topLeading)
    .allowsHitTesting(false)
  }

  // "orange 79 × 60  ·  text 39 × 20": the sizes SwiftUI really gave each layer.
  var sizeLine: some View {
    let orange = frames["orange"]?.size ?? .zero
    let text = frames["text"]?.size ?? .zero
    return HStack(spacing: 6) {
      RoundedRectangle(cornerRadius: 2).fill(.orange).frame(width: 10, height: 10)
      Text("orange").foregroundStyle(tertiary)
      Text("\(Int(orange.width.rounded())) × \(Int(orange.height.rounded()))")
        .foregroundStyle(ink)
        .fontWeight(.semibold)
        .contentTransition(.numericText())
      Text("·  text").foregroundStyle(tertiary)
      Text("\(Int(text.width.rounded())) × \(Int(text.height.rounded()))")
        .foregroundStyle(ink)
        .fontWeight(.semibold)
      Spacer()
    }
    .font(.system(size: 13, weight: .medium, design: .monospaced))
  }

  // Two lines: what you see, then why. Then the rule that never changes.
  var captionBlock: some View {
    let (see, why) = caption(sides, order, extra)
    return VStack(alignment: .leading, spacing: 2) {
      Text(see)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(ink)
      Text(why)
        .font(.system(size: 15))
        .foregroundStyle(secondary)
      Text("Modifiers apply top to bottom. Each wraps everything above.")
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(tertiary)
        .padding(.top, 6)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentTransition(.opacity)
  }

  // MARK: Options

  var options: some View {
    HStack(alignment: .top, spacing: 10) {
      VStack(alignment: .leading, spacing: 0) {
        sectionLabel("WHICH SIDES")
        ForEach(Sides.allCases, id: \.self) { option in
          optionRow(key: option.name, on: sides == option) { pick(option) }
        }
      }
      .frame(width: 150)
      VStack(alignment: .leading, spacing: 0) {
        sectionLabel("ORDER")
        ForEach(Order.allCases, id: \.self) { option in
          optionRow(key: option.name, on: order == option) { pick(option) }
        }
        sectionLabel("EXTRAS").padding(.top, 10)
        ForEach(Extra.allCases, id: \.self) { option in
          optionRow(key: option.name, on: extra == option) { pick(option) }
        }
      }
    }
  }

  func sectionLabel(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 12, weight: .semibold))
      .tracking(1)
      .foregroundStyle(tertiary)
      .padding(.leading, 10)
      .padding(.bottom, 4)
  }

  // One row. The chosen one gets a white chip and dark bold text; the rest stay quiet.
  func optionRow(key: String, on: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack {
        Text(key)
          .font(.system(size: 14, weight: on ? .semibold : .regular, design: .monospaced))
          .foregroundStyle(on ? ink : secondary)
        Spacer(minLength: 4)
      }
      .padding(.horizontal, 10)
      .frame(height: 26)
      .background {
        if on {
          RoundedRectangle(cornerRadius: 8)
            .fill(.white)
            .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
        }
      }
    }
    .buttonStyle(.plain)
    .onGeometryChange(for: CGPoint.self) { proxy in
      let f = proxy.frame(in: .named("screen"))
      return CGPoint(x: f.midX, y: f.midY)
    } action: { center in
      spots[key] = center
    }
  }

  // MARK: Code block

  var codeBlock: some View {
    let rows = codeRows(sides, order, extra)
    return VStack(alignment: .leading, spacing: 0) {
      // Each line keeps its id, so when the order flips, the lines slide past each other.
      ForEach(rows, id: \.id) { row in
        codeText(row.pieces)
          .font(.system(size: 14, design: .monospaced))
          .frame(maxWidth: .infinity, alignment: .leading)
          .frame(height: 22)
          .padding(.horizontal, 8)
          .background(
            RoundedRectangle(cornerRadius: 4)
              // Solid (not see-through), so a line sliding over another one hides it cleanly.
              .fill(changed.contains(row.id) ? Color(hex: 0x233950) : ink)
              .shadow(color: .black.opacity(lifted.contains(row.id) ? 0.35 : 0), radius: 4, y: 2)
          )
          .offset(x: lifted.contains(row.id) ? 24 : 0)   // step aside while the lines swap
          .zIndex(lifted.contains(row.id) ? 1 : 0)
          .transition(.opacity)
      }
    }
    .frame(height: 7 * 22, alignment: .top)   // room for the longest chain, so nothing jumps
    .clipped()
    .padding(.vertical, 12)
    .padding(.horizontal, 10)
    .background(ink, in: RoundedRectangle(cornerRadius: 12))
    .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
    .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
  }

  // MARK: Actions

  // Switch to a new choice, and light up the code lines that moved, changed or are new.
  func update(_ newSides: Sides, _ newOrder: Order, _ newExtra: Extra) async {
    let before = codeRows(sides, order, extra)
    let after = codeRows(newSides, newOrder, newExtra)
    // A layer we've never measured starts on the current outer layer (so it doesn't grow from zero).
    for name in layers(newSides, newOrder, newExtra) where frames[name] == nil {
      frames[name] = frames[outer]
    }
    // Where each line was before (by id), and what it said.
    var oldIndex: [String: Int] = [:]
    var oldText: [String: String] = [:]
    for (i, row) in before.enumerated() {
      oldIndex[row.id] = i
      oldText[row.id] = row.text
    }
    // Lines that move DOWN step aside first, so the lines pass side by side.
    var goingDown: Set<String> = []
    for (i, row) in after.enumerated() {
      if let old = oldIndex[row.id], i > old, oldText[row.id] == row.text { goingDown.insert(row.id) }
    }
    if order != newOrder && !goingDown.isEmpty {
      withAnimation(.easeOut(duration: 0.2)) {
        lifted = goingDown
        changed = goingDown
      }
      await wait(0.2)
    }
    withAnimation(.spring(duration: 0.55, bounce: 0.1)) {
      sides = newSides
      order = newOrder
      extra = newExtra
      changed = []
      for (i, row) in after.enumerated() where oldIndex[row.id] != i || oldText[row.id] != row.text {
        changed.insert(row.id)
      }
    }
    if !lifted.isEmpty {
      await wait(0.4)
      withAnimation(.spring(duration: 0.4, bounce: 0.1)) { lifted = [] }
    }
  }

  func pick(_ option: Sides) { Task { await update(option, order, extra) } }
  func pick(_ option: Order) { Task { await update(sides, option, extra) } }
  func pick(_ option: Extra) { Task { await update(sides, order, option) } }

  // MARK: Demo (-demo launch argument)

  var fingerDot: some View {
    Circle()
      .fill(ink.opacity(0.18))
      .overlay(Circle().stroke(ink.opacity(0.5), lineWidth: 1.5))
      .frame(width: 30, height: 30)
      .scaleEffect(touchOn ? 1 : 1.4)
      .opacity(touchOn ? 1 : 0)
      .position(touch)
      .allowsHitTesting(false)
  }

  func wait(_ seconds: Double) async {
    try? await Task.sleep(for: .seconds(seconds))
  }

  // Show the finger dot on a row, then press it.
  func demoTap(_ key: String, _ press: () -> Void) async {
    guard let spot = spots[key] else { return }
    touch = CGPoint(x: spot.x - 30, y: spot.y)
    withAnimation(.easeOut(duration: 0.15)) { touchOn = true }
    await wait(0.18)
    press()
    await wait(0.25)
    withAnimation(.easeOut(duration: 0.2)) { touchOn = false }
  }

  func tap(_ option: Sides, then seconds: Double) async {
    await demoTap(option.name) { pick(option) }
    await wait(seconds)
  }
  func tap(_ option: Order, then seconds: Double) async {
    await demoTap(option.name) { pick(option) }
    await wait(seconds)
  }
  func tap(_ option: Extra, then seconds: Double) async {
    await demoTap(option.name) { pick(option) }
    await wait(seconds)
  }

  func runDemo() async {
    await wait(2.4)                          // padding(20), then background
    await tap(Sides.standard, then: 2.6)     // .padding() = 16
    await tap(Sides.leading, then: 2.6)      // one side
    await tap(Sides.top, then: 2.5)
    await tap(Sides.horizontal, then: 2.9)   // pill look
    await tap(Sides.custom, then: 2.9)       // EdgeInsets
    await tap(Sides.all, then: 1.3)
    await tap(Order.backgroundFirst, then: 3.0)
    await tap(Extra.clip, then: 2.8)         // capsule hugs the text
    await tap(Order.paddingFirst, then: 2.8) // capsule cuts the box
    await tap(Extra.border, then: 2.6)
    await tap(Order.backgroundFirst, then: 2.8)
    await tap(Extra.nested, then: 2.6)
    await tap(Order.paddingFirst, then: 3.0) // end: nested layers
  }
}

// A light dot pattern behind the demo, like a design canvas.
struct DotGrid: View {
  var body: some View {
    Canvas { context, size in
      let step: CGFloat = 14
      for x in stride(from: step / 2, to: size.width, by: step) {
        for y in stride(from: step / 2, to: size.height, by: step) {
          context.fill(Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)),
                       with: .color(Color(hex: 0xCBD5E1)))
        }
      }
    }
  }
}

#Preview { ContentView() }
