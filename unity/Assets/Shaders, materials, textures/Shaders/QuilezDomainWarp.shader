Shader "Custom/AudioReactiveNoise"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.05, 0.05, 0.15, 1)
        _AccentColor ("Accent Color", Color) = (0.2, 0.6, 1.0, 1)
        _NoiseScale ("Noise Scale", Float) = 3.0
        _DispStrength ("Displacement Strength", Float) = 0.4
        _TimeScale ("Time Scale", Float) = 0.3
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // ── Audio globals set by AudioAnalyser.Update() ──────────────────
            float _RMS;
            float _Band0;   // sub-bass
            float _Band1;   // bass
            float _Band2;   // low-mid
            float _Band3;   // mid
            float _Band4;   // upper-mid
            float _Band5;   // presence
            float _Band6;   // brilliance
            float _Band7;   // air

            // ── Material properties ──────────────────────────────────────────
            fixed4  _BaseColor;
            fixed4  _AccentColor;
            float   _NoiseScale;
            float   _DispStrength;
            float   _TimeScale;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv  : TEXCOORD0;
            };

            // ── Value noise ──────────────────────────────────────────────────
            // Hash: maps a 2D coordinate to a pseudo-random float
            // Based on: https://www.shadertoy.com/view/4dS3Wd (Morgan McGuire)
            float hash(float2 p)
            {
                p = frac(p * float2(234.34, 435.345));
                p += dot(p, p + 34.23);
                return frac(p.x * p.y);
            }

            // Smooth value noise — bilinear interpolation between hashed corners
            // Returns values in [0, 1]
            float noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);

                // Smoothstep for C1 continuity (no gradient discontinuities at cell edges)
                float2 u = f * f * (3.0 - 2.0 * f);

                float a = hash(i);
                float b = hash(i + float2(1, 0));
                float c = hash(i + float2(0, 1));
                float d = hash(i + float2(1, 1));

                return lerp(lerp(a, b, u.x),
                            lerp(c, d, u.x), u.y);
            }

            // ── Fractional Brownian Motion ───────────────────────────────────
            // Sums multiple octaves of noise at increasing frequency and
            // decreasing amplitude. Each octave adds finer detail.
            // Reference: Musgrave (1994), "Texturing and Modelling: A Procedural Approach"
            // https://iquilezles.org/articles/fbm/
            float fbm(float2 p, int octaves, float persistence)
            {
                float value    = 0.0;
                float amplitude = 0.5;
                float frequency = 1.0;

                for (int o = 0; o < octaves; o++)
                {
                    value     += amplitude * noise(p * frequency);
                    frequency *= 2.0;
                    amplitude *= persistence;
                }
                return value;
            }

            // ── Vertex shader ────────────────────────────────────────────────
            v2f vert(appdata v)
            {
                v2f o;

                // RMS drives vertical displacement of vertices
                // Bass band adds a low-frequency pulse on top
                float rmsScaled  = _RMS * 5.0;
                float bassScaled = _Band1 * 200.0;

                float2 uv       = v.uv * _NoiseScale;
                float  t        = _Time.y * _TimeScale * (1.0 + rmsScaled);

                // Sample noise for displacement — animated by time + RMS speed
                float disp = fbm(uv + float2(t * 0.4, t * 0.3), 3, 0.5);

                // Bass pushes the geometry up in a wave
                v.vertex.y += disp * _DispStrength * (1.0 + rmsScaled)
                            + sin(v.uv.x * 6.28 + t * 2.0) * bassScaled * 0.01;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv  = v.uv;
                return o;
            }

            // ── Fragment shader ──────────────────────────────────────────────
            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv * _NoiseScale;
                float  t  = _Time.y * _TimeScale * (1.0 + _RMS * 5.0);

                // Mid and high bands modulate noise time evolution independently
                float midScaled  = _Band3 * 200.0;
                float highScaled = _Band6 * 200.0;

                // ── Domain warp ──────────────────────────────────────────────
                // First pass: sample noise to get a warp offset
                // Second pass: use that offset to displace the lookup point
                // This creates the characteristic folded/fluid look
                // Reference: https://iquilezles.org/articles/warp/
                float2 warp = float2(
                    fbm(uv + float2(t * 0.5, t * 0.3) + float2(1.7, 9.2), 2, 0.5),
                    fbm(uv + float2(t * 0.4, t * 0.6) + float2(8.3, 2.8), 2, 0.5)
                );

                // Warp strength driven by mid frequencies
                float warpStrength = _DispStrength * (1.0 + midScaled);
                float2 warpedUV    = uv + warpStrength * (warp - 0.5) * 2.0;

                // Final noise sample on warped coordinates
                float n = fbm(warpedUV + float2(t * 0.2, t * 0.15), 3, 0.5);

                // High band brightens the result — presence/air adds shimmer
                n += highScaled * 0.05;
                n  = saturate(n);

                // Colour: lerp between base and accent driven by noise value
                // Accent colour pulses with RMS
                fixed4 col = lerp(_BaseColor, _AccentColor * (1.0 + _RMS * 3.0), n);

                // Edge darkening (vignette) — draws attention to centre
                float2 centered = i.uv - 0.5;
                float  vignette = 1.0 - dot(centered, centered) * 2.0;
                col.rgb        *= saturate(vignette);

                return col;
            }
            ENDCG
        }
    }
}