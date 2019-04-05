/*
    屏幕碎裂的转场效果
*/
Shader "Volume 12/Screen Fade/Breaking Screen" {
    Properties {
        // 屏幕图像
        _MainTex("MainTex",2D) = "white" {}
        // 用于使屏幕呈碎裂效果的法线图(用于uv偏移)
        _DistortionTex("Distortion Texture",2D) = "bump" {}
        _Threshold("_Threshold",Float) = 0
    }
    SubShader {
        Pass {
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            sampler2D _DistortionTex;
            float _Threshold;

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
                // 从法线贴图中获得法线
                half2 bump = UnpackNormal(tex2D(_DistortionTex,i.uv)).xy;

                i.uv.y = (i.uv.y+bump.y*0.5*_Time.y)%1;
                bool result = (i.uv.y+bump.y*0.5 >= _Threshold) ;


                return tex2D(_MainTex,bump*0.5+i.uv) * !result;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}