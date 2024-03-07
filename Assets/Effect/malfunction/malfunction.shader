Shader "Unlit/malfunction"
{
    Properties
    {        _MainTex("maintex",2D) = "white"{}
        _BaseColor("basecolor",Color) = (1,1,1,1)

        _StreakCount("streakcount",float)=50
        _Amplitude("amplitude",range(0,0.02))=0
        _WaveFrequency("wavefrequency",float)=50

        _AppearTime("appeartime",range(0,10)) = 0
        _DisappearTime("disappeartime",range(0,10)) = 0
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

            float4 _BaseColor;

            float _StreakCount;

            float _Amplitude;
            float _WaveFrequency;

            float4 _Time;

            float _AppearTime;
            float _DisappearTime;
            

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,mul(unity_ObjectToWorld,v.vertex));
                o.uv = v.uv;
                return o;
            }

            float Random1DTo1D(float value) {
                float random = frac(sin(value + 0.546) * 10000);
                return random;
            }

            float4 MalFunction(float2 uv, float4 maintex, float4 _Color)
            {
                float streakfac= Random1DTo1D(floor(uv.y * _StreakCount));//根据uv的y轴分块取随机数
                float Hoffsetfac = sin(_Time.y * _WaveFrequency) * _Amplitude;
                float2 uvoffset = float2(Hoffsetfac * streakfac, 0);
                float4 malR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + uvoffset);
                float4 malB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv - uvoffset);
                float4 malcolor = float4(malR.x, maintex.y, malB.z, 1) * _BaseColor;

                float timesum = _AppearTime + _DisappearTime;
                float reciprocaltime = 1 / timesum;
                float timeval = 1;
                timeval = step(_AppearTime * reciprocaltime, frac(_Time.y * reciprocaltime));
                return lerp(malcolor, maintex, timeval);
                return malcolor;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                float4 finalcolor = MalFunction(i.uv, maintex, _BaseColor);
                return finalcolor;
               //return float4(0.1,0.04,0.02,1);
            }
            ENDHLSL
        }
    }
}
