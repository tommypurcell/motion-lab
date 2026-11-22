import SwiftUI

// XCODE LOOK
// A code editor that looks like Tommy's real Xcode
// (assets/tommy-xcode-screenshot.png): light macOS toolbar and jump bar on top,
// a dark editor below with sticky scope headers, line numbers and Xcode's colors.
// Colors were sampled from that screenshot. Numbers and @State aren't in it,
// so those two come from Xcode's "Default (Dark).xccolortheme".
// (Same file in LoginLiveProof and ProductLiveProof.)

// MARK: - Colors

enum Xcode {
  // Editor (sampled from the screenshot)
  static let background = Color(hex: 0x292A2F)
  static let gutter = Color(hex: 0x28292E)
  static let currentLine = Color(hex: 0x303238)
  static let stickyBG = Color(hex: 0x26282C)
  static let stickyLine = Color(hex: 0x3D4044)
  static let lineNumber = Color(hex: 0x737377)
  static let lineNumberCurrent = Color(hex: 0xDFDFE0)
  static let plain = Color(hex: 0xDFDFE0)
  static let keyword = Color(hex: 0xEE81B0)        // bold
  static let systemType = Color(hex: 0xD5BBFA)     // View, Text, Button
  static let projectType = Color(hex: 0xBBF0E4)    // LoginView, ProductCard
  static let projectMember = Color(hex: 0x89C0B4)  // user, field, rose
  static let systemMember = Color(hex: 0xAB83E4)   // .font, .white, label:
  static let declType = Color(hex: 0x89DCFB)       // struct LoginView
  static let declOther = Color(hex: 0x69AEC9)      // var body
  static let string = Color(hex: 0xEF8876)
  static let comment = Color(hex: 0x818C97)
  // From the theme file (not in the screenshot)
  static let number = Color(.sRGB, red: 0.814983, green: 0.749393, blue: 0.412334)
  static let attribute = Color(.sRGB, red: 0.74902, green: 0.521569, blue: 0.333333)
  static let selection = Color(.sRGB, red: 0.317647, green: 0.356862, blue: 0.439215)
  static let cursor = Color(hex: 0xDFDFE0)
  // (The toolbar and jump bar colors are in `Chrome` below.)
  static let projectBlue = Color(hex: 0x3B86F7)
  static let propertyCyan = Color(hex: 0x56BCC9)
  static let methodBlue = Color(hex: 0x5E9CF7)
  static let swiftOrange = Color(hex: 0xF05138)
}

// MARK: - Window chrome (toolbar + jump bar), light or dark

// The toolbar and jump bar above the editor. `.light` is sampled from Tommy's screenshot.
// `.dark` is Xcode in macOS dark appearance: text colors are NSColor.labelColor (white 85%)
// and secondaryLabelColor (white 55%) in dark mode; the backgrounds are Xcode's own grays
// (NSColor.windowBackgroundColor is #1E1E1E, darker than the editor, so it isn't used).
struct Chrome {
  let toolbar, jumpBar, pill, divider, bottomLine, text, secondary, icon: Color

  static let light = Chrome(
    toolbar: Color(hex: 0xECEDED), jumpBar: Color(hex: 0xE6E6E7), pill: Color(hex: 0xF9F9FA),
    divider: Color(hex: 0xD2D2D2), bottomLine: Color(hex: 0xD2D2D2),
    text: Color(hex: 0x242424), secondary: Color(hex: 0x242424).opacity(0.75), icon: Color(hex: 0x8A8A8E))

  static let dark = Chrome(
    toolbar: Color(hex: 0x2C2C30), jumpBar: Color(hex: 0x232327), pill: Color(hex: 0x3A3A3E),
    divider: .white.opacity(0.1),                       // NSColor.separatorColor (dark)
    bottomLine: .black.opacity(0.4),
    text: Color(hex: 0xE5E5E7), secondary: Color(hex: 0x98989D), icon: Color(hex: 0x8E8E93))
}

// MARK: - Syntax coloring

enum Kind {
  case keyword, attribute, declType, declOther, systemType, projectType,
       systemMember, projectMember, string, number, comment, plain
}

func color(of kind: Kind) -> Color {
  switch kind {
  case .keyword: Xcode.keyword
  case .attribute: Xcode.attribute
  case .declType: Xcode.declType
  case .declOther: Xcode.declOther
  case .systemType: Xcode.systemType
  case .projectType: Xcode.projectType
  case .systemMember: Xcode.systemMember
  case .projectMember: Xcode.projectMember
  case .string: Xcode.string
  case .number: Xcode.number
  case .comment: Xcode.comment
  case .plain: Xcode.plain
  }
}

