#ifndef DET_GROUP_SCANLINES_HLSL
#define DET_GROUP_SCANLINES_HLSL

float Scan_Hash(int index, float seed)
{
    return frac(sin(float(index) * 127.1 + seed * 311.7) * 43758.5453);
}

float Scan_Line(float posY, float phase, float width, float glow)
{
    float d        = abs(frac(posY - phase) - 0.5);
    float lineCore = smoothstep(width, width * 0.05, d);
    float halo     = exp(-d / max(glow, 0.0001)) * 0.001;
    return lineCore + halo;
}

void AudioScanLines_float(
    float3 worldPos,
    float  rms,
    float  bassEnergy,
    float  kickEnvelope,
    float  lineScale,
    float  lineWidth,
    float  glowAmount,
    float  brightness,
    float  scanPhase,     // replaces baseSpeed and speedScale — comes from C#
    out float4 color)
{
    color = float4(0.0, 0.0, 0.0, 1.0);

    float posY = worldPos.y * lineScale;

    float result = 0.0;

    for (int i = 0; i < 5; i++)
    {
        float offset   = Scan_Hash(i, 0.0);
        float speedVar = 0.7 + Scan_Hash(i, 99.0) * 0.6;

        // Phase comes from C# accumulator — speedVar gives per-line variation
        // around the same integrated base, so lines stay independent but
        // all respond to the same audio-driven speed changes
        float phase = offset + scanPhase * speedVar;

        float w = lineWidth * (0.5 + Scan_Hash(i, 13.0) * 0.5);
        float g = glowAmount;

        result = max(result, Scan_Line(posY, phase, w, g));
    }

    float b = result * brightness * (0.3 + rms * 0.7);
    b *= (1.0 + kickEnvelope * 2.0);

    color = float4(b, b, b, 1.0);
}

#endif