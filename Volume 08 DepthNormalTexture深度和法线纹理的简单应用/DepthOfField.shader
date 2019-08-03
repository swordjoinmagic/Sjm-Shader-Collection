/*
    后处理-景深效果
    思路：
        一张原图像,一张高斯模糊后的图像,
        将两张图像根据当前顶点距离焦点深度进行插值
*/
Shader "Volume 08/Depth Normal Texture/Depth Of Field" {
    Properties {
        _MainTex("Main Texture",2D) = "white" {}
        _BlurTex("Blur Texture",2D) = "white" {}
        // 焦点的深度(被归一化后的深度)
        _FocusDepth("Focus Depth",Float) = 0
        // 远景模糊权值
        _FarBlurScale("Far Blur Scale",Float) = 1
        // 近景模糊权值
        _NearBlurScale("Near Blur Scale",Float) = 1
    }
    SubShader {
        Pass {
            CGPROGRAM

            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            sampler2D _BlurTex;
            // 深度图（保存顶点在ndc坐标下的z值）
            sampler2D _CameraDepthTexture;
            fixed _FocusDepth;
            float _FarBlurScale;
            float _NearBlurScale;

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{

                // 原图像
                fixed4 main = tex2D(_MainTex,i.uv);
                // 高斯模糊后的图像
                fixed4 blur = tex2D(_BlurTex,i.uv);

                // 获得当前uv(即当前屏幕像素位置)位置的深度(ndc坐标下的)
                float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv);
                // 将该ndc坐标下的深度转换到视角空间下并归一化
                fixed depth = Linear01Depth(d);

                // 根据当前顶点深度和焦点深度进行插值
                fixed4 finalColor = (depth <= _FocusDepth) ? main : lerp(main, blur, clamp((depth - _FocusDepth)*_FarBlurScale, 0, 1));
                finalColor = (depth>_FocusDepth) ? finalColor : lerp(main,blur,clamp((_FocusDepth-depth)*_NearBlurScale,0,1));
                return finalColor; 
            }

            ENDCG
        
        }
    }
    FallBack "Diffuse"
    
}