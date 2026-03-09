float _ScanPhase;
float _LineFrequency;

void GetWallFlow_float(float2 uv, out float Out)
{
    Out = frac(uv.y * _LineFrequency + _ScanPhase);
}

void GetWallFlow_half(half2 uv, out half Out)
{
    Out = (half)frac((float)uv.y * _LineFrequency + _ScanPhase);
}