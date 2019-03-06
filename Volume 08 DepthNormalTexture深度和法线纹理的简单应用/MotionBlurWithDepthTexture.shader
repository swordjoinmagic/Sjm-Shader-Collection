// 根据深度图生成速度映射图来实现运动模糊效果
Shader "Volume 08/Depth Normal Texture/Motion Blur With Depth Texture" {
    Properties {
        _MainTex("_MainTex",2D) = "white" {}
        _BlurSize("Blur Size",Float) = 1.0
    }
    SubShader {
        Pass {
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            // 屏幕图像
            sampler2D _MainTex;
            // 屏幕纹素
            float4 _MainTex_TexelSize;
            // 深度图
            sampler2D _CameraDepthTexture;
            // 当前帧的裁剪-世界变换矩阵（用于将裁剪空间下的坐标变换到世界坐标下，其实就是世界-裁剪变换矩阵的逆矩阵）
            float4x4 _CurrentViewProjectionInverseMatrix;
            // 上一帧的世界-裁剪变换矩阵（用于将坐标从世界坐标变换到裁剪空间下）
            float4x4 _PreviousViewProjectionMatrix;
            // 模糊半径
            half _BlurSize;

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv_depth : TEXCOORD1;
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord;
                o.uv_depth = v.texcoord;

                // 处理平台差异导致的图像反转问题
                #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y < 0)
                    o.uv_depth.y = 1-o.uv_depth.y;
                #endif

                return o;
            }

            fixed3 frag(v2f i) : SV_TARGET{
                // 根据深度图获得当前深度
                float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth);
                // 根据当前的uv值和深度值构建当前的NDC坐标
                float4 NDCPos = float4(i.uv.x*2-1,i.uv.y*2-1,d*2-1,1);
                // 根据view-Projection矩阵将该NDC坐标变换到世界坐标下
                float4 worldPos = mul(_CurrentViewProjectionInverseMatrix,NDCPos);
                worldPos /= worldPos.w;

                // 当前NDC坐标
                float4 currentWorldPos = NDCPos;
                // 获得上一帧的裁剪空间坐标
                float4 previousPos = mul(_PreviousViewProjectionMatrix,worldPos);
                previousPos /= previousPos.w;

                // 根据这两帧的坐标,计算当前像素的速度
                float2 velocity = (currentWorldPos.xy - previousPos.xy)/2.0f;

                // 下面根据像素速度,对该像素速度方向的邻近像素进行均值模糊
                float2 uv = i.uv;
                float4 c = tex2D(_MainTex,uv);
                uv += velocity * _BlurSize;
                for(int it=1;it<3;it++,uv+=velocity*_BlurSize){
                    float4 currentColor = tex2D(_MainTex,uv);
                    c += currentColor;
                }
                c /= 3;

                return fixed4(c.rgb, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}