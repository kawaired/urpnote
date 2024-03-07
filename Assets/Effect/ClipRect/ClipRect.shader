Shader "Unlit/Flash"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _ClipRect("cliprect",float)=(1,1,1,1)
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
                float4 vertexws: TEXCOORD1;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            float4 _ClipRect;

            float4 _Time;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertexws = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(unity_MatrixVP, o.vertexws);
                o.uv = v.uv;
                return o;
            }

            float UnityGet2DClipping(float2 position,float4 clipRect)
            {
                float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
                return inside.x * inside.y;
            }


            float4 frag(v2f i) : SV_Target
            {
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                maintex.a = maintex.a * UnityGet2DClipping(i.vertexws.xy, _ClipRect);
                return maintex;
            }
            ENDHLSL
        }
    }
}
