#ifndef VORONOI_TRIPLANAR_INCLUDED
#define VORONOI_TRIPLANAR_INCLUDED

// ── Finger displacement ───────────────────────────────────────────────────
float3 _FingerPositions[2];
float  _FingerMaxDist;
float  _FingerStrength;
float  _FingerFalloff;

float2 ShaderDisplace(float3 surfaceWorldPos)
{
    float2 totalOffset = float2(0, 0);
    for (int i = 0; i < 2; i++)
    {
        float3 delta     = surfaceWorldPos - _FingerPositions[i];
        float  dist      = length(delta);
        float  influence = 1.0 - saturate(dist / _FingerMaxDist);
        float  strength  = pow(influence, _FingerFalloff) / max(dist * dist, 0.001);
        float2 dir       = normalize(float2(delta.x, delta.y + delta.z));
        totalOffset     += dir * strength * _FingerStrength;
    }
    return totalOffset;
}

// ── Hash ──────────────────────────────────────────────────────────────────
float Hash13(float3 p)
{
    p = frac(p * float3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yzx + 33.33);
    return frac((p.x + p.y) * p.z);
}

// ── 3D Value Noise ────────────────────────────────────────────────────────
float ValueNoise(float3 p)
{
    float3 i = floor(p);
    float3 f = frac(p);
    float3 u = f * f * (3.0 - 2.0 * f);
    return lerp(
        lerp(
            lerp(Hash13(i + float3(0,0,0)), Hash13(i + float3(1,0,0)), u.x),
            lerp(Hash13(i + float3(0,1,0)), Hash13(i + float3(1,1,0)), u.x), u.y),
        lerp(
            lerp(Hash13(i + float3(0,0,1)), Hash13(i + float3(1,0,1)), u.x),
            lerp(Hash13(i + float3(0,1,1)), Hash13(i + float3(1,1,1)), u.x), u.y),
        u.z);
}

// ── Main entry point ──────────────────────────────────────────────────────
void AudioCellular_float(
    float3 worldPos,
    float3 worldNormal,
    float2 uv,
    float4 wallColor,
    float4 accentColor,
    float  cellScale,
    float  noiseStretchX,
    float  noiseStretchY,
    float  t,
    float  effectStrength,
    float  edgeBrightness,
    float  rms,
    float  bass,
    float  lowMid,
    float  mid,
    float  hi,
    out float4 color)
{
    // Displace worldPos XY before building p —
    // fingers push/pull the noise pattern on the surface
    float2 disp = ShaderDisplace(worldPos);
    float3 displacedPos = float3(
        worldPos.x + disp.x,
        worldPos.y + disp.y,
        worldPos.z
    );

    float3 p = float3(
        displacedPos.x * cellScale * noiseStretchX,
        displacedPos.y * cellScale * noiseStretchY,
        displacedPos.z * cellScale
    );

    float v1 = ValueNoise(p + float3(0.0, 0.0, t * (1.0 + rms)));
    float v2 = ValueNoise(p * 2.3 + float3(3.7, 1.4, t * (1.3 + mid)));

    float edge  = 1.0 - smoothstep(0.45, 0.55 + bass * 0.1,  v1);
    float edge2 = 1.0 - smoothstep(0.45, 0.52 + mid  * 0.05, v2);

    float4 accentPulse = accentColor * (1.0 + rms * 1.5);

    float4 col  = wallColor;
    col.rgb    += edge  * accentPulse.rgb * edgeBrightness * (0.5 + bass * 0.8);
    col.rgb    += edge2 * accentPulse.rgb * edgeBrightness * 0.3 * (0.3 + mid * 0.5);

    float interior = saturate(v1 * 2.0 - 1.0);
    col.rgb = lerp(col.rgb,
                   col.rgb * accentPulse.rgb * 0.5,
                   interior * effectStrength * rms);

    float grain = Hash13(float3(uv * 300.0, t * 3.0));
    col.rgb    += grain * hi * 0.1;

    col.rgb = max(col.rgb, wallColor.rgb);
    color   = col;
}

#endif