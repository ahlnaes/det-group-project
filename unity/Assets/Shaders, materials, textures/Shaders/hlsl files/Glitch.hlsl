#ifndef DET_GROUP_GLITCH_HLSL
#define DET_GROUP_GLITCH_HLSL

// ── Hash functions ─────────────────────────────────────────────────────────
// Different seeds per function to avoid correlated patterns

float Glitch_Hash11(float p)
{
    p = frac(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

float Glitch_Hash21(float2 p)
{
    p = frac(p * float2(0.1031, 0.1030));
    p += dot(p, p.yx + 33.33);
    return frac((p.x + p.y) * p.x);
}

float2 Glitch_Hash22(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.xx + p3.yz) * p3.zy);
}

// ── Block ID ───────────────────────────────────────────────────────────────
// Returns the cell coordinate for a given UV and grid resolution.
// floor(uv * divisions) gives integer cell coords — all pixels in the
// same cell share the same ID, so they move together as a block.

float2 Glitch_CellID(float2 uv, float2 divisions)
{
    return floor(uv * divisions);
}

// ── Main entry point ───────────────────────────────────────────────────────
void AudioGlitch_float(
    float2            uv,
    UnityTexture2D    wallTex,
    UnitySamplerState wallSampler,
    float             transient,       // _TransientEnvelope — primary trigger
    float             spectralFlux,    // _SpectralFlux — modulates chaos amount
    float             timeScale,
    float             glitchAmount,    // base intensity, tuned in material
    float             sliceCount,      // number of potential cells
    out float4        color)
{
    float t = _Time.y * timeScale;

    // ── Per-frame seed ─────────────────────────────────────────────────────
    // Quantized time — blocks re-randomize at discrete intervals rather than
    // drifting continuously. Transient energy increases reshuffle rate.
    // At zero transient this ticks slowly; on loud hits it reshuffles fast.
    float reshuffleRate = 2.0 + transient * 10.0 + spectralFlux * 50.0;
    float seed          = floor(t * reshuffleRate);

    // ── Decide grid mode per coarse region ────────────────────────────────
    // The screen is divided into coarse zones. Each zone independently
    // decides whether to use horizontal slices or a square grid.
    // modeHash > 0.5 → grid squares, otherwise → horizontal slices.
    float2 coarseID = Glitch_CellID(uv, float2(1.0, sliceCount * 0.25));
    float  modeHash = Glitch_Hash21(coarseID + seed * 0.17);
    bool   isGrid   = modeHash > 0.5;

    // ── Cell ID based on mode ──────────────────────────────────────────────
    float2 cellID;
    float2 cellSize;

    if (isGrid)
    {
        float res  = sliceCount * 0.5;
        cellID   = Glitch_CellID(uv, float2(res, res));
        cellSize = float2(1.0 / res, 1.0 / res);
    }
    else
    {
        // Horizontal slice — full width, X cell always 0
        cellID   = Glitch_CellID(uv, float2(1.0, sliceCount));
        cellSize = float2(1.0, 1.0 / sliceCount);
    }

    // ── Per-cell random values ─────────────────────────────────────────────
    float2 cellRand2 = Glitch_Hash22(cellID + seed);
    float  cellRand1 = Glitch_Hash21(cellID + seed + float2(3.7, 1.4));

    // ── Active cell threshold ──────────────────────────────────────────────
    // Only a fraction of cells glitch at once.
    // glitchAmount sets the base density, transient pushes more cells active.
    // At transient=0 and glitchAmount=0.1, roughly 10% of cells move.
    // A big transient hit can push nearly all cells active simultaneously.
    float activeThreshold = glitchAmount + transient * 0.85;
    bool  cellActive      = cellRand1 > (1.0 - activeThreshold);

    // ── Displacement ───────────────────────────────────────────────────────
    // Each active cell offsets its UV sample in a random direction.
    // Inactive cells sample straight — no displacement, clean texture.
    float2 displacement = float2(0.0, 0.0);

    if (cellActive)
    {
        // Map cellRand2 from [0,1] to [-1,1]
        float2 dir = (cellRand2 - 0.5) * 2.0;

        // Horizontal slide is stronger than vertical — classic video glitch look
        displacement = float2(
            dir.x * (0.04 + transient * 0.12),
            dir.y * (0.01 + transient * 0.04)
        );
    }

    // ── Scale/zoom per active cell ─────────────────────────────────────────
    // Zoom toward cell centre — blocks appear to pop or lurch independently.
    // Only active cells zoom. Zoom strength tied to transient.
    float2 cellCenter = (cellID + 0.5) * cellSize;
    float2 toCenter   = uv - cellCenter;
    float  zoomAmount = cellActive
                      ? (cellRand1 - 0.5) * 0.08 * transient
                      : 0.0;

    float2 sampledUV  = uv + toCenter * zoomAmount + displacement;

    // ── Chromatic aberration ───────────────────────────────────────────────
    // Splits RGB channels horizontally on glitching blocks.
    // Physically: simulates lens chromatic aberration or magnetic tape dropout.
    // Aberration scales with displacement magnitude and transient energy.
    float  aberration = length(displacement) * 2.0 + transient * 0.008;
    float2 aberOffset = float2(aberration, 0.0);

    float4 colR = SAMPLE_TEXTURE2D(wallTex.tex, wallSampler.samplerstate, sampledUV + aberOffset);
    float4 colG = SAMPLE_TEXTURE2D(wallTex.tex, wallSampler.samplerstate, sampledUV);
    float4 colB = SAMPLE_TEXTURE2D(wallTex.tex, wallSampler.samplerstate, sampledUV - aberOffset);

    color = float4(colR.r, colG.g, colB.b, 1.0);
}

#endif