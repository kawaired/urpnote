Shader "Unlit/Bloom"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
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
                float2 uv:TEXCOORED0;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_ScreebTex);
            SAMPLER(sampler_ScreebTex);
            float4 _ScreebTex_ST;

            float _ClipValue;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,mul(unity_ObjectToWorld,v.vertex));
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                float4 screentex = SAMPLE_TEXTURE2D(_ScreebTex, sampler_ScreebTex, i.uv);
                return maintex;
                //screentex.a = 1;
                //return float4(1, 1, 1, 1);
                return screentex+float4(0.2,0,0,0);
            }
            ENDHLSL
        }
    }
}
