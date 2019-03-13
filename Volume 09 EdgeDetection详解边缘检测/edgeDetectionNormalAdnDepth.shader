/*
    基于深度及法线纹理的边缘检测(屏幕后处理)
*/
Shader "Volume xx/PostEffect/Edge Detection Normal And Depth" {
    Properties {
        _MainTex("MainTex",2D) = "white" {}
        // 只显示边缘线的程度,为1时,只显示边缘线,为0时,不显示
        _EdgeOnly("Edge Only",Float) = 1.0
        // 边缘颜色
        _EdgeColor("Edge Color",Color) = (0, 0, 0, 1)
        // 背景颜色
        _BackgroundColor("Background Color",Color) = (1, 1, 1, 1)
        // 进行卷积运算时,采样的范围
        _SampleDistance("Sample Distance",Float) = 1.0
        // _Sensitivity的xy分量分别对应了法线和深度的检测灵敏度,ZW分量没用
        _Sensitivity("Sensitivity",Vector) = (1, 1, 1, 1)
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass {                    
            CGPROGRAM

            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;
            float _SampleDistance;
            float4 _Sensitivity;
            sampler2D _CameraDepthNormalsTexture;       // Unity提供的深度图

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv[5] : TEXCOORD0;       // 用于在纹理周围进行法线和深度的采样
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                half2 uv = v.texcoord;
                o.uv[0] = uv;

                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;

                return o;
            }

            fixed CheckSame(fixed4 center,fixed4 sample){
                fixed2 centerNormal = center.xy;
                float centerDepth = DecodeFloatRG(center.zw);
                fixed2 sampleNormal = sample.xy;
                float sampleDepth = DecodeFloatRG(sample.zw);

                fixed2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
                int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;

                float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
                int isSameDepath = diffDepth < 0.1 * centerDepth;

                return isSameNormal*isSameDepath ? 1.0 : 0.0;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed4 sample1 = tex2D(_CameraDepthNormalsTexture,i.uv[1]);
                fixed4 sample2 = tex2D(_CameraDepthNormalsTexture,i.uv[2]);
                fixed4 sample3 = tex2D(_CameraDepthNormalsTexture,i.uv[3]);
                fixed4 sample4 = tex2D(_CameraDepthNormalsTexture,i.uv[4]);

                // edge为0时表示两点之间存在一条边界
                fixed edge = 1.0;
                
                edge *= CheckSame(sample1,sample2);
                edge *= CheckSame(sample3,sample4);

                fixed4 withEdgeColor = lerp(_EdgeColor,tex2D(_MainTex,i.uv[0]),edge);
                fixed4 onlyEdgeColor = lerp(_EdgeColor,_BackgroundColor,edge);

                return lerp(withEdgeColor,onlyEdgeColor,_EdgeOnly);
            }                
            ENDCG
        }
    }
    FallBack "Diffuse"
    
}