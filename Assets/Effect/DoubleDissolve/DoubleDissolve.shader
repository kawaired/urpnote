Shader "Unlit/DoubleDissolve"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _DissolveTex("dissolvetex",2D) = "white"{}
        _DissolveFactor("dissolvefacotr",range(0,1)) = 1
        _HardnessFactor("hardnessfactor",range(0,1))=1
        _DissolveWidth("dissolvewidth",range(0,1))=0.5
        _TransitionColor("transitioncolor",Color)=(1,1,1,1)
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

            TEXTURE2D(_DissolveTex);
            SAMPLER(sampler_DissolveTex);
            float4 _DissolveTex_ST;

            float _DissolveFactor;
            float _HardnessFactor;
            float _DissolveWidth;

            float4 _TransitionColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,mul(unity_ObjectToWorld,v.vertex));
                o.uv = v.uv;
                return o;
            }

            float4 DoubleDissolveFunction(float4 c, float dissolveTex, float4 WidthColor)
            {
                float hardness = clamp(_HardnessFactor, 0.00001, 0.999999);
                float dissolve = _DissolveFactor * (1 + _DissolveWidth);

                float fac01 = lerp(2, hardness, dissolve);
                float dissolve01 = smoothstep(hardness + dissolveTex, 1 + dissolveTex, fac01);

                float fac02 = lerp(2, hardness, dissolve - _DissolveWidth);
                float dissolve02 = smoothstep(hardness + dissolveTex, 1 + dissolveTex, fac02);

                c.rgb = lerp(WidthColor.rgb, c.rgb, dissolve01);
                c.a *= dissolve02;
                return c;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                //return maintex;
                float4 dissolvetex = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, i.uv);
                return DoubleDissolveFunction(maintex, dissolvetex.x, _TransitionColor);
            }
            ENDHLSL
        }
    }
}
