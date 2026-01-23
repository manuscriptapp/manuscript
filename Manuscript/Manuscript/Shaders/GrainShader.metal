#include <metal_stdlib>
using namespace metal;

// Smooth animated gradient color shift
[[stitchable]] half4 gradientShift(
    float2 position,
    half4 color,
    float time,
    half3 color1,
    half3 color2,
    half3 color3
) {
    // Normalize position for gradient (0-1 range based on text width)
    float x = position.x * 0.005;  // Scale factor for text width

    // Animated offset that flows through the text
    float offset = time * 0.15;
    float pos = fract(x + offset);

    // Smooth three-color gradient with animation
    half3 gradientColor;
    if (pos < 0.33) {
        float t = pos * 3.0;
        gradientColor = mix(color1, color2, t);
    } else if (pos < 0.66) {
        float t = (pos - 0.33) * 3.0;
        gradientColor = mix(color2, color3, t);
    } else {
        float t = (pos - 0.66) * 3.0;
        gradientColor = mix(color3, color1, t);
    }

    // Apply gradient to text (multiply with original alpha)
    return half4(gradientColor * color.a, color.a);
}
