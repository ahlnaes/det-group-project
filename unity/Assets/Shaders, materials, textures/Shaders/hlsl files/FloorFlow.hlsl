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

#ifndef _GLOBAL_FloorFlow
#define _GLOBAL_FloorFlow

// uv: UV0 of the floor disc mesh
// UV center = disc center, outer edge = UV boundary
// length(uv - 0.5) * 2 gives 0 at center, 1 at edge — rotationally invariant
// -_ScanPhase makes rings flow inward, matching wall lines flowing downward
void GetFloorFlow_float(float2 uv, out float Out)
{
    Out = frac(length(uv - 0.5) * 2.0 * _LineFrequency - _ScanPhase);
}

void GetFloorFlow_half(half2 uv, out half Out)
{
    Out = (half)frac(length((float2)uv - 0.5) * 2.0 * _LineFrequency - _ScanPhase);
}

#endif
