Shader "Unlit/Dissolve"
{
    Properties
    {
        //_MainTex("maintex",2D) = "white"{}
        _DissolveTex("dissolvetex",2D) = "white"{}
        _DissolveFactor("dissolvefacotr",range(0,1)) = 1
        _HardnessFactor("hardnessfactor",range(0,1))=1
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

            TEXTURE2D(_DissolveTex);
            SAMPLER(sampler_DissolveTex);
            float4 _DissolveTex_ST;

            float _DissolveFactor;
            float _HardnessFactor;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,mul(unity_ObjectToWorld,v.vertex));
                o.uv = v.uv;
                return o;
            }

            float4 DissolveFunction(float4 c, float dissolvefac)
            {
                float hardness = clamp(_HardnessFactor, 0.00001, 0.999999);
                float dissolve = lerp(hardness,2, _DissolveFactor) ;
                dissolvefac = smoothstep(hardness + dissolvefac, 1 + dissolvefac, dissolve);
                c.a *= dissolvefac;
                return c;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 dissolvetex = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, i.uv);
                return DissolveFunction(float4(1,1,1,1), dissolvetex.x);
            }
            ENDHLSL
        }
    }
}
