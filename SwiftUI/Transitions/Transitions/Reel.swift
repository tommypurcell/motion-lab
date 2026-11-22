import SwiftUI

// Page transitions reel: 8 phone tiles, each looping a different screen change.
// Tiles 1–7 run exactly TILE_CODE with the transition in their label; tile 8 runs HeroTile (MATCHED_CODE).

struct Tile<T: Transition>: View {
  let t: T
  let page: Bool
  let tint: Color
  var body: some View {
    ZStack {
      if page { DetailScreen(tint: tint).transition(t) }
      else { ListScreen(tint: tint).transition(t) }
    }
  }
}

let TILE_CODE = #"""
if page { DetailScreen().transition(t) }
else { ListScreen().transition(t) }
"""#

struct HeroTile: View {
  @Namespace var ns
  let page: Bool
  let tint: Color
  var body: some View {
    ZStack(alignment: .top) {
      if page {
        RoundedRectangle(cornerRadius: 14).fill(tint)
          .matchedGeometryEffect(
            id: "card", in: ns)
          .frame(height: 150)
          .padding(8)
      } else {
        GridScreen(tint: tint) { card in
          card.matchedGeometryEffect(
            id: "card", in: ns)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}

let MATCHED_CODE = #"""
.matchedGeometryEffect(
  id: "card", in: ns)
"""#

let TINTS: [UInt32] = [0x38BDF8, 0x818CF8, 0xA78BFA, 0xE879F9, 0xFB7185, 0xFB923C, 0xFBBF24, 0x34D399]

// --- the two mini screens (just decoration) ---

struct ListScreen: View {
  let tint: Color
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Capsule().fill(Color.white.opacity(0.85)).frame(width: 64, height: 10).padding(.top, 26)
      ForEach(0 ..< 5, id: \.self) { i in
        HStack(spacing: 8) {
          Circle().fill(i == 0 ? tint : Color.white.opacity(0.18)).frame(width: 22, height: 22)
          VStack(alignment: .leading, spacing: 5) {
            Capsule().fill(Color.white.opacity(0.35)).frame(width: 58, height: 7)
            Capsule().fill(Color.white.opacity(0.15)).frame(width: 40, height: 6)
          }
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(hex(0x1E293B))
  }
}

struct DetailScreen: View {
  let tint: Color
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      RoundedRectangle(cornerRadius: 12).fill(tint.gradient).frame(height: 116)
      Capsule().fill(Color.white.opacity(0.85)).frame(width: 80, height: 10)
      Capsule().fill(Color.white.opacity(0.25)).frame(width: 96, height: 7)
      Capsule().fill(Color.white.opacity(0.25)).frame(width: 70, height: 7)
      Spacer(minLength: 0)
    }
    .padding(8)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(hex(0x0F172A))
  }
}

struct GridScreen<Card: View>: View {
  let tint: Color
  @ViewBuilder let hero: (AnyView) -> Card
  var body: some View {
    let cell = RoundedRectangle(cornerRadius: 8)
    VStack(spacing: 8) {
      Capsule().fill(Color.white.opacity(0.85)).frame(width: 64, height: 10).padding(.top, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
      HStack(spacing: 8) {
        hero(AnyView(cell.fill(tint))).frame(height: 54)
        cell.fill(Color.white.opacity(0.15)).frame(height: 54)
      }
      HStack(spacing: 8) {
        cell.fill(Color.white.opacity(0.15)).frame(height: 54)
        cell.fill(Color.white.opacity(0.15)).frame(height: 54)
      }
    }
    .padding(.horizontal, 12)
  }
}

// A small phone: dark bezel, rounded screen, clipped so transitions stay inside.
struct Phone<Content: View>: View {
  let content: Content
  init(@ViewBuilder _ content: () -> Content) { self.content = content() }
  var body: some View {
    content
      .frame(width: 150, height: 280)
      .background(hex(0x1E293B))
      .clipShape(RoundedRectangle(cornerRadius: 24))
      .padding(5)
      .background(RoundedRectangle(cornerRadius: 29).fill(hex(0x020617)))
      .overlay(RoundedRectangle(cornerRadius: 29).stroke(Color.white.opacity(0.14), lineWidth: 1.5))
      .softShadow()
  }
}

struct Cell<Content: View>: View {
  let label: String
  let content: Content
  init(_ label: String, @ViewBuilder _ content: () -> Content) { self.label = label; self.content = content() }
  var body: some View {
    HStack(alignment: .center, spacing: 18) {
      Phone { content }
      CodeText(code: label, size: 22)
      Spacer(minLength: 0)
    }
  }
}

struct ReelCanvas: View {
  @State var page = false
  var body: some View {
    let cols = [GridItem(.flexible(), spacing: 16, alignment: .leading), GridItem(.flexible(), spacing: 16, alignment: .leading)]
    VStack(alignment: .leading, spacing: 0) {
      TitleBlock(title: "Page Transitions", subtitle: "8 ways to change the screen")
      Spacer().frame(height: 40)
      CodeWindow(code: TILE_CODE, size: 26, dots: false)
      Spacer().frame(height: 36)
      LazyVGrid(columns: cols, alignment: .leading, spacing: 28) {
        Cell(".slide") { Tile(t: .slide, page: page, tint: hex(TINTS[0])) }
        Cell(".opacity") { Tile(t: .opacity, page: page, tint: hex(TINTS[1])) }
        Cell(".scale") { Tile(t: .scale, page: page, tint: hex(TINTS[2])) }
        Cell(".move(edge: .bottom)") { Tile(t: .move(edge: .bottom), page: page, tint: hex(TINTS[3])) }
        Cell(".push(from: .trailing)") { Tile(t: .push(from: .trailing), page: page, tint: hex(TINTS[4])) }
        Cell("AsymmetricTransition(\n  insertion: .scale,\n  removal: .opacity)") {
          Tile(t: AsymmetricTransition(insertion: .scale, removal: .opacity), page: page, tint: hex(TINTS[5]))
        }
        Cell(".blurReplace") { Tile(t: .blurReplace, page: page, tint: hex(TINTS[6])) }
        Cell(MATCHED_CODE) { HeroTile(page: page, tint: hex(TINTS[7])) }
      }
      Spacer(minLength: 24)
      Footer(apis: "transition, matchedGeometryEffect")
    }
    .reelCanvas(hPad: 48, top: 92)
    .task {
      try? await Task.sleep(for: .seconds(3))
      while !Task.isCancelled {
        withAnimation(.smooth(duration: 0.8)) { page.toggle() }
        try? await Task.sleep(for: .seconds(2))
      }
    }
  }
}