let keywords: Set<String> = ["import", "struct", "var", "let", "func", "if", "else", "some",
                             "return", "extension", "init", "self", "in", "true", "false",
                             "private", "nil", "try", "await"]

// Split one line into colored pieces, the way Xcode colors them.
// `projectTypes` and `projectNames` are set by each app (its own types and properties).
func pieces(_ line: String) -> [(String, Kind)] {
  let chars = Array(line)
  // A function signature, or the wrapped second line of one (`_ text: Binding<String>) -> …`).
  let trimmedLine = line.trimmingCharacters(in: .whitespaces)
  let isSignature = trimmedLine.hasPrefix("func ") || trimmedLine.hasPrefix("_ ")
  var result: [(String, Kind)] = []
  var previousWord = ""
  var i = 0
  while i < chars.count {
    let c = chars[i]
    if c == "/" && i + 1 < chars.count && chars[i + 1] == "/" {   // a comment, to the end
      result.append((String(chars[i...]), .comment))
      break
    } else if c == "\"" {                              // a string, up to the closing quote
      var j = i + 1
      while j < chars.count && chars[j] != "\"" { j += 1 }
      j = min(j + 1, chars.count)
      result.append((String(chars[i..<j]), .string))
      i = j
    } else if c.isNumber {                             // a number: 0.05, 255, 0xBA7E7E
      var j = i
      while j < chars.count {
        let d = chars[j]
        let dotThenDigit = d == "." && j + 1 < chars.count && chars[j + 1].isNumber
        if d.isLetter || d.isNumber || dotThenDigit { j += 1 } else { break }
      }
      result.append((String(chars[i..<j]), .number))
      i = j
    } else if c.isLetter || c == "@" || c == "$" || c == "_" || c == "." {
      var j = i + 1                                    // a word (with its leading . @ or $)
      while j < chars.count && (chars[j].isLetter || chars[j].isNumber || chars[j] == "_") { j += 1 }
      let word = String(chars[i..<j])
      let bare = word.trimmingCharacters(in: CharacterSet(charactersIn: ".$"))
      let isLabel = j < chars.count && chars[j] == ":" && !word.hasPrefix(".")
      var kind = Kind.plain
      if word == "." || word.hasPrefix("..") { kind = .plain }
      else if word.hasPrefix("@") { kind = .attribute }                    // @State
      else if keywords.contains(word) && !isLabel { kind = .keyword }      // struct, var (but `in:` is a label)
      else if previousWord == "struct" { kind = .declType }                // struct LoginView
      else if ["var", "let", "func"].contains(previousWord) { kind = .declOther }   // var body
      else if isLabel {                                                    // argument labels
        if isSignature || word == "_" { kind = .plain }                    // our own parameters
        else if word == "hex" { kind = .projectMember }                    // our Color(hex:)
        else { kind = .systemMember }                                      // font:, spacing:
      }
      else if word.hasPrefix(".") { kind = projectNames.contains(bare) ? .projectMember : .systemMember }
      else if projectTypes.contains(word) { kind = .projectType }
      else if projectNames.contains(bare) { kind = .projectMember }        // user, $user, field
      else if word == "withAnimation" { kind = .systemMember }
      else if word.first!.isUppercase { kind = .systemType }               // View, Text, Color
      result.append((word, kind))
      previousWord = word
      i = j
    } else {
      result.append((String(c), .plain))
      i += 1
    }
  }
  return result
}

// Glue the pieces into one colored Text. Keywords are bold, the rest Medium, like Xcode.
func codeText(_ line: String) -> Text {
  pieces(line).reduce(Text("")) { result, piece in
    result + Text(piece.0)
      .foregroundColor(color(of: piece.1))
      .fontWeight(piece.1 == .keyword ? .bold : .medium)   // SF Mono Medium, like Xcode's theme
  }
}

// MARK: - Scopes (for the sticky headers and the jump bar)

// The declaration lines (struct / var / func / extension) that enclose line `upTo`.
// Returns indexes into `texts`.
func enclosingDeclarations(_ texts: [String], upTo: Int) -> [Int] {
  var stack: [(indent: Int, header: Int)] = []
  for i in 0..<min(upTo, texts.count) {
    let text = texts[i]
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    let indent = text.prefix { $0 == " " }.count
    if trimmed.hasPrefix("}") {
      while let last = stack.last, last.indent >= indent { stack.removeLast() }
    }
    if trimmed.hasSuffix("{") {
      // A signature that wraps (`_ text: Binding<String>) -> some View {`) belongs to the line above.
      let wraps = trimmed.filter { $0 == ")" }.count > trimmed.filter { $0 == "(" }.count
      let header = wraps && i > 0 ? i - 1 : i
      let headerIndent = texts[header].prefix { $0 == " " }.count
      stack.append((headerIndent, header))
    }
  }
  let declarations = ["struct ", "extension ", "func ", "var ", "init"]
  return stack.map(\.header).filter { h in
    let t = texts[h].trimmingCharacters(in: .whitespaces)
    return declarations.contains { t.hasPrefix($0) }
  }
}

