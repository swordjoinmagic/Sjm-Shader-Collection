Shader "Volume 07/SimplePostEffect/Motion Blur" {
    Properties {
        _MainTex("Main Texture",2D) = "white" {}
    }
    SubShader {
        
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;

        // 运动时每帧图像的混合参数
        fixed _BlurAmount;

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

        // 混合运动图像的rgb通道
        fixed4 fragRGB(v2f i) : SV_TARGET{
            return fixed4(tex2D(_MainTex,i.uv).rgb,_BlurAmount);
        }

        // 维护图像的A通道
        fixed4 fragA(v2f i) : SV_TARGET{
            return tex2D(_MainTex,i.uv);
        }

        ENDCG

        // 用于混合每一帧运动图像的Pass
        Pass{
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment fragRGB

            ENDCG
        }

        // 用于维护A通道的Pass
        Pass{
            Blend One Zero
            ColorMask A

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment fragA

            ENDCG
        }

    }
    FallBack "Diffuse"
    
}