float _ScanPhase;
float _WallHeight;
float3 _FingerPositions[2];
float _FingerMaxDist;
float _FingerStrength;
float _FingerFalloff;

float2 ShaderDisplace(float3 surfaceWorldPos, float2 currentUV){
    float2 totalOffset = float2(0, 0);

    for (int i = 0; i < 2; i++)
    {
        float3 fingerPos = _FingerPositions[i];
        float3 delta = surfaceWorldPos - fingerPos;
        float dist = length(delta);

        // only within maxDistance
        float influence = 1.0 - saturate(dist / _FingerMaxDist);

        //stronger closer to finger
        float strength = pow(influence, _FingerFalloff) / max(dist * dist, 0.001);

        //direction of displacement in UV space
        float2 dir = normalize(float2(delta.x, delta.y + delta.z));
        totalOffset += dir * strength * _FingerStrength;
    }

    return totalOffset;
}

void WallLinesScrollDown_float(
    UnityTexture2D noiseTex,
    UnitySamplerState noiseSampler,
    float3 worldPos,
    float3 rawWorldPos,        // <-- add this: unmodified world position for displacement
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
    float angle = atan2(worldPos.z, worldPos.x) / (3.14159265 * 2.0) + 0.5;
    float height = saturate(worldPos.y / _WallHeight);

    float2 u = float2(angle * columnCount, height / stripCount);
    u += ShaderDisplace(rawWorldPos, u);    // <-- use rawWorldPos here
    float2 speed = SAMPLE_TEXTURE2D(noiseTex.tex, noiseSampler.samplerstate, float2(0, u.y) * 16.0).rg;
    u.y *= speed.g * 0.9 + 0.1;
    u.y += _ScanPhase * (speed.r - 0.5) * scrollSpeed * (0.5 + bassEnergy + kickEnvelope * 2.0);

    float noiseVal = SAMPLE_TEXTURE2D(noiseTex.tex, noiseSampler.samplerstate, u * 16.0).r;
    float bar = noiseVal < 0.15 ? 1.0 : 0.0;

    float flash = 1.0 + kickEnvelope * 2.0;
    Out = barColor * bar * brightness * flash;
}

void WallLinesScrollDown_half(
    UnityTexture2D noiseTex,
    UnitySamplerState noiseSampler,
    float3 worldPos,
    float3 rawWorldPos,        // <-- same here
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
    float angle = atan2(worldPos.z, worldPos.x) / (3.14159265 * 2.0) + 0.5;
    float height = saturate(worldPos.y / _WallHeight);

    float2 u = float2(angle * columnCount, height / stripCount);
    u += ShaderDisplace(rawWorldPos, u);    // <-- and here
    float2 speed = SAMPLE_TEXTURE2D(noiseTex.tex, noiseSampler.samplerstate, float2(0, u.y) * 16.0).rg;
    u.y *= speed.g * 0.9 + 0.1;
    u.y += _ScanPhase * (speed.r - 0.5) * scrollSpeed * (0.5 + bassEnergy + kickEnvelope * 2.0);

    float noiseVal = SAMPLE_TEXTURE2D(noiseTex.tex, noiseSampler.samplerstate, u * 16.0).r;
    float bar = noiseVal < 0.15 ? 1.0 : 0.0;

    float flash = 1.0 + kickEnvelope * 2.0;
    Out = (half4)(barColor * bar * brightness * flash);
}