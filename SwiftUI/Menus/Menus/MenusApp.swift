import SwiftUI

@main
struct MenusApp: App {
  var body: some Scene { WindowGroup { ReelView { ReelCanvas() } } }
}

// The Menus reel: 5 menu open/close styles, each looping on its own (3.6 s loop).
// Each code window shows lines copied exactly from the view next to it (checked by ../TabBarsProof/check_code.py).

let rowIcons = ["square.and.pencil", "photo", "doc.viewfinder", "folder"]
let rowNames = ["New note", "Photo", "Scan", "Folder"]
let rowColors = [hex(0x818CF8), hex(0xF472B6), hex(0x34D399), hex(0xFBBF24)]

struct MenuRow: View {
  let i: Int
  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: rowIcons[i]).foregroundStyle(rowColors[i]).frame(width: 30)
      Text(rowNames[i]).foregroundStyle(.white)
      Spacer(minLength: 0)
    }
    .font(.system(size: 24, weight: .semibold))
  }
}

// 1. Morph: the plus button becomes the panel
struct MenuPanel: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      ForEach(0 ..< 3, id: \.self) { MenuRow(i: $0) }
    }
    .padding(22)
    .frame(width: 260, height: 180)
    .background(RoundedRectangle(cornerRadius: 28).fill(hex(0x312E81)))
  }
}
struct PlusButton: View {
  var body: some View {
    Image(systemName: "plus")
      .font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
      .frame(width: 76, height: 76)
      .background(Circle().fill(.indigo))
  }
}
struct Menu1: View {
  let open: Bool
  @Namespace var ns
  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      Color.clear
      Group {
        if open { MenuPanel() }
        else { PlusButton() }
      }
      .matchedGeometryEffect(id: "m", in: ns)
      .animation(.bouncy, value: open)
    }
    .padding(28)
  }
}

// 2. Popover fan
struct Leaf: View {
  let i: Int
  var body: some View {
    Image(systemName: rowIcons[i])
      .font(.system(size: 28, weight: .semibold)).foregroundStyle(.white)
      .frame(width: 70, height: 70)
      .background(Circle().fill(rowColors[i].gradient))
      .shadow(color: rowColors[i].opacity(0.5), radius: 10, y: 4)
  }
}
struct Menu2: View {
  let open: Bool
  var body: some View {
    ZStack {
      ForEach(0 ..< 4, id: \.self) { i in
        Leaf(i: i)
          .offset(y: open ? -118 : 0)
          .rotationEffect(.degrees(
            open ? Double(i) * 34 - 51 : 0))
          .opacity(open ? 1 : 0)
      }
      Image(systemName: "ellipsis")
        .font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
        .frame(width: 76, height: 76)
        .background(Circle().fill(hex(0x334155)))
        .rotationEffect(.degrees(open ? 90 : 0))
    }
    .animation(.spring(duration: 0.55, bounce: 0.4), value: open)
    .offset(y: 70)
  }
}

// 3. Stacked cards
struct CardRow: View {
  let i: Int
  var body: some View {
    MenuRow(i: i)
      .padding(.horizontal, 18)
      .frame(width: 250, height: 48)
      .background(RoundedRectangle(cornerRadius: 14).fill(hex(0x1E293B)))
      .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1)))
      .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
  }
}
struct Menu3: View {
  let open: Bool
  var body: some View {
    ZStack(alignment: .top) {
      ForEach(0 ..< 4, id: \.self) { i in
        let d = Double(i)
        CardRow(i: i)
          .offset(y: open ? d * 56 : d * 10)
          .scaleEffect(open ? 1 : 1 - d / 16)
          .zIndex(-d)
      }
    }
    .animation(.spring(duration: 0.5, bounce: 0.35), value: open)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    .padding(.trailing, 28)
    .padding(.top, open ? 32 : 100)
  }
}

// 4. Gooey glass group
let gIcons = ["plus", "camera.fill", "mic.fill", "photo.fill"]
struct Menu4: View {
  let open: Bool
  var body: some View {
    GlassEffectContainer(spacing: 30) {
      HStack(spacing: open ? 18 : -70) {
        ForEach(gIcons, id: \.self) { s in
          Image(systemName: open ? s : "plus")
            .padding(22).glassEffect()
        }
      }
    }
    .font(.system(size: 26, weight: .semibold))
    .foregroundStyle(.white)
    .animation(.bouncy(duration: 0.6), value: open)
  }
}

