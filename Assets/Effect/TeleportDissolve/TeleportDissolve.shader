Shader "Unlit/TeleportDissolve"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _DissolveTex("dissolvetex",2D) = "white"{}
        //_DissolveFactor("dissolvefacotr",range(0,1)) = 1
        _HardnessFactor("hardnessfactor",range(0,1)) = 1
        _DissolveWidth("dissolvewidth",range(0,1)) = 0.5
        _WidthColor("widthcolor",Color) = (0.1,0.9,0.4,1)
        _DissolveVOffsetDir("dissolvevoffsetdir",float) = (1,1,1)
        _DissolveVOffsetStep("dissolvevoffsetstep",range(0,1)) = 0.5
        _DissolveVOffsetMin("dissolvevoffsetmin",range(-20,-0.01)) = -1
        _DissolveVoffsetMax("dissolvevoffsetmax",range(0.01,20)) = 1
        _TeleportSpeed("teleportspeed",range(0,10)) = 5
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
            float2 teleportuv:TEXCOORD1;
            float worldfac : TEXCOORD2;
        };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            TEXTURE2D(_DissolveTex);
            SAMPLER(sampler_DissolveTex);
            float4 _DissolveTex_ST;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            //float _DissolveFactor;
            float _HardnessFactor;
            float _DissolveWidth;
            float4 _WidthColor;
            float3 _DissolveVOffsetDir;
            float _DissolveVOffsetStep;
            float _DissolveVOffsetMin;
            float _DissolveVOffsetMax;
            float _TeleportSpeed;
            float4 _Time;

            v2f vert(appdata v)
            {
                v2f o;
                float4 vertexws = mul(unity_ObjectToWorld, v.vertex);
                o.worldfac = smoothstep(_DissolveVOffsetMin, _DissolveVOffsetMax, vertexws.y);
                vertexws.xyz = vertexws.xyz + _DissolveVOffsetDir.xyz * o.worldfac;
                o.vertex = mul(unity_MatrixVP, vertexws);
                o.uv = v.uv;
                o.teleportuv=v.uv * _DissolveTex_ST.xy + float2(0, _TeleportSpeed * _Time.y);
                return o;
            }

            float4 TeleportDissolveFunction(half4 c, half dissolveTex, half4 WidthColor, half worldFactor)
            {
                float hardness = clamp(_HardnessFactor, 0.00001, 0.999999);
                float dissolve = worldFactor * (1 + _DissolveWidth);
                float fac01 = lerp(2, hardness, dissolve);
                float dissolve01 = smoothstep(hardness + dissolveTex, 1 + dissolveTex, fac01);

                //溶解透明度
                float fac02 = lerp(2, hardness, dissolve-worldFactor*_DissolveWidth);
                float dissolve02 = smoothstep(hardness + dissolveTex, 1 + dissolveTex, fac02);
                c.rgb = lerp(WidthColor.rgb, c.rgb, dissolve01);
                c.a *= dissolve02;
                return c;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                float4 dissolvetex = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, i.teleportuv);
                return TeleportDissolveFunction(maintex, dissolvetex.x, _WidthColor, i.worldfac);
            }
            ENDHLSL
        }
    }
}
