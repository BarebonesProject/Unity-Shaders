Shader "Barebone/GBuffer - BRDF"
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
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float2 texcoord1     : TEXCOORD1;
                float2 texcoord2     : TEXCOORD2;
                float2 texcoord3     : TEXCOORD3;
                float2 staticLightmapUV   : TEXCOORD4;
                float2 dynamicLightmapUV  : TEXCOORD5;
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                float2 uv1                      : TEXCOORD9;
                float2 uv2                      : TEXCOORD10;
                float2 uv3                      : TEXCOORD11;

                float3 positionWS               : TEXCOORD1;

                half3 normalWS                  : TEXCOORD2;
                float4 shadowCoord              : TEXCOORD5;

                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 7);
                float2 dynamicLightmapUV        : TEXCOORD8; // Dynamic lightmap UVs
                float4 positionCS               : SV_POSITION;
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                output.uv = input.texcoord;
                output.uv1 = input.texcoord1;
                output.uv2 = input.texcoord2;
                output.uv3 = input.texcoord3;

                output.normalWS = normalInput.normalWS;
                output.positionWS = vertexInput.positionWS;
                
                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                
                output.shadowCoord = GetShadowCoord(vertexInput);

                output.positionCS = vertexInput.positionCS;
                
                return output;
            }

            FragmentOutput frag(Varyings input) : SV_Target
            {
                //////////////// Colors computation ////////////////
                half3 albedo = half3(0, 1, 0);
                half3 emission = half3(1, 0, 0);

                half smoothness = 0.0;
                half occlusion = 0.0;
                half metallic = 0.0;
                half3 specular = half3(0, 0, 0);
                half alpha = 1.0;

                //////////////// BRDF parameters ////////////////
                float3 positionWS = input.positionWS;
            
                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS);
                half3 normalWS = NormalizeNormalPerPixel(input.normalWS);
            
                //float4 shadowCoord = input.shadowCoord;
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                //float4 shadowCoord = float4(0, 0, 0, 0);
            
                //half3 bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, normalWS);
                half3 bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, normalWS);
            
                half2 normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                half4 shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

                //////////////// BRDF ////////////////
                BRDFData brdfData;
                InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

                Light mainLight = GetMainLight(shadowCoord, positionWS, shadowMask);
                MixRealtimeAndBakedGI(mainLight, normalWS, bakedGI, shadowMask);
                half3 color = GlobalIllumination(brdfData, bakedGI, occlusion, positionWS, normalWS, viewDirWS);

                InputData inputData = (InputData)0;
                inputData.normalWS = normalWS;
                inputData.positionCS = input.positionCS;
                inputData.shadowMask = shadowMask;

                return BRDFDataToGbuffer(brdfData, inputData, smoothness, emission + color, occlusion);
            }
            ENDHLSL
        }
    }
}