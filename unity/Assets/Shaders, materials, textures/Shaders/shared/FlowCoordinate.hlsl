#ifndef _GLOBAL_ScanPhase
#define _GLOBAL_ScanPhase
float _ScanPhase;
#endif
#ifndef _GLOBAL_LineFrequency
#define _GLOBAL_LineFrequency
float _LineFrequency;
#endif

#ifndef _GLOBAL_GetFlowCoordinate
#define _GLOBAL_GetFlowCoordinate

// uv: V channel of the mesh UV — 0 at wall top, 1 at floor center, continuous across seam
void GetAnimatedFlowCoord_float(float2 uv, out float Out)
{
    Out = frac(uv.y * _LineFrequency + _ScanPhase);
}

void GetAnimatedFlowCoord_half(half2 uv, out half Out)
{
    Out = (half)frac((float)uv.y * _LineFrequency + _ScanPhase);
}

#endif
