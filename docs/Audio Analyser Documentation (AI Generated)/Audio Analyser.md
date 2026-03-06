---
type: assignment
tags:
  - fft
  - programming/audio
  - unity
parent: "[[DET]]"
---
# Audio Analyser

## Overview

The `AudioAnalyser` MonoBehaviour sits on the same GameObject as an `AudioSource` and processes audio on Unity's [DSP](https://en.wikipedia.org/wiki/Digital_signal_processor) thread in real time. It produces a set of **derived signals** that drive shaders and other visual systems.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    DSP THREAD                       │
│                                                     │
│  AudioSource → OnAudioFilterRead()                  │
│       ↓                                             │
│  Accumulate samples → Hann window → FFT             │
│       ↓                                             │
│  Magnitude spectrum → Log-spaced bands              │
│       ↓                                             │
│  Atomic swap → _frontBuffer / _rms (volatile)       │
└──────────────────────┬──────────────────────────────┘
                       │  thread boundary
┌──────────────────────▼──────────────────────────────┐
│                   MAIN THREAD                       │
│                                                     │
│  Update() reads _frontBuffer                        │
│       ↓                                             │
│  Derived signals computed                           │
│       ↓                                             │
│  Shader.SetGlobalFloat() → GPU                      │
└─────────────────────────────────────────────────────┘
```

---

## Concepts

### [[Spectral Leakage]]

The [[Fast Fourier Transform|FFT]] assumes your input buffer is one complete period of an infinitely repeating signal. **When the buffer edges don't line up smoothly, the discontinuity appears as a sharp transient** — which contains energy at all frequencies. This energy smears across frequency bins that shouldn't have any.

**Why it matters:** Without correction, the "bass" band contains leaked energy from mid frequencies and vice versa. Band separation becomes blurry — kick drums bleed into mids, hi-hats bleed downward.

**The fix — [Hann window](https://en.wikipedia.org/wiki/Hann_function):** Tapers the buffer edges to zero before the [[Fast Fourier Transform|FFT]]. No discontinuity at the seam, no leakage.

$$w[i] = 0.5 \cdot \left(1 - \cos\left(\frac{2\pi i}{N - 1}\right)\right)$$

At `i = 0` and `i = N-1` (edges): result = 0 — tapered to zero.  
At `i = N/2` (centre): result = 1 — fully preserved.

Pre-computed once in `Awake()`, applied each frame before [[Fast Fourier Transform|FFT]].

---

### [[Thread Safety]]

The DSP thread writes band values one element at a time. If the main thread reads mid-write, it gets a **torn read** — some values from the previous frame, some from the current one. Non-deterministic, nearly impossible to debug.

**Rules:**

- `float` / `int` marked `volatile` → [atomic](https://en.wikipedia.org/wiki/Read%E2%80%93modify%E2%80%93write) read/write, safe for single primitives
- `float[]` → `volatile` doesn't work on arrays. Requires **double buffer + atomic pointer swap**

> [!info] Double Buffer
> Double buffering is a technique used in computer graphics to reduce flickering and improve the smoothness of displayed images by using two buffers: one for displaying the current image and another for drawing the next image. Once the drawing is complete, the buffers are swapped, allowing the new image to be shown all at once, which helps avoid visual artifacts like tearing.

> [!info] Atomic Pointer Swap
> An atomic pointer swap is an operation that atomically exchanges the value of a pointer with a new value, ensuring that the operation is completed without interference from other threads. This is useful in multithreading environments to maintain data integrity and prevent race conditions.

**Why `_accumulationBuffer` needs no protection:** Only ever touched by the DSP thread. The main thread never reads it directly.

**Why `_rms` needs `volatile`:** Written by DSP thread, read by main thread every `Update()`. Without `volatile`, the compiler may cache the value in a register on the main thread — it would never see updates.

**Double buffer pattern:**

```
DSP THREAD                          MAIN THREAD
(every ~21ms)                       (every ~13ms @ 72fps)
     │                                    │
     ▼                                    ▼
