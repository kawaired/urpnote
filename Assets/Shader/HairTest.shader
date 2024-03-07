Shader "Unlit/HairTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FurNormalTex("furnormaltex",2D) = "white"{}
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
                //float2 uv1:TEXCOORD1; 
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 fur:TEXCOORD1;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4x4 unity_WorldToObject;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_FurNormalTex);
            SAMPLER(sampler_FurNormalTex);
            float4 _FurNormalTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                float4 vertexws = mul(unity_ObjectToWorld, v.vertex);
                
                float3 normalws = mul(transpose((float3x3)unity_WorldToObject), v.normal);
                float3 tangentws = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz) * v.tangent.w;
                float3 birnormalws = cross(normalws, tangentws);
                o.uv = v.uv;
                float2 furuv = v.uv * _FurNormalTex_ST.xy + _FurNormalTex_ST.zw;
                float4 furnormaltex = SAMPLE_TEXTURE2D_LOD(_FurNormalTex, sampler_FurNormalTex, furuv, 0) * 2 - float4(1, 1, 1,1);
                float3 furnormal = tangentws * furnormaltex.x + birnormalws * furnormaltex.y + normalws * furnormaltex.z;
                o.vertex = mul(unity_MatrixVP, vertexws);
                o.fur = furnormal;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return i.fur.xyzz;
                return SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
            }
            ENDHLSL
        }
    }
}
