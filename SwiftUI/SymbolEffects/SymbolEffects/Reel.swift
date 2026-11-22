import SwiftUI

// "Every .symbolEffect" reel: 8 SF Symbols, each running a different effect.
// Each FX view runs exactly the code in its window (REEL_CODE). `tick` goes up every 2 s; `on` flips with it.

struct FX1: View {
  let tick: Int, on: Bool
  var body: some View {
    Image(systemName: "bell.fill")
      .symbolEffect(.bounce, value: tick)
  }
}

struct FX2: View {
  let tick: Int, on: Bool
  var body: some View {
    Image(systemName: "dot.radiowaves.left.and.right")
      .symbolEffect(.pulse, value: tick)
  }
}

struct FX3: View {
  let tick: Int, on: Bool
  var body: some View {
    Image(systemName: "wifi")
      .symbolEffect(.variableColor, value: tick)
  }
}

struct FX4: View {
  let tick: Int, on: Bool
  var body: some View {
    Image(systemName: "magnifyingglass")
      .symbolEffect(.scale.up, isActive: on)
  }
}

struct FX5: View {
  let tick: Int, on: Bool
  var body: some View {
    Image(systemName: "hand.wave.fill")
      .symbolEffect(.wiggle, value: tick)
  }
}

struct FX6: View {
  let tick: Int, on: Bool
  var body: some View {
    Image(systemName: "gearshape.fill")
      .symbolEffect(.rotate, value: tick)
  }
}

struct FX7: View {
  let tick: Int, on: Bool
  var body: some View {
    Image(systemName: "heart.fill")
      .symbolEffect(.breathe, value: tick)
  }
}

struct FX8: View {
  let tick: Int, on: Bool
  var body: some View {
    Image(systemName: on ? "play.fill" : "pause.fill")
      .contentTransition(.symbolEffect(.replace))
  }
}

let REEL_CODE: [String] = [
#"""
Image(systemName: "bell.fill")
  .symbolEffect(.bounce, value: tick)
"""#,
#"""
Image(systemName: "dot.radiowaves.left.and.right")
  .symbolEffect(.pulse, value: tick)
"""#,
#"""
Image(systemName: "wifi")
  .symbolEffect(.variableColor, value: tick)
"""#,
#"""
Image(systemName: "magnifyingglass")
  .symbolEffect(.scale.up, isActive: on)
"""#,
#"""
Image(systemName: "hand.wave.fill")
  .symbolEffect(.wiggle, value: tick)
"""#,
#"""
Image(systemName: "gearshape.fill")
  .symbolEffect(.rotate, value: tick)
"""#,
#"""
Image(systemName: "heart.fill")
  .symbolEffect(.breathe, value: tick)
"""#,
#"""
Image(systemName: on ? "play.fill" : "pause.fill")
  .contentTransition(.symbolEffect(.replace))
"""#,
]

let TINTS: [UInt32] = [0xFBBF24, 0x38BDF8, 0x34D399, 0xA78BFA, 0xFB923C, 0x94A3B8, 0xFB7185, 0xE879F9]

struct ReelCanvas: View {
  @State var tick = 0
  var body: some View {
    let on = tick.isMultiple(of: 2)
    let effects: [AnyView] = [
      AnyView(FX1(tick: tick, on: on)), AnyView(FX2(tick: tick, on: on)), AnyView(FX3(tick: tick, on: on)), AnyView(FX4(tick: tick, on: on)),
      AnyView(FX5(tick: tick, on: on)), AnyView(FX6(tick: tick, on: on)), AnyView(FX7(tick: tick, on: on)), AnyView(FX8(tick: tick, on: on)),
    ]
    VStack(alignment: .leading, spacing: 0) {
      TitleBlock(title: "Symbol Effects", subtitle: "8 effects · one modifier each")
      Spacer().frame(height: 48)
      VStack(alignment: .leading, spacing: 22) {
        ForEach(0 ..< 8, id: \.self) { i in
          HStack(spacing: 20) {
            effects[i]
              .font(.system(size: 84, weight: .semibold))
              .foregroundStyle(hex(TINTS[i]))
              .frame(width: 164, height: 164)
              .background(RoundedRectangle(cornerRadius: 28).fill(hex(TINTS[i]).opacity(0.12)))
              .overlay(RoundedRectangle(cornerRadius: 28).stroke(hex(TINTS[i]).opacity(0.25)))
              .softShadow()
            CodeWindow(code: REEL_CODE[i], size: 24, dots: false)
              .frame(height: 164)
          }
        }
      }
      Spacer(minLength: 24)
      Footer(apis: "symbolEffect, contentTransition")
    }
    .reelCanvas()
    .task {
      try? await Task.sleep(for: .seconds(3))
      while !Task.isCancelled {
        tick += 1
        try? await Task.sleep(for: .seconds(2))
      }
    }
  }
}
