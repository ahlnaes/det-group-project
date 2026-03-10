float _ScanPhase;

void FloorBars_float(
    UnityTexture2D noiseTex,
    UnitySamplerState noiseSampler,
    float2 uv,
    float4 barColor,
    float brightness,
    float scrollSpeed,
    float flipSpeed,
    float bassEnergy,
    float kickEnvelope,
    float columnCount,
    float stripCount,
    out float4 Out)
{
    float2 centered = uv - 0.5;
    float radial = length(centered) * 2.0;
    float angle = atan2(centered.y, centered.x) / (3.14159265 * 2.0) + 0.5;

    float2 u = float2(angle * columnCount, radial / stripCount);
    float2 speed = SAMPLE_TEXTURE2D(noiseTex.tex, noiseSampler.samplerstate, float2(0, u.y) * 16.0).rg;
    u.x *= speed.g * 0.9 + 0.1;
    u.x -= _ScanPhase * (speed.r - 0.5) * scrollSpeed * (0.5 + bassEnergy + kickEnvelope * 2.0);

    float noiseVal = SAMPLE_TEXTURE2D(noiseTex.tex, noiseSampler.samplerstate, u * 16.0).r;
    float bar = frac(noiseVal + _ScanPhase * flipSpeed) < 0.15 ? 1.0 : 0.0;
    float flash = 1.0 + kickEnvelope * 2.0;
    Out = barColor * bar * brightness * flash;
}

void FloorBars_half(
    UnityTexture2D noiseTex,
    UnitySamplerState noiseSampler,
    float2 uv,
    half4 barColor,
    half brightness,
    float scrollSpeed,
    float flipSpeed,
    float bassEnergy,
    float kickEnvelope,
    float columnCount,
    float stripCount,
    out half4 Out)
{
    float2 centered = uv - 0.5;
    float radial = length(centered) * 2.0;
    float angle = atan2(centered.y, centered.x) / (3.14159265 * 2.0) + 0.5;

    float2 u = float2(angle * columnCount, radial / stripCount);
    float2 speed = SAMPLE_TEXTURE2D(noiseTex.tex, noiseSampler.samplerstate, float2(0, u.y) * 16.0).rg;
    u.x *= speed.g * 0.9 + 0.1;
    u.x -= _ScanPhase * (speed.r - 0.5) * scrollSpeed * (0.5 + bassEnergy + kickEnvelope * 2.0);

    float noiseVal = SAMPLE_TEXTURE2D(noiseTex.tex, noiseSampler.samplerstate, u * 16.0).r;
    float bar = frac(noiseVal + _ScanPhase * flipSpeed) < 0.15 ? 1.0 : 0.0;
    float flash = 1.0 + kickEnvelope * 2.0;
    Out = (half4)(barColor * bar * brightness * flash);
}