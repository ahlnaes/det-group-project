#ifndef DET_GROUP_CURL_NOISE_HLSL
#define DET_GROUP_CURL_NOISE_HLSL

float Curl_Hash(float2 p)
{
    p = frac(p * float2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return frac(p.x * p.y);
}

float Curl_ValueNoise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f * f * (3.0 - 2.0 * f);

    return lerp(
        lerp(Curl_Hash(i),               Curl_Hash(i + float2(1, 0)), u.x),
        lerp(Curl_Hash(i + float2(0,1)), Curl_Hash(i + float2(1, 1)), u.x),
        u.y
    );
}

float Curl_FBM(float2 p, int octaves, float persistence)
{
    float value     = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int o = 0; o < octaves; o++)
    {
        value     += amplitude * Curl_ValueNoise(p * frequency);
        frequency *= 2.0;
        amplitude *= persistence;
    }
    return value;
}

// Bridson (2007) https://doi.org/10.1145/1276377.1276435
float2 Curl_Noise(float2 p, float t, int octaves, float persistence)
{
    const float eps = 0.01;

    float n0 = Curl_FBM(p + float2(0,   eps) + t, octaves, persistence);
    float n1 = Curl_FBM(p + float2(0,  -eps) + t, octaves, persistence);
    float n2 = Curl_FBM(p + float2( eps, 0)  + t, octaves, persistence);
    float n3 = Curl_FBM(p + float2(-eps, 0)  + t, octaves, persistence);

    float dFdy = (n0 - n1) / (2.0 * eps);
    float dFdx = (n2 - n3) / (2.0 * eps);

    return float2(-dFdy, dFdx);
}

float2 Curl_Triplanar(
    float3 worldPos,
    float3 worldNormal,
    float  noiseScale,
    float  t,
    int    octaves,
    float  persistence)
{
    float3 blend = pow(abs(worldNormal), 8.0);
    blend /= (blend.x + blend.y + blend.z);

    float2 curlYZ = Curl_Noise(worldPos.yz * noiseScale, t, octaves, persistence);
    float2 curlXZ = Curl_Noise(worldPos.xz * noiseScale, t, octaves, persistence);
    float2 curlXY = Curl_Noise(worldPos.xy * noiseScale, t, octaves, persistence);

    return curlYZ * blend.x + curlXZ * blend.y + curlXY * blend.z;
}

void AudioCurl_float(
    float3            worldPos,
    float3            worldNormal,
    float2            uv,
    UnityTexture2D    wallTex,
    UnitySamplerState wallSampler,
    float4            accentColor,
    float             noiseScale,
    float             timeScale,
    float             dispStrength,
    float             glowStrength,
    float             rms,
    float             bass,
    float             mid,
    float             hi,
    float             kickEnvelope,
    out float4        color)
{
    float t = _Time.y * timeScale;

    float2 curl1 = Curl_Triplanar(worldPos, worldNormal, noiseScale * 0.4, t * 0.3, 3, 0.5);
    float2 curl2 = Curl_Triplanar(worldPos, worldNormal, noiseScale * 1.2, t * 0.7, 2, 0.5);
    float2 curl3 = Curl_Triplanar(worldPos, worldNormal, noiseScale * 3.0, t * 1.5, 2, 0.5);

    float2 totalCurl = curl1 * (1.0 + bass * 2.0)
                     + curl2 * (0.5 + mid  * 1.5)
                     + curl3 * (0.2 + hi   * 1.0);

    float  dispAmount  = dispStrength * kickEnvelope * (1.0 + rms * 2.0 + bass * 3.0);
    float2 displacedUV = uv + totalCurl * dispAmount;

    float4 wallColor = SAMPLE_TEXTURE2D(wallTex.tex, wallSampler.samplerstate, displacedUV);

    float  curlMag = length(totalCurl);
    float  glow    = saturate(curlMag * 1.5) * glowStrength * kickEnvelope * (0.5 + rms * 1.5);

    float4 col = wallColor;
    col.rgb   += accentColor.rgb * glow;
    col.rgb    = lerp(col.rgb, col.rgb * accentColor.rgb * 1.5, rms * 0.3 * kickEnvelope);

    color = col;
}

#endif