#include "Assets/Shaders, materials, textures/Shaders/shared/FlowCoordinate.hlsl"

void ScanLines_float(
    float3 worldPos,
    float3 worldNormal,
    float  lineSharpness,   // 0 = soft glow, 1 = hard crisp lines
    float  brightness,
    float4 lineColor,
    out float4 color
)
{
    float t = GetAnimatedFlowCoord(worldPos, worldNormal);

    float lineWidth = 0.04 + _BassEnergy * 0.08;

    float line = 1.0 - smoothstep(0.0, lineWidth, t)
                     + smoothstep(1.0 - lineWidth, 1.0, t);

    // Polynomial sharpness — avoids pow() which compiles to exp2(n*log2(x))
    // on Adreno (two transcendentals). Multiply is free by comparison.
    float lineSoft = line * line;
    line = lerp(lineSoft, line, lineSharpness);

    float flash = 1.0 + _KickEnvelope * 2.0;
    color = lineColor * line * brightness * flash;
}