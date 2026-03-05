#ifndef VORONOI_TRIPLANAR_INCLUDED
#define VORONOI_TRIPLANAR_INCLUDED

// ── Hash ─────────────────────────────────────────────────────────────────
float2 CellHash(float2 p)
{
    p = float2(dot(p, float2(127.1, 311.7)),
               dot(p, float2(269.5, 183.3)));
    return frac(sin(p) * 43758.5453);
}

float Hash11(float2 p)
{
    p = frac(p * float2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return frac(p.x * p.y);
}

// ── Voronoi ───────────────────────────────────────────────────────────────
// Worley (1996) https://dl.acm.org/doi/10.1145/237170.237267
float Voronoi(float2 uv, float t, float audioSpeed, float audioPull)
{
    float2 cell    = floor(uv);
    float2 local   = frac(uv);
    float  minDist = 8.0;

    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            float2 neighbour    = float2(x, y);
            float2 h            = CellHash(cell + neighbour);
            float2 featurePoint = 0.5 + 0.5 * sin(t * audioSpeed + 6.28 * h);
            featurePoint        = lerp(featurePoint, round(featurePoint), audioPull);
            float2 diff         = neighbour + featurePoint - local;
            float  d            = dot(diff, diff);
            minDist             = min(minDist, d);
        }
    }
    return sqrt(minDist);
}

// ── Triplanar voronoi ─────────────────────────────────────────────────────
float3 TriplanarVoronoi(
    float3 worldPos,
    float3 worldNormal,
    float  cellScale,
    float  t,
    float  rms,
    float  bass,
    float  mid,
    float  lowMid,
    float  hi)
{
    float3 blend = pow(abs(worldNormal), 8.0);
    blend /= (blend.x + blend.y + blend.z);

    float2 worldXZ = worldPos.xz * cellScale;
    float2 worldXY = worldPos.xy * cellScale;
    float2 worldYZ = worldPos.yz * cellScale;

    float v1 = Voronoi(worldYZ,             t,       1.0 + rms, bass   * 0.6) * blend.x
             + Voronoi(worldXZ,             t,       1.0 + rms, bass   * 0.6) * blend.y
             + Voronoi(worldXY,             t,       1.0 + rms, bass   * 0.6) * blend.z;

    float2 off2 = float2(3.7, 1.4);
    float v2 = Voronoi(worldYZ * 2.3 + off2, t * 1.3, 1.2 + mid,  lowMid * 0.4) * blend.x
             + Voronoi(worldXZ * 2.3 + off2, t * 1.3, 1.2 + mid,  lowMid * 0.4) * blend.y
             + Voronoi(worldXY * 2.3 + off2, t * 1.3, 1.2 + mid,  lowMid * 0.4) * blend.z;

    float2 off3 = float2(7.2, 4.9);
    float v3 = Voronoi(worldYZ * 5.1 + off3, t * 2.1, 1.5 + hi,  0.0) * blend.x
             + Voronoi(worldXZ * 5.1 + off3, t * 2.1, 1.5 + hi,  0.0) * blend.y
             + Voronoi(worldXY * 5.1 + off3, t * 2.1, 1.5 + hi,  0.0) * blend.z;

    return float3(v1, v2, v3);
}

// ── Main entry point ──────────────────────────────────────────────────────
// Audio values arrive pre-processed from the graph — scale/remap them
// using math nodes in Shader Graph before passing in here.
void AudioCellular_float(
    float3 worldPos,
    float3 worldNormal,
    float2 uv,
    float4 wallColor,
    float4 accentColor,
    float  cellScale,
    float  timeScale,
    float  effectStrength,
    float  edgeBrightness,
    float  rms,      // pre-processed in graph before arriving here
    float  bass,     // _Band1, scaled/remapped in graph
    float  lowMid,   // _Band2, scaled/remapped in graph
    float  mid,      // _Band3, scaled/remapped in graph
    float  hi,       // _Band6, scaled/remapped in graph
    out float4 color)
{
    float t = _Time.y * timeScale;

    float3 layers = TriplanarVoronoi(
        worldPos, worldNormal, cellScale,
        t, rms, bass, mid, lowMid, hi);

    float v1 = layers.x;
    float v2 = layers.y;

    float edge  = 1.0 - smoothstep(0.0, 0.08 + bass * 0.06, v1);
    float edge2 = 1.0 - smoothstep(0.0, 0.04 + mid  * 0.03, v2);

    float4 accentPulse = accentColor * (1.0 + rms * 1.5);

    float4 col = wallColor;
    col.rgb   += edge  * accentPulse.rgb * edgeBrightness * (0.5 + bass * 0.8);
    col.rgb   += edge2 * accentPulse.rgb * edgeBrightness * 0.3 * (0.3 + mid * 0.5);

    float interior = saturate(1.0 - v1 * 2.0);
    col.rgb = lerp(col.rgb,
                   col.rgb * accentPulse.rgb * 0.5,
                   interior * effectStrength * rms);

    float grain = Hash11(uv * 300.0 + _Time.y * 3.0);
    col.rgb    += grain * hi * 0.1;

    col.rgb = max(col.rgb, wallColor.rgb);
    color   = col;
}

#endif