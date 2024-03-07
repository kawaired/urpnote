Shader "Unlit/MarioToon"
{
    Properties
    {
        _MainTex("maintex", 2D) = "white" {}
        _NormalTex("normaltex",2D) = "white"{}
        _DissolveTex("dissolvetex",2D) = "white"{}
        _FeatherWidth("featherwidth",range(0.01,0.49)) = 0.05
        _Hardness("hardness",range(0.01,0.99)) = 0
    }
    SubShader
    {
        Pass
        {
            Cull off 
            //Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
            };
        
        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
            float3 normalws:NORMAL;
            float3 tangentws:TANGENT;
            float3 birnormalws:TEXCOORD1;
            float3 viewdir:TEXCOORD2;
            float4 clipvertex:TEXCOORD3;
            float2 disuv:TEXCOORD4;
        };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4x4 unity_WorldToObject;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            float4 _NormalTex_ST;

            TEXTURE2D(_DissolveTex);
            SAMPLER(sampler_DissolveTex);
            float4 _DissolveTex_ST;

            float3 _DirLightWay;
            float3 _DirLight2Way;
            float3 _CameraPos;
            float _FeatherWidth;
            float _Hardness;
            float4 _Time;


            v2f vert (appdata v)
            {
                v2f o;
                float4 vertexws = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(unity_MatrixVP, vertexws);
                o.clipvertex = o.vertex;
                o.normalws = mul(transpose((float3x3)unity_WorldToObject), v.normal);
                o.tangentws = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz) * v.tangent.w;
                o.birnormalws = cross(o.normalws, o.tangentws);
                o.viewdir = normalize(_CameraPos - vertexws.xyz);
                o.uv = v.uv;
                o.disuv = v.vertex.xy * 4 + float2(0, _Time.y);
                return o;
            }

            //float TrowbridgeReitzNormalDistribution(float NdotH, float roughness) {
            //    float roughnessSqr = roughness * roughness;
            //    float Distribution = NdotH * NdotH * (roughnessSqr - 1.0) + 1.0;
            //    return roughnessSqr / (3.1415926535 * Distribution * Distribution);
            //}

            //float4 Blur(SamplerState objsample, Texture2D objtex, float4 texelsize, int sampleR, float2 uv)
            //{
            //    int  samplecount = 0;
            //    sampleR = (sampleR > 0) * sampleR;
            //    float4 samplecolor = float4(0, 0, 0, 0);
            //    //return SAMPLE_TEXTURE2D(objtex, objsample, uv + float2(_Obj_ST.x, _Obj_ST.y ));
            //    for (int i = 0; i <= sampleR; i++)
            //    {
            //        for (int j = 0; j <= sampleR; j++)
            //        {
            //            samplecolor = samplecolor + SAMPLE_TEXTURE2D(objtex, objsample, uv + float2(i * texelsize.x, j * texelsize.y));
            //            samplecolor = samplecolor + SAMPLE_TEXTURE2D(objtex, objsample, uv - float2(i * texelsize.x, j * texelsize.y));
            //            samplecount = samplecount + 2;
            //        }
            //    }

            //    return samplecolor / samplecount;
            //}

            float Dissolve(float fac, float info)
            {
                float dissolve = fac + info - 1;
                return smoothstep(-_Hardness, _Hardness, dissolve);
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float3 normaltex = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv).xyz * 2 - float3(1, 1, 1);
                
                float3 cusnormal = i.tangentws * normaltex.x + i.birnormalws * normaltex.y + normalize(i.normalws) * normaltex.z;

                float lambert = dot(_DirLightWay, cusnormal);
             
                float lambert2 = dot(_DirLight2Way, cusnormal);
                
                float halflambert = (lambert + 1) * 0.5;
                float halflambert2 = (lambert2 + 1) * 0.5;

                float diffusefac = smoothstep(0.5 - _FeatherWidth, 0.5 + _FeatherWidth, halflambert);
                float diffusefac2 = smoothstep(0.5 - _FeatherWidth, 0.5 + _FeatherWidth, halflambert2);

                float2 dissolveuv = i.clipvertex.xy / i.clipvertex.w;
                float4 dissolvetex = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, i.disuv);
                return Dissolve(diffusefac2, dissolvetex.x);
                return diffusefac2;
                return dissolvetex;

                return diffusefac2;
            }
            ENDHLSL
        }
        //Pass
        //{
        //    Tags {"LightMode" = "MyDepth"}
        //    Cull front
        //    HLSLPROGRAM
        //    #pragma vertex vert
        //    #pragma fragment frag

        //    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

        //    struct appdata
        //    {
        //        float4 vertex : POSITION;
        //    };

        //    struct v2f
        //    {
        //        float4 vertex : SV_POSITION;
        //        float depth : TEXCOORD1;
        //    };

        //    float4x4 unity_MatrixVP;
        //    float4x4 unity_ObjectToWorld;

        //    v2f vert(appdata v)
        //    {
        //        v2f o;
        //        o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex));
        //        o.depth = o.vertex.z / o.vertex.w;
        //        return o;
        //    }

        //    float4 frag(v2f i) : SV_Target
        //    {
        //        return float4(i.depth,0,0,1);
        //    }
        //    ENDHLSL
        //}
    }
}
