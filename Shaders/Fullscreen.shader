Shader "Barebone/Fullscreen"
{
    Properties
    {
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
            Name "Fullscreen"

            Cull Off
            Blend Off
            ZTest Off
            ZWrite Off

            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #pragma vertex Vert
            #pragma fragment frag

            float4 SampleBuffer_BlitSource(float2 uv)
            {
                uint2 pixelCoords = uint2(uv * _ScreenSize.xy);
                return LOAD_TEXTURE2D_X_LOD(_BlitTexture, pixelCoords, 0);
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float3 color = SampleBuffer_BlitSource(input.texcoord).rgb;

                return float4(color.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}