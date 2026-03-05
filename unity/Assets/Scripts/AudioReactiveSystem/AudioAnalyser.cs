using System;
using System.Threading;
using UnityEngine;

public class AudioAnalyser : MonoBehaviour
{
    private const int FFTSize    = 1024;
    private const int BandCount  = 8;
    private const int SampleRate = 48000;

    // ── DSP thread buffers (never touched by main thread) ─────────────────
    private float[] _accumulationBuffer, _windowCoefficients, _windowedBuffer;
    private double[] _fftReal, _fftImag, _spectrum;
    private int _accumulationPos;

    // ── Thread-safe output from DSP thread ────────────────────────────────
    // _rms: volatile float — safe for single primitive cross-thread reads
    // Bands: double-buffered array — swapped atomically via Interlocked.Exchange
    private float[] _backBuffer;
    private volatile float _rms;

    public float   RMS  => _rms;
    public float[] Bands { get; private set; }

    // ── Kick envelope ──────────────────────────────────────────────────────
    // Triggers on sharp bass transients, decays between hits.
    // Reference: Bello et al. (2005) https://doi.org/10.1109/MSP.2005.1511798
    [Header("Kick Envelope")]
    [SerializeField] private float _kickThreshold = 0.02f;
    [SerializeField] private float _kickAttack    = 0.95f;
    [SerializeField] private float _kickRelease   = 0.05f;

    private float _kickEnvelope;
    private float _previousBand1;

    public float KickEnvelope => _kickEnvelope;

    // ── Transient envelope ─────────────────────────────────────────────────
    // Broadband onset — catches snares, claps, crashes across all bands.
    [Header("Transient Envelope")]
    [SerializeField] private float _transientThreshold = 0.05f;
    [SerializeField] private float _transientAttack    = 0.9f;
    [SerializeField] private float _transientRelease   = 0.08f;

    private float _transientEnvelope;

    public float TransientEnvelope => _transientEnvelope;

    // ── Smoothed band energies ─────────────────────────────────────────────
    // Asymmetric EMA — fast attack, slow release.
    // Reference: Zölzer (2008), Digital Audio Signal Processing, Ch. 4
    [Header("Band Energy Smoothing")]
    [SerializeField] private float _energyAttack  = 0.8f;
    [SerializeField] private float _energyRelease = 0.15f;

    private float   _bassEnergy;
    private float   _midEnergy;
    private float   _hiEnergy;
    private float   _spectralFlux;
    private float[] _previousBands;
    
    // ── Scan phase accumulator ─────────────────────────────────────────────────
    // Integrated in Update() so speed changes affect rate of change, not position.
    // Equivalent to a Speed CHOP in TouchDesigner.
    [Header("Scan Lines")]
    [SerializeField] private float _scanBaseSpeed  = 0.3f;
    [SerializeField] private float _scanSpeedScale = 1.0f;

    private float _scanPhase;

    private void Awake()
    {
        _accumulationBuffer = new float[FFTSize];
        _windowCoefficients = new float[FFTSize];
        _windowedBuffer     = new float[FFTSize];
        _fftReal            = new double[FFTSize];
        _fftImag            = new double[FFTSize];
        _spectrum           = new double[FFTSize / 2];

        Bands        = new float[BandCount];
        _backBuffer  = new float[BandCount];
        _previousBands = new float[BandCount];

        // Pre-compute Hann window coefficients once
        // https://en.wikipedia.org/wiki/Hann_function
        for (var i = 0; i < FFTSize; i++)
            _windowCoefficients[i] = 0.5f * (1f - Mathf.Cos(2f * Mathf.PI * i / (FFTSize - 1)));
    }

