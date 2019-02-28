// 屏幕后处理，用于调节饱和度、对比度、亮度的Shader
Shader "Volume 06/SimplePostEffect/Brightness Saturation And Contrast" {
    Properties {
        // 屏幕图像
        _MainTex("Main Texture",2D) = "white" {}
        // 亮度值
        _Brightness("Brightness",Range(1,10)) = 1
        // 对比度
        _Contrast("Contrast",Range(0,1.0)) = 0
        // 饱和度
        _Saturation("Saturation",Range(0,1.0)) = 0
    }
    SubShader {

        Tags{ "RenderType"="Opaque" "Queue"="Geometry" }

        Pass {
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float _Brightness;
            float _Contrast;
            float _Saturation;

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

                fixed3 finalColor = tex2D(_MainTex,i.uv);

                // 基于亮度系数调整图像颜色
                finalColor *= _Brightness;

                // 创建饱和度为0的颜色值
                fixed luminance = Luminance(finalColor);
                fixed3 luminanceColor = fixed3(luminance,luminance,luminance);
                finalColor = lerp(finalColor,luminanceColor,_Saturation);

                // 创建对比度为0的颜色值
                fixed3 avgColor = fixed3(0.5,0.5,0.5);
                // 调整对比度
                finalColor = lerp(finalColor,avgColor,_Contrast);

                return fixed4(finalColor,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}