Shader "Unlit/DonkeyFur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex("normaltex",2D) = "white"{}
        _MaskTex("masktex",2D) = "white"{}
        _NoiseTex("noisetex",2D) = "white"{}
        _FurNormalTex("furnomraltex",2D) = "white"{}

        _FurWidth("furwidth",range(0,0.1)) = 0
        _FeatherWidth("featherwidth",range(0.01,0.49)) = 0.2
        _FurDensity("furdensity",range(1,5))=1
    }
    SubShader
    {
        Pass
        {
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            //Tags {"LightMode" = "Fur1"}
            HLSLPROGRAM
            #define FURSTEP 0.2
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1:TEXCOORD0; 
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
                float4 color:COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normalws:NORMAL;
                float3 tangentws:TANGENT;
                float3 birnormalws:TEXCOORD1;
                float2 furuv:TEXCOORD2;
                float2 noiseuv:TEXCOORD3;
                float4 color:COLOR;
                //float noise : TEXCOORD4;
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

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            float4 _MaskTex_ST;

            TEXTURE2D(_FurNormalTex);
            SAMPLER(sampler_FurNormalTex);
            float4 _FurNormalTex_ST;

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);
            float4 _NoiseTex_ST;

            float _FurWidth;
            float _FeatherWidth;
            float3 _LightDir;
            float3 _DirLightWay;
            float3 _CameraPos;
            float _FurDensity;
             
            float Random3DTo1D(float3 value, float a, float3 b)
            {
                float3 smallValue = sin(value);
                float  random = dot(smallValue, b);
                random = frac(sin(random) * a);
                return random;
            }

            v2f vert (appdata v)
            {
                v2f o;
                float4 vertexws = mul(unity_ObjectToWorld, v.vertex + float4(v.normal.xyz*float3(1,1,2), 0) * FURSTEP * _FurWidth);
                o.vertex = mul(unity_MatrixVP, vertexws);
                o.normalws = mul(transpose((float3x3)unity_WorldToObject), v.normal);
                o.tangentws = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz) * v.tangent.w;
                o.birnormalws = cross(o.normalws, o.tangentws);
                o.uv = v.uv;
                o.furuv = v.uv * _FurNormalTex_ST.xy + _FurNormalTex_ST.zw;
                o.noiseuv = v.uv * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
                o.color = v.color;
                //o.noise = Random3DTo1D(v.vertex.xyz, 100, float3(15637, 76243, 37168));
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float4 normaltex = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv) * 2 - float4(1, 1, 1, 1);
                float4 noisetex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.noiseuv);
                //return noisetex.z;
                //return normaltex;
                //return i.normalws.xyzz;
                float4 masktex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv);
                float4 furnormaltex = SAMPLE_TEXTURE2D(_FurNormalTex, sampler_FurNormalTex, i.furuv) * 2 - float4(1, 1, 1, 1);
                //return furnormaltex;
                //return SAMPLE_TEXTURE2D(_FurNormalTex, sampler_FurNormalTex, i.furuv1);
                float3 furnormal = i.tangentws * furnormaltex.x + i.birnormalws * furnormaltex.y + i.normalws * furnormaltex.z;
                //return float4(furnormal, 1);
                //return furnormaltex.b;
                float3 cusnormal = i.tangentws * normaltex.x + i.birnormalws * normaltex.y + normalize(i.normalws) * normaltex.z;
                float lambert = (dot(_DirLightWay, cusnormal) + 1) * 0.5;
                //return normalize(cusnormal).xyzz;
                //return lambert;
                float diffusefac = smoothstep(0.5 - _FeatherWidth, 0.5 + _FeatherWidth, lambert * masktex.y);
                float4 diffusecolor = lerp(0.6, 1, diffusefac) * maintex;
                //return i.noise;
                float alpha= saturate(noisetex.z - _FurWidth * _FurWidth * 100 * _FurDensity);
                //return noisetex;
                diffusecolor.a = alpha;
                //return i.color;
                return diffusecolor;
                //return float4(1, 1, 1, 1);
            }
            ENDHLSL
        }
        //        Pass
        //{
        //        //Tags {"LightMode" = "Fur1"}
        //        HLSLPROGRAM
        //        #define FURSTEP 0.10
        //        #pragma vertex vert
        //        #pragma fragment frag

        //        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

        //        struct appdata
        //        {
        //            float4 vertex : POSITION;
        //            float2 uv : TEXCOORD0;
        //            float2 uv1:TEXCOORD1;
        //            float3 normal:NORMAL;
        //            float4 tangent:TANGENT;
        //        };

            //    struct v2f
            //    {
            //        float2 uv : TEXCOORD0;
            //        float4 vertex : SV_POSITION;

            //    };

            //    float4x4 unity_MatrixVP;
            //    float4x4 unity_ObjectToWorld;
            //    float4x4 unity_WorldToObject;

            //    TEXTURE2D(_MainTex);
            //    SAMPLER(sampler_MainTex);
            //    float4 _MainTex_ST;

            //    float _FurWidth;

            //    v2f vert(appdata v)
            //    {
            //        v2f o;
            //        float4 vertexws = mul(unity_ObjectToWorld, v.vertex + float4(v.normal.xyz, 0) * FURSTEP * _FurWidth);
            //        o.vertex = mul(unity_MatrixVP, vertexws);

            //        o.uv = v.uv;
            //        return o;
            //    }

            //    float4 frag(v2f i) : SV_Target
            //    {
            //        return SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
            //    }
            //    ENDHLSL
            //}
                //    Pass
                //{
                //    Tags {"LightMode" = "Fur1"}
                //    HLSLPROGRAM
                //    #define FURSTEP 0.10
                //    #pragma vertex vert
                //    #pragma fragment frag

                //    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

                //    struct appdata
                //    {
                //        float4 vertex : POSITION;
                //        float2 uv : TEXCOORD0;
                //        float2 uv1:TEXCOORD1;
                //        float3 normal:NORMAL;
                //        float4 tangent:TANGENT;
                //    };

                //    struct v2f
                //    {
                //        float2 uv : TEXCOORD0;
                //        float4 vertex : SV_POSITION;

                //    };

                //    float4x4 unity_MatrixVP;
                //    float4x4 unity_ObjectToWorld;
                //    float4x4 unity_WorldToObject;

                //    TEXTURE2D(_MainTex);
                //    SAMPLER(sampler_MainTex);
                //    float4 _MainTex_ST;

                //    float _FurWidth;

                //    v2f vert(appdata v)
                //    {
                //        v2f o;
                //        float4 vertexws = mul(unity_ObjectToWorld, v.vertex + float4(v.normal.xyz, 0) * FURSTEP * _FurWidth);
                //        o.vertex = mul(unity_MatrixVP, vertexws);

                //        o.uv = v.uv;
                //        return o;
                //    }

                //    float4 frag(v2f i) : SV_Target
                //    {
                //        return SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                //    }
                //    ENDHLSL
                //}
                //        Pass
                //    {
                //        Tags {"LightMode" = "Fur2"}
                //        HLSLPROGRAM
                //        #define FURSTEP 0.15
                //        #pragma vertex vert
                //        #pragma fragment frag

                //        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

                //        struct appdata
                //        {
                //            float4 vertex : POSITION;
                //            float2 uv : TEXCOORD0;
                //            float2 uv1:TEXCOORD1;
                //            float3 normal:NORMAL;
                //            float4 tangent:TANGENT;
                //        };

                //        struct v2f
                //        {
                //            float2 uv : TEXCOORD0;
                //            float4 vertex : SV_POSITION;

                //        };

                //        float4x4 unity_MatrixVP;
                //        float4x4 unity_ObjectToWorld;
                //        float4x4 unity_WorldToObject;

                //        TEXTURE2D(_MainTex);
                //        SAMPLER(sampler_MainTex);
                //        float4 _MainTex_ST;

                //        float _FurWidth;

                //        v2f vert(appdata v)
                //        {
                //            v2f o;
                //            float4 vertexws = mul(unity_ObjectToWorld, v.vertex + float4(v.normal.xyz, 0) * FURSTEP * _FurWidth);
                //            o.vertex = mul(unity_MatrixVP, vertexws);

                //            o.uv = v.uv;
                //            return o;
                //        }

                //        float4 frag(v2f i) : SV_Target
                //        {
                //            return SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                //        }
                //        ENDHLSL
                //    }
    }
}
