Shader "Unlit/UVRotate"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _EmissionTex("emissiontex",2D) = "white"{}
        _EmissionColor("emissioncolor",Color) = (1,1,1,1)
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

            TEXTURE2D(_EmissionTex);
            SAMPLER(sampler_EmissionTex);
            float4 _EmissionTex_ST;

            float4 _EmissionColor;

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
                float4 emissioncolor = SAMPLE_TEXTURE2D(_EmissionTex, sampler_EmissionTex, i.uv) * _EmissionColor;
                float4 finalcolor = float4(maintex.rgb + (emissioncolor.rgb * emissioncolor.a),maintex.a);
                return finalcolor;
            }
            ENDHLSL
        }
    }
}
