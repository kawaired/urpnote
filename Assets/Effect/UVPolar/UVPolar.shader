Shader "Unlit/UVPolar"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _AngleScale("anglescale",range(0.1,10)) = 1
        _LengthScale("lengthscale",range(0.1,10)) = 1
        _MoveSpeed("movespeed",range(0,10)) = 1
        _RotateSpeed("rotatespeed",range(0,10)) = 1
        _SwitchRadius("switchradius",range(0.1,1))=0.5
        _DissolveStrength("dissolvestrength",range(0,1))=0.5
        _Hardness("hardness",range(0.01,0.99))=0.9
        _DissolveOffset("dissolveoffset",range(0,1))=0
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

            float _AngleScale;
            float _LengthScale;

            float4 _Time;

            float _MoveSpeed;
            float _SwitchRadius;
            float _RotateSpeed;
            float _DissolveStrength;
            float _Hardness;
            float _DissolveOffset;

            float2 UVPolar(float2 uv)
            {
                half2 uvpolar = uv - float2(0.5, 0.5);
                half distance = length(uvpolar) * 2;
                half angle = atan2(uvpolar.y, uvpolar.x);
                angle = angle / 3.1415927 * 0.5 + 0.5;
                return half2(angle,distance);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,mul(unity_ObjectToWorld,v.vertex));
                o.uv = v.uv;
                return o;
            }

            float4 DissolveFunction(float4 c, float dissolvefac,float dissolvestrength)
            {
                float dissolve = lerp(_Hardness, 2, dissolvestrength);
                dissolvefac = smoothstep(_Hardness + dissolvefac, 1 + dissolvefac, dissolve);
                c.a *= dissolvefac;
                return c;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 polaruv=UVPolar(i.uv);
                float dirfac = (polaruv.y > _SwitchRadius) - (polaruv.y <= _SwitchRadius);
                float dissolvestrength = 1 - saturate(abs(polaruv.y - _SwitchRadius)) - _DissolveOffset;
                polaruv.x = polaruv.x * _AngleScale + dirfac * _Time.y * _RotateSpeed;
                polaruv.y = polaruv.y * _LengthScale - dirfac * _MoveSpeed * _Time.y;
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, polaruv);
                float4 finalcolor = DissolveFunction(float4(1, 1, 1, 1), maintex.x, dissolvestrength);
                return finalcolor;
            }
            ENDHLSL
        }
    }
}
