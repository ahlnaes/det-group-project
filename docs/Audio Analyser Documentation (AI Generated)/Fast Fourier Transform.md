# FFT

> [!What is FFT?]
> A fast Fourier transform (FFT) is an algorithm that computes the discrete Fourier transform ([DFT](Discrete%20Fourier%20Transform.md)) of a sequence, or its inverse (IDFT). A Fourier transform converts a signal from its original domain (often time or space) to a representation in the frequency domain and vice versa.

## Why is FFT faster than DFT?

The key insight — discovered by Cooley and Tukey in 1965 — is that the DFT of a sequence can be split into two DFTs of half the size:

$$X[k] = X_{even}[k] + e^{-i2\pi k/N} \cdot X_{odd}[k]$$

Where $X_{even}$ is the DFT of the even-indexed samples and $X_{odd}$ is the DFT of the odd-indexed samples. Apply this recursively — split evens and odds again and again — until you reach size-2 DFTs that are trivial to compute.

This reduces complexity from $O(N²)$ to $O(N \log_2 N)$.

For N=1024: from ~1,000,000 operations down to ~10,000. That's the entire reason FFT exists. [@Cooley1965]

## The Two Stages

**Stage 1 — Bit-reversal permutation**

The recursive splitting reorders the input in a specific pattern. Rather than actually recursing, we pre-shuffle the input array so the iterative passes work correctly. The index of each element, written in binary, gets its bits reversed:

| Original index | Binary | Bit-reversed | New index |
|---|---|---|---|
| 0 | 000 | 000 | 0 |
| 1 | 001 | 100 | 4 |
| 2 | 010 | 010 | 2 |
| 3 | 011 | 110 | 6 |
| 4 | 100 | 001 | 1 |
| 5 | 101 | 101 | 5 |
| 6 | 110 | 011 | 3 |
| 7 | 111 | 111 | 7 |

**Stage 2 — Butterfly passes**

After reordering, we perform $log₂(N)$ passes. Each pass combines pairs of values using the **butterfly operation**. For each pair of indices u and v:
