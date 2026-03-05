Shader "Custom/AudioReactiveCellularOverlay"
{
    Properties
    {
        _MainTex        ("Wall Texture",    2D)           = "white" {}
        _AccentColor    ("Accent Color",    Color)        = (0.1, 0.6, 1.0, 1)
        _CellScale      ("Cell Scale",      Float)        = 1.0
        _TimeScale      ("Time Scale",      Float)        = 0.2
        _EffectStrength ("Effect Strength", Range(0, 1))  = 0.4
        _EdgeBrightness ("Edge Brightness", Range(0, 3))  = 1.2
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex   vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // ── Audio globals set by AudioAnalyser.Update() ──────────────
            float _RMS;
            float _Band0, _Band1, _Band2, _Band3;
            float _Band4, _Band5, _Band6, _Band7;

            // ── Material properties ──────────────────────────────────────
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            float4 _AccentColor;
            float  _CellScale;
            float  _TimeScale;
            float  _EffectStrength;
            float  _EdgeBrightness;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;  // for wall texture sampling
                float3 positionWS  : TEXCOORD1;  // world position for seamless noise
            };

            // ── Voronoi helpers ──────────────────────────────────────────
            float2 cellHash(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)),
                           dot(p, float2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453);
            }

            // Worley (1996) "A cellular texture basis function"
            // https://dl.acm.org/doi/10.1145/237170.237267
            float voronoi(float2 uv, float t, float audioSpeed, float audioPull)
            {
                float2 cell    = floor(uv);
                float2 local   = frac(uv);
                float  minDist = 8.0;

                for (int y = -1; y <= 1; y++)
                {
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 neighbour    = float2(x, y);
                        float2 h            = cellHash(cell + neighbour);
                        float2 featurePoint = 0.5 + 0.5 * sin(t * audioSpeed + 6.28 * h);
                        featurePoint        = lerp(featurePoint, round(featurePoint), audioPull);
                        float2 diff         = neighbour + featurePoint - local;
                        float  d            = dot(diff, diff);
                        minDist             = min(minDist, d);
                    }
                }
                return sqrt(minDist);
            }

            float hash11(float2 p)
            {
                p = frac(p * float2(234.34, 435.345));
                p += dot(p, p + 34.23);
                return frac(p.x * p.y);
            }

            // ── Vertex ───────────────────────────────────────────────────
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv          = TRANSFORM_TEX(IN.uv, _MainTex);

                // World position passed to fragment so noise is sampled
                // in world space — eliminates seams at mesh boundaries
                OUT.positionWS  = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            // ── Fragment ─────────────────────────────────────────────────
            float4 frag(Varyings IN) : SV_Target
            {
                // ── Wall texture ─────────────────────────────────────────
                float4 wallCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // ── Audio ────────────────────────────────────────────────
                float bass   = _Band1 * 200.0;
                float lowMid = _Band2 * 200.0;
                float mid    = _Band3 * 200.0;
                float hi     = _Band6 * 200.0;
                float rms    = _RMS   * 5.0;

                float t = _Time.y * _TimeScale;

                // ── World-space noise coordinates ────────────────────────
                // XZ plane for floor-facing projection, XY for walls.
                // Blend both so the shader works on any surface orientation
                // without seams regardless of which way the face points.
                float2 worldXZ = IN.positionWS.xz * _CellScale;
                float2 worldXY = IN.positionWS.xy * _CellScale;
                float2 worldYZ = IN.positionWS.yz * _CellScale;

                // Derive blend weights from the surface normal direction.
                // We approximate this from the rate of change of world pos —
                // a flat upward surface varies more in XZ, a wall more in XY/YZ.
                float3 dpdx   = ddx(IN.positionWS);
                float3 dpdy   = ddy(IN.positionWS);
                float3 normal = abs(normalize(cross(dpdx, dpdy)));

                // normal.y ~ 1 means floor/ceiling, normal.x/z ~ 1 means wall
                float  blendXZ = normal.y;
                float  blendXY = normal.z;
                float  blendYZ = normal.x;

                // ── Voronoi layers ───────────────────────────────────────
                // Layer 1 — large cells, bass driven
                float v1XZ = voronoi(worldXZ,             t, 1.0 + rms, bass * 0.6);
                float v1XY = voronoi(worldXY,             t, 1.0 + rms, bass * 0.6);
                float v1YZ = voronoi(worldYZ,             t, 1.0 + rms, bass * 0.6);
                float v1   = v1XZ * blendXZ + v1XY * blendXY + v1YZ * blendYZ;

                // Layer 2 — medium cells, mid driven
                float v2XZ = voronoi(worldXZ * 2.3 + float2(3.7, 1.4), t * 1.3, 1.2 + mid, lowMid * 0.4);
                float v2XY = voronoi(worldXY * 2.3 + float2(3.7, 1.4), t * 1.3, 1.2 + mid, lowMid * 0.4);
                float v2YZ = voronoi(worldYZ * 2.3 + float2(3.7, 1.4), t * 1.3, 1.2 + mid, lowMid * 0.4);
                float v2   = v2XZ * blendXZ + v2XY * blendXY + v2YZ * blendYZ;

                // Layer 3 — fine cells, hi driven
                float v3XZ = voronoi(worldXZ * 5.1 + float2(7.2, 4.9), t * 2.1, 1.5 + hi, 0.0);
                float v3XY = voronoi(worldXY * 5.1 + float2(7.2, 4.9), t * 2.1, 1.5 + hi, 0.0);
                float v3YZ = voronoi(worldYZ * 5.1 + float2(7.2, 4.9), t * 2.1, 1.5 + hi, 0.0);
                float v3   = v3XZ * blendXZ + v3XY * blendXY + v3YZ * blendYZ;

                // ── Edge detection ───────────────────────────────────────
                float edge  = 1.0 - smoothstep(0.0, 0.08 + bass * 0.06, v1);
                float edge2 = 1.0 - smoothstep(0.0, 0.04 + mid  * 0.03, v2);

                // ── Composite ────────────────────────────────────────────
                float4 accentPulse = _AccentColor * (1.0 + rms * 1.5);

                float4 col = wallCol;

                // Primary edges — coloured, bass reactive
                col.rgb += edge  * accentPulse.rgb * _EdgeBrightness * (0.5 + bass * 0.8);

                // Secondary edges — quieter, mid reactive
                col.rgb += edge2 * accentPulse.rgb * _EdgeBrightness * 0.3 * (0.3 + mid * 0.5);

                // Interior tint — subtle colour wash inside cells, only on loud moments
                float interior = saturate(1.0 - v1 * 2.0);
                col.rgb = lerp(col.rgb,
                               col.rgb * accentPulse.rgb * 0.5,
                               interior * _EffectStrength * rms);

                // Hi freq shimmer grain
                float grain = hash11(IN.uv * 300.0 + _Time.y * 3.0);
                col.rgb    += grain * hi * 0.1;

                // Effect only brightens — wall texture always readable underneath
                col.rgb = max(col.rgb, wallCol.rgb);

                return col;
            }
            ENDHLSL
        }
    }
}