Shader "Unlit/FresnelAdd"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _FresnelWidth("fresnelwidth",range(0.01,2))=0.1
        _FresnelColor("fresnelcolor",Color)=(0.1,0.5,0.8,1)
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
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv:TEXCOORED0;
                float3 viewdir:TEXCOORD1;
                float3 normalws : NORMAL;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4x4 unity_WorldToObject;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            float _FresnelWidth;
            float4 _FresnelColor;

            float3 _CameraPos;

            v2f vert(appdata v)
            {
                v2f o;
                float4 vertexws = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(unity_MatrixVP, vertexws);
                o.normalws = mul(transpose((float3x3)unity_WorldToObject), v.normal);
                o.viewdir = normalize(_CameraPos - vertexws.xyz);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                float vdotn = saturate(dot(i.viewdir, i.normalws));
                float fresnelfac = smoothstep(1-_FresnelWidth, 1, 1 - vdotn);
                float4 fresnelcolor = _FresnelColor * fresnelfac;
                float4 finalcolor = maintex;
                finalcolor.xyz = finalcolor.xyz + fresnelcolor.xyz;
                finalcolor.a = finalcolor.a * lerp(fresnelfac, 1, _FresnelColor.a);
                return finalcolor;
            }
            ENDHLSL
        }
    }
}
