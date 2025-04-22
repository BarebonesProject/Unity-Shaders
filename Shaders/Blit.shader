Shader "Barebone/Blit"
{
    Properties
    {
        _MainTex ("_MainTex", 2D) = "white" {}
        _DstTexture ("_DstTexture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
            Name "Blit"

            Cull Off
            Blend Off
            ZTest Off
            ZWrite Off

            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            sampler2D _DstTexture;
            
            struct Attributes
            {
                half3 positionOS : POSITION;
                half2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                half4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.uv = input.uv;

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float4 src = tex2D(_MainTex, input.uv);
                float4 dst = tex2D(_DstTexture, input.uv);

                return lerp(src, dst, 0.5);
            }
            ENDHLSL
        }
    }
}