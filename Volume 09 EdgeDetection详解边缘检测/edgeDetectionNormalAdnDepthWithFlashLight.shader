/*
    基于深度及法线纹理的边缘检测(屏幕后处理)
    增加了简单的流光效果,在流光内的物体呈现原本的颜色或者只呈现线条颜色
*/
Shader "Volume xx/PostEffect/Edge Detection Normal And Depth With Flash Light" {
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
        // 流光图
        _FlashTex("Flash Tex",2D) = "black" {}
        // 流光采样x轴/y轴的速度,x分量是x轴,y分量是y轴,zw分量无意义
        _FlashSpeed("Flash Speed",Vector) = (0, 0, 0, 0)
        // 流光颜色
        _FlashColor("Flash Color",Color) = (1, 1, 1, 1)
        // 渐变阈值
        _EffectPercentage("EffectPercentage",Range(0,3)) = 0
        // 噪声图
        _NoiseTex("Noise Tex",2D) = "defaulttexture" {}
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
            sampler2D _FlashTex;
            float4 _FlashSpeed;
            fixed4 _FlashColor;
            fixed _EffectPercentage;
            sampler2D _NoiseTex;

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv[5] : TEXCOORD0;       // 用于在纹理周围进行法线和深度的采样

                float3 worldPos : TEXCOORD5;
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

                o.worldPos = mul(unity_ObjectToWorld,v.vertex);

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

                fixed4 finalColor = lerp(withEdgeColor,onlyEdgeColor,_EdgeOnly);

                // 根据世界坐标对流光图进行采样
                float2 flashUv = i.worldPos.zx + _FlashSpeed.xy * _Time.y;
                fixed4 flashColor = tex2D(_FlashTex,flashUv) * _FlashColor;

                // 根据uv坐标渐变边缘图至正常颜色
                finalColor.rgb = lerp(finalColor.rgb,withEdgeColor,saturate(_EffectPercentage-i.uv[0].x-tex2D(_NoiseTex,i.uv[0]).r));


                // 在流光范围内的颜色回复正常
                // finalColor.rgb = lerp(withEdgeColor.rgb,finalColor.rgb,flashColor.r*2);

                return finalColor;
            }                
            ENDCG
        }
    }
    FallBack "Diffuse"
    
}