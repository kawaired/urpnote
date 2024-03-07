Shader "Unlit/MarioPlatform"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _MaskTex("masktex",2D) = "white"{}
        _Metallic("metallic",range(0,1)) = 0.5
        _Roughness("roughtness",range(0,1)) = 0.5
        _FeatherWidth("FeatherWidth",range(0.01,0.49)) = 0.1
        _Lightness("lightness",range(0,5)) = 1
        _ShadowBias("shadowbias",range(-0.01,0.01)) = 0
        _ColorTone("colortone",Color) = (1,1,1,1)
        _DifferFac("differfac",range(0,1)) = 0
    }
    SubShader
    {
        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv:TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv:TEXCOORED0;
                float3 normalws:NORMAL;
                float3 halfdir:TEXCOORD1;
                float4 shadow1coord:TEXCOORD2;
                float4 shadow2coord:TEXCOORD3;
                float3 viewdir:TEXCOORD4;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4x4 unity_WorldToObject;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

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
            float3 _CameraPos;
            float _Metallic;
            float _Roughness;
            float _FeatherWidth;
            float _Lightness;
            float4x4 _Shadow1Matrix;
            float4x4 _Shadow2Matrix;
            float _ShadowBias;
            float4 _ColorTone;
            float _DifferFac;


            v2f vert(appdata v)
            {
                v2f o;
                float4 vertexws = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(unity_MatrixVP, vertexws);
                o.shadow1coord = mul(_Shadow1Matrix, vertexws);
                o.shadow2coord = mul(_Shadow2Matrix, vertexws);
                o.viewdir = normalize(_CameraPos - vertexws.xyz);
                o.normalws = mul(transpose((float3x3)unity_WorldToObject), v.normal);
                o.halfdir = normalize(o.viewdir + normalize(_DirLightWay));
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
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                float4 masktex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv);
                //return maintex;
                float2 shadow1uv = i.shadow1coord.xy / i.shadow1coord.w;
                float2 shadow2uv = i.shadow2coord.xy / i.shadow2coord.w;
                shadow1uv = shadow1uv * 0.5 + 0.5;
                shadow2uv = shadow2uv * 0.5 + 0.5;
                float4 shadow1tex = SAMPLE_TEXTURE2D(_Depth1Tex, sampler_Depth1Tex, shadow1uv);
                float4 shadow2tex = SAMPLE_TEXTURE2D(_Depth2Tex, sampler_Depth2Tex, shadow2uv);
                //return (masktex.y>0.51);
                //return shadow2tex.x;
                //float4 shadowtex = Blur(sampler_Depth1Tex, _Depth1Tex, _Depth1Tex_TexelSize, 1, shadowuv);
                //return shadow1tex;
                //return shadow1tex;
                float depth1 = i.shadow1coord.z / i.shadow1coord.w;
                float depth2 = i.shadow2coord.z / i.shadow2coord.w;
                //return (depth1 + _ShadowBias) < shadow1tex.x;
                float shadowfac1 = 1 - (0.3 * ((depth1 + _ShadowBias) < shadow1tex.x));
                float shadowfac2 = 1 - (0.1 * ((depth2 + _ShadowBias) < shadow2tex.x));
                //return (depth2 + _ShadowBias) > shadow2tex.x;
                //return shadowtex;

                float ndoth = dot(normalize(i.normalws), normalize(i.halfdir));
                //float ndotv = saturate(dot(normalize(i.normalws), normalize(i.viewdir))-0.8);
               
                float lambert = dot(normalize(i.normalws), _DirLightWay);
                float lambertfac = lambert * masktex.x;
                float shadowfac = smoothstep(0.5 - _FeatherWidth, 0.5 + _FeatherWidth, lambertfac);
                float4 diffusecolor = lerp(0.3, 1, shadowfac) * maintex;
                //return diffusecolor;
    
                float specularfac = TrowbridgeReitzNormalDistribution(ndoth, _Roughness);
                //float specularfac = pow(ndotv, 10)*10;
                float4 specularcolor = lerp(diffusecolor, specularfac * diffusecolor, _Metallic * 0.5);
                //return masktex.y;
                //return specularcolor;
                float maskfac = masktex.y * (masktex.y < 0.52) + masktex.y * (masktex.y >= 0.52) * (1 + _DifferFac);
                //return maskfac;

                diffusecolor = diffusecolor * (1 - _Metallic);
                return (diffusecolor + specularcolor ) * maskfac * _Lightness * shadowfac1 * shadowfac2 * _ColorTone;

                //return masktex.x;
                //return maintex * masktex.x;
            }
            ENDHLSL
        }
    }
}