// MARK: - The editor view

// One line on screen.
struct EditorRow {
  let id: Int          // stays the same while the line exists (used for scrolling)
  let text: String     // what has been typed so far
  let dying: Bool      // about to be deleted: shown selected, like Xcode
}

struct XcodeEditor: View {
  let project: String            // "LoginLive"
  let fileStem: String           // "LoginView"
  let status: String?            // shown in the toolbar pill, where Xcode says "Finished running…"
  let rows: [EditorRow]
  let current: Int               // id of the line being typed, or -1
  let lastKey: Date              // when the last letter was typed (the cursor blinks when idle)
  var dark = false               // true: dark toolbar + jump bar (macOS dark appearance)

  var chrome: Chrome { dark ? .dark : .light }

  @State private var topRow = 0  // first row at the top of the scroll view

  static let rowHeight: CGFloat = 16      // 11 pt SF Mono × ~1.45, like Tommy's Xcode
  static let topPad: CGFloat = 4

  var body: some View {
    VStack(spacing: 0) {
      toolbar
      jumpBar
      Rectangle().fill(chrome.bottomLine).frame(height: 1)
      code
    }
    .background(Xcode.background.ignoresSafeArea(edges: .bottom))
  }

  // MARK: Toolbar

  var toolbar: some View {
    HStack(spacing: 7) {
      projectIcon(size: 18)
      Text(project)
        .font(.system(size: 13.5, weight: .semibold))
        .foregroundStyle(chrome.text)
        .fixedSize()

      Spacer(minLength: 6)

      HStack(spacing: 5) {
        Image(systemName: "apple.terminal.fill")
          .font(.system(size: 9))
          .foregroundStyle(chrome.icon)
        Text(project)
        chevron
        Image(systemName: "iphone")
          .font(.system(size: 10))
        Text("iPhone 17 Pro").layoutPriority(1)
        if let status {
          Text(status)
            .foregroundStyle(chrome.secondary)
            .minimumScaleFactor(0.85)
            .padding(.leading, 6)
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: status)
        }
      }
      .font(.system(size: 10))
      .foregroundStyle(chrome.text)
      .lineLimit(1)
      .padding(.horizontal, 9)
      .frame(height: 26)
      .background(chrome.pill, in: .capsule)
      .shadow(color: .black.opacity(dark ? 0.25 : 0.08), radius: 2, y: 1)
    }
    .padding(.horizontal, 10)
    .frame(height: 40)
    .background(chrome.toolbar)
  }

  // The blue Xcode project icon: a rounded square with a white hammer.
  func projectIcon(size: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: size * 0.22)
      .fill(Xcode.projectBlue)
      .frame(width: size, height: size)
      .overlay(
        Image(systemName: "hammer.fill")
          .font(.system(size: size * 0.55, weight: .semibold))
          .foregroundStyle(.white)
      )
  }

  // MARK: Jump bar

  var jumpBar: some View {
    HStack(spacing: 4) {
      Image(systemName: "square.grid.2x2")
      Rectangle().fill(chrome.divider).frame(width: 1, height: 12).padding(.horizontal, 3)
      Image(systemName: "chevron.left")
      Image(systemName: "chevron.right").opacity(0.45).padding(.trailing, 4)

      projectIcon(size: 12)
      Text(project).layoutPriority(1)
      chevron
      Image(systemName: "folder.fill").foregroundStyle(chrome.icon)
      Text(project)
      chevron
      Image(systemName: "folder.fill").foregroundStyle(chrome.icon)
      Text("Views").layoutPriority(1)
      chevron
      Image(systemName: "swift").foregroundStyle(Xcode.swiftOrange)
      Text(fileStem).layoutPriority(1)
      chevron
      symbolCrumb
      Spacer(minLength: 0)
    }
    .font(.system(size: 10))
    .foregroundStyle(chrome.text)
    .lineLimit(1)
    .padding(.horizontal, 10)
    .frame(height: 26)
    .background(chrome.jumpBar)
  }

  // The last crumb: the declaration the cursor is in ("P body", "M field(_:_:)").
  @ViewBuilder
  var symbolCrumb: some View {
    let texts = rows.map(\.text)
    let at = rows.firstIndex { $0.id == current }
    let decls = at.map { enclosingDeclarations(texts, upTo: $0 + 1) } ?? []
    let inner = decls.last.map { texts[$0].trimmingCharacters(in: .whitespaces) } ?? ""
    if inner.hasPrefix("func "), let h = decls.last {
      // "field(_:_:)": one "_:" per unnamed parameter (the signature may wrap onto the next line)
      let name = String(inner.dropFirst(5).prefix { $0 != "(" })
      let signature = texts[h] + (texts[h].contains("{") || h + 1 >= texts.count ? "" : texts[h + 1])
      let params = max(signature.components(separatedBy: "_ ").count - 1, 1)
      badge("M", Xcode.methodBlue)
      Text(name + "(" + String(repeating: "_:", count: params) + ")").layoutPriority(2)
    } else if inner.hasPrefix("var body") {
      badge("P", Xcode.propertyCyan)
      Text("body").layoutPriority(2)
    } else {
      Text("No Selection").foregroundStyle(chrome.secondary).layoutPriority(2)
    }
  }

  func badge(_ letter: String, _ color: Color) -> some View {
    Text(letter)
      .font(.system(size: 8.5, weight: .bold))
      .foregroundStyle(.white)
      .frame(width: 12, height: 12)
      .background(color, in: .rect(cornerRadius: 3))
  }

  var chevron: some View {
    Image(systemName: "chevron.right")
      .font(.system(size: 6.5, weight: .semibold))
      .foregroundStyle(chrome.icon)
  }

  // MARK: Code

  var code: some View {
    ScrollViewReader { proxy in
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(Array(rows.enumerated()), id: \.element.id) { number, row in
            line(number: number + 1, row: row, highlighted: row.id == current)
              .id(row.id)
          }
        }
        .padding(.top, Self.topPad)
        .padding(.bottom, 200)   // room to scroll the last lines up
      }
      .onScrollGeometryChange(for: Int.self) { geometry in
        Int(((geometry.contentOffset.y + geometry.contentInsets.top - Self.topPad) / Self.rowHeight).rounded(.up))
      } action: { _, row in
        topRow = max(row, 0)
      }
      .overlay(alignment: .top) { stickyHeaders }
      .clipped()                 // stop above the home bar (a ScrollView draws into it otherwise)
      .onChange(of: current) {
        guard current >= 0 else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
          proxy.scrollTo(current, anchor: UnitPoint(x: 0, y: 0.55))
        }
      }
    }
  }

  // Xcode pins the enclosing struct / var / func lines while you scroll.
  var stickyHeaders: some View {
    let texts = rows.map(\.text)
    var headers = enclosingDeclarations(texts, upTo: topRow).filter { $0 < topRow }
    // The pinned rows cover lines too, so look again a little further down.
    let covered = topRow + headers.count
    headers = enclosingDeclarations(texts, upTo: covered).filter { $0 < covered }
    return VStack(spacing: 0) {
      ForEach(headers, id: \.self) { h in
        line(number: h + 1, row: rows[h], highlighted: false)
          .background(Xcode.stickyBG)
        Rectangle().fill(Xcode.stickyLine).frame(height: 1)
      }
    }
  }

  func line(number: Int, row: EditorRow, highlighted: Bool) -> some View {
    HStack(spacing: 0) {
      Text("\(number)")
        .font(.system(size: 10.5, design: .monospaced))
        .foregroundStyle(highlighted ? Xcode.lineNumberCurrent : Xcode.lineNumber)
        .frame(width: 30, alignment: .trailing)
        .padding(.trailing, 10)
        .background(highlighted ? .clear : Xcode.gutter)
      codeText(row.text)
        .font(.system(size: 11, design: .monospaced))   // SF Mono, like Xcode
        .lineLimit(1)
        .fixedSize()
        .background(row.dying ? Xcode.selection : .clear)
      if highlighted { cursor }
      Spacer(minLength: 0)
    }
    .frame(height: Self.rowHeight)
    .background(highlighted ? Xcode.currentLine : .clear)
  }

  // A thin I-beam. Solid while typing, blinking once typing stops.
  var cursor: some View {
    TimelineView(.periodic(from: .now, by: 0.5)) { context in
      let idle = context.date.timeIntervalSince(lastKey) > 0.5
      let on = !idle || Int(context.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
      Rectangle()
        .fill(Xcode.cursor)
        .frame(width: 1.5, height: 13)
        .opacity(on ? 1 : 0)
    }
  }
}
