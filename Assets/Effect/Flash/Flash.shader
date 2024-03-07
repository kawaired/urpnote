Shader "Unlit/Flash"
{
    Properties
    {
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
                float2 uv:TEXCOORD0;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            float _AppearTime;
            float _DisappearTime;

            float4 _Time;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,mul(unity_ObjectToWorld,v.vertex));
                o.uv = v.uv;
                return o;
            }

            float FlashAlpha()
            {
                float timesum = _AppearTime + _DisappearTime;
                float reciprocaltime = 1 / timesum;
                float timeval = 1;
                timeval = step(_DisappearTime * reciprocaltime, frac(_Time.y * reciprocaltime));
                return timeval;
            }


            float4 frag(v2f i) : SV_Target
            {
                float4 color=float4(1,1,1,1);
                color.a = FlashAlpha();
                return color;
            }
            ENDHLSL
        }
    }
}
