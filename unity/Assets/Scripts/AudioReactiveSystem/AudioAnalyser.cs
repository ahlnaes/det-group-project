using System;
using System.Threading;
using UnityEngine;

public class AudioAnalyser : MonoBehaviour
{
    private const int FFTSize    = 1024;
    private const int BandCount  = 8;
    private const int SampleRate = 48000;

    // Audio buffers (DSP thread only)
    private float[]
        _accumulationBuffer,
        _windowCoefficients,
        _windowedBuffer;

    // FFT buffers (DSP thread only)
    private double[]
        _fftReal,
        _fftImag,
        _spectrum;  // magnitude, length FFTSize / 2

    // Double buffer for band energies (written DSP, read main thread)
    private float[] _frontBuffer, _backBuffer;

    private int  _accumulationPos;
    private volatile float _rms;

    // Public accessors for main thread consumers (shaders, VFX, etc.)
    public float RMS => _rms;
    public float[] Bands => _frontBuffer;
    
    // ── Kick envelope ─────────────────────────────────────────────────────────
// Triggers on sharp bass transients and decays back to zero between hits.
// This is what drives displacement in the shader — spikes on kicks,
// returns to zero between them.

    [Header("Kick Envelope")]
    [SerializeField] private float _kickThreshold   = 0.02f;  // band1 value that counts as a kick
    [SerializeField] private float _kickAttack      = 0.95f;  // how instantly envelope jumps (0-1, higher = faster)
    [SerializeField] private float _kickRelease     = 0.05f;  // how fast it decays per frame (lower = slower decay)

    private float _kickEnvelope    = 0.0f;
    private float _previousBand1   = 0.0f;

    public float KickEnvelope => _kickEnvelope;

    private void Awake()
    {
        // DSP thread buffers
        _accumulationBuffer = new float[FFTSize];
        _windowCoefficients = new float[FFTSize];
        _windowedBuffer     = new float[FFTSize];
        _fftReal            = new double[FFTSize];
        _fftImag            = new double[FFTSize];
        _spectrum           = new double[FFTSize / 2];

        // Double buffer - sized to band count, not FFTSize
        _frontBuffer = new float[BandCount];
        _backBuffer  = new float[BandCount];

        // Pre-compute Hann window coefficients once
        // Hann formula: https://en.wikipedia.org/wiki/Hann_function
        for (var i = 0; i < FFTSize; i++)
            _windowCoefficients[i] = 0.5f * (1f - Mathf.Cos(2f * Mathf.PI * i / (FFTSize - 1)));
    }

    // Called by Unity on the DSP thread every time a new audio buffer is ready
    private void OnAudioFilterRead(float[] data, int channels)
    {
        // Accumulate mono samples (left channel only) until we have FFTSize samples
        for (var i = 0; i < data.Length; i += channels)
        {
            _accumulationBuffer[_accumulationPos] = data[i];
            _accumulationPos++;
        }

        if (_accumulationPos < FFTSize) return;

        // --- Buffer is full: process this frame ---

        // 1. RMS on raw audio (before windowing — windowing would skew the energy)
        float sum = 0;
        for (var i = 0; i < FFTSize; i++)
            sum += _accumulationBuffer[i] * _accumulationBuffer[i];
        _rms = Mathf.Sqrt(sum / FFTSize);  // volatile write, safe for single primitive

        // 2. Apply Hann window and copy to FFT input buffers
        //    _fftImag must be zeroed each frame — we're feeding real-valued audio
        for (var i = 0; i < FFTSize; i++)
        {
            _fftReal[i] = _accumulationBuffer[i] * _windowCoefficients[i];
            _fftImag[i] = 0.0;
        }

        // 3. In-place FFT — no allocations
        FFT.Forward(_fftReal, _fftImag);

        // 4. Compute magnitude spectrum for the positive frequencies only
        //    FFT output is symmetric: only bins 0.N/2 carry unique information
        //    Magnitude: sqrt(real² + imag²), normalised by FFTSize
        //    Reference: Harris (1978) - On the use of windows for harmonic analysis
        //    https://doi.org/10.1109/PROC.1978.10837
        for (var i = 0; i < FFTSize / 2; i++)
            _spectrum[i] = Math.Sqrt(_fftReal[i] * _fftReal[i] + _fftImag[i] * _fftImag[i]) / FFTSize;

        // 5. Bin spectrum into frequency bands using logarithmic spacing
        //    Log spacing mirrors human pitch perception (equal spacing = equal octaves)
        //    Frequency of bin i = i * SampleRate / FFTSize
        //    We map FFTSize/2 bins into BandCount bands on a log scale from 20Hz to Nyquist
        float minFreq = 20f;
        float maxFreq = SampleRate / 2f;  // Nyquist
        for (var b = 0; b < BandCount; b++)
        {
            // Exponential interpolation between minFreq and maxFreq
            float freqLow  = minFreq * Mathf.Pow(maxFreq / minFreq, (float)b       / BandCount);
            float freqHigh = minFreq * Mathf.Pow(maxFreq / minFreq, (float)(b + 1) / BandCount);

            // Convert frequency range to FFT bin indices
            int binLow  = Mathf.Clamp(Mathf.RoundToInt(freqLow  * FFTSize / SampleRate), 0, FFTSize / 2 - 1);
            int binHigh = Mathf.Clamp(Mathf.RoundToInt(freqHigh * FFTSize / SampleRate), 0, FFTSize / 2 - 1);

            // Average magnitude across bins in this band
            double bandSum = 0;
            int    count   = 0;
            for (var i = binLow; i <= binHigh; i++)
            {
                bandSum += _spectrum[i];
                count++;
            }
            _backBuffer[b] = count > 0 ? (float)(bandSum / count) : 0f;
        }

        // 6. Atomic buffer swap — main thread always reads a complete frame
        //    Interlocked.Exchange swaps the reference in a single CPU instruction,
        //    preventing the main thread from ever reading a half-written buffer
        _frontBuffer = Interlocked.Exchange(ref _backBuffer, _frontBuffer);

        _accumulationPos = 0;
    }

    // Called on the main thread every frame — push data to shader globals
    private void Update()
    {
        
        Debug.Log($"RMS: {_rms:F4}  Band1: {_frontBuffer[1]:F6}  Kick: {_kickEnvelope:F4}");
        // _frontBuffer is safe to read here after the atomic swap
        Shader.SetGlobalFloat("_RMS", _rms);
        for (var i = 0; i < BandCount; i++)
            Shader.SetGlobalFloat($"_Band{i}", _frontBuffer[i]);
        
        // ── Kick detection and envelope ───────────────────────────────────────────
// Onset detection: a kick is a sudden *increase* in band1 that crosses
// the threshold. Comparing to previous frame catches the transient.
// Reference: Bello et al. (2005) https://doi.org/10.1109/MSP.2005.1511798
        float currentBand1  = _frontBuffer[1];
        float band1Delta    = currentBand1 - _previousBand1;
        bool  kickDetected  = band1Delta > _kickThreshold && currentBand1 > 0.02f;

        if (kickDetected)
        {
            // Sharp attack — envelope jumps toward 1 instantly
            _kickEnvelope = Mathf.Lerp(_kickEnvelope, 1.0f, _kickAttack);
        }
        else
        {
            // Exponential decay back to zero between hits
            // Multiplying by (1 - release) each frame gives a smooth tail
            _kickEnvelope *= (1.0f - _kickRelease);
        }

        _previousBand1 = currentBand1;

        Shader.SetGlobalFloat("_KickEnvelope", _kickEnvelope);
    }
}