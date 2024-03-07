Shader "Unlit/ToStone"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _NormalTex("normaltex",2D) = "white"{}
        _DissolveTex("dissolvetex",2D) = "white"{}
        _HardnessFactor("hardnessfactor",range(0,1)) = 1
        _DissolveWidth("dissolvewidth",range(0,1)) = 0.5
        _TransitionColor("transitioncolor",Color) = (1,1,1,1)
        _StoneColor("stonecolor",Color) = (1,1,1,1)
        _StoneStrangth("stonestrangth",range(0,1)) = 0
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

                TEXTURE2D(_DissolveTex);
                SAMPLER(sampler_DissolveTex);
                float4 _DissolveTex_ST;

                float4 _StoneColor;
                float _StoneStrangth;
                float _HardnessFactor;
                float _DissolveWidth;
                float4 _TransitionColor;

                float3 _DirLightWay;
   

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = mul(unity_MatrixVP,mul(unity_ObjectToWorld,v.vertex));
                    o.normalws = mul(transpose((float3x3)unity_WorldToObject), v.normal);
                    o.tangentws = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz) * v.tangent.w;
                    o.birnormal = cross(o.normalws, o.tangentws);
                    o.uv = v.uv;
                    return o;
                }

                float4 StoneFunction(float4 c, float dissolveTex,float4 stonecolor)
                {
                    float hardness = clamp(_HardnessFactor, 0.00001, 0.999999);
                    float dissolve = _StoneStrangth * (1 + _DissolveWidth);
                    float fac01 = lerp(2, hardness, dissolve);
                    float dissolve01 = smoothstep(hardness + dissolveTex, 1 + dissolveTex, fac01);
                    float fac02 = lerp(2, hardness, dissolve - _DissolveWidth);
                    float dissolve02 = smoothstep(hardness + dissolveTex, 1 + dissolveTex, fac02);
                    float4 notstonedcolor = float4(lerp(_TransitionColor.rgb, c.rgb, dissolve01) * (dissolve02 > 0), 1);
                    float4 stonedcolor = float4(stonecolor.rgb * (dissolve02 <= 0), 1);
                    float4 color = notstonedcolor + stonedcolor;
                    return color;
                }

                float4 frag(v2f i) : SV_Target
                {
                    float3 normaltex = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv).xyz * 2 - float3(1,1,1);
                    float3 cusnormal = normalize(i.tangentws * normaltex.x + i.birnormal * normaltex.y + i.normalws * normaltex.z);
                    float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                    float4 dissolvetex = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, i.uv);
                    
                    float normalshadowfac = smoothstep(-0.02, 0.02, dot(i.normalws, _DirLightWay));
                    float stoneshadowfac = smoothstep(-0.02, 0.02, dot(cusnormal, _DirLightWay));
                     
                    float4 maincolor = maintex * lerp(0.6, 1, normalshadowfac);
                    float4 stonecolor = _StoneColor * lerp(0.6, 1, stoneshadowfac);
                    //return stonecolor;
                    float4 finalcolor = StoneFunction(maincolor, dissolvetex.x,stonecolor);

                    return finalcolor;
                }
                ENDHLSL
            }
        }
}
