using System;

/// <summary>
/// Iterative Cooley-Tukey FFT. Operates in-place on a pre-allocated Complex array.
/// No allocations after initialization — safe to call from the DSP thread.
/// </summary>
public static class FFT
{
    /// <summary>
    /// Performs in-place FFT on the provided buffer.
    /// Input: real parts loaded into buffer, imaginary parts zeroed.
    /// Output: complex spectrum in-place.
    /// Length must be a power of 2.
    /// </summary>
    public static void Forward(double[] real, double[] imag)
    {
        var n = real.Length;

        // Bit-reversal permutation
        var j = 0;
        for (var i = 1; i < n; i++)
        {
            int bit = n >> 1;
            for (; (j & bit) != 0; bit >>= 1)
                j ^= bit;
            j ^= bit;

            if (i < j)
            {
                (real[i], real[j]) = (real[j], real[i]);
                (imag[i], imag[j]) = (imag[j], imag[i]);
            }
        }

        // Cooley-Tukey iterative FFT
        for (int len = 2; len <= n; len <<= 1)
        {
            double ang = -2.0 * Math.PI / len;
            double wRe = Math.Cos(ang);
            double wIm = Math.Sin(ang);

            for (int i = 0; i < n; i += len)
            {
                double curRe = 1.0, curIm = 0.0;
                for (int k = 0; k < len / 2; k++)
                {
                    int u = i + k;
                    int v = i + k + len / 2;

                    double tRe = curRe * real[v] - curIm * imag[v];
                    double tIm = curRe * imag[v] + curIm * real[v];

                    real[v] = real[u] - tRe;
                    imag[v] = imag[u] - tIm;
                    real[u] += tRe;
                    imag[u] += tIm;

                    double nextRe = curRe * wRe - curIm * wIm;
                    curIm = curRe * wIm + curIm * wRe;
                    curRe = nextRe;
                }
            }
        }
    }
}