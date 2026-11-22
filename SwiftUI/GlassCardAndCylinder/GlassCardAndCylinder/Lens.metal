#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// signed distance to a rounded rect centered at 0
float rrect(float2 p, float2 hs, float r) {
    float2 q = abs(p) - hs + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Runs on the whole background. Inside the card rect it acts like a thick glass lens:
// zooms in, bends hard at the rim, splits colors (rainbow fringe), adds a rim highlight.
// Outside it draws the card's soft shadow. strength 0...1 = "liquidness".
[[ stitchable ]] half4 glassCard(float2 pos, SwiftUI::Layer layer, float4 rect, float radius, float strength) {
    float2 hs = rect.zw * 0.5;
    float2 c = rect.xy + hs;
    float2 p = pos - c;
    float sd = rrect(p, hs, radius);

    if (sd > 0.0) {
        half4 col = layer.sample(pos);
        float sh = rrect(p - float2(0, 18), hs, radius);      // shadow, pushed down
        float k = exp(-max(sh, 0.0) / 22.0) * 0.45;
        return half4(col.rgb * half(1.0 - k), col.a);
    }

    float d = -sd;
    float band = 26.0 + 70.0 * strength;
    float t = 1.0 - clamp(d / band, 0.0, 1.0);
    float e = 1.0;
    float2 n = normalize(float2(rrect(p + float2(e, 0), hs, radius) - rrect(p - float2(e, 0), hs, radius),
                                rrect(p + float2(0, e), hs, radius) - rrect(p - float2(0, e), hs, radius)) + 1e-5);

    float2 zoom = c + p * (1.0 - 0.22 * strength);           // magnify what's behind
    float2 disp = -n * (t * t) * band * 1.5;                  // bend at the rim

    half3 col;
    col.r = (layer.sample(zoom + disp * 0.92 + float2(1, 0)).r + layer.sample(zoom + disp * 0.92 - float2(1, 0)).r) * 0.5h;
    col.g = (layer.sample(zoom + disp * 1.06 + float2(0, 1)).g + layer.sample(zoom + disp * 1.06 - float2(0, 1)).g) * 0.5h;
    col.b = (layer.sample(zoom + disp * 1.22 + float2(1, 1)).b + layer.sample(zoom + disp * 1.22 - float2(1, 1)).b) * 0.5h;

    col = mix(col, half3(1.0), 0.07h);                        // a little frost
    float light = max(dot(n, normalize(float2(-0.6, -0.8))), 0.0);
    col += half(pow(t, 3.0) * (0.12 + 0.35 * light));          // rim glow, brighter top-left
    col += half(smoothstep(1.6, 0.0, d) * 0.55);               // thin bright edge line
    return half4(min(col, half3(1.0)), 1.0h);
}
