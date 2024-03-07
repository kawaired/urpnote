Shader "Unlit/UVScale"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _UVScale("uvscale",range(0.1,10))=1
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

            float _UVScale;

            float2 UVScale(float2 UV, float UVScale)
            {
                float2 UVScaleWrap = (UV - 0.5) * UVScale + 0.5;
                return UVScaleWrap;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,mul(unity_ObjectToWorld,v.vertex));
                o.uv = UVScale(v.uv, _UVScale);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
               
                return maintex;
               //return float4(0.1,0.04,0.02,1);
            }
            ENDHLSL
        }
    }
}
