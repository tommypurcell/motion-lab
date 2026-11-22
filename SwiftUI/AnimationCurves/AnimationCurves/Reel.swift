import SwiftUI

// The easing race reel: 8 lanes, same distance, same 1.4 s, different curves.
// Every ball runs exactly the code in the window (LANE_CODE); each lane's label is its curve (CURVES).

struct Lane: View {
  let curve: Animation
  let go: Bool
  var body: some View {
    Circle()
      .offset(x: go ? 820 : 0)
      .animation(curve, value: go)
  }
}

let LANE_CODE = #"""
Circle()
  .offset(x: go ? 820 : 0)
  .animation(curve, value: go)
"""#

let CURVES: [(label: String, curve: Animation, color: UInt32)] = [
  (".linear(duration: 1.4)", .linear(duration: 1.4), 0x38BDF8),
  (".easeIn(duration: 1.4)", .easeIn(duration: 1.4), 0x818CF8),
  (".easeOut(duration: 1.4)", .easeOut(duration: 1.4), 0xA78BFA),
  (".easeInOut(duration: 1.4)", .easeInOut(duration: 1.4), 0xE879F9),
  (".spring(duration: 1.4, bounce: 0.5)", .spring(duration: 1.4, bounce: 0.5), 0xFB7185),
  (".bouncy(duration: 1.4)", .bouncy(duration: 1.4), 0xFB923C),
  (".snappy(duration: 1.4)", .snappy(duration: 1.4), 0xFBBF24),
  (".smooth(duration: 1.4)", .smooth(duration: 1.4), 0x34D399),
]

struct Track: View {
  let label: String
  let curve: Animation
  let color: UInt32
  let go: Bool
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      CodeText(code: label, size: 26)
      ZStack(alignment: .leading) {
        Capsule().fill(hex(0x111A2E))
          .overlay(Capsule().stroke(Color.white.opacity(0.06)))
        // start and finish marks
        Rectangle().fill(Color.white.opacity(0.10)).frame(width: 2, height: 44).offset(x: 12 + 28 - 1)
        Rectangle().fill(Color.white.opacity(0.35)).frame(width: 3, height: 52).offset(x: 12 + 820 + 28 - 1)
        Lane(curve: curve, go: go)
          .frame(width: 56, height: 56)
          .foregroundStyle(hex(color))
          .shadow(color: hex(color).opacity(0.6), radius: 14)
          .padding(.leading, 12)
      }
      .frame(height: 76)
    }
  }
}

struct ReelCanvas: View {
  @State var go = false
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      TitleBlock(title: "Easing", subtitle: "8 curves · same distance · same 1.4 s")
      Spacer().frame(height: 48)
      CodeWindow(code: LANE_CODE, size: 28)
      Spacer().frame(height: 48)
      VStack(alignment: .leading, spacing: 26) {
        ForEach(0 ..< CURVES.count, id: \.self) { i in
          Track(label: CURVES[i].label, curve: CURVES[i].curve, color: CURVES[i].color, go: go)
        }
      }
      Spacer(minLength: 32)
      Footer(apis: "Animation curves, .animation(_:value:)")
    }
    .reelCanvas()
    .task {
      try? await Task.sleep(for: .seconds(3))
      while !Task.isCancelled {
        go.toggle()
        try? await Task.sleep(for: .seconds(2.4))
      }
    }
  }
}