┌─────────────┐                    ┌─────────────┐
│   WRITE to  │                    │   READ from │
│  back buffer│                    │ front buffer│
└─────────────┘                    └─────────────┘
      [B]  ← writing here                [A]  ← reading here safely

── DSP finishes frame → Interlocked.Exchange() ──

      [A]  ← writing here               [B]  ← reading here safely
```

`Interlocked.Exchange()` swaps the reference in a single CPU instruction — no window for a torn read.

---

### [[RMS — Root Mean Square]]

Measures the perceived loudness of an audio signal. The name describes the three steps in reverse order:

$$RMS = \sqrt{\frac{1}{N} \sum_{n=0}^{N-1} x[n]^2}$$

**Why square then root?** Audio samples are bipolar (−1 to +1). A plain average gives roughly zero regardless of loudness. Squaring makes everything positive, the root brings it back to the amplitude scale.

```csharp
float sum = 0;
for (int i = 0; i < FFTSize; i++)
    sum += _accumulationBuffer[i] * _accumulationBuffer[i];  // square
_rms = Mathf.Sqrt(sum / FFTSize);                           // mean, root
```

RMS is calculated from raw audio **before** windowing — windowing tapers edges to zero which would artificially lower the energy reading.

---

### Interleaved Audio

Stereo PCM packs both channels into one flat array:

```
Index:   [0]  [1]  [2]  [3]  [4]  [5]
Value:   [L0] [R0] [L1] [R1] [L2] [R2]
          ↑         ↑         ↑
          left channel samples only
```

To extract mono (left channel only), step by `channels`:

```csharp
for (int i = 0; i < data.Length; i += channels)
    _accumulationBuffer[_accumulationPos++] = data[i];
