Shader "Unlit/CreateNoise"
{
    Properties
    {
        _OutlineWidth("outlinewidth",range(0,1)) = 0.5
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex));
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return float4(1,1,1,1);
            }
            ENDHLSL
        }
        //Pass
        //{
        //    Tags {"LightMode" = "OutlinePass"}
        //    Cull front
        //    HLSLPROGRAM
        //    #pragma vertex vert
        //    #pragma fragment frag

        //    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

        //    struct appdata
        //    {
        //        float4 vertex : POSITION;
        //        float2 uv : TEXCOORD0;
        //        float3 normal:NORMAL;
        //    };

        //    struct v2f
        //    {
        //        float2 uv : TEXCOORD0;
        //        float4 vertex : SV_POSITION;
        //    };

        //    float4x4 unity_MatrixVP;
        //    float4x4 unity_ObjectToWorld;
        //    float _OutlineWidth;

        //    TEXTURE2D(_MainTex);
        //    SAMPLER(sampler_MainTex);

        //    v2f vert(appdata v)
        //    {
        //        v2f o;
        //        o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex+float4(v.normal, 1) * 0.01 * _OutlineWidth));
        //        o.uv = v.uv;
        //        return o;
        //    }

        //    float4 frag(v2f i) : SV_Target
        //    {
        //        return float4(0,0,0,1);
        //    }
        //    ENDHLSL
        //}
        Pass
        {
            Tags {"LightMode" = "OutlinePass"}
            Cull front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            float _Time;
            float4 _OutlineColor1;
            float _OutlineWidth;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float Random1DTo1D(float value, float a, float b) {
                //make value more random by making it bigger
                float random = frac(sin(value + b) * a);
                return random;
            }

            float Random3DTo1D(float3 value, float a, float3 b)
            {
                float3 smallValue = sin(value);
                float  random = dot(smallValue, b);
                random = frac(sin(random) * a);
                return random;
            }

            v2f vert(appdata v)
            {
                v2f o;
                float4 vertexoffset = v.vertex + float4(normalize(v.normal), 1) * _OutlineWidth;
                o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld,vertexoffset));
                //o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex + float4(v.normal, 1) * 0.0005 * Random3DTo1D(v.vertex.xyz, Random1DTo1D(_Time,1000,15), float3(15.637, 76.243, 37.168))));
                return o;
            }


            float4 frag(v2f i) : SV_Target
            {
                return float4(0,0,0,1);
            }
            ENDHLSL
        }
    }
}
