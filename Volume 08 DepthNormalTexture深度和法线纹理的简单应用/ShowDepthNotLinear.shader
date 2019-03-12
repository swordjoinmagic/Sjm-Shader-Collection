/*
    利用后处理效果，在屏幕上显示每个点的非线性深度值
*/
Shader "Volume 08/Depth Normal Texture/Show Depth Texture With Not Linear" {
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

                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv);

                // 在屏幕空间上显示深度图
                return fixed4(1-depth,1-depth,1-depth,1);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}