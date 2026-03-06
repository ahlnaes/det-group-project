---
type: info
tags:
  - audio-engineering
  - programming/audio
  - fft
parent: "[[Audio Programming]]"
related: "[[Fast Fourier Transform]]"
---
# Spectral Leakage

> [!INFO] Spectral Leakage
> This is why raw [[Fast Fourier Transform|FFT]] output looks messy and why every real-world spectrum analyser applies a window

^92ea79

### The [[Fast Fourier Transform|FFT]]'s Hidden Assumption
The [[Fast Fourier Transform|FFT]] doesn't know it's receiving a slice of a continuous audio stream. It mathematically assumes that the N samples you give it represent **one complete period of a perfectly repeating signal** — as if you took that buffer and tiled it infinitely in both directions.

This is almost never true. Say your 1024-sample buffer contains a 200Hz sine wave, but 1024 samples at 48kHz is ~21ms, and 200Hz has a period of 5ms — so you get about 4.2 cycles. That 0.2 fractional cycle means the signal at the end of the buffer doesn't match the signal at the start. When the [[Fast Fourier Transform|FFT]] "tiles" the buffer, it sees a **discontinuity at the seam** — a sudden jump in amplitude. ^92291b

That discontinuity isn't a real frequency in the signal — but the [[Fast Fourier Transform|FFT]] has to represent it somehow. It does so by smearing energy across many adjacent frequency bins. A clean 200Hz tone ends up polluting bins at 180Hz, 220Hz, and beyond. That's spectral leakage.

#### How a Window Function Fixes It

A window function is just an array of N values that you **multiply** your samples by before running the [[Fast Fourier Transform|FFT]]. It tapers smoothly to zero at both ends of the buffer, so regardless of what the signal is doing, the edges always go to zero — no discontinuity, no seam, no leakage artifact.

Visualised:

```
Raw buffer:     [■■■■■■■■■■■■■■■■]   ← hard edges, seam when tiled
Hann window:    [0..▲▲▲▲▲▲▲▲▲..0]   ← smooth bell shape
Windowed:       [0..████████████..0] ← edges taper to zero, no seam
```

Different windows trade off leakage suppression vs. frequency resolution — **Hann** is the standard choice for audio reactive work. **Blackman-Harris** suppresses leakage more aggressively at the cost of slightly wider peaks. For your use case Hann is fine.