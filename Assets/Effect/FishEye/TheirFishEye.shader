Shader "Unlit/Flash"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _FishEyeParamX("fisheyeparamx",range(-1,1))=0
        _FishEyeParamY("fisheyeparamy",range(-1,1))=0
    }
    SubShader
    {
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv:TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv:TEXCOORD0;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            float _FishEyeParamX;
            float _FishEyeParamY;


            float2 FishEye(float4 vertex)
            {
                float2 v = vertex.xy / vertex.w;
                float2 r_uv;
                r_uv.x = saturate(1 - v.y * v.y) * _FishEyeParamX * (v.x);
                r_uv.y = saturate(1 - v.x * v.x) * _FishEyeParamY * (v.y);
                v.xy = v.xy + r_uv;
                return v.xy * vertex.w;
            }

            v2f vert(appdata v)
            {
                v2f o;
                float4 veretexws = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(unity_MatrixVP, veretexws);
                o.vertex.xy = FishEye(o.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                return maintex;
            }
            ENDHLSL
        }
    }
}
