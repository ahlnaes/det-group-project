#ifndef _GLOBAL_ScanPhase
#define _GLOBAL_ScanPhase
float _ScanPhase;
#endif
#ifndef _GLOBAL_LineFrequency
#define _GLOBAL_LineFrequency
float _LineFrequency;
#endif
#ifndef _GLOBAL_RMS
#define _GLOBAL_RMS
float _RMS;
#endif
#ifndef _GLOBAL_BassEnergy
#define _GLOBAL_BassEnergy
float _BassEnergy;
#endif
#ifndef _GLOBAL_KickEnvelope
#define _GLOBAL_KickEnvelope
float _KickEnvelope;
#endif

#ifndef _GLOBAL_WallFlow
#define _GLOBAL_WallFlow

// uv: UV0 of the wall mesh
// V=0 at top, V=1 at bottom seam with floor
// Lines scan downward, meeting the floor edge in sync
void GetWallFlow_float(float2 uv, out float Out)
{
    Out = frac(uv.y * _LineFrequency + _ScanPhase);
}

void GetWallFlow_half(half2 uv, out half Out)
{
    Out = (half)frac((float)uv.y * _LineFrequency + _ScanPhase);
}

#endif