    private void OnAudioFilterRead(float[] data, int channels)
    {
        for (var i = 0; i < data.Length; i += channels)
        {
            _accumulationBuffer[_accumulationPos] = data[i];
            _accumulationPos++;
        }

        if (_accumulationPos < FFTSize) return;

        // RMS — calculated before windowing to avoid energy skew
        float sum = 0;
        for (var i = 0; i < FFTSize; i++)
            sum += _accumulationBuffer[i] * _accumulationBuffer[i];
        _rms = Mathf.Sqrt(sum / FFTSize);

        // Apply Hann window and copy to FFT input
        for (var i = 0; i < FFTSize; i++)
        {
            _fftReal[i] = _accumulationBuffer[i] * _windowCoefficients[i];
            _fftImag[i] = 0.0;
        }

        FFT.Forward(_fftReal, _fftImag);

        // Magnitude spectrum — positive frequencies only
        // Reference: Harris (1978) https://doi.org/10.1109/PROC.1978.10837
        for (var i = 0; i < FFTSize / 2; i++)
            _spectrum[i] = Math.Sqrt(_fftReal[i] * _fftReal[i] + _fftImag[i] * _fftImag[i]) / FFTSize;

        // Log-frequency band binning
        var minFreq = 20f;
        var maxFreq = SampleRate / 2f;
        for (var b = 0; b < BandCount; b++)
        {
            var freqLow  = minFreq * Mathf.Pow(maxFreq / minFreq, (float)b       / BandCount);
            var freqHigh = minFreq * Mathf.Pow(maxFreq / minFreq, (float)(b + 1) / BandCount);

            var binLow  = Mathf.Clamp(Mathf.RoundToInt(freqLow  * FFTSize / SampleRate), 0, FFTSize / 2 - 1);
            var binHigh = Mathf.Clamp(Mathf.RoundToInt(freqHigh * FFTSize / SampleRate), 0, FFTSize / 2 - 1);

            double bandSum = 0;
            var    count   = 0;
            for (var i = binLow; i <= binHigh; i++)
            {
                bandSum += _spectrum[i];
                count++;
            }
            _backBuffer[b] = count > 0 ? (float)(bandSum / count) : 0f;
        }

        // Atomic buffer swap
        Bands = Interlocked.Exchange(ref _backBuffer, Bands);
        _accumulationPos = 0;
    }

    private void Update()
    {
        // Push raw values to GPU
        Shader.SetGlobalFloat("_RMS", _rms);
        for (var i = 0; i < BandCount; i++)
            Shader.SetGlobalFloat($"_Band{i}", Bands[i]);

        // ── Smoothed band energies ─────────────────────────────────────────
        var rawBass = (Bands[0] + Bands[1]) / 2f;
        var rawMid  = (Bands[2] + Bands[3] + Bands[4]) / 3f;
        var rawHi   = (Bands[5] + Bands[6] + Bands[7]) / 3f;

        _bassEnergy = rawBass > _bassEnergy
            ? Mathf.Lerp(_bassEnergy, rawBass, _energyAttack)
            : Mathf.Lerp(_bassEnergy, rawBass, _energyRelease);

        _midEnergy = rawMid > _midEnergy
            ? Mathf.Lerp(_midEnergy, rawMid, _energyAttack)
            : Mathf.Lerp(_midEnergy, rawMid, _energyRelease);

        _hiEnergy = rawHi > _hiEnergy
            ? Mathf.Lerp(_hiEnergy, rawHi, _energyAttack)
            : Mathf.Lerp(_hiEnergy, rawHi, _energyRelease);

        Shader.SetGlobalFloat("_BassEnergy", _bassEnergy);
        Shader.SetGlobalFloat("_MidEnergy",  _midEnergy);
        Shader.SetGlobalFloat("_HiEnergy",   _hiEnergy);

        // ── Spectral flux + transient delta (shared loop) ─────────────────
        // Both need per-band deltas from the previous frame — compute once,
        // update _previousBands after both reads to avoid stale values.
        float flux       = 0f;
        float totalDelta = 0f;
        for (var i = 0; i < BandCount; i++)
        {
            float delta = Bands[i] - _previousBands[i];
            if (delta > 0f)
            {
                flux       += delta;
                totalDelta += delta;
            }
            _previousBands[i] = Bands[i];
        }

        _spectralFlux = flux;
        Shader.SetGlobalFloat("_SpectralFlux", _spectralFlux);

        // ── Kick envelope ──────────────────────────────────────────────────
        float currentBand1 = Bands[1];
        float band1Delta   = currentBand1 - _previousBand1;
        bool  kickDetected = band1Delta > _kickThreshold && currentBand1 > 0.02f;

        _kickEnvelope = kickDetected
            ? Mathf.Lerp(_kickEnvelope, 1.0f, _kickAttack)
            : _kickEnvelope * (1.0f - _kickRelease);

        _previousBand1 = currentBand1;
        Shader.SetGlobalFloat("_KickEnvelope", _kickEnvelope);

        // ── Transient envelope ─────────────────────────────────────────────
        _transientEnvelope = totalDelta > _transientThreshold
            ? Mathf.Lerp(_transientEnvelope, 1.0f, _transientAttack)
            : _transientEnvelope * (1.0f - _transientRelease);

        Shader.SetGlobalFloat("_TransientEnvelope", _transientEnvelope);
        
        // ── Scan phase ─────────────────────────────────────────────────────────────
        float shapedEnergy = Mathf.Pow(_bassEnergy, 0.5f);
        float scanSpeed = _scanBaseSpeed + shapedEnergy * _scanSpeedScale;
        _scanPhase += scanSpeed * Time.deltaTime;  // ← this line is missing
        Shader.SetGlobalFloat("_ScanPhase", _scanPhase);
    }
}