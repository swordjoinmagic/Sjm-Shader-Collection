Shader "Volume 08/Depth Normal Texture/Fog With DepthTexture" {
    Properties {
        // 屏幕图像
        _MainTex("Main Texture",2D) = "white" {}
        // 雾的强度
        _FogDensity("Fog Density",Float) = 1.0
        // 雾的颜色
        _FogColor("Fog Color",Color) = (1, 1, 1, 1)
        // 受雾影响的最小高度
        _FogStart("Fog Start",Float) = 0.0
        // 受雾影响的最大高度
        _FogEnd("Fog End",Float) = 1.0
    }
    SubShader {
        Pass {
        
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            // 记录四个顶点到摄像机的向量(包含方向和距离信息)
            float4x4 _FrustumCornersRay;

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            // 深度图
            sampler2D _CameraDepthTexture;
            float _FogDensity;
            fixed4 _FogColor;
            float _FogStart;
            float _FogEnd;


            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv_depth : TEXCOORD1;
                float4 interpolatedRay : TEXCOORD2;
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord;
                o.uv_depth = v.texcoord;

                // 处理DX和GL带来的差异
                #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y<0)
                    o.uv_depth.y = 1-o.uv_depth.y;
                #endif

                int index = 0;
                if(v.texcoord.x < 0.5 && v.texcoord.y < 0.5){
                    index = 0;
                }else if(v.texcoord.x > 0.5 && v.texcoord.y < 0.5){
                    index = 1;
                }else if(v.texcoord.x > 0.5 && v.texcoord.y > 0.5){
                    index = 2;
                }else{
                    index = 3;
                }

                #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y<0)
                    index = 3 - index;
                #endif

                o.interpolatedRay = _FrustumCornersRay[index];
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth));

                // 根据视角空间下的深度值(z值)和该像素指向摄像机的向量,求得该像素的世界坐标
                float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

                // 计算原始颜色和雾的颜色的混合系数
                float fogDensity = (_FogEnd-worldPos.y) / (_FogEnd-_FogStart);
                // 将该混合系数根据 雾的强度 进行缩放
                fogDensity = saturate(fogDensity * _FogDensity);

                fixed4 finalColor = tex2D(_MainTex,i.uv);
                finalColor.rgb = lerp(finalColor.rgb,_FogColor.rgb,fogDensity);

                return finalColor;
            }

            ENDCG

        }
    }
    FallBack "Diffuse"
    
}