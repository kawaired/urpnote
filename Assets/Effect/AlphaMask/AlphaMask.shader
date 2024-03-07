Shader "Unlit/AlphaMask"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _MaskTex("masktex",2D) = "white"{}
        _MaskTexAlpha("masktexalpha",range(0,1))=0.5
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

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            float4 _MaskTex_ST;

            float _MaskTexAlpha;

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
                float4 masktex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv);
                float maskchannel = lerp(masktex.a, masktex.r, _MaskTexAlpha);
                maintex.a = maintex.a * maskchannel;
                return maintex;
            }
            ENDHLSL
        }
    }
}
