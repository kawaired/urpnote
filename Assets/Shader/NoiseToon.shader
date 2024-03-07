Shader "Unlit/NoiseToon"
{
    Properties
    {
        _MainTex ("maintex", 2D) = "white" {}
        _LightColor("lightcolor",Color)=(1,1,1,1)
        _DarkColor("darkcolor",Color)=(0.5,0.5,0.5,1)
        _LightRimColor("lightrimcolor",Color)=(1,1,1,1)
        _DarkRimColor("darkrimcolor",Color)=(0.5,0.5,0.5,1)
        _RimThreshold("rimthreshold",range(0,1))=0.1
        _RimPower("rimpower",range(1,10))=1
        _NormalTex("normaltex",2D) = "white"{}
        _RampWidth("rampwidth",range(0.01,0.49))=0.02
        _OutlineWidth1("outlinewidth1",range(0,1))=1
        _OutlineColor1("outlinecolor1",Color)=(0.5,0.5,0.5,1)
        _OutlineWidth2("outlinewidth2",range(0,1))=0.5
        _OutlineColor2("outlinecolor2",Color)=(0.7,0.7,0.7,0.7)

        _OutlineTex("outlinedissolvetex",2D) = "white"{}
        _USpeed("uspeed",range(0,10))=0
        _VSpeed("vspeed",range(0,1))=0
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
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normalws:TEXCOORED1;
                float3 tangentws:TEXCOORED2;
                float3 birnormalws:TEXCOORED3;
                float3 viewdir:TEXCOORED4;
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

            float3 _DirLightWay;
            float _Time;
            float3 _CameraPos;

            float4 _LightColor;
            float4 _DarkColor;
            float4 _LightRimColor;
            float4 _DarkRimColor;
            float _RimThreshold;
            float _RimPower;
            float _RampWidth;

            v2f vert (appdata v)
            {
                v2f o;
                float4 vertexws = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(unity_MatrixVP, vertexws);
                o.normalws = mul(transpose((float3x3)unity_WorldToObject), v.normal);
                o.tangentws = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz);
                o.birnormalws = cross(o.normalws, o.tangentws) * v.tangent.w;
                o.viewdir = normalize(_CameraPos - vertexws.xyz);
                o.uv = v.uv*_MainTex_ST.xy+ _MainTex_ST.zw;
                return o;
            }

            float Diffuse(float3 normal, float3 lightdir,float rampwidth)
            {
                float lambert = dot(normal, lightdir);
                float diffuse = smoothstep(-rampwidth, rampwidth, lambert);
                return diffuse;
            }

            float4 frag(v2f i) : SV_Target
            {
                //return _DirLightWay.xyzz;
                float4 maintex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float4 normaltex = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv);
      
                normaltex = (normaltex * 2) - float4(1,1,1,1);
                float3 normal = normalize(i.normalws);
                float3 tangent = normalize(i.tangentws);
                float3 birnormal = normalize(i.birnormalws);
                float3 realnormal = normalize(tangent * normaltex.x + birnormal * normaltex.y + normal * normaltex.z);

                float diffuse = Diffuse(realnormal, _DirLightWay, _RampWidth);
                float4 diffusecolor = maintex * lerp(_DarkColor,_LightColor,diffuse);

                float fresnel = pow(1-saturate(dot(realnormal, i.viewdir)), _RimPower);
                float4 darkrim = (fresnel * (1 - diffuse) > _RimThreshold) * _DarkRimColor;
                float4 lightrim = (fresnel * diffuse > _RimThreshold) * _LightRimColor;
                return darkrim + lightrim+ diffusecolor;
            }
            ENDHLSL
        }
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
            float _OutlineWidth1;

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
                float4 vertexoffset = v.vertex + float4(v.normal, 1) * 0.01 * _OutlineWidth1 *(1+ Random3DTo1D(v.vertex.xyz, 100, float3(15.637, 76.243, 37.168)));
                o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld,vertexoffset));
                //o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex + float4(v.normal, 1) * 0.0005 * Random3DTo1D(v.vertex.xyz, Random1DTo1D(_Time,1000,15), float3(15.637, 76.243, 37.168))));
                return o;
            }


            float4 frag(v2f i) : SV_Target
            {
                return _OutlineColor1;
            }
            ENDHLSL
        }
            //Pass
            //{
            //    Tags {"LightMode" = "OutlinePass2"}
            //    Cull front
            //    HLSLPROGRAM
            //    #pragma vertex vert
            //    #pragma fragment frag

            //    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            //    struct appdata
            //    {
            //        float4 vertex : POSITION;
            //        float3 normal:NORMAL;
            //    };

            //    struct v2f
            //    {
            //        float4 vertex : SV_POSITION;
            //    };

            //    float4x4 unity_MatrixVP;
            //    float4x4 unity_ObjectToWorld;

            //    float _Time;
            //    float4 _OutlineColor2;
            //    float _OutlineWidth2;

            //    TEXTURE2D(_MainTex);
            //    SAMPLER(sampler_MainTex);
            //    float4 _MainTex_ST;

            //    TEXTURE2D(_OutlineDissolveTex);
            //    SAMPLER(sampler_OutlineDissolveTex);
            //    float4 _OutlineDissolveTex_ST;

            //    float Random1DTo1D(float value, float a, float b) {
            //        //make value more random by making it bigger
            //        float random = frac(sin(value + b) * a);
            //        return random;
            //    }

            //    float Random3DTo1D(float3 value, float a, float3 b)
            //    {
            //        float3 smallValue = sin(value);
            //        float  random = dot(smallValue, b);
            //        random = frac(sin(random) * a);
            //        return random;
            //    }

            //    v2f vert(appdata v)
            //    {
            //        v2f o;
            //        float4 vertexoffset = v.vertex + float4(v.normal, 1) * 0.01 * _OutlineWidth2 *(1+Random3DTo1D(v.vertex.xyz, 100, float3(15.637, 76.243, 37.168)));
            //        //float4 vertexoffset = float4(v.normal, 1) * 0.01*_OutlineWidth2 * Random3DTo1D(v.vertex.xyz, 200, float3(75.637, 36.243, 97.168));
            //        o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex + vertexoffset));
            //        //o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex + float4(v.normal, 1) * 0.0005 * Random3DTo1D(v.vertex.xyz, Random1DTo1D(_Time,1000,15), float3(15.637, 76.243, 37.168))));
            //        return o;
            //    }



            //    float4 frag(v2f i) : SV_Target
            //    {
            //        return _OutlineColor2;
            //    }
            //    ENDHLSL
            //}
        Pass
        {
            Tags {"LightMode" = "OutlinePass2"}
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

            float4 _Time;
            float4 _OutlineColor2;
            float _OutlineWidth2;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_OutlineTex);
            SAMPLER(sampler_OutlineTex);
            float4 _OutlineTex_ST;
            float _USpeed;
            float _VSpeed;

            float2 UVPolar(float2 uv)
            {
                half2 uvpolar = uv;
                half distance = length(uvpolar) * 2;
                half angle = atan2(uvpolar.y, uvpolar.x);
                angle = angle / 3.1415927 * 0.5 + 0.5;
                return half2(angle, distance);
            }



            //v2f vert(appdata v)
            //{
            //    v2f o;
            //    float2 outlineuv = float2(length(v.vertex.xz) * _USpeed, _Time.y * _VSpeed);
            //    float outlinefac = SAMPLE_TEXTURE2D_LOD(_OutlineTex, sampler_OutlineTex, outlineuv, 0).x;
            //    float4 vertexoffset = v.vertex + float4(v.normal, 1) * 0.04 * _OutlineWidth2 * (outlinefac*2-0.8);
            //    o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex + vertexoffset));
            //    return o;
            //}

            v2f vert(appdata v)
            {
                v2f o;
                float2 outlineuv = float2(length(v.vertex.xz) * _USpeed, _Time.y * _VSpeed);
                float outlinefac = SAMPLE_TEXTURE2D_LOD(_OutlineTex, sampler_OutlineTex, outlineuv, 0).x;
                float4 vertexoffset = v.vertex + float4(v.normal, 1) * 0.04 * _OutlineWidth2 * (outlinefac * 2 - 0.8);
                o.vertex = mul(unity_MatrixVP, mul(unity_ObjectToWorld, v.vertex + vertexoffset));
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return _OutlineColor2;
            }
            ENDHLSL
        }
    }
}
