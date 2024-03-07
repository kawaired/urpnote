Shader "Unlit/BloomMask"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _ColorHold("colorhold",range(0,1))=0.5
        
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

            float _ColorHold;

            float4 CheckColor(float4 color)
            {
                float lightness = 0.2990 * color.x + 0.5870 * color.y + 0.1140 * color.z;
                return color * (lightness > _ColorHold);
            }

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
                //return maintex + float4(0.2, 0, 0, 0);
                float4 finalcolor = CheckColor(maintex);
                //finalcolor.a = 1;
                return finalcolor;
            }
            ENDHLSL
        }
    }
}
