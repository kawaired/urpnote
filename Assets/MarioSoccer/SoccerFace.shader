Shader "Unlit/SoccerFace"
{
    Properties
    {
        _MainTex ("maintex", 2D) = "white" {}
        _NormalTex("normaltex",2D) = "white"{}
        _MaskTex("masktex",2D)="white"{}
        _FeatherWidth("featherwidth",range(0.01,0.49))=0.05
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normalws:NORMAL;
                float3 tangentws:TANGENT;
                float3 birnormalws:TEXCOORD1;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4x4 unity_WorldToObject;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            float4 _NormalTex_ST;

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            float4 _MaskTex_ST;

            float3 _DirLightWay;

            float _FeatherWidth;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex));
                o.normalws = mul(transpose((float3x3)unity_WorldToObject), v.normal);
                o.tangentws = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz) * v.tangent.w;
                o.birnormalws = cross(o.normalws, o.tangentws);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float3 normaltex = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv).xyz * 2 - float3(1, 1, 1);
                float4 masktex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv);
                //return masktex.y;
                float3 cusnormal = i.tangentws * normaltex.x + i.birnormalws * normaltex.y + i.normalws * normaltex.z;
                float diffusefac = smoothstep(0.5 - _FeatherWidth, 0.5 + _FeatherWidth, (dot(_DirLightWay, cusnormal) + 1) * 0.5 * masktex.y);
                //return diffusefac;
                //return masktex.y;
                //return float4(cusnormal, 1);
                float4 diffusecolor = float4(lerp(0.6, 1.2, diffusefac) * maintex.xyz, 1);
                return diffusecolor;
            }
            ENDHLSL
        }
    }
}
