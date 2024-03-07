Shader "Unlit/MarioRoom"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _MaskTex("masktex",2D) = "white"{}
        _Metallic("metallic",range(0,1))=0.5
        _Roughness("roughtness",range(0,1))=0.5
        _FeatherWidth("FeatherWidth",range(0.01,0.49))=0.1
    }
    SubShader
    {
        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv:TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv:TEXCOORED0;
                float3 normalws:NORMAL;
                float3 halfdir:TEXCOORD1;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4x4 unity_WorldToObject;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            float4 _MaskTex_ST;

            float3 _DirLightWay;
            float3 _CameraPos;
            float _Metallic;
            float _Roughness;
            float _FeatherWidth;

            v2f vert(appdata v)
            {
                v2f o;
                float4 vertexws = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(unity_MatrixVP, vertexws);
                float3 viewdir = normalize(_CameraPos - vertexws.xyz);
                o.normalws = mul(transpose((float3x3)unity_WorldToObject), v.normal);
                o.halfdir = normalize(viewdir + normalize(_DirLightWay));
                o.uv = v.uv;
                return o;
            }

            float TrowbridgeReitzNormalDistribution(float NdotH, float roughness) {
                float roughnessSqr = roughness * roughness;
                float Distribution = NdotH * NdotH * (roughnessSqr - 1.0) + 1.0;
                return roughnessSqr / (3.1415926535 * Distribution * Distribution);
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                float4 masktex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv);
                float ndoth = dot(normalize(i.normalws), normalize(i.halfdir));
                
                //float4 maincolor = maintex * masktex.x;

                float shadowfac = smoothstep(0.5 - _FeatherWidth, 0.5 + _FeatherWidth, dot(normalize(i.normalws), _DirLightWay) * masktex.x);
                float4 maincolor = lerp(0.6, 1, shadowfac) * maintex;
                //return maincolor;
                float specularfac = TrowbridgeReitzNormalDistribution(ndoth, _Roughness);
                float4 diffusecolor = maincolor * (1 - _Metallic);
                //float4 diffusecolor = maincolor * (1 - masktex.y);
                float4 specularcolor = lerp(maincolor, specularfac * maincolor, _Metallic * 0.5);
                return specularcolor;
                return float4(i.normalws,1);
                //return diffusecolor;
                //return masktex.x;
                return specularcolor * masktex.y*2.2;
                //return diffusecolor + specularcolor;

                //return masktex.x;
                //return maintex * masktex.x;
            }
            ENDHLSL
        }
    }
}
