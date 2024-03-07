Shader "Unlit/BowserArm"
{
    Properties
    {
        _MainTex ("maintex", 2D) = "white" {}
        _NormalTex("normaltex",2D) = "white"{}
        _MaskTex("masktex",2D)="white"{}
        _SpecularScale("specular",range(0,2))=1
        _FeatherWidth("featherwidth",range(0.01,0.49))=0.05
        _Emission("emissioncolor",Color)=(1,1,1,1)
        _EmissionStrength("emissionstrength",range(0,3))=2  
        _ShadowBias("shadowbias",range(-0.02,0.02))=0
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
                float3 halfdir:TEXCOORD2;
                float4 shadowcoord1:TEXCOORD3;
                float4 shadowcoord2:TEXCOORD4;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4x4 unity_WorldToObject;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            float4 _NormalTex_ST;;

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            float4 _MaskTex_ST;

            TEXTURE2D(_Depth1Tex);
            SAMPLER(sampler_Depth1Tex);
            float4 _Depth1Tex_TexelSize;

            TEXTURE2D(_Depth2Tex);
            SAMPLER(sampler_Depth2Tex);
            float4 _Depth2Tex_TexelSize;

            float3 _DirLightWay;
            float3 _DirLight2Way;
            float3 _CameraPos;
            float _FeatherWidth;
            float _SpecularScale;
            float _EmissionStrength;
            float4 _Emission;
            float _ShadowBias;

            float4x4 _Shadow1Matrix;
            float4x4 _Shadow2Matrix;

            v2f vert (appdata v)
            {
                v2f o;
                float4 vertexws = mul(unity_ObjectToWorld, v.vertex);
                o.shadowcoord1 = mul(_Shadow1Matrix, vertexws);
                o.shadowcoord2 = mul(_Shadow2Matrix, vertexws);
                o.vertex = mul(unity_MatrixVP, vertexws);
                o.normalws = mul(transpose((float3x3)unity_WorldToObject), v.normal);
                o.tangentws = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz) * v.tangent.w;
                o.birnormalws = cross(o.normalws, o.tangentws);
                float3 viewdir = normalize(_CameraPos - vertexws.xyz);
                //o.halfdir = normalize(viewdir);
                o.halfdir = normalize(viewdir +  normalize(_DirLightWay));
                o.uv = v.uv;
                return o;
            }

            float TrowbridgeReitzNormalDistribution(float NdotH, float roughness) {
                float roughnessSqr = roughness * roughness;
                float Distribution = NdotH * NdotH * (roughnessSqr - 1.0) + 1.0;
                return roughnessSqr / (3.1415926535 * Distribution * Distribution);
            }

            float4 Blur(SamplerState objsample, Texture2D objtex, float4 texelsize, int sampleR, float2 uv)
            {
                int  samplecount = 0;
                sampleR = (sampleR > 0) * sampleR;
                float4 samplecolor = float4(0, 0, 0, 0);
                //return SAMPLE_TEXTURE2D(objtex, objsample, uv + float2(_Obj_ST.x, _Obj_ST.y ));
                for (int i = 0; i <= sampleR; i++)
                {
                    for (int j = 0; j <= sampleR; j++)
                    {
                        samplecolor = samplecolor + SAMPLE_TEXTURE2D(objtex, objsample, uv + float2(i * texelsize.x, j * texelsize.y));
                        samplecolor = samplecolor + SAMPLE_TEXTURE2D(objtex, objsample, uv - float2(i * texelsize.x, j * texelsize.y));
                        samplecount = samplecount + 2;
                    }
                }

                return samplecolor / samplecount;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 shadowuv1 = i.shadowcoord1.xy / i.shadowcoord1.w;
                float2 shadowuv2 = i.shadowcoord2.xy / i.shadowcoord2.w;
                shadowuv1 = shadowuv1 * 0.5 + 0.5;
                shadowuv2 = shadowuv2 * 0.5 + 0.5;

                float4 maintex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float3 normaltex = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv).xyz * 2 - float3(1, 1, 1);
                float4 masktex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv);

                //float4 depth1tex = SAMPLE_TEXTURE2D(_Depth1Tex, sampler_Depth1Tex, shadowuv1);
                //float4 depth2tex = SAMPLE_TEXTURE2D(_Depth2Tex, sampler_Depth2Tex, shadowuv2);
                
                float4 depth1tex = Blur(sampler_Depth1Tex, _Depth1Tex, _Depth1Tex_TexelSize, 3, shadowuv1);
                float4 depth2tex = Blur(sampler_Depth2Tex, _Depth2Tex, _Depth2Tex_TexelSize, 3, shadowuv2);
                float depth1 = i.shadowcoord1.z / i.shadowcoord1.w;
                float depth2 = i.shadowcoord2.z / i.shadowcoord2.w;

                float3 cusnormal = i.tangentws * normaltex.x + i.birnormalws * normaltex.y + normalize(i.normalws) * normaltex.z;

                float lambert = dot(_DirLightWay, cusnormal);
                //return lambert;
                //lambert = (lambert<0.1)*(lambert)-((lambert >= 0.1) * ((depth1 + _ShadowBias) < (depth1tex.x)));
                float shadowfac1 = (depth1 + _ShadowBias) > depth1tex.x;
                //return shadowfac1;
                //return lambert;
                float lambert2 = dot(_DirLight2Way, cusnormal);
                float shadowfac2 = (depth2 + _ShadowBias) > depth2tex.x;;
                //lambert2 = lambert2 * (1 - (lambert2 > 0) * ((depth2 + _ShadowBias) < (depth2tex.x)));
                //return lambert2;
                float halflambert = (lambert + 1) * 0.5;
                //return halflambert;
                //return lambert;
                float halflambert2 = (lambert2 + 1) * 0.5;
                //halflambert = halflambert * (1 - (lambert >= -0.1) * ((depth1 + _ShadowBias) < (depth1tex.x)));
                //return halflambert;
                //halflambert2 = halflambert2 * (1 - (lambert2 > -0) * ((depth2 + _ShadowBias) < (depth2tex.x)));
                float diffusefac = smoothstep(0.5 - _FeatherWidth, 0.5 + _FeatherWidth, halflambert * masktex.y);
                //return diffusefac;
                diffusefac = diffusefac  * shadowfac1;
                float diffusefac2 = smoothstep(0.5 - _FeatherWidth, 0.5 + _FeatherWidth, halflambert2 * masktex.y);
                diffusefac2 = diffusefac2 * shadowfac2;
                float4 diffusecolor = float4(lerp(0.8,1.1,diffusefac)*lerp(0.8, 1.2, diffusefac2) * maintex.xyz, 1);
                float ndoth = saturate(dot(cusnormal, normalize(i.halfdir)));
                float specularfac = TrowbridgeReitzNormalDistribution(ndoth, masktex.w);
                float4 specularcolor = specularfac * maintex * _SpecularScale ;

                float4 emissioncolor = masktex.z * float4(0,0.4,1,1) * 3;
                emissioncolor.w = 1;
                float4 finalcolor = max(diffusecolor * (1 - masktex.x), specularcolor) + emissioncolor;
                finalcolor.a = 1;
                return finalcolor;
            }
            ENDHLSL
        }
        Pass
        {
            Tags {"LightMode" = "MyDepth"}
            Cull front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float depth : TEXCOORD1;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex));
                o.depth = o.vertex.z / o.vertex.w;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return float4(i.depth,0,0,1);
            }
            ENDHLSL
        }
    }
}
