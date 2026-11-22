import SwiftUI

@main
struct AnimatedTextApp: App {
    var body: some Scene { WindowGroup { if CommandLine.arguments.contains("-reel") { ReelView() } else { ContentView() } } }
}

// The screen for the Figma post "SwiftUI – Animated Text" (after the CSS reel by arfcode).
// Each card's content is exactly the code shown in its code window on the post (2-space indents).
struct ContentView: View {
  var body: some View {
    VStack(spacing: 20) {
      card {   // 1 Fade Up
        Text("Fade Up")
          .phaseAnimator([false, true]) { text, up in
            text.opacity(up ? 1 : 0)
              .offset(y: up ? 0 : 20)
          }
      }
      card {   // 2 Typing
        TimelineView(.periodic(from: .now, by: 0.15)) { t in
          let n = Int(t.date.timeIntervalSince1970 * 6) % 17
          Text(String("Typing Animation".prefix(n)) + "|")
        }
      }
      card {   // 3 Gradient
        Text("Gradient Text")
          .foregroundStyle(.linearGradient(
            colors: [.cyan, .purple, .pink],
            startPoint: .leading, endPoint: .trailing))
          .phaseAnimator([0.0, 120.0]) { text, hue in
            text.hueRotation(.degrees(hue))
          }
      }
      card {   // 4 Reveal
        Text("Reveal Text")
          .phaseAnimator([false, true]) { text, on in
            text.mask(alignment: .leading) {
              Rectangle().frame(width: on ? 220 : 0)
            }
          }
      }
      card {   // 5 Neon
        Text("Neon Light")
          .foregroundStyle(.cyan)
          .phaseAnimator([2.0, 14.0]) { text, glow in
            text.shadow(color: .cyan, radius: glow)
          }
      }
      card {   // 6 Wave
        TimelineView(.animation) { t in
          let s = t.date.timeIntervalSince1970 * 6
          HStack(spacing: 2) {
            ForEach(Array("Wave!".enumerated()), id: \.offset) { i, c in
              Text(String(c)).offset(y: sin(s + Double(i)) * 8)
            }
          }
        }
      }
    }
    .font(.system(size: 28, weight: .bold))
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(red: 0.04, green: 0.07, blue: 0.16))
  }

  // One effect card: dark navy, soft edge, effect in the middle.
  func card(@ViewBuilder _ content: () -> some View) -> some View {
    content()
      .frame(width: 360, height: 110)
      .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.07, green: 0.11, blue: 0.22)))
      .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
  }
}
