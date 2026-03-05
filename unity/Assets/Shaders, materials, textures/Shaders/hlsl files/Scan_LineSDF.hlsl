#ifndef DET_GROUP_SCANLINES_HLSL
#define DET_GROUP_SCANLINES_HLSL

// ── Signed distance to a sweeping line ────────────────────────────────────
// pos:   current position on the axis (0-1)
// phase: where the line centre is right now (0-1, wraps via frac)
// width: half-width of the line in UV space
// Returns 0 at the line centre, 1 at the edges — ready for smoothstep.
float Scan_LineSDF(float pos, float phase, float width)
{
    // frac() makes the line wrap around continuously
    float d = abs(frac(pos - phase) - 0.5);
    return smoothstep(width, width * 0.1, d);
}

// ── Glow falloff ──────────────────────────────────────────────────────────
// Adds a soft halo around each line — physically models light scatter.
// A single bright line in isolation would look harsh without this.
float Scan_Glow(float pos, float phase, float glowRadius)
{
    float d = abs(frac(pos - phase) - 0.5);
    return exp(-d * (1.0 / glowRadius) * 8.0);
}

// ── Main entry point ───────────────────────────────────────────────────────
void AudioScanLines_float(
    float3 worldPos,
    float  bassEnergy,     // _BassEnergy  — slow thick horizontal lines
    float  midEnergy,      // _MidEnergy   — medium diagonal lines
    float  hiEnergy,       // _HiEnergy    — fast thin vertical lines
    float  rms,            // _RMS         — overall brightness
    float  kickEnvelope,   // _KickEnvelope — brightness pulse on kick
    float  lineScale,      // spatial frequency of lines
    float  timeScale,      // global speed multiplier
    float  lineWidth,      // base line width
    float  glowAmount,     // how much soft halo around each line
    out float4 color)
{
    color = float4(0.0, 0.0, 0.0, 1.0);

    float t = _Time.y * timeScale;

    // Normalised world axes for line positioning.
    // Using world space means lines are consistent across mesh boundaries —
    // same reason we used triplanar in the curl shader.
    float axisH = frac(worldPos.y * lineScale);  // horizontal lines sweep vertically
    float axisV = frac(worldPos.x * lineScale);  // vertical lines sweep horizontally

    float brightness = 0.0;

    // ── Bass lines — thick, slow, horizontal ──────────────────────────────
    // Two lines at different phases so they don't always overlap
    float bassSpeed = 0.08 + bassEnergy * 0.25;
    float bassWidth = lineWidth * (2.5 + bassEnergy * 6.0);
    float bassGlow  = glowAmount * (1.5 + bassEnergy * 3.0);

    float bassLine1 = Scan_LineSDF(axisH, frac(t * bassSpeed),        bassWidth);
    float bassLine2 = Scan_LineSDF(axisH, frac(t * bassSpeed + 0.47), bassWidth * 0.7);
    float bassGlow1 = Scan_Glow(axisH, frac(t * bassSpeed),        bassGlow);
    float bassGlow2 = Scan_Glow(axisH, frac(t * bassSpeed + 0.47), bassGlow * 0.6);

    brightness += (bassLine1 + bassLine2) * (0.6 + bassEnergy * 1.5);
    brightness += (bassGlow1 + bassGlow2) * bassEnergy * 0.4;

    // ── Mid lines — medium speed, mix of horizontal and vertical ──────────
    float midSpeed  = 0.2 + midEnergy * 0.6;
    float midWidth  = lineWidth * (1.2 + midEnergy * 2.0);
    float midGlow   = glowAmount * (0.8 + midEnergy * 1.5);

    float midLineH = Scan_LineSDF(axisH, frac(t * midSpeed + 0.23),  midWidth);
    float midLineV = Scan_LineSDF(axisV, frac(t * midSpeed * 1.3 + 0.61), midWidth * 0.8);
    float midGlowH = Scan_Glow(axisH, frac(t * midSpeed + 0.23),  midGlow);
    float midGlowV = Scan_Glow(axisV, frac(t * midSpeed * 1.3 + 0.61), midGlow * 0.7);

    brightness += (midLineH + midLineV) * (0.4 + midEnergy * 1.2);
    brightness += (midGlowH + midGlowV) * midEnergy * 0.3;

    // ── Hi lines — thin, fast, vertical ───────────────────────────────────
    // Multiple thin lines for a dense shimmer on busy hi-frequency content
    float hiSpeed = 0.5 + hiEnergy * 2.0;
    float hiWidth = lineWidth * (0.4 + hiEnergy * 0.8);
    float hiGlow  = glowAmount * 0.4;

    float hiLine1 = Scan_LineSDF(axisV, frac(t * hiSpeed),          hiWidth);
    float hiLine2 = Scan_LineSDF(axisV, frac(t * hiSpeed + 0.33),   hiWidth * 0.6);
    float hiLine3 = Scan_LineSDF(axisV, frac(t * hiSpeed + 0.67),   hiWidth * 0.4);
    float hiGlow1 = Scan_Glow(axisV, frac(t * hiSpeed),             hiGlow);

    brightness += (hiLine1 + hiLine2 + hiLine3) * (0.2 + hiEnergy * 1.0);
    brightness += hiGlow1 * hiEnergy * 0.2;

    // ── Global brightness modulation ───────────────────────────────────────
    // RMS scales the overall output — quiet passages dim the lines.
    // Kick adds a sharp brightness pulse that decays with the envelope.
    float globalBright = 0.3 + rms * 1.2 + kickEnvelope * 1.5;
    brightness *= globalBright;

    // Clamp — lines can bloom slightly over 1.0 for a blown-out look on loud hits
    brightness = max(0.0, brightness);

    color = float4(brightness, brightness, brightness, 1.0);
}

#endif