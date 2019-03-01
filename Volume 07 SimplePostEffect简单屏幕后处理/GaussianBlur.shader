/* 简单实现高斯模糊效果
   原理:
      一张清晰的图片各个像素之间过渡明显,即具有突变的性质
      而如果将图中每个像素取平均,图像就会变得模糊,最极端的情况是
      所有像素都是所有像素的和的平均,这样就表现为一张纯色图片
*/
Shader "Volume 07/SimplePostEffect/Gaussian Blur" {
    Properties {
        _MainTex("Main Texture",2D) = "white" {}
        _BlurSize("Blur Size",Float) = 1.0
    }
    SubShader {

        CGINCLUDE
        #include "UnityCG.cginc"

        // 屏幕图像
        sampler2D _MainTex;
        // 屏幕图像的纹素
        float4 _MainTex_TexelSize;
        // 采样半径
        float _BlurSize;

        struct v2f{
            float4 pos : SV_POSITION;
            float2 uv[5] : TEXCOORD0;
        };

        // 竖直方向的高斯模糊
        v2f VerticalVert(appdata_img v){
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            // 获得从上到下的5个uv坐标 

            // 上上
            o.uv[0] = v.texcoord + _MainTex_TexelSize.y * half2(0,-2) * _BlurSize;
            // 上
            o.uv[1] = v.texcoord + _MainTex_TexelSize.y * half2(0,-1) * _BlurSize;
            // 原点
            o.uv[2] = v.texcoord;
            // 下
            o.uv[3] = v.texcoord + _MainTex_TexelSize.y * half2(0,1) * _BlurSize;
            // 下下
            o.uv[4] = v.texcoord + _MainTex_TexelSize.y * half2(0,2) * _BlurSize;

            return o;
        }

        // 水平方向上的高斯模糊
        v2f HorizontalVert(appdata_img v){
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            // 获得从左到右5个uv坐标

            // 左左
            o.uv[0] = v.texcoord + _MainTex_TexelSize.x * half2(-2,0) * _BlurSize;
            // 左
            o.uv[1] = v.texcoord + _MainTex_TexelSize.x * half2(-1,0) * _BlurSize;
            // 原点
            o.uv[2] = v.texcoord;
            // 右
            o.uv[3] = v.texcoord + _MainTex_TexelSize.x * half2(1,0) * _BlurSize;
            // 右右
            o.uv[4] = v.texcoord + _MainTex_TexelSize.x * half2(2,0) * _BlurSize;

            return o;
        }

        // 高斯模糊通用片元着色器
        fixed4 frag(v2f i) : SV_TARGET{

            // 高斯核
            float weight[5] = {0.0545,0.242,0.4026,0.242,0.0545};

            // 进行卷积
            fixed3 color = fixed3(0,0,0);

            for(int it=0;it<5;it++){
                // 对应uv位置像素颜色
                fixed4 texColor = tex2D(_MainTex,i.uv[it]);

                color += texColor.rgb * weight[it];
            }

            return fixed4(color,1.0);
        }

        ENDCG

        // 对图像进行竖直方向高斯模糊的Pass
        Pass {
            CGPROGRAM

            #pragma vertex VerticalVert
            #pragma fragment frag
            
            ENDCG
        }

        // 对图像进行水平方向高斯模糊的Pass
        Pass {
            CGPROGRAM

            #pragma vertex HorizontalVert
            #pragma fragment frag
            
            ENDCG
        }
    }
    FallBack "Diffuse"
    
}