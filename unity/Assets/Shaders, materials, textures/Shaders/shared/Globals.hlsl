#ifndef _GLOBAL_BassEnergy
#define _GLOBAL_BassEnergy
float _BassEnergy;
#endif
#ifndef _GLOBAL_KickEnvelope
#define _GLOBAL_KickEnvelope
float _KickEnvelope;
#endif
#ifndef _GLOBAL_MidEnergy
#define _GLOBAL_MidEnergy
float _MidEnergy;
#endif
#ifndef _GLOBAL_HiEnergy
#define _GLOBAL_HiEnergy
float _HiEnergy;
#endif
#ifndef _GLOBAL_SpectralFlux
#define _GLOBAL_SpectralFlux
float _SpectralFlux;
#endif
#ifndef _GLOBAL_TransientEnvelope
#define _GLOBAL_TransientEnvelope
float _TransientEnvelope;
#endif
#ifndef _GLOBAL_RMS
#define _GLOBAL_RMS
float _RMS;
#endif
#ifndef _GLOBAL_Bands
#define _GLOBAL_Bands
float _Band0, _Band1, _Band2, _Band3, _Band4, _Band5, _Band6, _Band7;
#endif

#ifndef _GLOBAL_GetAudioGlobals
#define _GLOBAL_GetAudioGlobals
void GetAudioGlobals_float(out float bassEnergy, out float kickEnvelope,
                            out float midEnergy,  out float hiEnergy,
                            out float spectralFlux, out float transientEnvelope,
                            out float rms)
{
    bassEnergy        = _BassEnergy;
    kickEnvelope      = _KickEnvelope;
    midEnergy         = _MidEnergy;
    hiEnergy          = _HiEnergy;
    spectralFlux      = _SpectralFlux;
    transientEnvelope = _TransientEnvelope;
    rms               = _RMS;
}

void GetAudioGlobals_half(out half bassEnergy, out half kickEnvelope,
                           out half midEnergy,  out half hiEnergy,
                           out half spectralFlux, out half transientEnvelope,
                           out half rms)
{
    bassEnergy        = (half)_BassEnergy;
    kickEnvelope      = (half)_KickEnvelope;
    midEnergy         = (half)_MidEnergy;
    hiEnergy          = (half)_HiEnergy;
    spectralFlux      = (half)_SpectralFlux;
    transientEnvelope = (half)_TransientEnvelope;
    rms               = (half)_RMS;
}
#endif