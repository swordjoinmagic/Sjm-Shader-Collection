/*
    利用后处理效果，在屏幕上显示每个点的深度值
*/
Shader "Volume 08/Depth Normal Texture/Show Depth Texture" {
    Properties {
        _MainTex("Main Texture",2D) = "white" {}
    }
    SubShader {
        Pass {
            CGPROGRAM
            
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag
            
            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

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
                float depthV = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv);
                // 将该深度变换到[0,1]范围内(在近裁剪平面上就是0，在远裁剪平面上就是1)
                fixed depth = Linear01Depth(depthV);

                // 在屏幕空间上显示深度图（近的小，远的大，即深度越大的地方越亮）
                return fixed4(1-depth,1-depth,1-depth,1);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}