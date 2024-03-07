Shader "Unlit/UVRotate"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _RotateAngle("rotateangle",range(0,359))=0
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

            float _RotateAngle;

            float2 UVRotate(float2 uv, float angle)
            {
                angle *= (PI * 2) / 360;
                float2 pivot = float2(0.5, 0.5);
                float cosAngle = cos(angle);
                float sinAngle = sin(angle);
                float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
                float2 rotateUV = uv - pivot;
                rotateUV = mul(rot, rotateUV);
                rotateUV += pivot;
                return rotateUV;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,mul(unity_ObjectToWorld,v.vertex));
                o.uv = UVRotate(v.uv, _RotateAngle);
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