// 5. Command palette
struct PaletteRow: View {
  let i: Int
  var body: some View {
    MenuRow(i: i)
      .padding(.horizontal, 16)
      .frame(width: 250, height: 46)
      .background(RoundedRectangle(cornerRadius: 12).fill(i == 0 ? hex(0x334155) : .clear))
  }
}
struct Menu5: View {
  let open: Bool
  var body: some View {
    VStack(spacing: 6) {
      HStack(spacing: 12) {
        Image(systemName: "magnifyingglass")
        Text("Search…")
        Spacer()
        Text("⌘K").font(.system(size: 20, weight: .semibold, design: .monospaced))
      }
      .font(.system(size: 24))
      .foregroundStyle(hex(0x94A3B8))
      .padding(.horizontal, 16)
      .frame(width: 258, height: 54)
      .background(RoundedRectangle(cornerRadius: 14).fill(hex(0x1E293B)))
      .offset(y: open ? 0 : -24)
      .opacity(open ? 1 : 0)
      .animation(.snappy, value: open)
      ForEach(0 ..< 3, id: \.self) { i in
        PaletteRow(i: i)
          .offset(y: open ? 0 : -30)
          .opacity(open ? 1 : 0)
          .animation(.snappy
            .delay(Double(i) * 0.06),
            value: open)
      }
    }
    .padding(8)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    .padding(.top, 24).padding(.trailing, 20)
    .overlay {
      Text("⌘ K")
        .font(.system(size: 30, weight: .semibold, design: .rounded))
        .foregroundStyle(hex(0xCBD5E1))
        .frame(width: 110, height: 72)
        .background(RoundedRectangle(cornerRadius: 16).fill(hex(0x1E293B)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12)))
        .shadow(color: .black.opacity(0.4), radius: 8, y: 5)
        .scaleEffect(open ? 0.6 : 1)
        .opacity(open ? 0 : 1)
        .animation(.snappy, value: open)
    }
  }
}

let REEL_TITLES = ["Morph", "Popover fan", "Stacked cards", "Gooey glass", "Command palette"]
let REEL_CODE: [String] = [
#"""
Group {
  if open { MenuPanel() }
  else { PlusButton() }
}
.matchedGeometryEffect(id: "m", in: ns)
.animation(.bouncy, value: open)
"""#,
#"""
ForEach(0 ..< 4, id: \.self) { i in
  Leaf(i: i)
    .offset(y: open ? -118 : 0)
    .rotationEffect(.degrees(
      open ? Double(i) * 34 - 51 : 0))
    .opacity(open ? 1 : 0)
}
"""#,
#"""
ForEach(0 ..< 4, id: \.self) { i in
  let d = Double(i)
  CardRow(i: i)
    .offset(y: open ? d * 56 : d * 10)
    .scaleEffect(open ? 1 : 1 - d / 16)
    .zIndex(-d)
}
"""#,
#"""
GlassEffectContainer(spacing: 30) {
  HStack(spacing: open ? 18 : -70) {
    ForEach(gIcons, id: \.self) { s in
      Image(systemName: open ? s : "plus")
        .padding(22).glassEffect()
    }
  }
}
"""#,
#"""
ForEach(0 ..< 3, id: \.self) { i in
  PaletteRow(i: i)
    .offset(y: open ? 0 : -30)
    .opacity(open ? 1 : 0)
    .animation(.snappy
      .delay(Double(i) * 0.06),
      value: open)
}
"""#,
]

// One demo row: the live menu card on the left with its number, the code on the right.
struct Demo<Content: View>: View {
  let n: Int
  var glass = false
  @ViewBuilder let content: () -> Content
  var body: some View {
    HStack(alignment: .center, spacing: 24) {
      ZStack(alignment: .topLeading) {
        if glass { Backdrop() } else { hex(0x0F1A33) }
        content().frame(maxWidth: .infinity, maxHeight: .infinity)
        NumberBadge(n: n).padding(16)
      }
      .frame(width: 360, height: 280)
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.08)))
      .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
      .shadow(color: .black.opacity(0.3), radius: 14, y: 10)
      CodeWindow(code: REEL_CODE[n - 1], size: 21)
    }
  }
}

struct ReelCanvas: View {
  var body: some View {
    // step 0.3 s; 12 ticks = a 3.6 s loop; open for half; each menu starts 1 tick after the one above
    Beat(step: 0.3) { t in
      let open = { (k: Int) in (t - k) % 12 < 6 }
      VStack(alignment: .leading, spacing: 0) {
        ReelTitle(title: "Menus", subtitle: "5 open / close styles · which one would you ship?")
        Spacer(minLength: 24)
        VStack(alignment: .leading, spacing: 20) {
          Demo(n: 1) { Menu1(open: open(0)) }
          Demo(n: 2) { Menu2(open: open(1)) }
          Demo(n: 3) { Menu3(open: open(2)) }
          Demo(n: 4, glass: true) { Menu4(open: open(3)) }
          Demo(n: 5) { Menu5(open: open(4)) }
        }
        Spacer(minLength: 24)
        Text("Real SwiftUI · iOS 26 · matchedGeometryEffect, GlassEffectContainer, spring")
          .font(.system(size: 22)).foregroundStyle(hex(0x64748B))
          .frame(maxWidth: .infinity)
      }
      .padding(.horizontal, 64).padding(.top, 64).padding(.bottom, 44)
      .frame(width: 1080, height: 1920, alignment: .topLeading)
      .background(REEL_BG)
    }
  }
}
