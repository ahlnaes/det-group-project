Shader "Custom/PlutoGlobe"
{
    // Properties are what shows up in the Material inspector.
    // Think of them like public variables in a C# MonoBehaviour.
    Properties
    {
        _ColorTex ("Color Map", 2D) = "white" {}
    }

    SubShader
    {
        // Tags tell Unity's render pipeline how to categorize this shader.
        // "Opaque" = no transparency, "Geometry" = render with normal objects.
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            HLSLPROGRAM
            // These pragmas tell the compiler which functions are the
            // vertex shader and fragment shader entry points.
            #pragma vertex vert
            #pragma fragment frag

            // URP core library — gives us transformation functions
            // like TransformObjectToHClip that convert between spaces.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Input FROM the mesh — Unity fills these automatically
            // from the vertex buffer. The semantics (POSITION, TEXCOORD0)
            // tell the GPU which data to bind to which field.
            struct Attributes
            {
                float4 positionOS : POSITION;   // vertex position in object space
                float2 uv : TEXCOORD0;          // UV coordinates from the mesh
            };

            // Output FROM vertex shader, input TO fragment shader.
            // The GPU interpolates these values across the triangle
            // between vertices — this is how UVs smoothly vary per pixel.
            struct Varyings
            {
                float4 positionCS : SV_POSITION;  // clip space position (required)
                float2 uv : TEXCOORD0;            // pass UVs through to fragment
            };

            // Declare the texture and its sampler.
            // TEXTURE2D = the actual texture data on the GPU.
            // SAMPLER = how to read it (filtering, wrapping, etc).
            TEXTURE2D(_ColorTex);
            SAMPLER(sampler_ColorTex);

            // Vertex shader — runs once per vertex.
            // Takes mesh data in, outputs screen position + any data
            // the fragment shader needs.
            Varyings vert(Attributes input)
            {
                Varyings output;

                // Transform from object space → clip space.
                // Clip space is what the GPU needs to figure out where
                // on screen this vertex lands. This one function handles
                // the full chain: object → world → view → projection.
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                // Pass UVs straight through — no modification needed.
                output.uv = input.uv;

                return output;
            }

            // Fragment shader — runs once per pixel (technically per fragment).
            // Returns the final color for that pixel.
            half4 frag(Varyings input) : SV_Target
            {
                // Sample the color texture at the interpolated UV coordinate.
                // The GPU automatically picks the right mip level.
                half4 color = SAMPLE_TEXTURE2D(_ColorTex, sampler_ColorTex, input.uv);
                return color;
            }
            ENDHLSL
        }
    }
}