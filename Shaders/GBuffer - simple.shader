Shader "Barebone/GBuffer - simple"
{
    Properties
    {
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }
        
        Pass
        {
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

            struct Attributes
            {
                half3 positionOS : POSITION;
                half3 normalOS : NORMAL;
                half2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                half4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
                half3 normalWS : TEXCOORD1;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.normalWS = normalize(mul(input.normalOS.xyz, (float3x3)unity_WorldToObject));
                output.uv = input.uv;
                
                return output;
            }

            FragmentOutput frag(Varyings input) : SV_Target
            {
                half3 emission = half3(1, 0, 0);

                FragmentOutput output = (FragmentOutput)0; // https://docs.unity3d.com/6000.0/Documentation/Manual/urp/rendering/g-buffer-layout.html
                output.GBuffer0 = half4(0, 0, 0, 0); // Albedo sRGB (3) + MaterialFlags bits [SpecularSetup, SubtractiveMixedLighting, SpecularHighlightsOff, ReceiveShadowsOff] (1)
                output.GBuffer1 = half4(0, 0, 0, 0); // Specular (3) + Occlusion (1)
                output.GBuffer2 = half4(input.normalWS, 0); // normal (3) + smoothness (1)
                output.GBuffer3 = half4(emission, 1); // emission (4)

                return output;
            }
            ENDHLSL
        }
    }
}