/*
    基于屏幕颜色的边缘检测
*/
Shader "Volume xx/PostEffect/Edge Detection Post Effect" {
    Properties {
        _MainTex("Main Tex",2D) = "white" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;  // 纹素,纹理每个像素的大小
            fixed4 _EdgeColor;      // 边缘颜色
            fixed4 _NonEdgeColor;
            float _EdgePower;
            float _SampleRange;
            float _EdgeOnly;

            struct a2v{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float2 uvSobel[9] : TEXCOORD0;
            };

            // 使用Sobel算子计算水平/竖直方向梯度值
            float Sobel(v2f i){
                const float Gx[9] = {
                    -1,-2,-1,
                     0, 0, 0,
                     1, 2, 1
                };
                const float Gy[9] = {
                     1, 0,-1,
                     2, 0,-2,
                     1, 0,-1
                };

                float edgex,edgey;
                for(int j=0;j<9;j++){
                    // 对对应uv点进行采样
                    fixed4 color = tex2D(_MainTex,i.uvSobel[j]);

                    // 将颜色转为灰度值
                    float lum = Luminance(color.rgb);       

                    // 进行卷积
                    // 对两个方向上的梯度值
                    edgex += lum * Gx[j];
                    edgey += lum * Gy[j];
                }
                // abs(edgex) + abs(edgey)为梯度值
                // 梯度值越大,越有可能是边缘点
                // 1-(abs(edgex)+abs(edgey))表示梯度值的反面,即这个值越小,那么越有可能是梯度值
                return 1 - abs(edgex) - abs(edgey);     
            }

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 注意unity中的uv坐标,原点在左下角(directX在左上角)

                // 得到uv点周围8个像素的uv位置
                o.uvSobel[0] = v.uv + float2(-1,-1) * _MainTex_TexelSize * _SampleRange;
                o.uvSobel[1] = v.uv + float2( 0,-1) * _MainTex_TexelSize * _SampleRange;
                o.uvSobel[2] = v.uv + float2( 1,-1) * _MainTex_TexelSize * _SampleRange;
                o.uvSobel[3] = v.uv + float2(-1, 0) * _MainTex_TexelSize * _SampleRange;
                o.uvSobel[4] = v.uv + float2( 0, 0) * _MainTex_TexelSize * _SampleRange;
                o.uvSobel[5] = v.uv + float2( 1, 0) * _MainTex_TexelSize * _SampleRange;
                o.uvSobel[6] = v.uv + float2(-1, 1) * _MainTex_TexelSize * _SampleRange;
                o.uvSobel[7] = v.uv + float2( 0, 1) * _MainTex_TexelSize * _SampleRange;
                o.uvSobel[8] = v.uv + float2( 1, 1) * _MainTex_TexelSize * _SampleRange;

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{

                // i.uvSobel[4]对应当前uv点
                fixed4 color = tex2D(_MainTex,i.uvSobel[4]);

                // 计算该点的1-梯度值
                float g = Sobel(i);

                // 将"反梯度值"进一步缩小(这一步说明了上面为什么不直接计算梯度值,而是要用1减去)
                // 因为如果是真梯度值,这里应该放大梯度值,放大梯度值不能进行整数幂计算,而是要分数幂
                // 更消耗性能(个人猜测)
                g = pow(g,_EdgePower);

                // 使用"反梯度值"来过渡边缘颜色,梯度值越高,边缘颜色黑色更多,反之,呈白色
                fixed4 edgeColor = lerp(_EdgeColor,_NonEdgeColor,g);

                // 根据_EdgeOnly变量,判断如何从正常的颜色过渡到只显示边缘的屏幕效果
                color.rgb = lerp(color.rgb,edgeColor,_EdgeOnly);

                return color;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}