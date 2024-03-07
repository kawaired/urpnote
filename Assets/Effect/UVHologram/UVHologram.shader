Shader "Unlit/UVHologram"
{
    Properties
    {
        _MainTex("maintex",2D) = "white"{}
        _HologramTex("hologramtex",2D) = "white"{} 
        _ScrollSpeed("scrollspeed",range(0,30)) = 1
        _FlaskSpeed("flaskspeed",range(0.01,1))=0.5
        _HoloColor("holocolor",Color)=(1,1,1,1)
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
                float2 holouv:TEXCOORD1;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_HologramTex);
            SAMPLER(sampler_HologramTex);
            float4 _HologramTex_ST;

            float _ScrollSpeed;

            float _FlaskSpeed;

            float4 _Time;

            float4 _HoloColor;

            v2f vert(appdata v)
            {
                v2f o;
                float4 vertexws = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(unity_MatrixVP, vertexws);
                o.uv = v.uv;
                o.holouv = vertexws.xy;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                float2 UVholo = i.holouv* _HologramTex_ST.xy + _ScrollSpeed * float2(0, _Time.y) ;
                float4 hologramtex= SAMPLE_TEXTURE2D(_HologramTex, sampler_HologramTex, UVholo);
                maintex.a= hologramtex.x * step(0.01, saturate(_Time.y % _FlaskSpeed));
                return maintex * _HoloColor;
            }
            ENDHLSL
        }
    }
}
