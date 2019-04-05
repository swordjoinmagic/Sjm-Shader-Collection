/*
    后处理·径向模糊
    原理：
    根据屏幕上一个指定的位置，对屏幕图像进行模糊。
    离该指定位置越近的点（屏幕空间下），采样面积越小
    离该指定位置越远的点，采样面积越大


*/
Shader "Volume 07/SimplePostEffect/RadialBlurEffect" {
    Properties {
        // 屏幕图像
        _MainTex("Main Texture",2D) = "white" {}
        // 指定径向模糊的中心点(只用x、y分量,范围在[0,1]之间)
        _CenterPoint("Center Point",Vector) = (0.5, 0.5, 0, 0)   
    }
    SubShader {
        Pass {
            CGPROGRAM

            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            fixed4 _CenterPoint;
            

            v2f vert(appdata_img v){
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                // 取上下左右中心做均值模糊
                float4 color = float4(0,0,0,1);
                // 模糊方向
                float2 dir = -_CenterPoint + i.uv;
                // 采样半径
                float factor = 15;
                for(int it=0;it<10;it++){
                    color += tex2D(_MainTex,i.uv - dir*factor*it*_MainTex_TexelSize);
                }
                fixed4 finalColor = color / 10;
                return finalColor;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}