```

`channels` is provided directly by Unity as the second parameter of `OnAudioFilterRead`.

---

### Sample Accumulation

`OnAudioFilterRead` is called with ~512 samples at a time. The [[Fast Fourier Transform|FFT]] needs 1024. Samples must be accumulated across multiple calls before an [[Fast Fourier Transform|FFT]] frame can be processed.

`_accumulationPos` tracks progress. When it reaches `FFTSize`:

1. Apply window function
2. Calculate RMS
3. Run [[Fast Fourier Transform|FFT]] and bin into bands
4. Swap buffers
5. Reset `_accumulationPos = 0` (no need to clear — values will be overwritten)

---

### [[Fast Fourier Transform|FFT]] — [[Fast Fourier Transform]]

Converts time-domain samples into frequency-domain magnitudes. Based on the Cooley-Tukey algorithm (1965), which reduces complexity from $O(N^2)$ to $O(N \log_2 N)$ by recursively splitting the [[Discrete Fourier Transform|DFT]] into even and odd sub-problems.

$$X[k] = \sum_{n=0}^{N-1} x[n] \cdot e^{-i 2\pi k n / N}$$

Output is symmetric — only the first `FFTSize / 2` bins carry unique information (positive frequencies).

Magnitude per bin:

$$|X[k]| = \frac{\sqrt{\text{real}[k]^2 + \text{imag}[k]^2}}{N}$$

**References:**

- Cooley, J.W. & Tukey, J.W. (1965). An algorithm for the machine calculation of complex Fourier series. _Mathematics of Computation, 19_(90), 297–301. https://doi.org/10.1090/S0025-5718-1965-0178586-1
- Harris, F.J. (1978). On the use of windows for harmonic analysis with the [[discrete Fourier transform]]. _Proceedings of the IEEE, 66_(1), 51–83. https://doi.org/10.1109/PROC.1978.10837

---

### Log-Frequency Band Binning

The [[Fast Fourier Transform|FFT]] produces linearly spaced bins (each bin = `SampleRate / FFTSize` Hz wide). Human pitch perception is logarithmic — each octave doubles in frequency. A linear split would give bass only 3 bins and highs 500 bins.

Log spacing: exponential interpolation between `minFreq` and `maxFreq`:

$$f_{low}(b) = f_{min} \cdot \left(\frac{f_{max}}{f_{min}}\right)^{b / B}$$

```
$$f_{low}(b) = f_{min} \cdot \left(\frac{f_{max}}{f_{min}}\right)^{b / B}$$
```

Where $B$ is the total number of bands.

---

## Derived Signals

Computed on the main thread in `Update()` from the raw band data. All pushed to the GPU via `Shader.SetGlobalFloat()`.

|Signal|Source|Used by|
|---|---|---|
|`_RMS`|Volatile float from DSP thread|General brightness, speed|
|`_Band0–7`|Double-buffered band energies|Per-frequency reactions|
|`_KickEnvelope`|Bass onset detector with decay|Curl shader displacement|
|`_TransientEnvelope`|Broadband onset detector|Glitch shader|
|`_BassEnergy`|Smoothed Band0+1|Slow breathing motion|
|`_MidEnergy`|Smoothed Band2–4|Colour shifts|
|`_HiEnergy`|Smoothed Band5–7|Shimmer, fine detail|
|`_SpectralFlux`|Sum of positive band deltas|Overall audio activity level|

---

### Onset Detection

A sudden increase in a band's energy that crosses a threshold. Comparing the current value to the previous frame's value catches the transient edge rather than the sustained energy.

$$\delta[n] = E[n] - E[n-1], \quad \text{onset if } \delta[n] > \theta$$

**Reference:** Bello, J.P. et al. (2005). A tutorial on onset detection in music signals. _IEEE Signal Processing Magazine, 22_(5), 23–41. https://doi.org/10.1109/MSP.2005.1511798

---

### Smoothed Envelopes — Attack / Release

Raw band values jump frame to frame. An asymmetric exponential moving average smooths the signal while preserving transient response.

$$y[n] = \alpha \cdot x[n] + (1 - \alpha) \cdot y[n-1]$$

- **Attack** $\alpha$ — high value (e.g. 0.9), fast rise, tight to the beat
- **Release** $\alpha$ — low value (e.g. 0.05), slow decay, smooth tail

Same principle as a dynamics compressor's attack/release controls.

**Reference:** Zölzer, U. (2008). _Digital Audio Signal Processing_ (2nd ed.). Wiley. Chapter 4.

---

### Spectral Flux

Measures how rapidly the spectrum is changing frame to frame — the sum of all positive band energy increases.

$$\text{Flux}[n] = \sum_{b=0}^{B-1} \max(0, , E_b[n] - E_b[n-1])$$

Low flux = quiet, sustained, harmonic content.  
High flux = busy, percussive, rapidly changing content.

Different from RMS — a loud sustained note has high RMS but low flux. A busy drum fill has high flux regardless of absolute loudness.

---

## Shaders

|Shader|Primary signal|Effect|
|---|---|---|
|`CurlNoise`|`_KickEnvelope`|Wall texture warped by fluid curl noise|
|`AudioGlitch`|`_TransientEnvelope`|Texture sliced into blocks, offset on transients|

---

## References

- Cooley, J.W. & Tukey, J.W. (1965). An algorithm for the machine calculation of complex Fourier series. _Mathematics of Computation, 19_(90), 297–301. https://doi.org/10.1090/S0025-5718-1965-0178586-1
- Harris, F.J. (1978). On the use of windows for harmonic analysis with the [[discrete Fourier transform]]. _Proceedings of the IEEE, 66_(1), 51–83. https://doi.org/10.1109/PROC.1978.10837
- Bello, J.P., Daudet, L., Abdallah, S., Duxbury, C., Davies, M., & Sandler, M.B. (2005). A tutorial on onset detection in music signals. _IEEE Signal Processing Magazine, 22_(5), 23–41. https://doi.org/10.1109/MSP.2005.1511798
- Bridson, R. (2007). Curl-noise for procedural fluid flow. _ACM SIGGRAPH 2007_. https://doi.org/10.1145/1276377.1276435
- Worley, S. (1996). A cellular texture basis function. _SIGGRAPH '96_, 291–294. https://dl.acm.org/doi/10.1145/237170.237267
- Zölzer, U. (2008). _Digital Audio Signal Processing_ (2nd ed.). Wiley.