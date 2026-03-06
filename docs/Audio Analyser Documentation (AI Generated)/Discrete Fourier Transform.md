---
tags:
  - programming/audio
  - audio-engineering
type: info
parent: "[[Audio Programming]]"
aliases:
  - DFT
---
# The Discrete Fourier Transform
The DFT takes a sequence of N time-domain samples and produces N complex numbers representing the signal's frequency content. The formula for each output bin k is:
$$X[k] = \sum_{n=0}^{N-1} x[n] \cdot e^{-i 2\pi k n / N}$$
In plain English: for each frequency bin k, you multiply every sample by a rotating complex exponential and sum the results. The complex exponential is just a sinusoid — by Euler's formula:
$$e^{-i\theta} = \cos(\theta) - i\sin(\theta)$$
So each bin is essentially asking: "how much does my signal correlate with a sinusoid at frequency k?"

The problem: computing this naively requires N multiplications per bin, and there are N bins. That's O(N²) operations. For N=1024 that's ~1 million operations per frame. This is where [[Fast Fourier Transform|FFT]] comes in.