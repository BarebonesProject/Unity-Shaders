Shader "Barebone/Forward - simple"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 10
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Op", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend [_SrcBlend] [_DstBlend]
            BlendOp [_BlendOp]
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #define _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
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
                half3 positionOS : TEXCOORD2;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.normalWS = normalize(mul(input.normalOS.xyz, (float3x3)unity_WorldToObject));
                output.positionOS = input.positionOS;
                output.uv = input.uv;

                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                half4 color = half4(1, 1, 1, 1);
                float smoothness = 0;
                
                //////////////// Lights computation ////////////////
                float3 positionWS = mul(unity_ObjectToWorld, input.positionOS);
                
                const half4 shadowmask = half4(1, 1, 1, 1);
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                
                Light mainLight = GetMainLight(shadowCoord, positionWS, shadowmask);
                half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
                half3 diffuseColor = attenuatedLightColor;

                uint pixelLightCount = GetAdditionalLightsCount();
                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light light = GetAdditionalLight(lightIndex, positionWS, shadowmask);
                    {
                        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
                        diffuseColor += attenuatedLightColor;
                    }
                LIGHT_LOOP_END

                color.rgb = diffuseColor * color.rgb;

                return half4(color.rgb * color.a, color.a);
            }
            ENDHLSL
        }
    }
}