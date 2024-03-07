Shader "Unlit/UVNoise"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _NoiseTex("noisetex",2D) = "white"{}
        _NoiseIntensity("noiseintensity",range(0,1)) = 0
        _WaveSpeed("wavespeed",range(0,10)) = 0
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
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv:TEXCOORED0;
                float2 noiseuv:TEXCOORD1;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);
            float4 _NoiseTex_ST;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            float _NoiseIntensity;
            float _WaveSpeed;
            float4 _Time;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,mul(unity_ObjectToWorld,v.vertex));
                o.uv = v.uv;
                o.noiseuv = v.uv + float2(0, _WaveSpeed * _Time.y);
                
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 noiseTex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.noiseuv);
                noiseTex = (noiseTex * 2 - 1) * _NoiseIntensity;
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy+ noiseTex.xx);
                return maintex;
            }
            ENDHLSL
        }
    }
}
