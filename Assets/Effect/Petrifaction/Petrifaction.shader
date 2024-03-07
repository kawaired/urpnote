Shader "Unlit/Petrifaction"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _NormalTex("normaltex",2D) = "white"{}
        _CusLightDir("cuslightdir",float)=(0.2,0.2,0.2)
        _ShadowContrast("shadowcontrast",range(-1,1))=0
        _ShadowColor("shadowcolor",Color)=(0.1,0.1,0.1,1)
        _Tint("tint",Color)=(0.4,0.5,1,1)
        _StatueDegree("statuedegree",range(0,5))=0.5
        _Brightness("brightness",range(1,5))=1.2


        _StoneColor("stonecolor",Color)=(1,1,1,1)
        _StoneStrangth("stonestrangth",range(0,1))=0
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
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv:TEXCOORED0;
                float3 normalws:NORMAL;
                float3 tangentws:TANGENT;
                float3 birnormal:TEXCOORD1;
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

            TEXTURE2D(_StatueTex);
            SAMPLER(sampler_StatueTex);
            float4 _StatueTex_ST;

            float4 _StoneColor;
            float _StoneStrangth;

            float3 _DirLightWay;
            float _ShadowContrast;
            float4 _ShadowColor;
            float4 _Tint;
            float _StatueDegree;
            float _Brightness;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP,mul(unity_ObjectToWorld,v.vertex));
                o.normalws= mul(transpose((float3x3)unity_WorldToObject), v.normal);
                o.tangentws = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz)*v.tangent.w;
                o.birnormal = cross(o.normalws, o.tangentws);
                o.uv = v.uv;
                return o;
            }

            //float4 Petrifaction(float4 col,float3 onormal, float3 cusnormal)
            //{
            //    float3 worldlightdir = -normalize(_DirLightWay);
            //    float ndotl = dot(onormal,worldlightdir);
            //    float w = fwidth(ndotl);
            //    float shadowcontrast = smoothstep(-w, w, ndotl - _ShadowContrast);
            //    float halflambert = saturate(dot(cusnormal, worldlightdir))*0.5+0.5;
            //    float4 colstatue = lerp(_ShadowColor * halflambert, col * halflambert, shadowcontrast);
            //    //float4 colstatue = _ShadowColor * halflambert;
            //    col.rgb *= lerp(half3(1, 1, 1), colstatue.xyz, _StatueDegree) * lerp(1, _Brightness, _StatueDegree);
            //    return col * _Tint;

            //}
            //float4 Petrifaction(float4 col, float3 cusnormal)
            //{
            //    float3 worldlightdir = -normalize(_DirLightWay);
            //    float halflambert = saturate(dot(cusnormal, worldlightdir)) * 0.5 + 0.5;
            //    float4 colstatue = _ShadowColor * halflambert;
            //    col.rgb *= lerp(half3(1, 1, 1), colstatue.xyz, _StatueDegree) * lerp(1, _Brightness, _StatueDegree);
            //    return col * _Tint;
            //}


            float4 frag(v2f i) : SV_Target
            {
                float3 normaltex = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv).xyz*2-float3(1,1,1);
                float3 cusnormal = normalize(i.tangentws * normaltex.x + i.birnormal * normaltex.y + i.normalws * normaltex.z);
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                float3 realnormal = lerp(i.normalws, cusnormal, _StoneStrangth);
                float ndotl = dot(realnormal, normalize(_DirLightWay));
                float shadowfac = smoothstep(-0.02, 0.02, ndotl);
                float4 finalcolor = lerp(maintex, _StoneColor, _StoneStrangth) * lerp(0.5, 1, shadowfac);
                return finalcolor;
            }
            ENDHLSL
        }
    }
}
