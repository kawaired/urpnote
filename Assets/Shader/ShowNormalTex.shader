Shader "Unlit/ShowNormalTex"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1:TEXCOORD1; 
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex));
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 normaltex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv)*2-float4(1,1,1,1);
                normaltex = normaltex ;
                normaltex.a = 1;
                return normaltex;
            }
            ENDHLSL
        }
    }
}
