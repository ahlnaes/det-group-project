#ifndef _GLOBAL_ScanPhase
#define _GLOBAL_ScanPhase
float _ScanPhase;
#endif

#ifndef _GLOBAL_GetWorldSurfaceUV
#define _GLOBAL_GetWorldSurfaceUV

float2 _GetWorldSurfaceUVInternal(float3 worldPos, float3 worldNormal, float scale)
{
    float3 absNormal = abs(worldNormal);
    float2 uv;
    if (absNormal.y >= absNormal.x && absNormal.y >= absNormal.z)
        uv = worldPos.xz;
    else if (absNormal.x >= absNormal.z)
        uv = worldPos.yz;
    else
        uv = worldPos.xy;
    return uv * scale;
}

void GetWorldSurfaceUV_float(float3 worldPos, float3 worldNormal, float scale, out float2 Out)
{
    Out = _GetWorldSurfaceUVInternal(worldPos, worldNormal, scale);
}

void GetWorldSurfaceUV_half(half3 worldPos, half3 worldNormal, half scale, out half2 Out)
{
    Out = (half2)_GetWorldSurfaceUVInternal((float3)worldPos, (float3)worldNormal, (float)scale);
}

void GetAnimatedWorldSurfaceUV_float(float3 worldPos, float3 worldNormal,
                                     float scale, float2 scrollDir, float speed,
                                     out float2 Out)
{
    Out = _GetWorldSurfaceUVInternal(worldPos, worldNormal, scale) + scrollDir * _ScanPhase * speed;
}

void GetAnimatedWorldSurfaceUV_half(half3 worldPos, half3 worldNormal,
                                    half scale, half2 scrollDir, half speed,
                                    out half2 Out)
{
    float2 uv = _GetWorldSurfaceUVInternal((float3)worldPos, (float3)worldNormal, (float)scale);
    Out = (half2)(uv + (float2)scrollDir * _ScanPhase * (float)speed);
}

void GetWorldSurfaceUV_Triplanar_float(float3 worldPos, float3 worldNormal, float scale, out float2 Out)
{
    float3 w = abs(worldNormal);
    w /= (w.x + w.y + w.z + 0.0001);
    Out = worldPos.yz * scale * w.x
        + worldPos.xz * scale * w.y
        + worldPos.xy * scale * w.z;
}

void GetWorldSurfaceUV_Triplanar_half(half3 worldPos, half3 worldNormal, half scale, out half2 Out)
{
    float3 w = abs((float3)worldNormal);
    w /= (w.x + w.y + w.z + 0.0001);
    float s = (float)scale;
    Out = (half2)(worldPos.yz * s * w.x
                + worldPos.xz * s * w.y
                + worldPos.xy * s * w.z);
}

#endif