float _ScanPhase;
float _LineFrequency;

void GetFloorFlow_float(float2 uv, out float Out)
{
    float r = length((float2)uv - 0.5) * 2.0;
    Out = frac(r * _LineFrequency - _ScanPhase);
}

void GetFloorFlow_half(half2 uv, out half Out)
{
    float r = length((float2)uv - 0.5) * 2.0;
    Out = (half)frac(r * _LineFrequency - _ScanPhase);
}