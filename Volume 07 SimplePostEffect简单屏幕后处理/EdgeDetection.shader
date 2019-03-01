// 利用图像之间的梯度值进行的边缘检测
// 主要利用sobel算子算出图像中水平和竖直方向的梯度值,
// 并根据梯度值来判断当前像素点是不是边界
Shader "Volume 07/SimplePostEffect/EdgeDetection" {
    Properties {
        // 屏幕图像
        _MainTex("Main Texture",2D) = "white" {}
        // 判断图像是否只有边线
        _EdgeOnly("Edge Only",Range(0,1.0)) = 0
        // 边缘颜色
        _EdgeColor("Edge Color",Color) = (0, 0, 0, 1)
        // 背景颜色
        _BackgroundColor("Background Color",Color) = (1, 1, 1, 1)
    }
    SubShader {
        Tags{ "RenderType"="Opaque" "Queue"="Geometry" }
        Pass {
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            // 纹理的纹素，x = 1/width, y = 1/height, z = width, w = height
            float4 _MainTex_TexelSize;
            fixed _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;

            struct v2f{
                float4 pos : SV_POSITION;
                // 定义9个纹理坐标,
                // 分别用于采样原点、左上角、左边、左下角、上边、下边、右边、右上角、右下角这九个位置
                float2 uv[9] : TEXCOORD0;
            };

            // 声明方法签名
            half sobel(v2f i);

            v2f vert(appdata_img v){
                v2f o;

                // 把顶点变换到裁剪空间去
                o.pos = UnityObjectToClipPos(v.vertex);

                // opengl中，左下角是（0,0）,右上角（1，1）

                // 这里的顺序很重要，书上的顺序是从左到右，从下到上
                // 左上角
                o.uv[0] = v.texcoord + _MainTex_TexelSize * half2(-1,1);
                // 上边
                o.uv[1] = v.texcoord + _MainTex_TexelSize * half2(0,1);
                // 右上角
                o.uv[2] = v.texcoord + _MainTex_TexelSize * half2(1,1);
                // 左边
                o.uv[3] = v.texcoord + _MainTex_TexelSize * half2(-1,0);
                // uv原点
                o.uv[4] = v.texcoord;
                // 右边
                o.uv[5] = v.texcoord + _MainTex_TexelSize * half2(1,0);
                // 左下角
                o.uv[6] = v.texcoord + _MainTex_TexelSize * half2(-1,-1);
                // 下边
                o.uv[7] = v.texcoord + _MainTex_TexelSize * half2(0,-1);
                // 右下角
                o.uv[8] = v.texcoord + _MainTex_TexelSize * half2(1,-1);
                

                return o; 
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 获得当前像素点的边缘值
                half edge = sobel(i);

                // 当前uv位置的像素值
                fixed4 color = tex2D(_MainTex,i.uv[4]);

                // 边缘值越大，该点越有可能是边界
                fixed4 withEdgeColor = lerp(color,_EdgeColor,edge);
                fixed4 onlyEdgeColor = lerp(_EdgeColor,_BackgroundColor,1-edge);
                
                return lerp(withEdgeColor,onlyEdgeColor,_EdgeOnly);
            }

            // 对当前像素位置进行卷积操作，返回该像素点的边缘值
            // 边缘值越大，则说明此处越有可能是边界
            half sobel(v2f i){

                // Gx用于检测水平方向上的边界线
                // (注:书上的两个用于卷积的矩阵写反了)
                const half Gx[9] = {
                    -1,0,1,
                    -2,0,2,
                    -1,0,1
                };

                // Gy用于检测竖直方向上的边界线
                const half Gy[9] = {
                    -1,-2,-1,
                     0, 0, 0,
                     1, 2, 1
                };

                half edgeX = 0;
                half edgeY = 0;

                // 进行卷积操作，具体来说，就是将对应像素值位置（当前uv原点）
                // 的上下左右等9个角分别和其对应像素位置的颜色值相乘并求和
                for(int it=0;it<9;it++){
                    // fixed3 color = tex2D(_MainTex,i.uv[it]);
                    fixed3 color = Luminance(tex2D(_MainTex,i.uv[it]));
                    edgeX += color * Gx[it];
                    edgeY += color * Gy[it];
                }

                // 返回该像素点的边缘值
                return (abs(edgeX) + abs(edgeY));
            }

            ENDCG            
        }
    }
    FallBack "Diffuse"
    
}