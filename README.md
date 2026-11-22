# Motion Lab

Animations I build and post on X ([@purcelldev](https://x.com/purcelldev)), with the full source for each.

```
SwiftUI/<Name>/
  README.md     what it is + how to run
  preview.mp4   the video from the post
  project.yml   XcodeGen project
  <Name>/       the Swift source
```

## SwiftUI

24 animations: 23 small iPhone apps and 1 Mac script (the dual-monitor koi). Real SwiftUI, no packages.

### Run one

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. `cd SwiftUI/<Name>`, run `xcodegen`, then open the `.xcodeproj` and run.

Most need Xcode 26 / iOS 26 (Liquid Glass); a few run on iOS 17 or 18. Each folder's README says how to run it.

Many apps auto-play a scripted demo (a fake finger dot) for recording. Look for the `-demo` / `-reel` launch arguments at the top of the main file; without them you can drive it with your own finger.

### The animations

| Preview | Animation |
|---|---|
| [![Koi across two Mac screens](SwiftUI/KoiDualMonitor/preview.jpg)](SwiftUI/KoiDualMonitor) | **[Koi across two Mac screens](SwiftUI/KoiDualMonitor)**<br>The koi swims behind the bezels from one monitor to the other. Renders the video offline (macOS script).<br>[post](https://x.com/purcelldev/status/2124586271444283703) · [video](SwiftUI/KoiDualMonitor/preview.mp4) |
| [![Dark mode circle reveal](SwiftUI/ThemeReveal/preview.jpg)](SwiftUI/ThemeReveal) | **[Dark mode circle reveal](SwiftUI/ThemeReveal)**<br>Dark mode spreads out from the toggle with a circle mask.<br>[post](https://x.com/purcelldev/status/2124210993211552140) · [video](SwiftUI/ThemeReveal/preview.mp4) |
| [![Octopus sprite sheet](SwiftUI/SpriteSheetOctopus/preview.jpg)](SwiftUI/SpriteSheetOctopus) | **[Octopus sprite sheet](SwiftUI/SpriteSheetOctopus)**<br>361 poses in one sheet; the octopus watches your finger and blends the 4 closest poses.<br>[post](https://x.com/purcelldev/status/2124055469513953761) · [video](SwiftUI/SpriteSheetOctopus/preview.mp4) |
| [![Liquid glass card + 3D cylinder carousel](SwiftUI/GlassCardAndCylinder/preview.jpg)](SwiftUI/GlassCardAndCylinder) | **[Liquid glass card + 3D cylinder carousel](SwiftUI/GlassCardAndCylinder)**<br>A draggable glass card that bends what's behind it (Metal layerEffect), and a trig photo cylinder you spin.<br>[post](https://x.com/purcelldev/status/2123707779508801901) · [video](SwiftUI/GlassCardAndCylinder/preview.mp4) |
| [![Card reveal](SwiftUI/CardReveal/preview.jpg)](SwiftUI/CardReveal) | **[Card reveal](SwiftUI/CardReveal)**<br>Tap the card: it lifts, the photo slides up and the details fade in.<br>[post](https://x.com/purcelldev/status/2123589752180056488) · [video](SwiftUI/CardReveal/preview.mp4) |
| [![AI thinking orb](SwiftUI/ThinkingDotOrb/preview.jpg)](SwiftUI/ThinkingDotOrb) | **[AI thinking orb](SwiftUI/ThinkingDotOrb)**<br>Dots morph while it searches, reads and plans, then the result slides in with parallax.<br>[post](https://x.com/purcelldev/status/2123282030721167366) · [video](SwiftUI/ThinkingDotOrb/preview.mp4) |
| [![3D tilt collectible card](SwiftUI/TiltParallax/preview.jpg)](SwiftUI/TiltParallax) | **[3D tilt collectible card](SwiftUI/TiltParallax)**<br>Every layer shifts by its depth; the shine moves the other way.<br>[post](https://x.com/purcelldev/status/2123148508438172115) · [video](SwiftUI/TiltParallax/preview.mp4) |
| [![Lock screen remake](SwiftUI/LockScreen/preview.jpg)](SwiftUI/LockScreen) | **[Lock screen remake](SwiftUI/LockScreen)**<br>The clock hides behind the mountain and notifications stack in.<br>[post](https://x.com/purcelldev/status/2123148270239416564) · [video](SwiftUI/LockScreen/preview.mp4) |
| [![5 ways to open a menu](SwiftUI/Menus/preview.jpg)](SwiftUI/Menus) | **[5 ways to open a menu](SwiftUI/Menus)**<br>Morphing plus, popover fan, stacked cards, gooey Liquid Glass and a command palette.<br>[post](https://x.com/purcelldev/status/2123043454720868562) · [video](SwiftUI/Menus/preview.mp4) |
| [![Liquid glass weather cards](SwiftUI/GlassCarousel/preview.jpg)](SwiftUI/GlassCarousel) | **[Liquid glass weather cards](SwiftUI/GlassCarousel)**<br>Glass weather cards that snap as you swipe.<br>[post](https://x.com/purcelldev/status/2123043331546685729) · [video](SwiftUI/GlassCarousel/preview.mp4) |
| [![Parallax carousel](SwiftUI/ParallaxCarousel/preview.jpg)](SwiftUI/ParallaxCarousel) | **[Parallax carousel](SwiftUI/ParallaxCarousel)**<br>The photo slides slower than the card; one visualEffect does it.<br>[post](https://x.com/purcelldev/status/2122811366650364387) · [video](SwiftUI/ParallaxCarousel/preview.mp4) |
| [![Lizard that follows your finger](SwiftUI/Lizard/preview.jpg)](SwiftUI/Lizard) | **[Lizard that follows your finger](SwiftUI/Lizard)**<br>Each bone follows the one in front; the legs use 2-bone IK and step when they fall behind.<br>[post](https://x.com/purcelldev/status/2122786869515849993) · [video](SwiftUI/Lizard/preview.mp4) |
| [![Share button fan](SwiftUI/ShareFan/preview.jpg)](SwiftUI/ShareFan) | **[Share button fan](SwiftUI/ShareFan)**<br>5 buttons fan out in an arc, each a few ms after the last.<br>[post](https://x.com/purcelldev/status/2122785542400307455) · [video](SwiftUI/ShareFan/preview.mp4) |
| [![Upload free throw](SwiftUI/UploadHoop/preview.jpg)](SwiftUI/UploadHoop) | **[Upload free throw](SwiftUI/UploadHoop)**<br>Flick the file, it arcs into the hoop, the net wiggles and the count ticks up.<br>[post](https://x.com/purcelldev/status/2122761304918429988) · [video](SwiftUI/UploadHoop/preview.mp4) |
| [![8 screen transitions](SwiftUI/Transitions/preview.jpg)](SwiftUI/Transitions) | **[8 screen transitions](SwiftUI/Transitions)**<br>.slide, .opacity, .scale, .move, .push, asymmetric, .blurReplace and matchedGeometryEffect.<br>[post](https://x.com/purcelldev/status/2122702749985128820) · [video](SwiftUI/Transitions/preview.mp4) |
| [![Tiny solar system](SwiftUI/SolarSystem/preview.jpg)](SwiftUI/SolarSystem) | **[Tiny solar system](SwiftUI/SolarSystem)**<br>Tap Earth and it flies into a card.<br>[post](https://x.com/purcelldev/status/2122701257186128082) · [video](SwiftUI/SolarSystem/preview.mp4) |
| [![8 SF Symbol effects](SwiftUI/SymbolEffects/preview.jpg)](SwiftUI/SymbolEffects) | **[8 SF Symbol effects](SwiftUI/SymbolEffects)**<br>.bounce, .pulse, .variableColor, .scale, .wiggle, .rotate, .breathe and .replace.<br>[post](https://x.com/purcelldev/status/2122561573042688118) · [video](SwiftUI/SymbolEffects/preview.mp4) |
| [![Animation curves](SwiftUI/AnimationCurves/preview.jpg)](SwiftUI/AnimationCurves) | **[Animation curves](SwiftUI/AnimationCurves)**<br>linear, easeIn, easeOut, easeInOut, spring, bouncy and snappy, one by one.<br>[post](https://x.com/purcelldev/status/2122262272345255989) · [video](SwiftUI/AnimationCurves/preview.mp4) |
| [![3,000-particle heart](SwiftUI/ParticleHeart/preview.jpg)](SwiftUI/ParticleHeart) | **[3,000-particle heart](SwiftUI/ParticleHeart)**<br>Particles swirl into the classic heart curve with TimelineView + Canvas.<br>[post](https://x.com/purcelldev/status/2122198880985182243) · [video](SwiftUI/ParticleHeart/preview.mp4) |
| [![Glass navbar](SwiftUI/GlassNavbar/preview.jpg)](SwiftUI/GlassNavbar) | **[Glass navbar](SwiftUI/GlassNavbar)**<br>A pill slides between tabs with matchedGeometryEffect and a bouncy spring.<br>[post](https://x.com/purcelldev/status/2121817792148332557) · [video](SwiftUI/GlassNavbar/preview.mp4) |
| [![Modifier order](SwiftUI/ModifierOrder/preview.jpg)](SwiftUI/ModifierOrder) | **[Modifier order](SwiftUI/ModifierOrder)**<br>.padding() then .background() vs the other way round.<br>[post](https://x.com/purcelldev/status/2121609229303955912) · [video](SwiftUI/ModifierOrder/preview.mp4) |
| [![Liquid tab bar](SwiftUI/LiquidTabBar/preview.jpg)](SwiftUI/LiquidTabBar) | **[Liquid tab bar](SwiftUI/LiquidTabBar)**<br>A bead floats on the bar and the edge dips under it like water.<br>[post](https://x.com/purcelldev/status/2121509813670777080) · [video](SwiftUI/LiquidTabBar/preview.mp4) |
| [![Koi that follows your finger](SwiftUI/Koi/preview.jpg)](SwiftUI/Koi) | **[Koi that follows your finger](SwiftUI/Koi)**<br>14 spine points, each joint bends at most ~20 degrees, so the body stays one smooth curve.<br>[post](https://x.com/purcelldev/status/2121492929021915248) · [video](SwiftUI/Koi/preview.mp4) |
| [![Animated text, 6 ways](SwiftUI/AnimatedText/preview.jpg)](SwiftUI/AnimatedText) | **[Animated text, 6 ways](SwiftUI/AnimatedText)**<br>Six text animation styles.<br>[post](https://x.com/purcelldev/status/2121248596200996962) · [video](SwiftUI/AnimatedText/preview.mp4) |

## License

MIT. Use them in your apps. A link back is appreciated, not required.
